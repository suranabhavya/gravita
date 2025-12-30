import 'dart:convert';
import '../models/permissions_model.dart';
import 'api_service.dart';

class PermissionsService {
  Future<UserPermissions> getUserPermissions(String userId) async {
    final response = await ApiService.get('/users/$userId/permissions', includeAuth: true);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserPermissions.fromJson(data);
    } else {
      throw Exception('Failed to load permissions: ${response.body}');
    }
  }

  Future<UserPermissions> updateUserPermissions(String userId, UserPermissions permissions) async {
    try {
      print('[PermissionsService] Updating permissions for user: $userId');
      print('[PermissionsService] Permissions to send: ${permissions.toJson()}');
      
      final response = await ApiService.put(
        '/users/$userId/permissions',
        {'permissions': permissions.toJson()},
        includeAuth: true,
      );
      
      print('[PermissionsService] Response status: ${response.statusCode}');
      print('[PermissionsService] Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[PermissionsService] Parsed data: $data');
        // The backend returns the user object with permissions nested
        final permissionsData = data['permissions'] ?? {};
        return UserPermissions.fromJson(permissionsData);
      } else {
        final errorBody = response.body;
        print('[PermissionsService] Error response: $errorBody');
        throw Exception('Failed to update permissions: $errorBody');
      }
    } catch (e) {
      print('[PermissionsService] Exception: $e');
      rethrow;
    }
  }
}

