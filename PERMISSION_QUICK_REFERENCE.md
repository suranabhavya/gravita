# Permission System - Quick Reference Guide

## For Backend Developers

### Protecting a Route

```typescript
import { UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionGuard } from '../auth/guards/permission.guard';
import { RequirePermission } from '../auth/decorators/require-permission.decorator';

@Controller('teams')
@UseGuards(JwtAuthGuard, PermissionGuard)
export class TeamController {
  
  // Simple permission check
  @Post()
  @RequirePermission({ action: 'manage_structure' })
  async createTeam(@Body() dto: CreateTeamDto) {
    // ...
  }

  // Permission check with scope validation
  @Get(':id')
  @RequirePermission({ 
    action: 'view', 
    targetType: 'team',
    getTargetId: (req) => req.params.id 
  })
  async getTeam(@Param('id') id: string) {
    // ...
  }

  // Permission check with custom validation
  @Patch(':id')
  @RequirePermission({ 
    action: 'manage_structure',
    targetType: 'team',
    getTargetId: (req) => req.params.id,
    customCheck: async (context, permissionsService, targetId) => {
      // Custom logic here
      return true;
    }
  })
  async updateTeam(@Param('id') id: string, @Body() dto: UpdateTeamDto) {
    // ...
  }
}
```

### Accessing User Permission Context

```typescript
import { Request } from 'express';

@Get()
async getSomething(@Req() request: Request) {
  const permissionContext = request.permissionContext;
  
  // Available properties:
  // - userId: string
  // - companyId: string
  // - roleType: 'admin' | 'manager' | 'lead' | 'member'
  // - permissions: { canManageStructure, canApproveListings, canAccessSettings }
  // - scopeType: 'company' | 'department' | 'team'
  // - scopeId: string | null
  // - maxApprovalAmount: number
}
```

### Implementing Scope-Based Filtering

```typescript
async getTeams(permissionContext: UserPermissionContext) {
  const { scopeType, scopeId, companyId } = permissionContext;

  let query = this.db
    .select()
    .from(teams)
    .where(eq(teams.companyId, companyId));

  if (scopeType === 'department' && scopeId) {
    // Filter by department hierarchy
    const subQuery = this.db
      .select({ teamId: teamDepartments.teamId })
      .from(teamDepartments)
      .innerJoin(
        departmentHierarchy,
        eq(teamDepartments.departmentId, departmentHierarchy.descendantId)
      )
      .where(eq(departmentHierarchy.ancestorId, scopeId));
    
    query = query.where(inArray(teams.id, subQuery));
  } else if (scopeType === 'team' && scopeId) {
    // Filter by specific team
    query = query.where(eq(teams.id, scopeId));
  }

  return await query;
}
```

### Checking Permissions in Service

```typescript
import { PermissionsService } from './permissions.service';

constructor(
  private readonly permissionsService: PermissionsService,
) {}

async doSomething(userId: string, targetId: string) {
  const context = await this.permissionsService.getUserPermissionContext(userId);
  
  // Check if user can perform action
  const canPerform = await this.permissionsService.canPerformAction(
    context,
    'manage_structure',
    'team',
    targetId
  );
  
  if (!canPerform) {
    throw new ForbiddenException('You do not have permission');
  }
  
  // Check if target is in user's scope
  const isInScope = await this.permissionsService.isInScope(
    context,
    'team',
    targetId
  );
  
  if (!isInScope) {
    throw new ForbiddenException('Target is outside your scope');
  }
}
```

## For Frontend Developers

### Using PermissionGate

```dart
import 'package:gravita/widgets/permission_gate.dart';

// Show/hide based on permission
PermissionGate(
  permission: 'canManageStructure',
  child: ElevatedButton(
    onPressed: () => Navigator.push(...),
    child: Text('Create Team'),
  ),
  fallback: SizedBox.shrink(), // Optional
)

// Show/hide based on role
RoleGate(
  roleType: RoleType.admin,
  child: SettingsButton(),
)

// Show/hide based on scope
ScopeGate(
  scopeType: ScopeType.company,
  child: CompanyWideAnalytics(),
)

// Show/hide based on approval limit
ApprovalLimitGate(
  amount: 50000,
  child: ApproveButton(),
  fallback: Text('Amount exceeds your limit'),
)
```

### Accessing Permission Context

```dart
import 'package:provider/provider.dart';
import 'package:gravita/providers/permission_provider.dart';

Widget build(BuildContext context) {
  final permissionProvider = Provider.of<PermissionProvider>(context);
  
  // Check permissions
  if (permissionProvider.canManageStructure) {
    // Show management UI
  }
  
  if (permissionProvider.canApproveListings) {
    // Show approval UI
  }
  
  if (permissionProvider.canAccessSettings) {
    // Show settings UI
  }
  
  // Check role
  if (permissionProvider.isAdmin) {
    // Admin-specific UI
  }
  
  // Check approval limit
  if (permissionProvider.canApprove(50000)) {
    // Show approve button
  }
  
  // Get full context
  final context = permissionProvider.context;
  // context.userId, context.roleType, context.scopeType, etc.
}
```

### Using Role-Based Navigation

```dart
import 'package:gravita/widgets/role_based_navigation.dart';

// Get navigation items for current role
final navItems = RoleBasedNavigation.getNavigationItems(roleType);

// Get FAB configuration
final fabConfig = RoleBasedNavigation.getFABConfig(roleType);

// Check if settings should be shown
final showSettings = RoleBasedNavigation.shouldShowSettings(roleType);

// Get contextual actions for a screen
final actions = ContextualActions.getActionsForScreen('company', roleType);
```

### Using Analytics Service

```dart
import 'package:gravita/services/analytics_service.dart';

final analyticsService = AnalyticsService();
final permissionContext = permissionProvider.context!;

// Get scope-appropriate analytics
final analytics = await analyticsService.getAnalytics(permissionContext);

// Get specific stats
final listingStats = await analyticsService.getListingStats(permissionContext);
final teamStats = await analyticsService.getTeamStats(permissionContext);
final memberStats = await analyticsService.getMemberStats(permissionContext);
final approvalStats = await analyticsService.getApprovalStats(permissionContext);
final financialSummary = await analyticsService.getFinancialSummary(permissionContext);

// Check analytics permissions
final canViewCompany = AnalyticsScope.canViewCompanyAnalytics(permissionContext);
final canViewDept = AnalyticsScope.canViewDepartmentAnalytics(permissionContext);
final canViewTeam = AnalyticsScope.canViewTeamAnalytics(permissionContext);
final canExport = AnalyticsScope.canExportAnalytics(permissionContext);
```

## Permission Actions Reference

### Available Actions
- `view` - View a resource
- `manage_structure` - Create/update/delete teams, departments, invite members
- `approve_listings` - Approve material listings
- `access_settings` - Access company settings

### Target Types
- `team` - Team entity
- `department` - Department entity
- `user` - User entity
- `company` - Company entity
- `listing` - Material listing entity

## Role Capabilities Matrix

| Capability | Admin | Manager | Lead | Member |
|-----------|-------|---------|------|--------|
| View company-wide data | ✅ | ❌ | ❌ | ❌ |
| View department data | ✅ | ✅ (own) | ❌ | ❌ |
| View team data | ✅ | ✅ (in dept) | ✅ (own) | ✅ (own) |
| Create departments | ✅ | ❌ | ❌ | ❌ |
| Create teams | ✅ | ✅ (in dept) | ❌ | ❌ |
| Invite members | ✅ | ✅ (to dept) | ✅ (to team) | ❌ |
| Approve listings | ✅ (up to limit) | ✅ (up to limit, in scope) | ✅ (up to limit, in scope) | ❌ |
| Access settings | ✅ | ❌ | ❌ | ❌ |
| Export analytics | ✅ | ✅ | ❌ | ❌ |

## Common Patterns

### Pattern 1: Admin-Only Feature
```dart
// Frontend
PermissionGate(
  permission: 'canAccessSettings',
  child: SettingsButton(),
)

// Backend
@RequirePermission({ action: 'access_settings' })
```

### Pattern 2: Scope-Based List
```typescript
// Backend
async getList(permissionContext: UserPermissionContext) {
  // Apply scope filtering
  return await this.service.getFiltered(permissionContext);
}

// Frontend - automatically scoped by backend
final items = await ApiService.get('/items');
```

### Pattern 3: Approval with Amount Check
```dart
// Frontend
ApprovalLimitGate(
  amount: listing.amount,
  child: ApproveButton(onPressed: () => approve(listing)),
  fallback: Text('Exceeds your approval limit'),
)

// Backend
@RequirePermission({ 
  action: 'approve_listings',
  customCheck: async (context, service, listingId) => {
    const listing = await getListing(listingId);
    return listing.amount <= context.maxApprovalAmount;
  }
})
```

### Pattern 4: Hierarchical Scope Check
```typescript
// Check if user can access a team in their department
const isInScope = await this.permissionsService.isInScope(
  context,
  'team',
  teamId
);
```

## Debugging Tips

### Backend
1. Check `request.permissionContext` to see what permissions the user has
2. Use `permissionsService.getUserPermissionContext(userId)` to debug permission issues
3. Check database: `userRoles` table for role assignments, `departmentHierarchy` for scope

### Frontend
1. Use `permissionProvider.context` to inspect current permissions
2. Check console for permission-related errors
3. Verify API responses include proper error messages for permission denials

## Common Mistakes to Avoid

1. ❌ Don't check permissions only on frontend - always enforce on backend
2. ❌ Don't forget to pass `permissionContext` to service methods
3. ❌ Don't use recursive queries for hierarchy - use closure table
4. ❌ Don't hardcode role names - use enums/types
5. ❌ Don't forget to update `departmentHierarchy` when moving teams/departments
6. ❌ Don't expose sensitive data in API responses - filter based on scope
7. ❌ Don't forget to handle permission errors gracefully in UI

## Testing Checklist

- [ ] User with role A can access feature X
- [ ] User with role B cannot access feature X
- [ ] User can only see data within their scope
- [ ] Approval limits are enforced
- [ ] Settings are admin-only
- [ ] Navigation adapts to user role
- [ ] Analytics show correct scope
- [ ] Permission errors show helpful messages
- [ ] Automatic role upgrades work
- [ ] Invitation flow respects permissions


