import 'dart:convert';
import '../models/team_model.dart';
import 'api_service.dart';

class TeamService {
  Future<List<TeamListItem>> getCompanyTeams() async {
    final response = await ApiService.get('/teams', includeAuth: true);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((t) => TeamListItem.fromJson(t)).toList();
    } else {
      throw Exception('Failed to load teams: ${response.body}');
    }
  }

  Future<Team> getTeamById(String teamId) async {
    final response = await ApiService.get('/teams/$teamId', includeAuth: true);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Team.fromJson(data);
    } else {
      throw Exception('Failed to load team: ${response.body}');
    }
  }

  Future<Team> createTeam({
    required String name,
    String? description,
    String? location,
    required List<String> memberIds,
    String? teamLeadId,
  }) async {
    final body = {
      'name': name,
      if (description != null) 'description': description,
      if (location != null) 'location': location,
      'memberIds': memberIds,
      if (teamLeadId != null) 'teamLeadId': teamLeadId,
    };

    final response = await ApiService.post('/teams', body, includeAuth: true);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Team.fromJson(data);
    } else {
      throw Exception('Failed to create team: ${response.body}');
    }
  }

  Future<Team> updateTeam(
    String teamId, {
    String? name,
    String? description,
    String? location,
    String? teamLeadId,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (location != null) body['location'] = location;
    if (teamLeadId != null) body['teamLeadId'] = teamLeadId;

    final response = await ApiService.put('/teams/$teamId', body, includeAuth: true);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Team.fromJson(data);
    } else {
      throw Exception('Failed to update team: ${response.body}');
    }
  }

  Future<Team> addTeamMembers(String teamId, List<String> userIds) async {
    final body = {'userIds': userIds};

    final response = await ApiService.post('/teams/$teamId/members', body, includeAuth: true);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Team.fromJson(data);
    } else {
      throw Exception('Failed to add team members: ${response.body}');
    }
  }

  Future<void> removeTeamMember(String teamId, String userId) async {
    final response = await ApiService.delete('/teams/$teamId/members/$userId', includeAuth: true);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove team member: ${response.body}');
    }
  }

  Future<void> dissolveTeam(String teamId) async {
    final response = await ApiService.delete('/teams/$teamId', includeAuth: true);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to dissolve team: ${response.body}');
    }
  }
}

