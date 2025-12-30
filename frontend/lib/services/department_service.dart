import 'dart:convert';
import '../models/department_model.dart';
import 'api_service.dart';

class DepartmentService {
  Future<List<DepartmentTree>> getCompanyDepartments() async {
    final response = await ApiService.get('/departments', includeAuth: true);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((d) => DepartmentTree.fromJson(d)).toList();
    } else {
      throw Exception('Failed to load departments: ${response.body}');
    }
  }

  Future<Department> getDepartmentById(String departmentId) async {
    final response = await ApiService.get('/departments/$departmentId', includeAuth: true);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Department.fromJson(data);
    } else {
      throw Exception('Failed to load department: ${response.body}');
    }
  }

  Future<Department> createDepartment({
    required String name,
    String? description,
    String? parentDepartmentId,
    String? managerId,
    List<String>? teamIds,
  }) async {
    final body = {
      'name': name,
      if (description != null) 'description': description,
      if (parentDepartmentId != null) 'parentDepartmentId': parentDepartmentId,
      if (managerId != null) 'managerId': managerId,
      if (teamIds != null) 'teamIds': teamIds,
    };

    final response = await ApiService.post('/departments', body, includeAuth: true);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Department.fromJson(data);
    } else {
      throw Exception('Failed to create department: ${response.body}');
    }
  }

  Future<void> moveTeamToDepartment(String departmentId, String teamId) async {
    final body = {'departmentId': departmentId};

    final response = await ApiService.post('/departments/$departmentId/teams/$teamId', body, includeAuth: true);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to move team to department: ${response.body}');
    }
  }

  Future<void> removeTeamFromDepartment(String departmentId, String teamId) async {
    final response = await ApiService.delete('/departments/$departmentId/teams/$teamId', includeAuth: true);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove team from department: ${response.body}');
    }
  }

  Future<Department> updateDepartment({
    required String departmentId,
    String? name,
    String? description,
    String? parentDepartmentId,
    String? managerId,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (parentDepartmentId != null) {
      body['parentDepartmentId'] = parentDepartmentId;
    } else if (parentDepartmentId == null && name == null && description == null && managerId == null) {
      // Explicitly set to null to make it top-level
      body['parentDepartmentId'] = null;
    }
    if (managerId != null) {
      body['managerId'] = managerId;
    } else if (managerId == null && name == null && description == null && parentDepartmentId == null) {
      // Explicitly set to null to remove manager
      body['managerId'] = null;
    }

    final response = await ApiService.put('/departments/$departmentId', body, includeAuth: true);

    if (response.statusCode == 200 || response.statusCode == 204) {
      final data = jsonDecode(response.body);
      return Department.fromJson(data);
    } else {
      throw Exception('Failed to update department: ${response.body}');
    }
  }
}

