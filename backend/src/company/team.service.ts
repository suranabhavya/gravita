import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { db } from '../database';
import { teams, teamMembers, users, companies, materialListings, departmentTeams } from '../database/schema';
import { eq, and, isNull, sql, count, desc, inArray } from 'drizzle-orm';
import { CreateTeamDto } from './dto/create-team.dto';
import { UpdateTeamDto } from './dto/update-team.dto';
import { AddTeamMembersDto } from './dto/add-team-members.dto';

@Injectable()
export class TeamService {
  async getCompanyTeams(companyId: string) {
    const companyTeams = await db
      .select({
        id: teams.id,
        name: teams.name,
        description: teams.description,
        location: teams.location,
        teamLeadId: teams.teamLeadUserId,
        teamLeadName: users.name,
        teamLeadEmail: users.email,
        createdAt: teams.createdAt,
        memberCount: sql<number>`(
          SELECT COUNT(*)::int
          FROM ${teamMembers}
          WHERE ${teamMembers.teamId} = ${teams.id}
        )`,
        activeListingsCount: sql<number>`(
          SELECT COUNT(*)::int
          FROM ${materialListings}
          WHERE ${materialListings.teamId} = ${teams.id}
            AND ${materialListings.status} = 'listed'
            AND ${materialListings.deletedAt} IS NULL
        )`,
      })
      .from(teams)
      .leftJoin(users, eq(teams.teamLeadUserId, users.id))
      .where(and(eq(teams.companyId, companyId), isNull(teams.deletedAt)))
      .orderBy(desc(teams.createdAt));

    return companyTeams;
  }

  async getTeamById(teamId: string, companyId: string) {
    const [team] = await db
      .select({
        id: teams.id,
        name: teams.name,
        description: teams.description,
        location: teams.location,
        teamLeadId: teams.teamLeadUserId,
        companyId: teams.companyId,
        createdAt: teams.createdAt,
        updatedAt: teams.updatedAt,
      })
      .from(teams)
      .where(and(eq(teams.id, teamId), eq(teams.companyId, companyId), isNull(teams.deletedAt)))
      .limit(1);

    if (!team) {
      throw new NotFoundException('Team not found');
    }

    // Get team lead info
    let teamLead = null;
    if (team.teamLeadId) {
      const [lead] = await db
        .select({
          id: users.id,
          name: users.name,
          email: users.email,
          avatarUrl: users.avatarUrl,
        })
        .from(users)
        .where(eq(users.id, team.teamLeadId))
        .limit(1);
      teamLead = lead;
    }

    // Get team members
    const members = await db
      .select({
        id: users.id,
        name: users.name,
        email: users.email,
        avatarUrl: users.avatarUrl,
        joinedAt: teamMembers.joinedAt,
      })
      .from(teamMembers)
      .innerJoin(users, eq(teamMembers.userId, users.id))
      .where(eq(teamMembers.teamId, teamId));

    // Get team stats
    const [stats] = await db
      .select({
        memberCount: sql<number>`COUNT(DISTINCT ${teamMembers.userId})::int`,
        activeListingsCount: sql<number>`COUNT(CASE WHEN ${materialListings.status} = 'listed' AND ${materialListings.deletedAt} IS NULL THEN 1 END)::int`,
        totalValue: sql<number>`COALESCE(SUM(CASE WHEN ${materialListings.status} = 'listed' AND ${materialListings.deletedAt} IS NULL THEN ${materialListings.estimatedValue} ELSE 0 END), 0)::numeric`,
      })
      .from(teamMembers)
      .leftJoin(materialListings, eq(materialListings.teamId, teamId))
      .where(eq(teamMembers.teamId, teamId));

    return {
      ...team,
      teamLead,
      members,
      stats: {
        memberCount: stats.memberCount || 0,
        activeListingsCount: stats.activeListingsCount || 0,
        totalValue: stats.totalValue || 0,
      },
    };
  }

  async createTeam(companyId: string, createTeamDto: CreateTeamDto) {
    console.log('[TeamService] Creating team:', {
      companyId,
      name: createTeamDto.name,
      memberIds: createTeamDto.memberIds,
      teamLeadId: createTeamDto.teamLeadId,
    });

    // Verify all members belong to the company
    const memberUsers = await db
      .select()
      .from(users)
      .where(
        and(
          inArray(users.id, createTeamDto.memberIds),
          eq(users.companyId, companyId),
          isNull(users.deletedAt),
        ),
      );

    console.log('[TeamService] Found members:', {
      requested: createTeamDto.memberIds.length,
      found: memberUsers.length,
      memberIds: memberUsers.map(u => u.id),
    });

    if (memberUsers.length !== createTeamDto.memberIds.length) {
      const foundIds = memberUsers.map(u => u.id);
      const missingIds = createTeamDto.memberIds.filter(id => !foundIds.includes(id));
      throw new BadRequestException(`Some members do not belong to your company. Missing: ${missingIds.join(', ')}`);
    }

    // Check if team name already exists
    const [existingTeam] = await db
      .select()
      .from(teams)
      .where(
        and(eq(teams.companyId, companyId), eq(teams.name, createTeamDto.name), isNull(teams.deletedAt)),
      )
      .limit(1);

    if (existingTeam) {
      throw new BadRequestException('Team with this name already exists');
    }

    // Verify team lead is in member list if provided
    if (createTeamDto.teamLeadId && !createTeamDto.memberIds.includes(createTeamDto.teamLeadId)) {
      throw new BadRequestException('Team lead must be one of the selected members');
    }

    // Use transaction to ensure atomicity
    const result = await db.transaction(async (tx) => {
      // Create team
      const [newTeam] = await tx
        .insert(teams)
        .values({
          companyId,
          name: createTeamDto.name,
          description: createTeamDto.description,
          location: createTeamDto.location,
          teamLeadUserId: createTeamDto.teamLeadId || createTeamDto.memberIds[0], // Default to first member
        })
        .returning();

      console.log('[TeamService] Team created:', newTeam.id);

      // Add members to team
      if (createTeamDto.memberIds.length > 0) {
        await tx.insert(teamMembers).values(
          createTeamDto.memberIds.map((userId) => ({
            teamId: newTeam.id,
            userId,
          })),
        );
        console.log('[TeamService] Team members added:', createTeamDto.memberIds.length);
      }

      return newTeam;
    });

    console.log('[TeamService] Team creation completed successfully');
    return this.getTeamById(result.id, companyId);
  }

  async updateTeam(teamId: string, companyId: string, updateTeamDto: UpdateTeamDto) {
    const [team] = await db
      .select()
      .from(teams)
      .where(and(eq(teams.id, teamId), eq(teams.companyId, companyId), isNull(teams.deletedAt)))
      .limit(1);

    if (!team) {
      throw new NotFoundException('Team not found');
    }

    // Check name uniqueness if name is being updated
    if (updateTeamDto.name && updateTeamDto.name !== team.name) {
      const [existingTeam] = await db
        .select()
        .from(teams)
        .where(
          and(
            eq(teams.companyId, companyId),
            eq(teams.name, updateTeamDto.name),
            isNull(teams.deletedAt),
          ),
        )
        .limit(1);

      if (existingTeam) {
        throw new BadRequestException('Team with this name already exists');
      }
    }

    // Verify team lead belongs to company if provided
    if (updateTeamDto.teamLeadId) {
      const [leadUser] = await db
        .select()
        .from(users)
        .where(
          and(
            eq(users.id, updateTeamDto.teamLeadId),
            eq(users.companyId, companyId),
            isNull(users.deletedAt),
          ),
        )
        .limit(1);

      if (!leadUser) {
        throw new BadRequestException('Team lead must belong to your company');
      }
    }

    const [updatedTeam] = await db
      .update(teams)
      .set({
        name: updateTeamDto.name,
        description: updateTeamDto.description,
        location: updateTeamDto.location,
        teamLeadUserId: updateTeamDto.teamLeadId,
        updatedAt: new Date(),
      })
      .where(eq(teams.id, teamId))
      .returning();

    return this.getTeamById(updatedTeam.id, companyId);
  }

  async addTeamMembers(teamId: string, companyId: string, addMembersDto: AddTeamMembersDto) {
    const [team] = await db
      .select()
      .from(teams)
      .where(and(eq(teams.id, teamId), eq(teams.companyId, companyId), isNull(teams.deletedAt)))
      .limit(1);

    if (!team) {
      throw new NotFoundException('Team not found');
    }

    // Verify all users belong to the company
    const memberUsers = await db
      .select()
      .from(users)
      .where(
        and(
          sql`${users.id} = ANY(${addMembersDto.userIds})`,
          eq(users.companyId, companyId),
          isNull(users.deletedAt),
        ),
      );

    if (memberUsers.length !== addMembersDto.userIds.length) {
      throw new BadRequestException('Some users do not belong to your company');
    }

    // Check if users are already in the team
    const existingMembers = await db
      .select()
      .from(teamMembers)
      .where(
        and(
          eq(teamMembers.teamId, teamId),
          sql`${teamMembers.userId} = ANY(${addMembersDto.userIds})`,
        ),
      );

    if (existingMembers.length > 0) {
      throw new BadRequestException('Some users are already members of this team');
    }

    // Add members
    await db.insert(teamMembers).values(
      addMembersDto.userIds.map((userId) => ({
        teamId,
        userId,
      })),
    );

    return this.getTeamById(teamId, companyId);
  }

  async removeTeamMember(teamId: string, companyId: string, userId: string) {
    const [team] = await db
      .select()
      .from(teams)
      .where(and(eq(teams.id, teamId), eq(teams.companyId, companyId), isNull(teams.deletedAt)))
      .limit(1);

    if (!team) {
      throw new NotFoundException('Team not found');
    }

    // Don't allow removing team lead
    if (team.teamLeadUserId === userId) {
      throw new BadRequestException('Cannot remove team lead. Assign a new team lead first.');
    }

    await db
      .delete(teamMembers)
      .where(and(eq(teamMembers.teamId, teamId), eq(teamMembers.userId, userId)));

    return { success: true };
  }

  async dissolveTeam(teamId: string, companyId: string) {
    const [team] = await db
      .select()
      .from(teams)
      .where(and(eq(teams.id, teamId), eq(teams.companyId, companyId), isNull(teams.deletedAt)))
      .limit(1);

    if (!team) {
      throw new NotFoundException('Team not found');
    }

    // Soft delete team
    await db
      .update(teams)
      .set({ deletedAt: new Date() })
      .where(eq(teams.id, teamId));

    // Remove all team members
    await db.delete(teamMembers).where(eq(teamMembers.teamId, teamId));

    // Remove team from departments
    await db.delete(departmentTeams).where(eq(departmentTeams.teamId, teamId));

    return { success: true };
  }
}

