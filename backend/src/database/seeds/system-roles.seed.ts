import { db } from '../index';
import { roles } from '../schema';
import { eq, and, isNull } from 'drizzle-orm';

/**
 * Creates 4 system roles for a company
 * Called when company is first created
 */
export async function createSystemRoles(companyId: string) {
  // Check if system roles already exist
  const existingRoles = await db
    .select()
    .from(roles)
    .where(
      and(
        eq(roles.companyId, companyId),
        eq(roles.isSystemRole, true),
        isNull(roles.deletedAt),
      ),
    );

  if (existingRoles.length > 0) {
    // System roles already exist, return them
    return existingRoles;
  }

  const systemRoles = [
    {
      companyId,
      name: 'Company Admin',
      description: 'Full control over company',
      roleType: 'admin' as const,
      permissions: {
        canManageStructure: true,
        canApproveListings: true,
        canAccessSettings: true,
      },
      maxApprovalAmount: '999999999', // Unlimited
      isSystemRole: true,
    },
    {
      companyId,
      name: 'Manager',
      description: 'Manages departments and approves listings',
      roleType: 'manager' as const,
      permissions: {
        canManageStructure: true,
        canApproveListings: true,
        canAccessSettings: false,
      },
      maxApprovalAmount: '500000',
      isSystemRole: true,
    },
    {
      companyId,
      name: 'Team Lead',
      description: 'Leads a team and approves small listings',
      roleType: 'lead' as const,
      permissions: {
        canManageStructure: true, // Only their team
        canApproveListings: true,
        canAccessSettings: false,
      },
      maxApprovalAmount: '50000',
      isSystemRole: true,
    },
    {
      companyId,
      name: 'Team Member',
      description: 'Creates material listings',
      roleType: 'member' as const,
      permissions: {
        canManageStructure: false,
        canApproveListings: false,
        canAccessSettings: false,
      },
      maxApprovalAmount: '0',
      isSystemRole: true,
    },
  ];

  return await db.insert(roles).values(systemRoles).returning();
}


