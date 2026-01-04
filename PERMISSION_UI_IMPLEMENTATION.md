# Permission-Based UI Implementation Guide

## Overview
This document explains how to implement permission-based UI in Flutter screens using the new permission system.

## Setup

### 1. Provider Setup (Already Done)
The `PermissionProvider` is registered in `main.dart` and available throughout the app.

### 2. Fetch Permission Context After Login
After successful login, fetch and set the permission context:

```dart
import 'package:provider/provider.dart';
import '../providers/permission_provider.dart';
import '../services/permissions_service.dart';
import '../models/permission_context_model.dart';

// After login
final authData = await _authService.login(email, password);
final userId = authData['user']['id'];
final companyId = authData['user']['companyId'];

// Fetch permission context
final permissionsService = PermissionsService();
final permissionContext = await permissionsService.getPermissionContext(userId, companyId);

// Set in provider
Provider.of<PermissionProvider>(context, listen: false).setContext(permissionContext);
```

## Usage Examples

### Example 1: Show/Hide Button Based on Permission

```dart
import '../widgets/role_based_widget.dart';

PermissionCheck(
  permission: 'manage_structure',
  child: FloatingActionButton(
    onPressed: () => _handleInviteMember(),
    child: Icon(Icons.person_add),
  ),
)
```

### Example 2: Different UI for Different Roles

```dart
RoleBasedWidget(
  adminWidget: Column(
    children: [
      Text('Admin Dashboard'),
      ElevatedButton(onPressed: () => _manageSettings(), child: Text('Settings')),
      ElevatedButton(onPressed: () => _inviteMembers(), child: Text('Invite')),
    ],
  ),
  managerWidget: Column(
    children: [
      Text('Manager Dashboard'),
      ElevatedButton(onPressed: () => _inviteMembers(), child: Text('Invite')),
    ],
  ),
  memberWidget: Column(
    children: [
      Text('Member Dashboard'),
      ElevatedButton(onPressed: () => _createListing(), child: Text('Create Listing')),
    ],
  ),
)
```

### Example 3: Approval Amount Check

```dart
ApprovalAmountCheck(
  amount: 50000,
  child: ElevatedButton(
    onPressed: () => _approveListing(),
    child: Text('Approve Listing'),
  ),
  insufficientWidget: Text('Insufficient approval limit'),
)
```

### Example 4: Role-Specific Check

```dart
RoleCheck(
  allowedRoles: [RoleType.admin, RoleType.manager],
  child: ListTile(
    leading: Icon(Icons.settings),
    title: Text('Company Settings'),
    onTap: () => Navigator.pushNamed(context, '/settings'),
  ),
)
```

### Example 5: Using Provider Directly

```dart
import 'package:provider/provider.dart';
import '../providers/permission_provider.dart';

Consumer<PermissionProvider>(
  builder: (context, permissionProvider, child) {
    if (permissionProvider.canManageStructure) {
      return ElevatedButton(
        onPressed: () => _inviteMembers(),
        child: Text('Invite Members'),
      );
    }
    return SizedBox.shrink();
  },
)
```

## Complete Example: Company Page with Permissions

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/role_based_widget.dart';
import '../providers/permission_provider.dart';

class CompanyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final permissionProvider = Provider.of<PermissionProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Company'),
        actions: [
          // Only show settings for admins
          PermissionCheck(
            permission: 'access_settings',
            child: IconButton(
              icon: Icon(Icons.settings),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Show different tabs based on role
          RoleBasedWidget(
            adminWidget: _buildAdminTabs(),
            managerWidget: _buildManagerTabs(),
            memberWidget: _buildMemberTabs(),
          ),
        ],
      ),
      floatingActionButton: PermissionCheck(
        permission: 'manage_structure',
        child: FloatingActionButton.extended(
          onPressed: () => _showInviteOptions(context),
          icon: Icon(Icons.person_add),
          label: Text('Invite People'),
        ),
      ),
    );
  }

  void _showInviteOptions(BuildContext context) {
    final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.group_add),
            title: Text('Invite Members'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/invitations/bulk');
            },
          ),
          // Only show team creation for those who can manage structure
          PermissionCheck(
            permission: 'manage_structure',
            child: ListTile(
              leading: Icon(Icons.groups),
              title: Text('Create Team'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/teams/create');
              },
            ),
          ),
          // Only show department creation for managers and admins
          RoleCheck(
            allowedRoles: [RoleType.admin, RoleType.manager],
            child: ListTile(
              leading: Icon(Icons.corporate_fare),
              title: Text('Create Department'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/departments/create');
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

## Key Points

1. **Always check permissions at API level** - UI checks are for UX only
2. **Use PermissionCheck for simple show/hide** - Based on permission flags
3. **Use RoleBasedWidget for different content** - Based on role type
4. **Use ApprovalAmountCheck for amount-based actions** - For approval workflows
5. **Use RoleCheck for role-specific features** - When role matters more than permissions

## Backend Endpoint Needed

Add this endpoint to your backend to fetch permission context:

```typescript
// In users.controller.ts
@Get(':id/permission-context')
@UseGuards(JwtAuthGuard)
async getPermissionContext(
  @Param('id') userId: string,
  @Query('companyId') companyId: string,
  @CurrentUser() user: any,
) {
  const context = await this.permissionsService.getUserPermissionContext(
    userId,
    companyId,
  );
  return context;
}
```


