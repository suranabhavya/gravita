import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/permission_provider.dart';
import '../models/permission_context_model.dart';

/// Shows different content based on user's role
class RoleBasedWidget extends StatelessWidget {
  final Widget? adminWidget;
  final Widget? managerWidget;
  final Widget? leadWidget;
  final Widget? memberWidget;
  final Widget? fallbackWidget;

  const RoleBasedWidget({
    Key? key,
    this.adminWidget,
    this.managerWidget,
    this.leadWidget,
    this.memberWidget,
    this.fallbackWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
    final roleType = permissionProvider.context?.roleType;

    if (roleType == null) {
      return fallbackWidget ?? const SizedBox.shrink();
    }

    switch (roleType) {
      case RoleType.admin:
        return adminWidget ?? fallbackWidget ?? const SizedBox.shrink();
      case RoleType.manager:
        return managerWidget ?? fallbackWidget ?? const SizedBox.shrink();
      case RoleType.lead:
        return leadWidget ?? fallbackWidget ?? const SizedBox.shrink();
      case RoleType.member:
        return memberWidget ?? fallbackWidget ?? const SizedBox.shrink();
    }
  }
}

/// Shows content only if user has specific permission
class PermissionCheck extends StatelessWidget {
  final String permission; // 'manage_structure', 'approve_listings', 'access_settings'
  final Widget child;
  final Widget? fallback;

  const PermissionCheck({
    Key? key,
    required this.permission,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);

    bool hasPermission = false;

    switch (permission) {
      case 'manage_structure':
        hasPermission = permissionProvider.canManageStructure;
        break;
      case 'approve_listings':
        hasPermission = permissionProvider.canApproveListings;
        break;
      case 'access_settings':
        hasPermission = permissionProvider.canAccessSettings;
        break;
    }

    if (hasPermission) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Show/hide based on approval amount
class ApprovalAmountCheck extends StatelessWidget {
  final double amount;
  final Widget child;
  final Widget? insufficientWidget;

  const ApprovalAmountCheck({
    Key? key,
    required this.amount,
    required this.child,
    this.insufficientWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);

    if (permissionProvider.canApprove(amount)) {
      return child;
    }

    return insufficientWidget ?? const SizedBox.shrink();
  }
}

/// Show widget only for specific roles
class RoleCheck extends StatelessWidget {
  final List<RoleType> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleCheck({
    Key? key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
    final roleType = permissionProvider.context?.roleType;

    if (roleType != null && allowedRoles.contains(roleType)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}


