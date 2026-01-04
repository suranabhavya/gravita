import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/permission_provider.dart';
import '../models/permission_context_model.dart';

/// A widget that conditionally renders its child based on user permissions.
/// 
/// Example usage:
/// ```dart
/// PermissionGate(
///   permission: 'manage_structure',
///   child: ElevatedButton(
///     onPressed: () => createTeam(),
///     child: Text('Create Team'),
///   ),
///   fallback: SizedBox.shrink(), // Optional: widget to show when no permission
/// )
/// ```
class PermissionGate extends StatelessWidget {
  /// The permission required to show the child widget.
  /// Valid values: 'manage_structure', 'approve_listings', 'access_settings'
  final String permission;
  
  /// The widget to display if the user has the required permission
  final Widget child;
  
  /// Optional widget to display if the user doesn't have permission
  /// Defaults to SizedBox.shrink() (invisible widget)
  final Widget? fallback;

  const PermissionGate({
    Key? key,
    required this.permission,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final permissionProvider = Provider.of<PermissionProvider>(context);

    bool hasPermission = false;

    switch (permission) {
      case 'manage_structure':
        hasPermission = permissionProvider.context?.permissions.canManageStructure ?? false;
        break;
      case 'approve_listings':
        hasPermission = permissionProvider.context?.permissions.canApproveListings ?? false;
        break;
      case 'access_settings':
        hasPermission = permissionProvider.context?.permissions.canAccessSettings ?? false;
        break;
      default:
        // Unknown permission, default to false
        hasPermission = false;
        break;
    }

    if (hasPermission) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// A widget that conditionally renders its child based on user role.
/// 
/// Example usage:
/// ```dart
/// RoleGate(
///   allowedRoles: [RoleType.admin, RoleType.manager],
///   child: Text('Admin/Manager only content'),
/// )
/// ```
class RoleGate extends StatelessWidget {
  /// List of roles that are allowed to see the child widget
  final List<RoleType> allowedRoles;
  
  /// The widget to display if the user has one of the allowed roles
  final Widget child;
  
  /// Optional widget to display if the user doesn't have an allowed role
  final Widget? fallback;

  const RoleGate({
    Key? key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final permissionProvider = Provider.of<PermissionProvider>(context);
    final userRole = permissionProvider.context?.roleType;

    if (userRole != null && allowedRoles.contains(userRole)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// A widget that conditionally renders its child based on user scope.
/// 
/// Example usage:
/// ```dart
/// ScopeGate(
///   requiredScopes: [ScopeType.company, ScopeType.department],
///   child: Text('Company/Department scope only content'),
/// )
/// ```
class ScopeGate extends StatelessWidget {
  /// List of scopes that are allowed to see the child widget
  final List<ScopeType> requiredScopes;
  
  /// The widget to display if the user has one of the required scopes
  final Widget child;
  
  /// Optional widget to display if the user doesn't have a required scope
  final Widget? fallback;

  const ScopeGate({
    Key? key,
    required this.requiredScopes,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final permissionProvider = Provider.of<PermissionProvider>(context);
    final userScope = permissionProvider.context?.scopeType;

    if (userScope != null && requiredScopes.contains(userScope)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// A widget that shows different content based on approval limit.
/// 
/// Example usage:
/// ```dart
/// ApprovalLimitGate(
///   requiredAmount: 100000.0,
///   child: ElevatedButton(
///     onPressed: () => approveListing(),
///     child: Text('Approve'),
///   ),
///   fallback: Text('Amount exceeds your approval limit'),
/// )
/// ```
class ApprovalLimitGate extends StatelessWidget {
  /// The amount that needs to be approved
  final double requiredAmount;
  
  /// The widget to display if the user can approve this amount
  final Widget child;
  
  /// Optional widget to display if the user cannot approve this amount
  final Widget? fallback;

  const ApprovalLimitGate({
    Key? key,
    required this.requiredAmount,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final permissionProvider = Provider.of<PermissionProvider>(context);
    final canApprove = permissionProvider.canApprove(requiredAmount);

    if (canApprove) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

