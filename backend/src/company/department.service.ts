import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { db } from '../database';
import {
  departments,
  departmentTeams,
  departmentHierarchy,
  teams,
  users,
  teamMembers,
  userRoles,
  roles,
} from '../database/schema';
import { eq, and, isNull, sql, inArray } from 'drizzle-orm';
import { CreateDepartmentDto } from './dto/create-department.dto';
import { MoveTeamToDepartmentDto } from './dto/move-team-to-department.dto';
import { UpdateDepartmentDto } from './dto/update-department.dto';
import { PermissionsService } from './permissions.service';

@Injectable()
export class DepartmentService {
  constructor(private readonly permissionsService: PermissionsService) {}

  async getCompanyDepartments(companyId: string, requestingUserId?: string) {
    // Get user's permission context to filter by scope
    let scopedDepartmentIds: string[] | null = null;
    
    if (requestingUserId) {
      try {
        const context = await this.permissionsService.getUserPermissionContext(requestingUserId, companyId);
        
        // If user has company scope, they can see all departments
        if (context.scopeType === 'company' && !context.scopeId) {
          scopedDepartmentIds = null; // No filtering needed
        }
        // If user has department scope, get that department and all its descendants using closure table
        else if (context.scopeType === 'department' && context.scopeId) {
          // Get all descendant departments using closure table (O(1) query!)
          const descendantDepts = await db
            .select({ deptId: departmentHierarchy.descendantId })
            .from(departmentHierarchy)
            .where(eq(departmentHierarchy.ancestorId, context.scopeId));
          
          scopedDepartmentIds = [context.scopeId, ...descendantDepts.map(d => d.deptId)];
        }
        // If user has team scope, they cannot see departments
        else if (context.scopeType === 'team') {
          scopedDepartmentIds = [];
        }
      } catch (error) {
        // If permission context fails, default to no departments
        scopedDepartmentIds = [];
      }
    }
    // Build where conditions
    const whereConditions = [
      eq(departments.companyId, companyId),
      isNull(departments.deletedAt)
    ];
    
    // Apply scope filtering if needed
    if (scopedDepartmentIds !== null) {
      if (scopedDepartmentIds.length === 0) {
        // No departments in scope, return empty array
        return [];
      }
      whereConditions.push(inArray(departments.id, scopedDepartmentIds));
    }

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
      .where(and(...whereConditions))
      .orderBy(departments.level, departments.name);

    // Get teams for each department
    const departmentTeamsMap = new Map<string, any[]>();
    if (companyDepartments.length > 0) {
      const departmentIds = companyDepartments.map(d => d.id);
      const allDepartmentTeams = await db
        .select({
          departmentId: departmentTeams.departmentId,
          teamId: teams.id,
          teamName: teams.name,
          teamLocation: teams.location,
          memberCount: sql<number>`(
            SELECT COUNT(*)::int
            FROM ${teamMembers}
            WHERE ${teamMembers.teamId} = ${teams.id}
          )`,
        })
        .from(departmentTeams)
        .innerJoin(teams, eq(departmentTeams.teamId, teams.id))
        .where(and(
          inArray(departmentTeams.departmentId, departmentIds),
          isNull(teams.deletedAt),
        ));

      allDepartmentTeams.forEach((dt) => {
        if (!departmentTeamsMap.has(dt.departmentId)) {
          departmentTeamsMap.set(dt.departmentId, []);
        }
        departmentTeamsMap.get(dt.departmentId)!.push({
          id: dt.teamId,
          name: dt.teamName,
          location: dt.teamLocation,
          memberCount: dt.memberCount,
        });
      });
    }

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
      const teams = departmentTeamsMap.get(parent.id) || [];
      return {
        ...parent,
        teams,
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
            inArray(teams.id, createDepartmentDto.teamIds),
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

  async updateDepartment(
    departmentId: string,
    companyId: string,
    updateDepartmentDto: UpdateDepartmentDto,
  ) {
    // Verify department belongs to company
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

    // If updating parent, validate and check for circular references
    if (updateDepartmentDto.parentDepartmentId !== undefined) {
      // If setting to null, it becomes top-level
      if (updateDepartmentDto.parentDepartmentId === null) {
        // Valid - making it top-level
      } else {
        // Verify new parent exists and belongs to company
        const [newParent] = await db
          .select()
          .from(departments)
          .where(
            and(
              eq(departments.id, updateDepartmentDto.parentDepartmentId),
              eq(departments.companyId, companyId),
              isNull(departments.deletedAt),
            ),
          )
          .limit(1);

        if (!newParent) {
          throw new NotFoundException('Parent department not found');
        }

        // Check for circular reference: new parent cannot be a descendant of this department
        const isDescendant = await db
          .select()
          .from(departmentHierarchy)
          .where(
            and(
              eq(departmentHierarchy.ancestorId, departmentId),
              eq(departmentHierarchy.descendantId, updateDepartmentDto.parentDepartmentId),
              sql`${departmentHierarchy.depth} > 0`, // Not self-reference
            ),
          )
          .limit(1);

        if (isDescendant.length > 0) {
          throw new BadRequestException(
            'Cannot move department: would create circular reference',
          );
        }

        // Check if parent is the same as current parent
        if (department.parentDepartmentId === updateDepartmentDto.parentDepartmentId) {
          // No change needed
          updateDepartmentDto.parentDepartmentId = undefined;
        }
      }
    }

    // Verify manager if provided
    if (updateDepartmentDto.managerId !== undefined) {
      if (updateDepartmentDto.managerId === null) {
        // Removing manager - valid
      } else {
        const [managerUser] = await db
          .select()
          .from(users)
          .where(
            and(
              eq(users.id, updateDepartmentDto.managerId),
              eq(users.companyId, companyId),
              isNull(users.deletedAt),
            ),
          )
          .limit(1);

        if (!managerUser) {
          throw new BadRequestException('Manager must belong to your company');
        }
      }
    }

    // Check name uniqueness if updating name
    if (updateDepartmentDto.name && updateDepartmentDto.name !== department.name) {
      const [existingDept] = await db
        .select()
        .from(departments)
        .where(
          and(
            eq(departments.companyId, companyId),
            eq(departments.name, updateDepartmentDto.name),
            isNull(departments.deletedAt),
            sql`${departments.id} != ${departmentId}`, // Exclude current department
          ),
        )
        .limit(1);

      if (existingDept) {
        throw new BadRequestException('Department with this name already exists');
      }
    }

    // Calculate new level and path if parent is changing
    let newLevel = department.level;
    let newPath = department.path;

    if (updateDepartmentDto.parentDepartmentId !== undefined) {
      if (updateDepartmentDto.parentDepartmentId === null) {
        // Becoming top-level
        newLevel = 1;
        newPath = updateDepartmentDto.name || department.name;
      } else {
        // Getting a new parent
        const [parentDept] = await db
          .select()
          .from(departments)
          .where(eq(departments.id, updateDepartmentDto.parentDepartmentId))
          .limit(1);

        if (parentDept) {
          newLevel = parentDept.level + 1;
          newPath = `${parentDept.path || parentDept.name} > ${updateDepartmentDto.name || department.name}`;
        }
      }
    } else if (updateDepartmentDto.name) {
      // Name changed but parent didn't - update path
      if (department.parentDepartmentId) {
        const [parentDept] = await db
          .select()
          .from(departments)
          .where(eq(departments.id, department.parentDepartmentId))
          .limit(1);

        if (parentDept) {
          newPath = `${parentDept.path || parentDept.name} > ${updateDepartmentDto.name}`;
        }
      } else {
        newPath = updateDepartmentDto.name;
      }
    }

    // Update department
    const updateData: any = {};
    if (updateDepartmentDto.name) updateData.name = updateDepartmentDto.name;
    if (updateDepartmentDto.description !== undefined)
      updateData.description = updateDepartmentDto.description;
    if (updateDepartmentDto.parentDepartmentId !== undefined)
      updateData.parentDepartmentId = updateDepartmentDto.parentDepartmentId;
    if (updateDepartmentDto.managerId !== undefined)
      updateData.managerUserId = updateDepartmentDto.managerId;
    if (newLevel !== department.level) updateData.level = newLevel;
    if (newPath !== department.path) updateData.path = newPath;
    updateData.updatedAt = new Date();

    await db.update(departments).set(updateData).where(eq(departments.id, departmentId));

    // If parent changed, rebuild hierarchy for this department and all descendants
    if (updateDepartmentDto.parentDepartmentId !== undefined) {
      // Delete old hierarchy records for this department and its descendants
      const descendants = await db
        .select({ id: departmentHierarchy.descendantId })
        .from(departmentHierarchy)
        .where(eq(departmentHierarchy.ancestorId, departmentId));

      const descendantIds = [departmentId, ...descendants.map((d) => d.id)];

      await db
        .delete(departmentHierarchy)
        .where(inArray(departmentHierarchy.descendantId, descendantIds));

      // Rebuild hierarchy for this department
      await this.buildHierarchy(departmentId, companyId);

      // Rebuild hierarchy for all descendants
      const directChildren = await db
        .select()
        .from(departments)
        .where(eq(departments.parentDepartmentId, departmentId));

      for (const child of directChildren) {
        await this._rebuildDepartmentPathAndHierarchy(child.id, companyId);
      }
    }

    return this.getDepartmentById(departmentId, companyId);
  }

  private async _rebuildDepartmentPathAndHierarchy(
    departmentId: string,
    companyId: string,
  ) {
    const [dept] = await db
      .select()
      .from(departments)
      .where(eq(departments.id, departmentId))
      .limit(1);

    if (!dept) return;

    // Recalculate path
    let newPath = dept.name;
    let newLevel = 1;

    if (dept.parentDepartmentId) {
      const [parent] = await db
        .select()
        .from(departments)
        .where(eq(departments.id, dept.parentDepartmentId))
        .limit(1);

      if (parent) {
        newLevel = parent.level + 1;
        newPath = `${parent.path || parent.name} > ${dept.name}`;
      }
    }

    // Update department
    await db
      .update(departments)
      .set({ path: newPath, level: newLevel })
      .where(eq(departments.id, departmentId));

    // Rebuild hierarchy
    await this.buildHierarchy(departmentId, companyId);

    // Rebuild children
    const children = await db
      .select()
      .from(departments)
      .where(eq(departments.parentDepartmentId, departmentId));

    for (const child of children) {
      await this._rebuildDepartmentPathAndHierarchy(child.id, companyId);
    }
  }

  /**
   * Create department from existing teams (People-First approach)
   * Upgrades manager role if specified
   */
  async createDepartmentFromTeams(dto: {
    companyId: string;
    createdByUserId: string;
    departmentName: string;
    description?: string;
    teamIds: string[];
    managerUserId?: string;
    parentDepartmentId?: string;
  }) {
    // Verify teams belong to company
    const teamList = await db
      .select()
      .from(teams)
      .where(
        and(
          inArray(teams.id, dto.teamIds),
          eq(teams.companyId, dto.companyId),
          isNull(teams.deletedAt),
        ),
      );

    if (teamList.length !== dto.teamIds.length) {
      throw new BadRequestException('Some teams do not belong to your company');
    }

    // Verify manager belongs to company if provided
    if (dto.managerUserId) {
      const [managerUser] = await db
        .select()
        .from(users)
        .where(
          and(
            eq(users.id, dto.managerUserId),
            eq(users.companyId, dto.companyId),
            isNull(users.deletedAt),
          ),
        )
        .limit(1);

      if (!managerUser) {
        throw new BadRequestException('Manager must belong to your company');
      }
    }

    // Verify parent department if provided
    if (dto.parentDepartmentId) {
      const [parentDept] = await db
        .select()
        .from(departments)
        .where(
          and(
            eq(departments.id, dto.parentDepartmentId),
            eq(departments.companyId, dto.companyId),
            isNull(departments.deletedAt),
          ),
        )
        .limit(1);

      if (!parentDept) {
        throw new NotFoundException('Parent department not found');
      }
    }

    return await db.transaction(async (tx) => {
      // 1. Determine level and path
      let level = 1;
      let path = '/';

      if (dto.parentDepartmentId) {
        const [parent] = await tx
          .select({ level: departments.level, path: departments.path })
          .from(departments)
          .where(eq(departments.id, dto.parentDepartmentId))
          .limit(1);

        if (parent) {
          level = parent.level + 1;
          path = `${parent.path}/${dto.parentDepartmentId}`;
        }
      }

      // 2. Create department
      const [newDept] = await tx
        .insert(departments)
        .values({
          companyId: dto.companyId,
          name: dto.departmentName,
          description: dto.description,
          parentDepartmentId: dto.parentDepartmentId,
          level,
          path,
          managerUserId: dto.managerUserId,
        })
        .returning();

      const deptId = newDept.id;

      // 3. Insert into closure table (self + all ancestors)
      await tx
        .insert(departmentHierarchy)
        .values({
          ancestorId: deptId,
          descendantId: deptId,
          depth: 0,
        })
        .onConflictDoNothing();

      if (dto.parentDepartmentId) {
        // Copy all ancestors of parent, incrementing depth
        const parentAncestors = await tx
          .select()
          .from(departmentHierarchy)
          .where(eq(departmentHierarchy.descendantId, dto.parentDepartmentId));

        if (parentAncestors.length > 0) {
          await tx.insert(departmentHierarchy).values(
            parentAncestors.map(ancestor => ({
              ancestorId: ancestor.ancestorId,
              descendantId: deptId,
              depth: ancestor.depth + 1,
            })),
          ).onConflictDoNothing();
        }
      }

      // 4. Link teams to department
      const teamLinks = dto.teamIds.map(teamId => ({
        departmentId: deptId,
        teamId,
      }));

      await tx.insert(departmentTeams).values(teamLinks).onConflictDoNothing();

      // 5. If manager specified, upgrade their role
      if (dto.managerUserId) {
        // Get "Manager" role
        const [managerRole] = await tx
          .select()
          .from(roles)
          .where(
            and(
              eq(roles.companyId, dto.companyId),
              eq(roles.roleType, 'manager'),
              isNull(roles.deletedAt),
            ),
          )
          .limit(1);

        if (managerRole) {
          // Update user's role to department scope
          await tx
            .update(userRoles)
            .set({
              roleId: managerRole.id,
              scopeType: 'department',
              scopeId: deptId,
            })
            .where(eq(userRoles.userId, dto.managerUserId));
        }
      }

      return this.getDepartmentById(deptId, dto.companyId);
    });
  }
}

