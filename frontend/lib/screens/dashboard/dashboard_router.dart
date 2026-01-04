import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/permission_provider.dart';
import '../../models/permission_context_model.dart';
import 'admin_dashboard.dart';
import 'manager_dashboard.dart';
import 'lead_dashboard.dart';
import 'member_dashboard.dart';

/// Routes to the appropriate dashboard based on user's role
class DashboardRouter extends StatefulWidget {
  const DashboardRouter({Key? key}) : super(key: key);

  @override
  State<DashboardRouter> createState() => _DashboardRouterState();
}

class _DashboardRouterState extends State<DashboardRouter> {
  @override
  void initState() {
    super.initState();
    // Load permission context when widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
      if (permissionProvider.context == null && !permissionProvider.isLoading) {
        permissionProvider.loadPermissionContext();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final permissionProvider = Provider.of<PermissionProvider>(context);
    final roleType = permissionProvider.context?.roleType;

    // Show loading if permission context not yet loaded
    if (roleType == null) {
      // If not loading and there's an error, show error message
      if (!permissionProvider.isLoading && permissionProvider.error != null) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0d2818),
                Color(0xFF1a4d2e),
                Color(0xFF0f2e1a),
                Color(0xFF052e16),
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load permissions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  permissionProvider.error ?? 'Unknown error',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    permissionProvider.loadPermissionContext();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      // Show loading indicator
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0d2818),
              Color(0xFF1a4d2e),
              Color(0xFF0f2e1a),
              Color(0xFF052e16),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    // Route to appropriate dashboard based on role
    switch (roleType) {
      case RoleType.admin:
        return const AdminDashboard();
      case RoleType.manager:
        return const ManagerDashboard();
      case RoleType.lead:
        return const LeadDashboard();
      case RoleType.member:
        return const MemberDashboard();
    }
  }
}

