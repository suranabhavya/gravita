import 'package:flutter/material.dart';
import '../models/permission_context_model.dart';

/// Navigation items configuration based on user role
class RoleBasedNavigation {
  /// Get navigation items for the given role
  static List<NavigationItem> getNavigationItems(RoleType roleType) {
    switch (roleType) {
      case RoleType.admin:
        return _adminNavItems;
      case RoleType.manager:
        return _managerNavItems;
      case RoleType.lead:
        return _leadNavItems;
      case RoleType.member:
        return _memberNavItems;
    }
  }

  /// Get FAB configuration for the given role
  static FABConfig? getFABConfig(RoleType roleType) {
    switch (roleType) {
      case RoleType.admin:
        return FABConfig(
          icon: Icons.add,
          label: 'Quick Actions',
          actions: [
            FABAction(
              icon: Icons.person_add,
              label: 'Invite Members',
              route: '/invitations/bulk',
            ),
            FABAction(
              icon: Icons.group_add,
              label: 'Create Team',
              route: '/teams/create',
            ),
            FABAction(
              icon: Icons.apartment,
              label: 'Create Department',
              route: '/departments/create',
            ),
          ],
        );
      case RoleType.manager:
        return FABConfig(
          icon: Icons.add,
          label: 'Quick Actions',
          actions: [
            FABAction(
              icon: Icons.person_add,
              label: 'Invite to Department',
              route: '/invitations/bulk',
            ),
            FABAction(
              icon: Icons.group_add,
              label: 'Create Team',
              route: '/teams/create',
            ),
          ],
        );
      case RoleType.lead:
      case RoleType.member:
        return FABConfig(
          icon: Icons.add_box,
          label: 'Create Listing',
          route: '/materials/create',
        );
    }
  }

  /// Check if settings icon should be shown
  static bool shouldShowSettings(RoleType roleType) {
    return roleType == RoleType.admin;
  }

  // Admin navigation items
  static final List<NavigationItem> _adminNavItems = [
    NavigationItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
      route: '/dashboard',
    ),
    NavigationItem(
      icon: Icons.inventory_2,
      label: 'Materials',
      route: '/materials',
    ),
    NavigationItem(
      icon: Icons.business,
      label: 'Company',
      route: '/company',
    ),
    NavigationItem(
      icon: Icons.settings,
      label: 'Settings',
      route: '/settings',
    ),
  ];

  // Manager navigation items
  static final List<NavigationItem> _managerNavItems = [
    NavigationItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
      route: '/dashboard',
    ),
    NavigationItem(
      icon: Icons.inventory_2,
      label: 'Materials',
      route: '/materials',
    ),
    NavigationItem(
      icon: Icons.apartment,
      label: 'My Department',
      route: '/department',
    ),
  ];

  // Lead navigation items
  static final List<NavigationItem> _leadNavItems = [
    NavigationItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
      route: '/dashboard',
    ),
    NavigationItem(
      icon: Icons.inventory_2,
      label: 'Materials',
      route: '/materials',
    ),
    NavigationItem(
      icon: Icons.group,
      label: 'My Team',
      route: '/team',
    ),
  ];

  // Member navigation items
  static final List<NavigationItem> _memberNavItems = [
    NavigationItem(
      icon: Icons.home,
      label: 'Home',
      route: '/dashboard',
    ),
    NavigationItem(
      icon: Icons.list_alt,
      label: 'My Listings',
      route: '/materials/my-listings',
    ),
    NavigationItem(
      icon: Icons.group,
      label: 'My Team',
      route: '/team',
    ),
  ];
}

/// Navigation item model
class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

/// FAB configuration model
class FABConfig {
  final IconData icon;
  final String label;
  final String? route;
  final List<FABAction>? actions;

  FABConfig({
    required this.icon,
    required this.label,
    this.route,
    this.actions,
  });

  bool get hasMultipleActions => actions != null && actions!.isNotEmpty;
}

/// FAB action model
class FABAction {
  final IconData icon;
  final String label;
  final String route;

  FABAction({
    required this.icon,
    required this.label,
    required this.route,
  });
}

/// Widget that shows/hides based on role
class RoleBasedWidget extends StatelessWidget {
  final RoleType? requiredRole;
  final List<RoleType>? allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleBasedWidget({
    Key? key,
    this.requiredRole,
    this.allowedRoles,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This would need to access the permission provider
    // For now, just return the child
    return child;
  }
}

/// Action button configuration based on context
class ContextualActions {
  /// Get actions available for a specific screen based on role
  static List<ActionButton> getActionsForScreen(
    String screenName,
    RoleType roleType,
  ) {
    switch (screenName) {
      case 'company':
        return _getCompanyActions(roleType);
      case 'team':
        return _getTeamActions(roleType);
      case 'materials':
        return _getMaterialActions(roleType);
      default:
        return [];
    }
  }

  static List<ActionButton> _getCompanyActions(RoleType roleType) {
    switch (roleType) {
      case RoleType.admin:
        return [
          ActionButton(
            icon: Icons.person_add,
            label: 'Invite Members',
            route: '/invitations/bulk',
          ),
          ActionButton(
            icon: Icons.group_add,
            label: 'Create Team',
            route: '/teams/create',
          ),
          ActionButton(
            icon: Icons.apartment,
            label: 'Create Department',
            route: '/departments/create',
          ),
          ActionButton(
            icon: Icons.people_outline,
            label: 'Unassigned Members',
            route: '/teams/unassigned',
          ),
        ];
      case RoleType.manager:
        return [
          ActionButton(
            icon: Icons.person_add,
            label: 'Invite to Department',
            route: '/invitations/bulk',
          ),
          ActionButton(
            icon: Icons.group_add,
            label: 'Create Team',
            route: '/teams/create',
          ),
          ActionButton(
            icon: Icons.people_outline,
            label: 'Unassigned Members',
            route: '/teams/unassigned',
          ),
        ];
      default:
        return [];
    }
  }

  static List<ActionButton> _getTeamActions(RoleType roleType) {
    switch (roleType) {
      case RoleType.admin:
      case RoleType.manager:
      case RoleType.lead:
        return [
          ActionButton(
            icon: Icons.person_add,
            label: 'Invite to Team',
            route: '/invitations/bulk',
          ),
        ];
      default:
        return [];
    }
  }

  static List<ActionButton> _getMaterialActions(RoleType roleType) {
    return [
      ActionButton(
        icon: Icons.add_box,
        label: 'Create Listing',
        route: '/materials/create',
      ),
      if (roleType == RoleType.admin ||
          roleType == RoleType.manager ||
          roleType == RoleType.lead)
        ActionButton(
          icon: Icons.pending_actions,
          label: 'Pending Approvals',
          route: '/materials/approvals/pending',
        ),
    ];
  }
}

/// Action button model
class ActionButton {
  final IconData icon;
  final String label;
  final String route;
  final VoidCallback? onTap;

  ActionButton({
    required this.icon,
    required this.label,
    required this.route,
    this.onTap,
  });
}


