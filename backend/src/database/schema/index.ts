import {
  pgTable,
  uuid,
  varchar,
  text,
  timestamp,
  boolean,
  integer,
  decimal,
  pgEnum,
  jsonb,
  unique,
  index,
  primaryKey,
  point,
} from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';
import { sql } from 'drizzle-orm';

// ============================================
// ENUMS
// ============================================

export const companyTypeEnum = pgEnum('company_type', ['supplier', 'recycler']);
export const statusEnum = pgEnum('status', ['active', 'suspended', 'deleted', 'invited']);
export const listingStatusEnum = pgEnum('listing_status', [
  'draft',
  'pending_approval',
  'approved',
  'rejected',
  'listed',
  'in_negotiation',
  'sold',
  'cancelled',
]);
export const scopeTypeEnum = pgEnum('scope_type', ['company', 'department', 'team']);
export const roleTypeEnum = pgEnum('role_type', ['admin', 'manager', 'lead', 'member']);
export const approvalActionEnum = pgEnum('approval_action', [
  'approved',
  'rejected',
  'requested_changes',
]);
export const invitationStatusEnum = pgEnum('invitation_status', [
  'pending',
  'accepted',
  'expired',
  'cancelled',
]);

// ============================================
// TYPES
// ============================================

export type CompanySettings = {
  max_hierarchy_depth: number;
  require_approval_chain: boolean;
  auto_escalate_hours: number;
};

/**
 * Simplified permissions structure - only 3 flags
 * Permissions are determined by roleType + scope + maxApprovalAmount
 */
export type SimplifiedPermissions = {
  canManageStructure?: boolean;   // Create/edit teams, departments, add members
  canApproveListings?: boolean;    // Approve listings (up to maxApprovalAmount)
  canAccessSettings?: boolean;     // Access company settings
};

// Keep old type for backward compatibility during transition (can be removed later)
export type RolePermissions = SimplifiedPermissions;

export type MaterialSpecifications = {
  purity?: string;
  grade?: string;
  form?: string;
  contamination?: string;
  [key: string]: any;
};

// ============================================
// 1. COMPANIES
// ============================================

export const companies = pgTable(
  'companies',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    name: varchar('name', { length: 255 }).notNull(),
    companyType: companyTypeEnum('company_type').notNull(),
    industry: varchar('industry', { length: 100 }),
    size: varchar('size', { length: 20 }),
    status: statusEnum('status').default('active').notNull(),
    settings: jsonb('settings')
      .$type<CompanySettings>()
      .default({
        max_hierarchy_depth: 5,
        require_approval_chain: true,
        auto_escalate_hours: 48,
      }),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
    deletedAt: timestamp('deleted_at'),
  },
  (table) => [
    index('idx_companies_type')
      .on(table.companyType)
      .where(sql`${table.deletedAt} IS NULL`),
    index('idx_companies_status')
      .on(table.status)
      .where(sql`${table.deletedAt} IS NULL`),
  ],
);

// ============================================
// 2. USERS
// ============================================

export const users = pgTable(
  'users',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    companyId: uuid('company_id').references(() => companies.id, { onDelete: 'cascade' }),
    email: varchar('email', { length: 255 }).notNull(),
    name: varchar('name', { length: 255 }).notNull(),
    phone: varchar('phone', { length: 20 }),
    avatarUrl: text('avatar_url'),
    passwordHash: varchar('password_hash', { length: 255 }),
    emailVerified: boolean('email_verified').default(false).notNull(),
    reportsToUserId: uuid('reports_to_user_id').references((): any => users.id, {
      onDelete: 'set null',
    }),
    status: statusEnum('status').default('active').notNull(),
    metadata: jsonb('metadata').default({}),
    lastLoginAt: timestamp('last_login_at'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
    deletedAt: timestamp('deleted_at'),
  },
  (table) => [
    index('idx_users_company')
      .on(table.companyId)
      .where(sql`${table.deletedAt} IS NULL`),
    index('idx_users_email')
      .on(table.email)
      .where(sql`${table.deletedAt} IS NULL`),
    index('idx_users_reports_to')
      .on(table.reportsToUserId)
      .where(sql`${table.deletedAt} IS NULL`),
    index('idx_users_status')
      .on(table.companyId, table.status)
      .where(sql`${table.deletedAt} IS NULL`),
  ],
);

// ============================================
// 3. TEAMS
// ============================================

export const teams = pgTable(
  'teams',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    companyId: uuid('company_id')
      .references(() => companies.id, { onDelete: 'cascade' })
      .notNull(),
    name: varchar('name', { length: 255 }).notNull(),
    description: text('description'),
    teamLeadUserId: uuid('team_lead_user_id').references(() => users.id, {
      onDelete: 'set null',
    }),
    location: varchar('location', { length: 255 }),
    metadata: jsonb('metadata').default({}),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
    deletedAt: timestamp('deleted_at'),
  },
  (table) => [
    unique('teams_company_name_unique').on(table.companyId, table.name),
    index('idx_teams_company')
      .on(table.companyId)
      .where(sql`${table.deletedAt} IS NULL`),
    index('idx_teams_lead')
      .on(table.teamLeadUserId)
      .where(sql`${table.deletedAt} IS NULL`),
  ],
);

export const teamMembers = pgTable(
  'team_members',
  {
    teamId: uuid('team_id')
      .references(() => teams.id, { onDelete: 'cascade' })
      .notNull(),
    userId: uuid('user_id')
      .references(() => users.id, { onDelete: 'cascade' })
      .notNull(),
    joinedAt: timestamp('joined_at').defaultNow().notNull(),
  },
  (table) => [
    primaryKey({ columns: [table.teamId, table.userId] }),
    index('idx_team_members_user').on(table.userId),
    index('idx_team_members_team').on(table.teamId),
  ],
);

// ============================================
// 4. DEPARTMENTS
// ============================================

export const departments = pgTable(
  'departments',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    companyId: uuid('company_id')
      .references(() => companies.id, { onDelete: 'cascade' })
      .notNull(),
    name: varchar('name', { length: 255 }).notNull(),
    description: text('description'),
    parentDepartmentId: uuid('parent_department_id').references(
      (): any => departments.id,
      { onDelete: 'cascade' },
    ),
    level: integer('level').default(1).notNull(),
    path: text('path'),
    managerUserId: uuid('manager_user_id').references(() => users.id, {
      onDelete: 'set null',
    }),
    metadata: jsonb('metadata').default({}),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
    deletedAt: timestamp('deleted_at'),
  },
  (table) => [
    unique('departments_company_name_unique').on(table.companyId, table.name),
    index('idx_departments_company')
      .on(table.companyId)
      .where(sql`${table.deletedAt} IS NULL`),
    index('idx_departments_parent')
      .on(table.parentDepartmentId)
      .where(sql`${table.deletedAt} IS NULL`),
    index('idx_departments_manager')
      .on(table.managerUserId)
      .where(sql`${table.deletedAt} IS NULL`),
    index('idx_departments_path')
      .on(table.path)
      .where(sql`${table.deletedAt} IS NULL`),
    index('idx_departments_level')
      .on(table.companyId, table.level)
      .where(sql`${table.deletedAt} IS NULL`),
  ],
);

export const departmentHierarchy = pgTable(
  'department_hierarchy',
  {
    ancestorId: uuid('ancestor_id')
      .references(() => departments.id, { onDelete: 'cascade' })
      .notNull(),
    descendantId: uuid('descendant_id')
      .references(() => departments.id, { onDelete: 'cascade' })
      .notNull(),
    depth: integer('depth').notNull(),
  },
  (table) => [
    primaryKey({ columns: [table.ancestorId, table.descendantId] }),
    index('idx_dept_hierarchy_ancestor').on(table.ancestorId, table.depth),
    index('idx_dept_hierarchy_descendant').on(table.descendantId),
  ],
);

export const departmentTeams = pgTable(
  'department_teams',
  {
    departmentId: uuid('department_id')
      .references(() => departments.id, { onDelete: 'cascade' })
      .notNull(),
    teamId: uuid('team_id')
      .references(() => teams.id, { onDelete: 'cascade' })
      .notNull(),
    addedAt: timestamp('added_at').defaultNow().notNull(),
  },
  (table) => [
    primaryKey({ columns: [table.departmentId, table.teamId] }),
    index('idx_dept_teams_dept').on(table.departmentId),
    index('idx_dept_teams_team').on(table.teamId),
  ],
);

// ============================================
// 5. ROLES & PERMISSIONS
// ============================================

export const roles = pgTable(
  'roles',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    companyId: uuid('company_id')
      .references(() => companies.id, { onDelete: 'cascade' })
      .notNull(),
    name: varchar('name', { length: 100 }).notNull(),
    description: text('description'),
    roleType: roleTypeEnum('role_type').notNull(),
    permissions: jsonb('permissions')
      .$type<SimplifiedPermissions>()
      .notNull()
      .default({}),
    maxApprovalAmount: decimal('max_approval_amount', { precision: 12, scale: 2 }).default('0'),
    isSystemRole: boolean('is_system_role').default(false).notNull(),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
    deletedAt: timestamp('deleted_at'),
  },
  (table) => [
    unique('roles_company_name_unique').on(table.companyId, table.name),
    index('idx_roles_company')
      .on(table.companyId)
      .where(sql`${table.deletedAt} IS NULL`),
    index('idx_roles_system')
      .on(table.isSystemRole)
      .where(sql`${table.deletedAt} IS NULL`),
    index('idx_roles_type')
      .on(table.roleType)
      .where(sql`${table.deletedAt} IS NULL`),
    index('idx_roles_permissions').using('gin', table.permissions),
  ],
);

export const userRoles = pgTable(
  'user_roles',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .references(() => users.id, { onDelete: 'cascade' })
      .notNull(),
    roleId: uuid('role_id')
      .references(() => roles.id, { onDelete: 'cascade' })
      .notNull(),
    scopeType: scopeTypeEnum('scope_type').notNull(),
    scopeId: uuid('scope_id'),
    maxApprovalAmountOverride: decimal('max_approval_amount_override', {
      precision: 12,
      scale: 2,
    }),
    grantedAt: timestamp('granted_at').defaultNow().notNull(),
    grantedByUserId: uuid('granted_by_user_id').references(() => users.id),
  },
  (table) => [
    unique('user_roles_unique').on(table.userId, table.roleId, table.scopeType, table.scopeId),
    index('idx_user_roles_user').on(table.userId),
    index('idx_user_roles_role').on(table.roleId),
    index('idx_user_roles_scope').on(table.scopeType, table.scopeId),
  ],
);

// ============================================
// 6. MATERIAL LISTINGS
// ============================================

export const materialCategories = pgTable('material_categories', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: varchar('name', { length: 100 }).notNull().unique(),
  description: text('description'),
  propertiesSchema: jsonb('properties_schema'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const materialListings = pgTable(
  'material_listings',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    companyId: uuid('company_id')
      .references(() => companies.id, { onDelete: 'cascade' })
      .notNull(),
    createdByUserId: uuid('created_by_user_id')
      .references(() => users.id)
      .notNull(),
    teamId: uuid('team_id').references(() => teams.id, { onDelete: 'set null' }),
    categoryId: uuid('category_id').references(() => materialCategories.id),
    materialType: varchar('material_type', { length: 100 }).notNull(),
    quantity: decimal('quantity', { precision: 12, scale: 2 }).notNull(),
    unit: varchar('unit', { length: 20 }).notNull(),
    specifications: jsonb('specifications')
      .$type<MaterialSpecifications>()
      .default({}),
    estimatedValue: decimal('estimated_value', { precision: 12, scale: 2 }),
    currency: varchar('currency', { length: 3 }).default('USD'),
    images: text('images').array(),
    documents: text('documents').array(),
    pickupLocation: varchar('pickup_location', { length: 255 }),
    pickupCoordinates: point('pickup_coordinates'),
    status: listingStatusEnum('status').default('draft').notNull(),
    currentApproverUserId: uuid('current_approver_user_id').references(
      () => users.id,
    ),
    approvedByUserId: uuid('approved_by_user_id').references(() => users.id),
    approvedAt: timestamp('approved_at'),
    rejectionReason: text('rejection_reason'),
    gravitaVisibility: boolean('gravita_visibility').default(false).notNull(),
    listedAt: timestamp('listed_at'),
    metadata: jsonb('metadata').default({}),
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
    deletedAt: timestamp('deleted_at'),
  },
  (table) => [
    index('idx_listings_company')
      .on(table.companyId)
      .where(sql`${table.deletedAt} IS NULL`),
    index('idx_listings_creator')
      .on(table.createdByUserId)
      .where(sql`${table.deletedAt} IS NULL`),
    index('idx_listings_team')
      .on(table.teamId)
      .where(sql`${table.deletedAt} IS NULL`),
    index('idx_listings_status')
      .on(table.status)
      .where(sql`${table.deletedAt} IS NULL`),
    index('idx_listings_category')
      .on(table.categoryId)
      .where(sql`${table.deletedAt} IS NULL`),
    index('idx_listings_gravita').on(table.gravitaVisibility, table.status),
    index('idx_listings_approver').on(table.currentApproverUserId).where(
      sql`${table.status} = 'pending_approval'`,
    ),
    index('idx_listings_created').on(table.createdAt),
    index('idx_listings_specs').using('gin', table.specifications),
  ],
);

// ============================================
// 7. APPROVAL WORKFLOW
// ============================================

export const listingApprovals = pgTable(
  'listing_approvals',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    listingId: uuid('listing_id')
      .references(() => materialListings.id, { onDelete: 'cascade' })
      .notNull(),
    approverUserId: uuid('approver_user_id')
      .references(() => users.id)
      .notNull(),
    action: approvalActionEnum('action').notNull(),
    approvalLevel: integer('approval_level').notNull(),
    levelName: varchar('level_name', { length: 50 }),
    comments: text('comments'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
  },
  (table) => [
    index('idx_approvals_listing').on(table.listingId, table.createdAt),
    index('idx_approvals_approver').on(table.approverUserId, table.createdAt),
  ],
);

export const listingStatusHistory = pgTable(
  'listing_status_history',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    listingId: uuid('listing_id')
      .references(() => materialListings.id, { onDelete: 'cascade' })
      .notNull(),
    oldStatus: listingStatusEnum('old_status'),
    newStatus: listingStatusEnum('new_status').notNull(),
    changedByUserId: uuid('changed_by_user_id').references(() => users.id),
    reason: text('reason'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
  },
  (table) => [
    index('idx_status_history_listing').on(table.listingId, table.createdAt),
  ],
);

// ============================================
// 8. INVITATIONS
// ============================================

export const invitations = pgTable(
  'invitations',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    companyId: uuid('company_id')
      .references(() => companies.id, { onDelete: 'cascade' })
      .notNull(),
    email: varchar('email', { length: 255 }).notNull(),
    invitedByUserId: uuid('invited_by_user_id')
      .references(() => users.id)
      .notNull(),
    teamId: uuid('team_id').references(() => teams.id, { onDelete: 'set null' }),
    roleId: uuid('role_id').references(() => roles.id, { onDelete: 'set null' }),
    token: varchar('token', { length: 255 }).notNull().unique(),
    inviteCode: varchar('invite_code', { length: 10 }).notNull().unique(),
    expiresAt: timestamp('expires_at').notNull(),
    status: invitationStatusEnum('status').default('pending').notNull(),
    acceptedAt: timestamp('accepted_at'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
  },
  (table) => [
    unique('invitations_unique').on(table.companyId, table.email, table.status),
    index('idx_invitations_company').on(table.companyId, table.status),
    index('idx_invitations_token')
      .on(table.token)
      .where(sql`${table.status} = 'pending'`),
    index('idx_invitations_code')
      .on(table.inviteCode)
      .where(sql`${table.status} = 'pending'`),
    index('idx_invitations_email').on(table.email, table.status),
  ],
);

// ============================================
// 9. EMAIL VERIFICATIONS
// ============================================

export const emailVerifications = pgTable(
  'email_verifications',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .references(() => users.id, { onDelete: 'cascade' })
      .notNull(),
    email: varchar('email', { length: 255 }).notNull(),
    otp: varchar('otp', { length: 6 }).notNull(),
    expiresAt: timestamp('expires_at').notNull(),
    verifiedAt: timestamp('verified_at'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
  },
  (table) => [
    index('idx_email_verifications_user').on(table.userId),
    index('idx_email_verifications_email').on(table.email),
    index('idx_email_verifications_otp').on(table.otp),
    index('idx_email_verifications_expires').on(table.expiresAt),
  ],
);

// ============================================
// 10. NOTIFICATIONS
// ============================================

export const notifications = pgTable(
  'notifications',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .references(() => users.id, { onDelete: 'cascade' })
      .notNull(),
    type: varchar('type', { length: 50 }).notNull(),
    title: varchar('title', { length: 255 }).notNull(),
    message: text('message').notNull(),
    relatedEntityType: varchar('related_entity_type', { length: 50 }),
    relatedEntityId: uuid('related_entity_id'),
    actionUrl: text('action_url'),
    read: boolean('read').default(false).notNull(),
    readAt: timestamp('read_at'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
  },
  (table) => [
    index('idx_notifications_user').on(table.userId, table.read, table.createdAt),
    index('idx_notifications_type').on(table.type, table.createdAt),
  ],
);

// ============================================
// 11. ACTIVITY LOGS
// ============================================

export const activityLogs = pgTable(
  'activity_logs',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    companyId: uuid('company_id')
      .references(() => companies.id, { onDelete: 'cascade' })
      .notNull(),
    userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }),
    action: varchar('action', { length: 100 }).notNull(),
    entityType: varchar('entity_type', { length: 50 }).notNull(),
    entityId: uuid('entity_id').notNull(),
    details: jsonb('details').default({}),
    ipAddress: varchar('ip_address', { length: 45 }),
    userAgent: text('user_agent'),
    createdAt: timestamp('created_at').defaultNow().notNull(),
  },
  (table) => [
    index('idx_activity_company').on(table.companyId, table.createdAt),
    index('idx_activity_user').on(table.userId, table.createdAt),
    index('idx_activity_entity').on(table.entityType, table.entityId, table.createdAt),
  ],
);

// ============================================
// RELATIONS
// ============================================

export const companiesRelations = relations(companies, ({ many }) => ({
  users: many(users),
  teams: many(teams),
  departments: many(departments),
  roles: many(roles),
  materialListings: many(materialListings),
  invitations: many(invitations),
  activityLogs: many(activityLogs),
}));

export const usersRelations = relations(users, ({ one, many }) => ({
  company: one(companies, {
    fields: [users.companyId],
    references: [companies.id],
  }),
  manager: one(users, {
    fields: [users.reportsToUserId],
    references: [users.id],
  }),
  directReports: many(users),
  teamMemberships: many(teamMembers),
  ledTeams: many(teams),
  managedDepartments: many(departments),
  userRoles: many(userRoles),
  createdListings: many(materialListings),
  sentInvitations: many(invitations),
  receivedApprovals: many(listingApprovals),
  activityLogs: many(activityLogs),
  notifications: many(notifications),
}));

export const teamsRelations = relations(teams, ({ one, many }) => ({
  company: one(companies, {
    fields: [teams.companyId],
    references: [companies.id],
  }),
  teamLead: one(users, {
    fields: [teams.teamLeadUserId],
    references: [users.id],
  }),
  members: many(teamMembers),
  departments: many(departmentTeams),
  listings: many(materialListings),
}));

export const teamMembersRelations = relations(teamMembers, ({ one }) => ({
  team: one(teams, {
    fields: [teamMembers.teamId],
    references: [teams.id],
  }),
  user: one(users, {
    fields: [teamMembers.userId],
    references: [users.id],
  }),
}));

export const departmentsRelations = relations(departments, ({ one, many }) => ({
  company: one(companies, {
    fields: [departments.companyId],
    references: [companies.id],
  }),
  parent: one(departments, {
    fields: [departments.parentDepartmentId],
    references: [departments.id],
  }),
  children: many(departments),
  manager: one(users, {
    fields: [departments.managerUserId],
    references: [users.id],
  }),
  teams: many(departmentTeams),
  ancestors: many(departmentHierarchy, { relationName: 'descendant' }),
  descendants: many(departmentHierarchy, { relationName: 'ancestor' }),
}));

export const departmentTeamsRelations = relations(departmentTeams, ({ one }) => ({
  department: one(departments, {
    fields: [departmentTeams.departmentId],
    references: [departments.id],
  }),
  team: one(teams, {
    fields: [departmentTeams.teamId],
    references: [teams.id],
  }),
}));

export const rolesRelations = relations(roles, ({ one, many }) => ({
  company: one(companies, {
    fields: [roles.companyId],
    references: [companies.id],
  }),
  userRoles: many(userRoles),
}));

export const userRolesRelations = relations(userRoles, ({ one }) => ({
  user: one(users, {
    fields: [userRoles.userId],
    references: [users.id],
  }),
  role: one(roles, {
    fields: [userRoles.roleId],
    references: [roles.id],
  }),
  grantedBy: one(users, {
    fields: [userRoles.grantedByUserId],
    references: [users.id],
  }),
}));

export const materialListingsRelations = relations(
  materialListings,
  ({ one, many }) => ({
    company: one(companies, {
      fields: [materialListings.companyId],
      references: [companies.id],
    }),
    creator: one(users, {
      fields: [materialListings.createdByUserId],
      references: [users.id],
    }),
    team: one(teams, {
      fields: [materialListings.teamId],
      references: [teams.id],
    }),
    category: one(materialCategories, {
      fields: [materialListings.categoryId],
      references: [materialCategories.id],
    }),
    currentApprover: one(users, {
      fields: [materialListings.currentApproverUserId],
      references: [users.id],
    }),
    approvedBy: one(users, {
      fields: [materialListings.approvedByUserId],
      references: [users.id],
    }),
    approvals: many(listingApprovals),
    statusHistory: many(listingStatusHistory),
  }),
);

export const listingApprovalsRelations = relations(
  listingApprovals,
  ({ one }) => ({
    listing: one(materialListings, {
      fields: [listingApprovals.listingId],
      references: [materialListings.id],
    }),
    approver: one(users, {
      fields: [listingApprovals.approverUserId],
      references: [users.id],
    }),
  }),
);

export const invitationsRelations = relations(invitations, ({ one }) => ({
  company: one(companies, {
    fields: [invitations.companyId],
    references: [companies.id],
  }),
  invitedBy: one(users, {
    fields: [invitations.invitedByUserId],
    references: [users.id],
  }),
  team: one(teams, {
    fields: [invitations.teamId],
    references: [teams.id],
  }),
  role: one(roles, {
    fields: [invitations.roleId],
    references: [roles.id],
  }),
}));

