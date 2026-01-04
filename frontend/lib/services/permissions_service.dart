import 'dart:convert';
import '../models/permission_context_model.dart';
import 'api_service.dart';

class PermissionsService {
  /// Get current user's permission context from backend
  /// Uses the /me endpoint which automatically uses the authenticated user's ID
  Future<PermissionContext> getMyPermissionContext({String? companyId}) async {
    final endpoint = companyId != null 
        ? '/users/me/permission-context?companyId=$companyId'
        : '/users/me/permission-context';
    final response = await ApiService.get(endpoint, includeAuth: true);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PermissionContext.fromJson(data);
    } else {
      throw Exception('Failed to load permission context: ${response.body}');
    }
  }

  /// Get user's permission context from backend (for viewing other users - requires permissions)
  /// This should be called after login to set up permissions
  @Deprecated('Use getMyPermissionContext instead for current user')
  Future<PermissionContext> getPermissionContext(String userId, String companyId) async {
    final response = await ApiService.get('/users/$userId/permission-context?companyId=$companyId', includeAuth: true);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PermissionContext.fromJson(data);
    } else {
      throw Exception('Failed to load permission context: ${response.body}');
    }
  }

  /// Legacy method for backward compatibility
  @Deprecated('Use getPermissionContext instead')
  Future<Map<String, dynamic>> getUserPermissions(String userId) async {
    final response = await ApiService.get('/users/$userId/permissions', includeAuth: true);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to load permissions: ${response.body}');
    }
  }
}

