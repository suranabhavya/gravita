import 'dart:convert';
import 'api_service.dart';

class InvitationService {
  Future<Map<String, dynamic>> inviteMembers({
    required List<String> emails,
    String? teamId,
    String? roleId,
  }) async {
    final body = {
      'emails': emails,
      if (teamId != null) 'teamId': teamId,
      if (roleId != null) 'roleId': roleId,
    };

    final response = await ApiService.post('/invitations', body, includeAuth: true);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to invite members: ${response.body}');
    }
  }
}

