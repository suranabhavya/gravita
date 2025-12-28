import 'package:flutter/material.dart';
import '../screens/auth/complete_invite_signup_page.dart';
import 'invitation_service.dart';

class DeepLinkService {
  static final InvitationService _invitationService = InvitationService();

  static Future<void> handleInviteLink(BuildContext context, String token) async {
    try {
      // Validate invitation
      final invitationData = await _invitationService.validateInvitation(token);

      // Navigate to complete signup page
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => CompleteInviteSignupPage(
              invitationData: invitationData,
              tokenOrCode: token,
            ),
          ),
          (route) => route.isFirst, // Clear navigation stack
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid or expired invitation: ${e.toString()}'),
            backgroundColor: Colors.red.withValues(alpha: 0.8),
          ),
        );
      }
    }
  }

  static Future<void> handleInitialLink(BuildContext context, String? initialLink) async {
    if (initialLink == null) return;

    final uri = Uri.parse(initialLink);
    if (uri.scheme == 'gravita' && uri.host == 'invite') {
      final token = uri.queryParameters['token'];
      if (token != null) {
        await handleInviteLink(context, token);
      }
    }
  }
}

