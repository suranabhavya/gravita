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
  companies,
  SimplifiedPermissions 
} from '../database/schema';
import { eq, and, isNull, or, sql, inArray } from 'drizzle-orm';

export type UserRoleInfo = {
  roleType: 'admin' | 'manager' | 'member' | 'viewer';
  scopeType: 'company' | 'department' | 'team';
  scopeId: string | null;
  maxApprovalAmount: string; // decimal as string
  permissions: SimplifiedPermissions;
};

@Injectable()
export class PermissionsService {
  /**
   * Get user's role information (role type, scope, and max approval amount)
   * Returns the highest privilege role if user has multiple roles
   */
  async getUserRoleInfo(userId: string, companyId: string): Promise<UserRoleInfo | null> {
    const userRolesList = await db
      .select({
        roleType: roles.roleType,
        scopeType: userRoles.scopeType,
        scopeId: userRoles.scopeId,
        maxApprovalAmount: roles.maxApprovalAmount,
        maxApprovalAmountOverride: userRoles.maxApprovalAmountOverride,
        permissions: roles.permissions,
      })
      .from(userRoles)
      .innerJoin(roles, eq(userRoles.roleId, roles.id))
      .where(
        and(
          eq(userRoles.userId, userId),
          eq(roles.companyId, companyId),
          isNull(roles.deletedAt),
        ),
      );

    if (userRolesList.length === 0) {
      return null;
    }

    // Priority: admin > manager > member > viewer
    const rolePriority = { admin: 4, manager: 3, member: 2, viewer: 1 };
    
    // Get the highest privilege role
    const highestRole = userRolesList.reduce((prev, current) => {
      const prevPriority = rolePriority[prev.roleType] || 0;
      const currentPriority = rolePriority[current.roleType] || 0;
      return currentPriority > prevPriority ? current : prev;
    });

    // Use override if available, otherwise use role's default
    const maxApprovalAmount = highestRole.maxApprovalAmountOverride 
      ? highestRole.maxApprovalAmountOverride 
      : highestRole.maxApprovalAmount;

    return {
      roleType: highestRole.roleType,
      scopeType: highestRole.scopeType,
      scopeId: highestRole.scopeId,
      maxApprovalAmount: maxApprovalAmount || '0',
      permissions: (highestRole.permissions as SimplifiedPermissions) || {},
    };
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
   * Check if user can access a target scope (company/department/team)
   * Returns true if user's scope includes the target scope
   */
  async isInScope(
    userId: string,
    companyId: string,
    targetScopeType: 'company' | 'department' | 'team',
    targetScopeId: string,
  ): Promise<boolean> {
    const roleInfo = await this.getUserRoleInfo(userId, companyId);
    
    if (!roleInfo) return false;
    
    return this.isInScopeInternal(roleInfo, targetScopeType, targetScopeId, companyId);
  }

  /**
   * Internal helper to check scope inclusion
   */
  private async isInScopeInternal(
    roleInfo: UserRoleInfo,
    targetScopeType: 'company' | 'department' | 'team',
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
    if (roleInfo.scopeType === 'team' && roleInfo.scopeId === targetScopeId) {
      return true;
    }

    return false;
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
    return roleInfo.roleType !== 'viewer';
  }
}
