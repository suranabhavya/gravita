import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { db } from '../database';
import {
  departments,
  departmentTeams,
  departmentHierarchy,
  teams,
  users,
  teamMembers,
} from '../database/schema';
import { eq, and, isNull, sql } from 'drizzle-orm';
import { CreateDepartmentDto } from './dto/create-department.dto';
import { MoveTeamToDepartmentDto } from './dto/move-team-to-department.dto';

@Injectable()
export class DepartmentService {
  async getCompanyDepartments(companyId: string) {
    const companyDepartments = await db
      .select({
        id: departments.id,
        name: departments.name,
        description: departments.description,
        parentDepartmentId: departments.parentDepartmentId,
        level: departments.level,
        managerId: departments.managerUserId,
        managerName: users.name,
        managerEmail: users.email,
        createdAt: departments.createdAt,
        teamCount: sql<number>`(
          SELECT COUNT(*)::int
          FROM ${departmentTeams}
          WHERE ${departmentTeams.departmentId} = ${departments.id}
        )`,
        memberCount: sql<number>`(
          SELECT COUNT(DISTINCT ${teamMembers.userId})::int
          FROM ${departmentTeams}
          INNER JOIN ${teams} ON ${departmentTeams.teamId} = ${teams.id}
          INNER JOIN ${teamMembers} ON ${teams.id} = ${teamMembers.teamId}
          WHERE ${departmentTeams.departmentId} = ${departments.id}
        )`,
      })
      .from(departments)
      .leftJoin(users, eq(departments.managerUserId, users.id))
      .where(and(eq(departments.companyId, companyId), isNull(departments.deletedAt)))
      .orderBy(departments.level, departments.name);

    // Build hierarchy
    const rootDepartments = companyDepartments.filter((dept) => !dept.parentDepartmentId);
    const childrenMap = new Map<string, typeof companyDepartments>();

    companyDepartments.forEach((dept) => {
      if (dept.parentDepartmentId) {
        if (!childrenMap.has(dept.parentDepartmentId)) {
          childrenMap.set(dept.parentDepartmentId, []);
        }
        childrenMap.get(dept.parentDepartmentId)!.push(dept);
      }
    });

    const buildTree = (parent: (typeof companyDepartments)[0]): any => {
      const children = childrenMap.get(parent.id) || [];
      return {
        ...parent,
        children: children.map(buildTree),
      };
    };

    return rootDepartments.map(buildTree);
  }

  async getDepartmentById(departmentId: string, companyId: string) {
    const [department] = await db
      .select()
      .from(departments)
      .where(
        and(
          eq(departments.id, departmentId),
          eq(departments.companyId, companyId),
          isNull(departments.deletedAt),
        ),
      )
      .limit(1);

    if (!department) {
      throw new NotFoundException('Department not found');
    }

    // Get manager info
    let manager = null;
    if (department.managerUserId) {
      const [managerUser] = await db
        .select({
          id: users.id,
          name: users.name,
          email: users.email,
          avatarUrl: users.avatarUrl,
        })
        .from(users)
        .where(eq(users.id, department.managerUserId))
        .limit(1);
      manager = managerUser;
    }

    // Get teams in department
    const departmentTeamsList = await db
      .select({
        id: teams.id,
        name: teams.name,
        location: teams.location,
        memberCount: sql<number>`(
          SELECT COUNT(*)::int
          FROM ${teamMembers}
          WHERE ${teamMembers.teamId} = ${teams.id}
        )`,
      })
      .from(departmentTeams)
      .innerJoin(teams, eq(departmentTeams.teamId, teams.id))
      .where(and(eq(departmentTeams.departmentId, departmentId), isNull(teams.deletedAt)));

    return {
      ...department,
      manager,
      teams: departmentTeamsList,
    };
  }

  async createDepartment(companyId: string, createDepartmentDto: CreateDepartmentDto) {
    // Check if department name already exists
    const [existingDept] = await db
      .select()
      .from(departments)
      .where(
        and(
          eq(departments.companyId, companyId),
          eq(departments.name, createDepartmentDto.name),
          isNull(departments.deletedAt),
        ),
      )
      .limit(1);

    if (existingDept) {
      throw new BadRequestException('Department with this name already exists');
    }

    // Calculate level and path if parent is provided
    let level = 1;
    let path = createDepartmentDto.name;

    if (createDepartmentDto.parentDepartmentId) {
      const [parentDept] = await db
        .select()
        .from(departments)
        .where(
          and(
            eq(departments.id, createDepartmentDto.parentDepartmentId),
            eq(departments.companyId, companyId),
            isNull(departments.deletedAt),
          ),
        )
        .limit(1);

      if (!parentDept) {
        throw new NotFoundException('Parent department not found');
      }

      level = parentDept.level + 1;
      path = `${parentDept.path || parentDept.name} > ${createDepartmentDto.name}`;
    }

    // Verify manager belongs to company if provided
    if (createDepartmentDto.managerId) {
      const [managerUser] = await db
        .select()
        .from(users)
        .where(
          and(
            eq(users.id, createDepartmentDto.managerId),
            eq(users.companyId, companyId),
            isNull(users.deletedAt),
          ),
        )
        .limit(1);

      if (!managerUser) {
        throw new BadRequestException('Manager must belong to your company');
      }
    }

    // Create department
    const [newDepartment] = await db
      .insert(departments)
      .values({
        companyId,
        name: createDepartmentDto.name,
        description: createDepartmentDto.description,
        parentDepartmentId: createDepartmentDto.parentDepartmentId,
        level,
        path,
        managerUserId: createDepartmentDto.managerId,
      })
      .returning();

    // Add teams to department if provided
    if (createDepartmentDto.teamIds && createDepartmentDto.teamIds.length > 0) {
      // Verify teams belong to company
      const teamList = await db
        .select()
        .from(teams)
        .where(
          and(
            sql`${teams.id} = ANY(${createDepartmentDto.teamIds})`,
            eq(teams.companyId, companyId),
            isNull(teams.deletedAt),
          ),
        );

      if (teamList.length !== createDepartmentDto.teamIds.length) {
        throw new BadRequestException('Some teams do not belong to your company');
      }

      // Add teams to department
      await db.insert(departmentTeams).values(
        createDepartmentDto.teamIds.map((teamId) => ({
          departmentId: newDepartment.id,
          teamId,
        })),
      );
    }

    // Build hierarchy records
    await this.buildHierarchy(newDepartment.id, companyId);

    return this.getDepartmentById(newDepartment.id, companyId);
  }

  private async buildHierarchy(departmentId: string, companyId: string) {
    const [dept] = await db
      .select()
      .from(departments)
      .where(eq(departments.id, departmentId))
      .limit(1);

    if (!dept) return;

    // Self-reference
    await db
      .insert(departmentHierarchy)
      .values({
        ancestorId: departmentId,
        descendantId: departmentId,
        depth: 0,
      })
      .onConflictDoNothing();

    // If has parent, inherit parent's ancestors
    if (dept.parentDepartmentId) {
      const parentAncestors = await db
        .select()
        .from(departmentHierarchy)
        .where(eq(departmentHierarchy.descendantId, dept.parentDepartmentId));

      for (const ancestor of parentAncestors) {
        await db
          .insert(departmentHierarchy)
          .values({
            ancestorId: ancestor.ancestorId,
            descendantId: departmentId,
            depth: ancestor.depth + 1,
          })
          .onConflictDoNothing();
      }
    }
  }

  async moveTeamToDepartment(
    teamId: string,
    companyId: string,
    moveTeamDto: MoveTeamToDepartmentDto,
  ) {
    // Verify team belongs to company
    const [team] = await db
      .select()
      .from(teams)
      .where(and(eq(teams.id, teamId), eq(teams.companyId, companyId), isNull(teams.deletedAt)))
      .limit(1);

    if (!team) {
      throw new NotFoundException('Team not found');
    }

    // Verify department belongs to company
    const [department] = await db
      .select()
      .from(departments)
      .where(
        and(
          eq(departments.id, moveTeamDto.departmentId),
          eq(departments.companyId, companyId),
          isNull(departments.deletedAt),
        ),
      )
      .limit(1);

    if (!department) {
      throw new NotFoundException('Department not found');
    }

    // Remove team from any existing department
    await db.delete(departmentTeams).where(eq(departmentTeams.teamId, teamId));

    // Add team to new department
    await db.insert(departmentTeams).values({
      departmentId: moveTeamDto.departmentId,
      teamId,
    });

    return { success: true };
  }

  async removeTeamFromDepartment(teamId: string, companyId: string) {
    // Verify team belongs to company
    const [team] = await db
      .select()
      .from(teams)
      .where(and(eq(teams.id, teamId), eq(teams.companyId, companyId), isNull(teams.deletedAt)))
      .limit(1);

    if (!team) {
      throw new NotFoundException('Team not found');
    }

    await db.delete(departmentTeams).where(eq(departmentTeams.teamId, teamId));

    return { success: true };
  }
}

