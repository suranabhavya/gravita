# Permission System Implementation Progress

## Overview
This document tracks the implementation of the comprehensive role-based permission system based on the Gravita Permission Matrix.

---

## ✅ Phase 1: Backend Permission Enforcement (COMPLETED)

### 1.1 Permission Guards Added to All Controllers ✅

**Files Modified:**
- `backend/src/company/team.controller.ts`
- `backend/src/company/department.controller.ts`
- `backend/src/company/users.controller.ts`
- `backend/src/company/company.controller.ts`
- `backend/src/company/invitation.controller.ts`

**Changes:**
- Added `PermissionGuard` and `@RequirePermission` decorators to all endpoints
- Protected team operations with `manage_structure` permission
- Protected department operations with `manage_structure` permission
- Protected user operations with scope-based checks
- Protected company settings with `access_settings` permission (admin only)
- Protected invitation endpoints with `manage_structure` permission

**Key Implementation Details:**
- Team endpoints now check if user has permission to manage the specific team (scope check)
- Department endpoints verify user's department scope using closure table
- User endpoints filter results based on requesting user's scope
- Settings endpoints restricted to admins only

---

### 1.2 Scope-Based Query Filtering Using Closure Table ✅

**Files Modified:**
- `backend/src/company/team.service.ts`
- `backend/src/company/department.service.ts`
- `backend/src/company/user.service.ts`

**Implementation Highlights:**

#### Team Service (`getCompanyTeams`)
```typescript
// O(1) query using closure table for department scope
const descendantDepts = await db
  .select({ deptId: departmentHierarchy.descendantId })
  .from(departmentHierarchy)
  .where(eq(departmentHierarchy.ancestorId, context.scopeId));
```

**Scope Filtering Logic:**
- **Company Scope**: Returns all teams (no filtering)
- **Department Scope**: Uses closure table to get all descendant departments, then returns teams in those departments
- **Team Scope**: Returns only the user's own team

#### Department Service (`getCompanyDepartments`)
```typescript
// Get department + all descendants in O(1)
const descendantDepts = await db
  .select({ deptId: departmentHierarchy.descendantId })
  .from(departmentHierarchy)
  .where(eq(departmentHierarchy.ancestorId, context.scopeId));
```

**Scope Filtering Logic:**
- **Company Scope**: Returns all departments
- **Department Scope**: Returns department + all descendants using closure table
- **Team Scope**: Returns empty array (team-scoped users can't see departments)

#### User Service (`getCompanyMembers`)
**Scope Filtering Logic:**
- **Company Scope**: Returns all members
- **Department Scope**: Gets teams in department (via closure table), then returns members in those teams
- **Team Scope**: Returns only members of the user's team

**Performance Benefits:**
- All hierarchical queries are O(1) instead of O(n) recursive queries
- No need for recursive CTEs
- Instant scope validation

---

### 1.3 Role Upgrade Logic (Already Implemented) ✅

**Files Verified:**
- `backend/src/company/team.service.ts` - `createTeamFromMembers()`
- `backend/src/company/department.service.ts` - `createDepartmentFromTeams()`

**Implementation Details:**

#### Team Lead Upgrade (lines 522-557 in team.service.ts)
```typescript
if (dto.teamLeadUserId) {
  // Get "Team Lead" system role
  const [leadRole] = await tx
    .select()
    .from(roles)
    .where(
      and(
        eq(roles.companyId, dto.companyId),
        eq(roles.roleType, 'lead'),
        isNull(roles.deletedAt),
      ),
    )
    .limit(1);

  if (leadRole) {
    // Update user's role to Lead with team scope
    await tx
      .update(userRoles)
      .set({
        roleId: leadRole.id,
        scopeType: 'team',
        scopeId: teamId,
        maxApprovalAmountOverride: dto.teamLeadApprovalLimit 
          ? dto.teamLeadApprovalLimit.toString() 
          : null,
      })
      .where(eq(userRoles.userId, dto.teamLeadUserId));
  }
}
```

#### Department Manager Upgrade (lines 812-838 in department.service.ts)
```typescript
if (dto.managerUserId) {
  // Get "Manager" system role
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
    // Update user's role to Manager with department scope
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
```

**Key Features:**
- Automatic role upgrade when user becomes team lead or department manager
- Scope automatically updated to match their new responsibility
- Optional approval limit override for team leads
- All done within database transactions for atomicity

---

### 1.4 Invitation Dual-Flow (Already Implemented) ✅

**Files Verified:**
- `backend/src/company/invitation.service.ts` - `validateInvitation()`
- `backend/src/company/utils/invite-code-generator.ts`

**Implementation Details:**

#### Invite Code Generator
```typescript
export function generateInviteCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excluding O, 0, I, 1
  const segments = [4, 4]; // XXXX-XXXX format
  
  return segments
    .map((length) => {
      let segment = '';
      for (let i = 0; i < length; i++) {
        segment += chars.charAt(Math.floor(Math.random() * chars.length));
      }
      return segment;
    })
    .join('-');
}
```

#### Dual Validation (lines 64-77 in invitation.service.ts)
```typescript
const [invitation] = await db
  .select()
  .from(invitations)
  .where(
    and(
      or(
        eq(invitations.token, trimmed), // Magic link token
        eq(invitations.inviteCode, normalizedCode) // Manual code (XXXX-XXXX)
      ),
      eq(invitations.status, 'pending'),
      gt(invitations.expiresAt, new Date()),
    ),
  )
  .limit(1);
```

**Key Features:**
- Both magic link (token) and manual code (XXXX-XXXX) work
- Invite codes exclude confusing characters (O, 0, I, 1)
- Case-insensitive code matching
- Expiration check for both methods
- Detailed error logging for debugging

---

## ✅ Phase 2: Frontend Permission UI (IN PROGRESS)

### 2.1 Permission Gate Widget ✅

**File Created:**
- `frontend/lib/widgets/permission_gate.dart`

**Widgets Implemented:**

#### 1. PermissionGate
Conditionally renders based on permission flags.
```dart
PermissionGate(
  permission: 'manage_structure',
  child: ElevatedButton(
    onPressed: () => createTeam(),
    child: Text('Create Team'),
  ),
  fallback: SizedBox.shrink(),
)
```

#### 2. RoleGate
Conditionally renders based on user role.
```dart
RoleGate(
  allowedRoles: [RoleType.admin, RoleType.manager],
  child: Text('Admin/Manager only content'),
)
```

#### 3. ScopeGate
Conditionally renders based on user scope.
```dart
ScopeGate(
  requiredScopes: [ScopeType.company, ScopeType.department],
  child: Text('Company/Department scope only'),
)
```

#### 4. ApprovalLimitGate
Conditionally renders based on approval amount.
```dart
ApprovalLimitGate(
  requiredAmount: 100000.0,
  child: ElevatedButton(
    onPressed: () => approveListing(),
    child: Text('Approve'),
  ),
  fallback: Text('Amount exceeds your limit'),
)
```

---

### 2.2 Role-Specific Dashboards (PENDING)

**To Be Created:**
- `frontend/lib/screens/dashboard/dashboard_router.dart`
- `frontend/lib/screens/dashboard/admin_dashboard.dart`
- `frontend/lib/screens/dashboard/manager_dashboard.dart`
- `frontend/lib/screens/dashboard/lead_dashboard.dart`
- `frontend/lib/screens/dashboard/member_dashboard.dart`

**Planned Features:**
- Dashboard router based on RoleType
- Different navigation bars per role
- Role-specific stats and widgets
- Scope indicators

---

### 2.3 Conditional UI Elements (PENDING)

**To Be Implemented:**
- Role-based bottom navigation
- Conditional action buttons (FAB)
- Settings icon (admin only)
- Scope indicators in app bar
- Role badges

---

## 🔄 Phase 3: People-First Flow (PENDING)

### 3.1 Unassigned Members Screen (PENDING)

**To Be Created:**
- `frontend/lib/screens/teams/unassigned_members_screen.dart`
- `frontend/lib/screens/teams/create_team_from_members_screen.dart`

**Features:**
- Show members with `scopeType='company'` and `scopeId=null`
- Multi-select functionality
- "Create Team from Selected" button
- Smart suggestions ("3+ unassigned members")

---

### 3.2 Bulk Invitation Screen (PENDING)

**To Be Created:**
- `frontend/lib/screens/invitations/bulk_invite_screen.dart`

**Features:**
- Large textarea for email input (one per line)
- Email validation
- Role selector dropdown
- Optional team assignment
- "Send Invites" button

---

## 🔄 Phase 4: Advanced Features (PENDING)

### 4.1 Approval Workflow UI (PENDING)

**To Be Created:**
- `frontend/lib/screens/materials/pending_approvals_screen.dart`

**Features:**
- Filtered by user's scope
- Amount-based filtering (only show approvable listings)
- Approve/Reject buttons
- Escalation indicators
- Amount badges (color-coded)

---

### 4.2 Analytics Scope Filtering (PENDING)

**To Be Implemented:**
- Company-wide analytics (admin only)
- Department analytics (manager)
- Team analytics (lead)
- Personal analytics (member)

---

### 4.3 Settings Access Control (PENDING)

**To Be Implemented:**
- Hide settings icon for non-admins
- Restrict settings routes
- Show "Access Denied" for unauthorized access

---

## 📊 Progress Summary

### Completed (5/12 tasks - 42%)
1. ✅ Backend permission guards on all controllers
2. ✅ Scope-based query filtering (using closure table)
3. ✅ Role upgrade logic (team leads & managers)
4. ✅ Invitation dual-flow (magic link + code)
5. ✅ PermissionGate widget

### In Progress (0/12 tasks)
None currently

### Pending (7/12 tasks - 58%)
6. ⏳ Role-specific dashboards
7. ⏳ Conditional UI elements
8. ⏳ Unassigned members screen
9. ⏳ Bulk invitation screen
10. ⏳ Approval workflow UI
11. ⏳ Analytics scope filtering
12. ⏳ Settings access control

---

## 🎯 Next Steps

### Immediate Priority (Phase 2)
1. Create dashboard router with role-based routing
2. Implement role-specific dashboard screens
3. Add conditional navigation and action buttons
4. Add scope indicators and role badges

### Short-term (Phase 3)
1. Build unassigned members screen
2. Implement "organize into teams" flow
3. Create bulk invitation screen

### Medium-term (Phase 4)
1. Build pending approvals screen
2. Implement scope-based analytics
3. Add settings access control

---

## 🔍 Key Learnings

### Backend
1. **Closure Table Pattern**: O(1) hierarchical queries are crucial for performance at scale
2. **Permission Guards**: Decorator-based approach keeps controllers clean
3. **Scope Filtering**: Always filter at query level, not in application code
4. **Transaction Safety**: Role upgrades must be atomic with team/department creation

### Frontend
1. **Permission Gates**: Reusable widgets prevent permission checks scattered throughout code
2. **Provider Pattern**: Centralized permission context makes checks consistent
3. **Multiple Gate Types**: Different gates for permissions, roles, scopes, and amounts
4. **Fallback Widgets**: Always provide fallback for better UX

### Architecture
1. **3-Flag System**: Simplified from 31 permissions to 3 flags reduces complexity
2. **Role + Scope Model**: Separating role from scope enables flexible permissions
3. **Approval Limits**: Per-user overrides allow customization without creating custom roles
4. **Dual Invitation**: Magic links for convenience, codes for reliability

---

## 📝 Notes for Future Implementation

### Testing Priorities
1. Test closure table queries with EXPLAIN ANALYZE
2. Verify scope filtering with different user roles
3. Test role upgrades in transaction rollback scenarios
4. Validate invitation dual-flow with expired codes

### Performance Considerations
1. Cache permission context after login
2. Index `departmentHierarchy` table properly
3. Consider materialized views for analytics
4. Batch permission checks where possible

### Security Considerations
1. Always validate scope on backend (never trust frontend)
2. Log all permission denials for audit
3. Rate limit invitation code attempts
4. Expire invite codes after reasonable time

---

*Last Updated: December 30, 2025*
*Implementation Status: 42% Complete (5/12 tasks)*


