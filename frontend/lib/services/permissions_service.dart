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
    final response = await ApiService.put(
      '/users/$userId/permissions',
      {'permissions': permissions.toJson()},
      includeAuth: true,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserPermissions.fromJson(data['permissions'] ?? {});
    } else {
      throw Exception('Failed to update permissions: ${response.body}');
    }
  }
}

