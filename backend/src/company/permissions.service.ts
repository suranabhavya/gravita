import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { db } from '../database';
import { users, roles, userRoles } from '../database/schema';
import { eq, and, isNull } from 'drizzle-orm';
import { RolePermissions } from '../database/schema';
import { UpdateUserPermissionsDto } from './dto/update-user-permissions.dto';

@Injectable()
export class PermissionsService {
  /**
   * Get all permissions for a user (combines direct permissions and role permissions)
   */
  async getUserPermissions(userId: string, companyId: string): Promise<RolePermissions> {
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

    // Start with user's direct permissions
    const directPermissions = (user.permissions as RolePermissions) || {};

    // Get user's roles and merge their permissions
    const userRolesList = await db
      .select({
        permissions: roles.permissions,
      })
      .from(userRoles)
      .innerJoin(roles, eq(userRoles.roleId, roles.id))
      .where(
        and(
          eq(userRoles.userId, userId),
          isNull(roles.deletedAt),
        ),
      );

    // Merge role permissions with direct permissions (direct permissions take precedence)
    const mergedPermissions: RolePermissions = { ...directPermissions };

    for (const userRole of userRolesList) {
      const rolePerms = (userRole.permissions as RolePermissions) || {};
      
      // Merge each category
      for (const category in rolePerms) {
        if (!mergedPermissions[category]) {
          mergedPermissions[category] = {};
        }
        Object.assign(mergedPermissions[category], rolePerms[category]);
      }
    }

    return mergedPermissions;
  }

  /**
   * Check if user has a specific permission
   */
  async hasPermission(
    userId: string,
    companyId: string,
    category: keyof RolePermissions,
    permission: string,
  ): Promise<boolean> {
    const permissions = await this.getUserPermissions(userId, companyId);
    
    // Check if user is admin (has all permissions)
    const isAdmin = await this.isAdmin(userId, companyId);
    if (isAdmin) return true;

    const categoryPerms = permissions[category] as any;
    if (!categoryPerms) return false;

    return categoryPerms[permission] === true;
  }

  /**
   * Check if user is admin
   */
  async isAdmin(userId: string, companyId: string): Promise<boolean> {
    const userRolesList = await db
      .select({
        name: roles.name,
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

    // Check if user has admin role
    return userRolesList.some((ur) => ur.name === 'Company Admin');
  }

  /**
   * Update user's direct permissions
   */
  async updateUserPermissions(
    userId: string,
    companyId: string,
    updateDto: UpdateUserPermissionsDto,
  ) {
    // Verify user belongs to company
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

    // Merge with existing permissions (don't overwrite, merge)
    const existingPermissions = (user.permissions as RolePermissions) || {};
    const newPermissions = updateDto.permissions || {};

    const mergedPermissions: RolePermissions = {
      ...existingPermissions,
    };

    // Merge each category
    for (const category in newPermissions) {
      mergedPermissions[category] = {
        ...(existingPermissions[category] || {}),
        ...(newPermissions[category] || {}),
      };
    }

    // Update user permissions
    await db
      .update(users)
      .set({
        permissions: mergedPermissions,
        updatedAt: new Date(),
      })
      .where(eq(users.id, userId));

    return {
      ...user,
      permissions: mergedPermissions,
    };
  }

  /**
   * Get all available permission categories and their permissions
   */
  getAvailablePermissions(): {
    category: string;
    label: string;
    permissions: { key: string; label: string; description: string }[];
  }[] {
    return [
      {
        category: 'people',
        label: 'People & Members',
        permissions: [
          { key: 'view_members', label: 'View Members', description: 'View company members list' },
          { key: 'invite_members', label: 'Invite Members', description: 'Send invitations to new members' },
          { key: 'edit_members', label: 'Edit Members', description: 'Edit member profiles and information' },
          { key: 'remove_members', label: 'Remove Members', description: 'Remove members from company' },
          { key: 'view_all_profiles', label: 'View All Profiles', description: 'View detailed profiles of all members' },
        ],
      },
      {
        category: 'teams',
        label: 'Teams',
        permissions: [
          { key: 'view_teams', label: 'View Teams', description: 'View teams list and details' },
          { key: 'create_teams', label: 'Create Teams', description: 'Create new teams' },
          { key: 'edit_teams', label: 'Edit Teams', description: 'Edit team information' },
          { key: 'delete_teams', label: 'Delete Teams', description: 'Delete teams' },
          { key: 'manage_team_members', label: 'Manage Team Members', description: 'Add/remove members from teams' },
          { key: 'assign_team_leads', label: 'Assign Team Leads', description: 'Assign team leaders' },
        ],
      },
      {
        category: 'departments',
        label: 'Departments',
        permissions: [
          { key: 'view_departments', label: 'View Departments', description: 'View department structure' },
          { key: 'create_departments', label: 'Create Departments', description: 'Create new departments' },
          { key: 'edit_departments', label: 'Edit Departments', description: 'Edit department information' },
          { key: 'delete_departments', label: 'Delete Departments', description: 'Delete departments' },
          { key: 'move_departments', label: 'Move Departments', description: 'Reorganize department hierarchy' },
          { key: 'assign_team_to_department', label: 'Assign Teams', description: 'Assign teams to departments' },
        ],
      },
      {
        category: 'listings',
        label: 'Listings',
        permissions: [
          { key: 'create', label: 'Create Listings', description: 'Create new material listings' },
          { key: 'edit_own', label: 'Edit Own Listings', description: 'Edit listings you created' },
          { key: 'edit_any', label: 'Edit Any Listings', description: 'Edit any company listings' },
          { key: 'delete', label: 'Delete Listings', description: 'Delete listings' },
          { key: 'approve', label: 'Approve Listings', description: 'Approve pending listings' },
          { key: 'view_all', label: 'View All Listings', description: 'View all company listings' },
        ],
      },
      {
        category: 'analytics',
        label: 'Analytics',
        permissions: [
          { key: 'view_own', label: 'View Own Analytics', description: 'View your personal analytics' },
          { key: 'view_own_team', label: 'View Team Analytics', description: 'View your team analytics' },
          { key: 'view_department', label: 'View Department Analytics', description: 'View department analytics' },
          { key: 'view_company', label: 'View Company Analytics', description: 'View company-wide analytics' },
        ],
      },
      {
        category: 'settings',
        label: 'Settings',
        permissions: [
          { key: 'view_settings', label: 'View Settings', description: 'View company settings' },
          { key: 'manage_company', label: 'Manage Company', description: 'Edit company information' },
          { key: 'manage_roles', label: 'Manage Roles', description: 'Create and edit roles' },
          { key: 'manage_permissions', label: 'Manage Permissions', description: 'Manage user permissions' },
        ],
      },
    ];
  }
}

