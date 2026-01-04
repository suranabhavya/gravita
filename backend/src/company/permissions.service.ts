import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { db } from '../database';
import { 
  users, 
  roles, 
  userRoles, 
  departments, 
  teams, 
  departmentHierarchy,
  departmentTeams,
  teamMembers,
  materialListings,
  companies,
  SimplifiedPermissions 
} from '../database/schema';
import { eq, and, isNull, or, sql, inArray } from 'drizzle-orm';

export interface UserPermissionContext {
  userId: string;
  companyId: string;
  roleType: 'admin' | 'manager' | 'lead' | 'member';
  permissions: {
    canManageStructure: boolean;
    canApproveListings: boolean;
    canAccessSettings: boolean;
  };
  scopeType: 'company' | 'department' | 'team';
  scopeId: string | null;
  maxApprovalAmount: number;
}

// Keep for backward compatibility
export type UserRoleInfo = {
  roleType: 'admin' | 'manager' | 'lead' | 'member';
  scopeType: 'company' | 'department' | 'team';
  scopeId: string | null;
  maxApprovalAmount: string; // decimal as string
  permissions: SimplifiedPermissions;
};

@Injectable()
export class PermissionsService {
  /**
   * Get user's complete permission context
   * This is the main method called at auth time
   */
  async getUserPermissionContext(userId: string, companyId: string): Promise<UserPermissionContext> {
    // Get user's role assignment
    const userRoleData = await db
      .select({
        roleType: roles.roleType,
        permissions: roles.permissions,
        maxApprovalAmount: roles.maxApprovalAmount,
        scopeType: userRoles.scopeType,
        scopeId: userRoles.scopeId,
        override: userRoles.maxApprovalAmountOverride,
      })
      .from(userRoles)
      .innerJoin(roles, eq(userRoles.roleId, roles.id))
      .where(
        and(
          eq(userRoles.userId, userId),
          eq(roles.companyId, companyId),
          isNull(roles.deletedAt),
        ),
      )
      .limit(1);

    if (!userRoleData.length) {
      throw new Error('User has no role assigned');
    }

    const data = userRoleData[0];

    // Use override if exists, otherwise use role's default
    const effectiveApprovalLimit = data.override 
      ? parseFloat(data.override) 
      : parseFloat(data.maxApprovalAmount || '0');

    const permissions = (data.permissions as SimplifiedPermissions) || {
      canManageStructure: false,
      canApproveListings: false,
      canAccessSettings: false,
    };

    return {
      userId,
      companyId,
      roleType: data.roleType as 'admin' | 'manager' | 'lead' | 'member',
      permissions: {
        canManageStructure: permissions.canManageStructure ?? false,
        canApproveListings: permissions.canApproveListings ?? false,
        canAccessSettings: permissions.canAccessSettings ?? false,
      },
      scopeType: data.scopeType,
      scopeId: data.scopeId,
      maxApprovalAmount: effectiveApprovalLimit,
    };
  }

  /**
   * Get user's role information (role type, scope, and max approval amount)
   * Returns the highest privilege role if user has multiple roles
   * @deprecated Use getUserPermissionContext instead
   */
  async getUserRoleInfo(userId: string, companyId: string): Promise<UserRoleInfo | null> {
    try {
      const context = await this.getUserPermissionContext(userId, companyId);
      return {
        roleType: context.roleType,
        scopeType: context.scopeType,
        scopeId: context.scopeId,
        maxApprovalAmount: context.maxApprovalAmount.toString(),
        permissions: context.permissions,
      };
    } catch {
      return null;
    }
  }

  /**
   * Get simplified permissions for a user based on their role
   */
  async getUserPermissions(userId: string, companyId: string): Promise<SimplifiedPermissions> {
    const roleInfo = await this.getUserRoleInfo(userId, companyId);
    
    if (!roleInfo) {
      // Default to no permissions if no role assigned
      return {
        canManageStructure: false,
        canApproveListings: false,
        canAccessSettings: false,
      };
    }

    return roleInfo.permissions;
  }

  /**
   * Check if user is admin
   */
  async isAdmin(userId: string, companyId: string): Promise<boolean> {
    const roleInfo = await this.getUserRoleInfo(userId, companyId);
    return roleInfo?.roleType === 'admin';
  }

  /**
   * Check if user can manage structure (create/edit teams, departments, add members)
   */
  async canManageStructure(
    userId: string,
    companyId: string,
    targetScopeType?: 'company' | 'department' | 'team',
    targetScopeId?: string,
  ): Promise<boolean> {
    const roleInfo = await this.getUserRoleInfo(userId, companyId);
    
    if (!roleInfo) return false;
    
    // Admin can manage everything
    if (roleInfo.roleType === 'admin') return true;
    
    // Manager can manage structure
    if (roleInfo.roleType === 'manager' && roleInfo.permissions.canManageStructure) {
      // If target scope is specified, check if user's scope includes it
      if (targetScopeType && targetScopeId) {
        return this.isInScopeInternal(roleInfo, targetScopeType, targetScopeId, companyId);
      }
      return true;
    }
    
    return false;
  }

  /**
   * Check if user can approve listings (with amount limit)
   */
  async canApproveListing(
    userId: string,
    companyId: string,
    listingAmount: number | string,
    targetScopeType?: 'company' | 'department' | 'team',
    targetScopeId?: string,
  ): Promise<boolean> {
    const roleInfo = await this.getUserRoleInfo(userId, companyId);
    
    if (!roleInfo) return false;
    
    // Admin can approve any amount
    if (roleInfo.roleType === 'admin') return true;
    
    // Check if role allows approval
    if (!roleInfo.permissions.canApproveListings) return false;
    
    // Check amount limit
    const maxAmount = parseFloat(roleInfo.maxApprovalAmount || '0');
    const listingValue = typeof listingAmount === 'string' ? parseFloat(listingAmount) : listingAmount;
    
    if (listingValue > maxAmount) return false;
    
    // If target scope is specified, check if user's scope includes it
    if (targetScopeType && targetScopeId) {
      return this.isInScopeInternal(roleInfo, targetScopeType, targetScopeId, companyId);
    }
    
    return true;
  }

  /**
   * Check if user can access settings
   */
  async canAccessSettings(userId: string, companyId: string): Promise<boolean> {
    const roleInfo = await this.getUserRoleInfo(userId, companyId);
    
    if (!roleInfo) return false;
    
    // Admin can always access settings
    if (roleInfo.roleType === 'admin') return true;
    
    return roleInfo.permissions.canAccessSettings === true;
  }

  /**
   * Check if user can perform action on target
   */
  async canPerformAction(
    context: UserPermissionContext,
    action: 'manage_structure' | 'approve_listing' | 'access_settings' | 'view' | 'edit',
    targetType?: 'department' | 'team' | 'user' | 'listing',
    targetId?: string,
    listingAmount?: number,
  ): Promise<boolean> {
    // Admin can do everything
    if (context.roleType === 'admin') {
      if (action === 'approve_listing' && listingAmount) {
        return listingAmount <= context.maxApprovalAmount;
      }
      return true;
    }

    // Check permission flags
    if (action === 'manage_structure' && !context.permissions.canManageStructure) {
      return false;
    }
    if (action === 'approve_listing' && !context.permissions.canApproveListings) {
      return false;
    }
    if (action === 'access_settings' && !context.permissions.canAccessSettings) {
      return false;
    }

    // Check approval amount limit
    if (action === 'approve_listing' && listingAmount) {
      if (listingAmount > context.maxApprovalAmount) {
        return false;
      }
    }

    // Check scope-based access
    if (targetId && targetType) {
      return await this.isInScope(context, targetType, targetId);
    }

    return true;
  }

  /**
   * Check if user can access a target scope (company/department/team)
   * Returns true if user's scope includes the target scope
   */
  async isInScope(
    userIdOrContext: string | UserPermissionContext,
    companyIdOrTargetType: string | 'department' | 'team' | 'user' | 'listing',
    targetScopeTypeOrTargetId?: 'company' | 'department' | 'team' | 'user' | 'listing' | string,
    targetScopeId?: string,
  ): Promise<boolean> {
    // Handle overload: isInScope(userId, companyId, targetScopeType, targetScopeId)
    if (typeof userIdOrContext === 'string' && typeof companyIdOrTargetType === 'string') {
      const userId = userIdOrContext;
      const companyId = companyIdOrTargetType;
      const targetScopeType = targetScopeTypeOrTargetId as 'company' | 'department' | 'team';
      const scopeId = targetScopeId as string;
      
      const context = await this.getUserPermissionContext(userId, companyId);
      return this.isInScopeForContext(context, targetScopeType, scopeId);
    }
    
    // Handle overload: isInScope(context, targetType, targetId)
    if (typeof userIdOrContext !== 'string' && typeof companyIdOrTargetType === 'string') {
      const context = userIdOrContext;
      const targetType = companyIdOrTargetType as 'department' | 'team' | 'user' | 'listing';
      const targetId = targetScopeTypeOrTargetId as string;
      
      return this.isInScopeForContext(context, targetType, targetId);
    }
    
    return false;
  }

  /**
   * Check if context's scope includes the target
   */
  private async isInScopeForContext(
    context: UserPermissionContext,
    targetScopeType: 'company' | 'department' | 'team' | 'user' | 'listing',
    targetScopeId: string,
  ): Promise<boolean> {
    return await this.isInScopeInternal(
      {
        roleType: context.roleType,
        scopeType: context.scopeType,
        scopeId: context.scopeId,
        maxApprovalAmount: context.maxApprovalAmount.toString(),
        permissions: context.permissions,
      },
      targetScopeType,
      targetScopeId,
      context.companyId,
    );
  }

  /**
   * Internal helper to check scope inclusion
   */
  private async isInScopeInternal(
    roleInfo: UserRoleInfo,
    targetScopeType: 'company' | 'department' | 'team' | 'user' | 'listing',
    targetScopeId: string,
    companyId: string,
  ): Promise<boolean> {
    // Admin with company scope can access everything
    if (roleInfo.roleType === 'admin' && roleInfo.scopeType === 'company') {
      return true;
    }

    // If user's scope is company, they can access everything
    if (roleInfo.scopeType === 'company') {
      return true;
    }

    // If user's scope matches target scope exactly
    if (roleInfo.scopeType === targetScopeType && roleInfo.scopeId === targetScopeId) {
      return true;
    }

    // Department scope can access its children and teams
    if (roleInfo.scopeType === 'department' && roleInfo.scopeId) {
      if (targetScopeType === 'department') {
        // Check if target department is a descendant or the same department
        if (roleInfo.scopeId === targetScopeId) return true;
        
        const [isDescendant] = await db
          .select()
          .from(departmentHierarchy)
          .where(
            and(
              eq(departmentHierarchy.ancestorId, roleInfo.scopeId),
              eq(departmentHierarchy.descendantId, targetScopeId),
            ),
          )
          .limit(1);
        
        if (isDescendant) return true;
      }
      
      if (targetScopeType === 'team') {
        // Get all descendant department IDs including self
        const descendantDepts = await db
          .select({ id: departmentHierarchy.descendantId })
          .from(departmentHierarchy)
          .where(eq(departmentHierarchy.ancestorId, roleInfo.scopeId));
        
        const deptIds = [roleInfo.scopeId, ...descendantDepts.map(d => d.id)];
        
        // Check if team belongs to any of these departments
        const [teamInDept] = await db
          .select()
          .from(departmentTeams)
          .where(
            and(
              eq(departmentTeams.teamId, targetScopeId),
              inArray(departmentTeams.departmentId, deptIds),
            ),
          )
          .limit(1);
        
        if (teamInDept) return true;
      }
    }

    // Team scope can only access its own team
    if (roleInfo.scopeType === 'team' && roleInfo.scopeId) {
      if (targetScopeType === 'team') {
        return roleInfo.scopeId === targetScopeId;
      }

      if (targetScopeType === 'user') {
        return await this.isUserInTeam(roleInfo.scopeId, targetScopeId);
      }

      if (targetScopeType === 'listing') {
        return await this.isListingInTeam(roleInfo.scopeId, targetScopeId);
      }
    }

    // Handle user and listing targets for department scope
    if (roleInfo.scopeType === 'department' && roleInfo.scopeId) {
      if (targetScopeType === 'user') {
        return await this.isUserInDepartment(roleInfo.scopeId, targetScopeId);
      }

      if (targetScopeType === 'listing') {
        return await this.isListingInDepartment(roleInfo.scopeId, targetScopeId);
      }
    }

    return false;
  }

  /**
   * Check if user belongs to team
   */
  private async isUserInTeam(teamId: string, userId: string): Promise<boolean> {
    const result = await db
      .select()
      .from(teamMembers)
      .where(and(eq(teamMembers.teamId, teamId), eq(teamMembers.userId, userId)))
      .limit(1);

    return result.length > 0;
  }

  /**
   * Check if listing belongs to team
   */
  private async isListingInTeam(teamId: string, listingId: string): Promise<boolean> {
    const result = await db
      .select()
      .from(materialListings)
      .where(and(eq(materialListings.id, listingId), eq(materialListings.teamId, teamId)))
      .limit(1);

    return result.length > 0;
  }

  /**
   * Check if user belongs to department (via team membership)
   */
  private async isUserInDepartment(departmentId: string, userId: string): Promise<boolean> {
    // Get all descendant departments (including self)
    const descendants = await db
      .select({ id: departmentHierarchy.descendantId })
      .from(departmentHierarchy)
      .where(eq(departmentHierarchy.ancestorId, departmentId));

    const deptIds = [departmentId, ...descendants.map(d => d.id)];

    // Check if user is in any team under these departments
    const result = await db
      .select()
      .from(teamMembers)
      .innerJoin(departmentTeams, eq(teamMembers.teamId, departmentTeams.teamId))
      .where(
        and(
          eq(teamMembers.userId, userId),
          inArray(departmentTeams.departmentId, deptIds),
        ),
      )
      .limit(1);

    return result.length > 0;
  }

  /**
   * Check if listing belongs to department (via team)
   */
  private async isListingInDepartment(departmentId: string, listingId: string): Promise<boolean> {
    // Get all descendant departments (including self)
    const descendants = await db
      .select({ id: departmentHierarchy.descendantId })
      .from(departmentHierarchy)
      .where(eq(departmentHierarchy.ancestorId, departmentId));

    const deptIds = [departmentId, ...descendants.map(d => d.id)];

    // Check if listing's team is in any of these departments
    const listing = await db
      .select({ teamId: materialListings.teamId })
      .from(materialListings)
      .where(eq(materialListings.id, listingId))
      .limit(1);

    if (!listing.length || !listing[0].teamId) {
      return false;
    }

    const result = await db
      .select()
      .from(departmentTeams)
      .where(
        and(
          eq(departmentTeams.teamId, listing[0].teamId),
          inArray(departmentTeams.departmentId, deptIds),
        ),
      )
      .limit(1);

    return result.length > 0;
  }

  /**
   * Find appropriate approver for listing
   * Walks up hierarchy until finds someone with sufficient limit
   */
  async findApproverForListing(listingId: string, listingAmount: number): Promise<string | null> {
    // 1. Get listing's team
    const listing = await db
      .select({ teamId: materialListings.teamId, companyId: materialListings.companyId })
      .from(materialListings)
      .where(eq(materialListings.id, listingId))
      .limit(1);

    if (!listing.length || !listing[0].teamId) {
      return null;
    }

    const teamId = listing[0].teamId;
    const companyId = listing[0].companyId;

    // 2. Get team lead
    const team = await db
      .select({ teamLeadUserId: teams.teamLeadUserId })
      .from(teams)
      .where(eq(teams.id, teamId))
      .limit(1);

    if (team.length && team[0].teamLeadUserId) {
      try {
        const leadContext = await this.getUserPermissionContext(
          team[0].teamLeadUserId,
          companyId,
        );

        if (leadContext.maxApprovalAmount >= listingAmount) {
          return team[0].teamLeadUserId;
        }
      } catch {
        // Lead doesn't have valid context, continue
      }
    }

    // 3. Walk up department hierarchy
    // Get department this team belongs to
    const deptTeams = await db
      .select({ departmentId: departmentTeams.departmentId })
      .from(departmentTeams)
      .where(eq(departmentTeams.teamId, teamId))
      .limit(1);

    if (deptTeams.length && deptTeams[0].departmentId) {
      let currentDeptId = deptTeams[0].departmentId;

      // Walk up the hierarchy
      while (currentDeptId) {
        const dept = await db
          .select({
            managerUserId: departments.managerUserId,
            parentDepartmentId: departments.parentDepartmentId,
          })
          .from(departments)
          .where(eq(departments.id, currentDeptId))
          .limit(1);

        if (dept.length && dept[0].managerUserId) {
          try {
            const managerContext = await this.getUserPermissionContext(
              dept[0].managerUserId,
              companyId,
            );

            if (managerContext.maxApprovalAmount >= listingAmount) {
              return dept[0].managerUserId;
            }
          } catch {
            // Manager doesn't have valid context, continue
          }
        }

        // Move to parent department
        currentDeptId = dept[0]?.parentDepartmentId || null;
      }
    }

    // 4. Check company admins
    const admins = await db
      .select({ userId: userRoles.userId })
      .from(userRoles)
      .innerJoin(roles, eq(userRoles.roleId, roles.id))
      .where(
        and(
          eq(roles.companyId, companyId),
          eq(roles.roleType, 'admin'),
          isNull(roles.deletedAt),
        ),
      )
      .limit(1);

    if (admins.length) {
      return admins[0].userId;
    }

    return null;
  }

  /**
   * Get user's effective scope (what they can manage)
   */
  async getEffectiveScope(userId: string, companyId: string): Promise<{
    scopeType: 'company' | 'department' | 'team';
    scopeId: string | null;
    scopeName?: string;
  }> {
    const roleInfo = await this.getUserRoleInfo(userId, companyId);
    
    if (!roleInfo) {
      return { scopeType: 'team', scopeId: null };
    }

    // Get scope name if available
    let scopeName: string | undefined;
    
    if (roleInfo.scopeType === 'company') {
      const [company] = await db
        .select({ name: companies.name })
        .from(companies)
        .where(eq(companies.id, companyId))
        .limit(1);
      scopeName = company?.name;
    } else if (roleInfo.scopeType === 'department' && roleInfo.scopeId) {
      const [dept] = await db
        .select({ name: departments.name })
        .from(departments)
        .where(eq(departments.id, roleInfo.scopeId))
        .limit(1);
      scopeName = dept?.name;
    } else if (roleInfo.scopeType === 'team' && roleInfo.scopeId) {
      const [team] = await db
        .select({ name: teams.name })
        .from(teams)
        .where(eq(teams.id, roleInfo.scopeId))
        .limit(1);
      scopeName = team?.name;
    }

    return {
      scopeType: roleInfo.scopeType,
      scopeId: roleInfo.scopeId,
      scopeName,
    };
  }

  /**
   * Legacy method for backward compatibility - maps old permission checks to new system
   * @deprecated Use specific methods like canManageStructure, canApproveListing, etc.
   */
  async hasPermission(
    userId: string,
    companyId: string,
    category: string,
    permission: string,
  ): Promise<boolean> {
    const roleInfo = await this.getUserRoleInfo(userId, companyId);
    
    if (!roleInfo) return false;
    
    // Admin has all permissions
    if (roleInfo.roleType === 'admin') return true;
    
    // Map old permission checks to new system
    if (category === 'settings') {
      return this.canAccessSettings(userId, companyId);
    }
    
    if (category === 'listings' && permission === 'approve') {
      // This is a simplified check - actual amount should be checked with canApproveListing
      return roleInfo.permissions.canApproveListings === true;
    }
    
    if (['teams', 'departments', 'people'].includes(category)) {
      return this.canManageStructure(userId, companyId);
    }
    
    // For other permissions, return true if user has any role (member can view)
    return roleInfo.roleType !== 'member' || roleInfo.roleType === 'member';
  }
}
