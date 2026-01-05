import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { db } from '../database';
import { users, teamMembers, teams, userRoles, roles, departments, departmentTeams, departmentHierarchy } from '../database/schema';
import { eq, and, isNull, sql, or, like, ilike, inArray } from 'drizzle-orm';
import { PermissionsService } from './permissions.service';
import { AssignRoleDto, RoleType, ScopeType } from './dto/assign-role.dto';

@Injectable()
export class UserService {
  constructor(private readonly permissionsService: PermissionsService) {}

  async getCompanyMembers(companyId: string, filters?: { search?: string; teamId?: string; roleId?: string; requestingUserId?: string }) {
    // Get user's permission context to filter by scope
    let scopedUserIds: string[] | null = null;
    
    if (filters?.requestingUserId) {
      try {
        const context = await this.permissionsService.getUserPermissionContext(filters.requestingUserId, companyId);
        
        // If user has company scope, they can see all members
        if (context.scopeType === 'company') {
          scopedUserIds = null; // No filtering needed
        }
        // If user has department scope with null scopeId, they can see all departments (company-wide manager)
        else if (context.scopeType === 'department' && !context.scopeId) {
          scopedUserIds = null; // No filtering needed - can see all company members
        }
        // If user has department scope with specific department ID
        else if (context.scopeType === 'department' && context.scopeId) {
          // Get all descendant departments using closure table
          const descendantDepts = await db
            .select({ deptId: departmentHierarchy.descendantId })
            .from(departmentHierarchy)
            .where(eq(departmentHierarchy.ancestorId, context.scopeId));
          
          const deptIds = [context.scopeId, ...descendantDepts.map(d => d.deptId)];
          
          // Get teams in those departments
          const teamsInDepts = await db
            .select({ teamId: departmentTeams.teamId })
            .from(departmentTeams)
            .where(inArray(departmentTeams.departmentId, deptIds));
          
          const teamIds = teamsInDepts.map(t => t.teamId);
          
          if (teamIds.length === 0) {
            scopedUserIds = [];
          } else {
            // Get users in those teams
            const usersInTeams = await db
              .select({ userId: teamMembers.userId })
              .from(teamMembers)
              .where(inArray(teamMembers.teamId, teamIds));
            
            scopedUserIds = usersInTeams.map(u => u.userId);
          }
        }
        // If user has team scope, they can only see members of their team
        else if (context.scopeType === 'team' && context.scopeId) {
          const usersInTeam = await db
            .select({ userId: teamMembers.userId })
            .from(teamMembers)
            .where(eq(teamMembers.teamId, context.scopeId));
          
          scopedUserIds = usersInTeam.map(u => u.userId);
        }
      } catch (error) {
        // If permission context fails, default to no users
        scopedUserIds = [];
      }
    }
    // Build where conditions dynamically
    const whereConditions = [
      eq(users.companyId, companyId),
      isNull(users.deletedAt),
      eq(users.status, 'active'),
    ];

    // Apply scope filtering if needed
    if (scopedUserIds !== null) {
      if (scopedUserIds.length === 0) {
        // No users in scope, return empty result
        return {
          members: [],
          groupedByTeam: {},
          unassignedCount: 0,
        };
      }
      whereConditions.push(inArray(users.id, scopedUserIds));
    }

    if (filters?.search) {
      whereConditions.push(
        or(
          ilike(users.name, `%${filters.search}%`),
          ilike(users.email, `%${filters.search}%`),
        )!,
      );
    }

    if (filters?.teamId) {
      whereConditions.push(eq(teamMembers.teamId, filters.teamId));
    }

    if (filters?.roleId) {
      whereConditions.push(eq(userRoles.roleId, filters.roleId));
    }

    const members = await db
      .select({
        id: users.id,
        name: users.name,
        email: users.email,
        avatarUrl: users.avatarUrl,
        phone: users.phone,
        status: users.status,
        createdAt: users.createdAt,
        teamId: teams.id,
        teamName: teams.name,
        isTeamLead: sql<boolean>`${teams.teamLeadUserId} = ${users.id}`,
        roleName: roles.name,
      })
      .from(users)
      .leftJoin(teamMembers, eq(users.id, teamMembers.userId))
      .leftJoin(teams, eq(teamMembers.teamId, teams.id))
      .leftJoin(userRoles, eq(users.id, userRoles.userId))
      .leftJoin(roles, eq(userRoles.roleId, roles.id))
      .where(and(...whereConditions));

    // Group by user (since one user can have multiple teams/roles)
    const memberMap = new Map<string, any>();

    members.forEach((member) => {
      if (!memberMap.has(member.id)) {
        memberMap.set(member.id, {
          id: member.id,
          name: member.name,
          email: member.email,
          avatarUrl: member.avatarUrl,
          phone: member.phone,
          status: member.status,
          createdAt: member.createdAt,
          teams: [],
          roles: [],
        });
      }

      const userData = memberMap.get(member.id)!;
      if (member.teamId && !userData.teams.some((t: any) => t.id === member.teamId)) {
        userData.teams.push({
          id: member.teamId,
          name: member.teamName,
          isTeamLead: member.isTeamLead,
        });
      }

      if (member.roleName && !userData.roles.includes(member.roleName)) {
        userData.roles.push(member.roleName);
      }
    });

    // Get unassigned members
    const unassignedMembers = Array.from(memberMap.values()).filter((m) => m.teams.length === 0);

    // Group by team
    const teamMap = new Map<string, any[]>();
    Array.from(memberMap.values()).forEach((member) => {
      if (member.teams.length === 0) {
        if (!teamMap.has('unassigned')) {
          teamMap.set('unassigned', []);
        }
        teamMap.get('unassigned')!.push(member);
      } else {
        member.teams.forEach((team: any) => {
          if (!teamMap.has(team.id)) {
            teamMap.set(team.id, []);
          }
          teamMap.get(team.id)!.push(member);
        });
      }
    });

    return {
      members: Array.from(memberMap.values()),
      groupedByTeam: Object.fromEntries(teamMap),
      unassignedCount: unassignedMembers.length,
    };
  }

  async getUserById(userId: string, companyId: string) {
    const [user] = await db
      .select()
      .from(users)
      .where(
        and(
          eq(users.id, userId),
          eq(users.companyId, companyId),
          isNull(users.deletedAt),
        ),
      )
      .limit(1);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Get user's teams
    const userTeams = await db
      .select({
        id: teams.id,
        name: teams.name,
        location: teams.location,
        isTeamLead: sql<boolean>`${teams.teamLeadUserId} = ${users.id}`,
        joinedAt: teamMembers.joinedAt,
      })
      .from(teamMembers)
      .innerJoin(teams, eq(teamMembers.teamId, teams.id))
      .where(and(eq(teamMembers.userId, userId), isNull(teams.deletedAt)));

    // Get user's roles
    const userRolesList = await db
      .select({
        id: roles.id,
        name: roles.name,
        description: roles.description,
        scopeType: userRoles.scopeType,
        scopeId: userRoles.scopeId,
      })
      .from(userRoles)
      .innerJoin(roles, eq(userRoles.roleId, roles.id))
      .where(eq(userRoles.userId, userId));

    return {
      ...user,
      teams: userTeams,
      roles: userRolesList,
    };
  }

  async getCompanyStats(companyId: string) {
    const [stats] = await db
      .select({
        totalMembers: sql<number>`COUNT(DISTINCT ${users.id})::int`,
        unassignedMembers: sql<number>`COUNT(DISTINCT CASE WHEN NOT EXISTS (
          SELECT 1 FROM ${teamMembers} WHERE ${teamMembers.userId} = ${users.id}
        ) THEN ${users.id} END)::int`,
        totalTeams: sql<number>`COUNT(DISTINCT ${teams.id})::int`,
      })
      .from(users)
      .leftJoin(teamMembers, eq(users.id, teamMembers.userId))
      .leftJoin(teams, eq(teamMembers.teamId, teams.id))
      .where(and(eq(users.companyId, companyId), isNull(users.deletedAt), eq(users.status, 'active')));

    // Get department count separately
    const [deptStats] = await db
      .select({ count: sql<number>`COUNT(*)::int` })
      .from(departments)
      .where(and(eq(departments.companyId, companyId), isNull(departments.deletedAt)));

    return {
      totalMembers: stats.totalMembers || 0,
      unassignedMembers: stats.unassignedMembers || 0,
      totalTeams: stats.totalTeams || 0,
      totalDepartments: deptStats?.count || 0,
    };
  }

  async assignRole(
    assignRoleDto: AssignRoleDto,
    companyId: string,
    requestingUserId: string,
  ) {
    const { userId, roleType, scopeType, scopeId, maxApprovalAmountOverride } = assignRoleDto;

    // Verify target user exists and belongs to company
    const [targetUser] = await db
      .select()
      .from(users)
      .where(
        and(
          eq(users.id, userId),
          eq(users.companyId, companyId),
          isNull(users.deletedAt),
        ),
      )
      .limit(1);

    if (!targetUser) {
      throw new NotFoundException('User not found');
    }

    // Get requesting user's permission context
    const requestingUserContext = await this.permissionsService.getUserPermissionContext(
      requestingUserId,
      companyId,
    );

    // Permission checks based on requesting user's role
    if (requestingUserContext.roleType === 'member') {
      throw new ForbiddenException('Members cannot assign roles');
    }

    // Leads can only assign member roles to their own team
    if (requestingUserContext.roleType === 'lead') {
      if (roleType !== 'member') {
        throw new ForbiddenException('Team leads can only assign member roles');
      }
      if (scopeType !== 'team' || scopeId !== requestingUserContext.scopeId) {
        throw new ForbiddenException('Team leads can only assign roles within their team');
      }
    }

    // Managers cannot assign admin roles
    if (requestingUserContext.roleType === 'manager' && roleType === 'admin') {
      throw new ForbiddenException('Managers cannot assign admin roles');
    }

    // Validate scope for role type
    const determinedScopeType = scopeType || this.getDefaultScopeForRole(roleType);

    // Determine scope ID based on role type and provided values
    let determinedScopeId: string | null;
    if (scopeId) {
      // Explicitly provided scope ID
      determinedScopeId = scopeId;
    } else if (determinedScopeType === 'company') {
      // Company-wide roles don't need a scope ID
      determinedScopeId = null;
    } else if (roleType === 'manager') {
      // Managers without explicit department get company-wide department access (null scopeId)
      determinedScopeId = null;
    } else {
      // For leads and members, use requesting user's scope (their team/department)
      determinedScopeId = requestingUserContext.scopeId || null;
    }

    // Find system role
    const [systemRole] = await db
      .select()
      .from(roles)
      .where(
        and(
          eq(roles.companyId, companyId),
          eq(roles.roleType, roleType),
          eq(roles.isSystemRole, true),
        ),
      )
      .limit(1);

    if (!systemRole) {
      throw new BadRequestException(`System role for ${roleType} not found. Please contact support.`);
    }

    // Remove existing role assignments for this user
    await db
      .delete(userRoles)
      .where(eq(userRoles.userId, userId));

    // Create new role assignment
    const [newRoleAssignment] = await db
      .insert(userRoles)
      .values({
        userId,
        roleId: systemRole.id,
        scopeType: determinedScopeType,
        scopeId: determinedScopeId,
        maxApprovalAmountOverride: maxApprovalAmountOverride?.toString(),
        grantedByUserId: requestingUserId,
        grantedAt: new Date(),
      })
      .returning();

    return {
      success: true,
      roleAssignment: newRoleAssignment,
      message: `Role ${roleType} assigned successfully`,
    };
  }

  private getDefaultScopeForRole(roleType: RoleType): ScopeType {
    switch (roleType) {
      case RoleType.ADMIN:
        return ScopeType.COMPANY;
      case RoleType.MANAGER:
        return ScopeType.DEPARTMENT;
      case RoleType.LEAD:
      case RoleType.MEMBER:
        return ScopeType.TEAM;
    }
  }
}

