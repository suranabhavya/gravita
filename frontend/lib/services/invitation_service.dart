import 'dart:convert';
import 'api_service.dart';

class InvitationService {
  Future<Map<String, dynamic>> inviteMembers({
    String? email, // Deprecated: use emails instead
    List<String>? emails, // Preferred: list of emails
    String? teamId,
    String? roleId,
    String? roleType, // 'admin', 'manager', 'member', 'viewer'
  }) async {
    // Support both single email (backward compatibility) and list of emails
    final emailList = emails ?? (email != null ? [email] : []);
    
    if (emailList.isEmpty) {
      throw Exception('At least one email address is required');
    }

    final body = {
      'emails': emailList, // Backend expects array
      if (teamId != null) 'teamId': teamId,
      if (roleId != null) 'roleId': roleId,
      if (roleType != null) 'roleType': roleType,
    };

    print('[InvitationService] Sending invitation request with ${emailList.length} emails: $emailList');
    print('[InvitationService] Request body: $body');

    final response = await ApiService.post('/invitations', body, includeAuth: true);
    
    print('[InvitationService] Response status: ${response.statusCode}');
    print('[InvitationService] Response body: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to invite members: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> validateInvitation(String tokenOrCode) async {
    try {
      print('[InvitationService] Validating invitation with code: $tokenOrCode');
      final response = await ApiService.post(
        '/invitations/validate',
        {'tokenOrCode': tokenOrCode},
        includeAuth: false,
      );

      print('[InvitationService] Response status: ${response.statusCode}');
      print('[InvitationService] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final decoded = jsonDecode(response.body);
          print('[InvitationService] Decoded response: $decoded');
          print('[InvitationService] Has invitation: ${decoded['invitation'] != null}');
          print('[InvitationService] Email: ${decoded['invitation']?['email']}');
          return decoded;
        } catch (e) {
          print('[InvitationService] JSON decode error: $e');
          print('[InvitationService] Response body was: ${response.body}');
          throw Exception('Failed to parse invitation response: $e');
        }
      } else {
        String errorMessage = 'Failed to validate invitation';
        try {
          final error = jsonDecode(response.body);
          errorMessage = error['message'] ?? error['error'] ?? errorMessage;
        } catch (e) {
          errorMessage = response.body.isNotEmpty 
              ? response.body 
              : 'HTTP ${response.statusCode}: Failed to validate invitation';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[InvitationService] Error validating invitation: $e');
      print('[InvitationService] Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> acceptInvitation(String tokenOrCode) async {
    try {
      print('[InvitationService] Accepting invitation with code: $tokenOrCode');
      final response = await ApiService.post(
        '/invitations/accept',
        {'tokenOrCode': tokenOrCode},
        includeAuth: true,
      );

      print('[InvitationService] Accept invitation response status: ${response.statusCode}');
      print('[InvitationService] Accept invitation response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        print('[InvitationService] Invitation accepted successfully');
        return decoded;
      } else {
        String errorMessage = 'Failed to accept invitation';
        try {
          final error = jsonDecode(response.body);
          errorMessage = error['message'] ?? error['error'] ?? errorMessage;
        } catch (e) {
          errorMessage = response.body.isNotEmpty 
              ? response.body 
              : 'HTTP ${response.statusCode}: Failed to accept invitation';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[InvitationService] Error accepting invitation: $e');
      rethrow;
    }
  }
}

