import 'dart:convert';
import 'api_service.dart';
import '../models/permission_context_model.dart';

class RolePermissionInfo {
  final String title;
  final String description;
  final List<String> permissions;
  final String approvalLimit;

  RolePermissionInfo({
    required this.title,
    required this.description,
    required this.permissions,
    required this.approvalLimit,
  });
}

class RolesService {
  Future<Map<String, dynamic>> assignRole({
    required String userId,
    required RoleType roleType,
    ScopeType? scopeType,
    String? scopeId,
    double? maxApprovalAmountOverride,
  }) async {
    final body = {
      'userId': userId,
      'roleType': roleType.name,
      if (scopeType != null) 'scopeType': scopeType.name,
      if (scopeId != null) 'scopeId': scopeId,
      if (maxApprovalAmountOverride != null)
        'maxApprovalAmountOverride': maxApprovalAmountOverride,
    };

    final response = await ApiService.post(
      '/users/assign-role',
      body,
      includeAuth: true,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to assign role');
    }
  }

  RolePermissionInfo getRolePermissionInfo(RoleType roleType) {
    switch (roleType) {
      case RoleType.admin:
        return RolePermissionInfo(
          title: 'Company Admin',
          description: 'Full control over the entire company',
          permissions: [
            'Manage company structure',
            'Create & manage teams/departments',
            'Approve all listings',
            'Access company settings',
            'Manage all users',
          ],
          approvalLimit: 'Unlimited',
        );
      case RoleType.manager:
        return RolePermissionInfo(
          title: 'Manager',
          description: 'Manages departments and approves listings',
          permissions: [
            'Manage department structure',
            'Create & edit teams in department',
            'Approve listings up to limit',
            'Add members to department',
          ],
          approvalLimit: '\$500,000',
        );
      case RoleType.lead:
        return RolePermissionInfo(
          title: 'Team Lead',
          description: 'Leads a team and approves smaller listings',
          permissions: [
            'Manage team members',
            'Approve listings up to limit',
            'Create material listings',
            'View team analytics',
          ],
          approvalLimit: '\$50,000',
        );
      case RoleType.member:
        return RolePermissionInfo(
          title: 'Team Member',
          description: 'Creates and manages material listings',
          permissions: [
            'Create material listings',
            'Edit own listings',
            'View team materials',
          ],
          approvalLimit: 'None',
        );
    }
  }

  List<RoleType> getAvailableRolesForUser(RoleType currentUserRole) {
    switch (currentUserRole) {
      case RoleType.admin:
        return [RoleType.admin, RoleType.manager, RoleType.lead, RoleType.member];
      case RoleType.manager:
        return [RoleType.manager, RoleType.lead, RoleType.member];
      case RoleType.lead:
        return [RoleType.member];
      case RoleType.member:
        return [];
    }
  }
}
