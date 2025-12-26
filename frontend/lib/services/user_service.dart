import 'dart:convert';
import '../models/user_model.dart';
import '../models/company_model.dart';
import 'api_service.dart';

class UserService {
  Future<CompanyMembersResponse> getCompanyMembers({
    String? search,
    String? teamId,
    String? roleId,
  }) async {
    String endpoint = '/users/members?';
    final params = <String>[];
    if (search != null && search.isNotEmpty) params.add('search=$search');
    if (teamId != null) params.add('teamId=$teamId');
    if (roleId != null) params.add('roleId=$roleId');
    endpoint += params.join('&');

    final response = await ApiService.get(endpoint, includeAuth: true);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CompanyMembersResponse.fromJson(data);
    } else {
      throw Exception('Failed to load members: ${response.body}');
    }
  }

  Future<User> getUserById(String userId) async {
    final response = await ApiService.get('/users/$userId', includeAuth: true);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      throw Exception('Failed to load user: ${response.body}');
    }
  }

  Future<CompanyStats> getCompanyStats() async {
    final response = await ApiService.get('/users/stats', includeAuth: true);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CompanyStats.fromJson(data);
    } else {
      throw Exception('Failed to load stats: ${response.body}');
    }
  }
}

