import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_text_field.dart';
import 'dart:ui';
import '../../services/invitation_service.dart';
import 'complete_invite_signup_page.dart';

class InviteCodePage extends StatefulWidget {
  const InviteCodePage({super.key});

  @override
  State<InviteCodePage> createState() => _InviteCodePageState();
}

class _InviteCodePageState extends State<InviteCodePage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _invitationService = InvitationService();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validateCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Remove dashes and convert to uppercase
      final code = _codeController.text.replaceAll('-', '').toUpperCase();
      // Format back to XXXX-XXXX
      final formattedCode = code.length == 8
          ? '${code.substring(0, 4)}-${code.substring(4)}'
          : code;

      final invitationData = await _invitationService.validateInvitation(formattedCode);

      // Debug: Print the response to see what we got
      print('[InviteCodePage] Received invitation data: $invitationData');
      print('[InviteCodePage] Email: ${invitationData['invitation']?['email']}');

      if (mounted) {
        // Verify we have the required data before navigating
        if (invitationData['invitation']?['email'] == null) {
          throw Exception('Invalid invitation data: missing email');
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CompleteInviteSignupPage(
              invitationData: invitationData,
              tokenOrCode: formattedCode,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to validate invitation';
        try {
          final errorStr = e.toString();
          if (errorStr.contains('Invalid or expired')) {
            errorMessage = 'Invalid or expired invite code. Please check the code and try again.';
          } else if (errorMessage.contains('Exception: ')) {
            errorMessage = errorStr.replaceFirst('Exception: ', '');
          } else {
            errorMessage = errorStr;
          }
        } catch (_) {
          errorMessage = e.toString();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF052e16), // Fallback color
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0d2818),
              Color(0xFF1a4d2e),
              Color(0xFF0f2e1a),
              Color(0xFF052e16),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GlassContainer(
                      width: 48,
                      height: 48,
                      isCircular: true,
                      padding: EdgeInsets.zero,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(24),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Title
                  Text(
                    'Join with Invite Code',
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the invite code you received via email',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Code input
                  GlassTextField(
                    label: 'Invite Code',
                    controller: _codeController,
                    hintText: 'XXXX-XXXX',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your invite code';
                      }
                      final cleaned = value.replaceAll('-', '').toUpperCase();
                      if (cleaned.length != 8) {
                        return 'Invite code must be 8 characters';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      // Auto-format as user types
                      final cleaned = value.replaceAll('-', '').toUpperCase();
                      if (cleaned.length > 8) {
                        _codeController.value = TextEditingValue(
                          text: '${cleaned.substring(0, 4)}-${cleaned.substring(4, 8)}',
                          selection: TextSelection.collapsed(offset: 9),
                        );
                      } else if (cleaned.length > 4) {
                        _codeController.value = TextEditingValue(
                          text: '${cleaned.substring(0, 4)}-${cleaned.substring(4)}',
                          selection: TextSelection.collapsed(offset: cleaned.length + 1),
                        );
                      } else {
                        _codeController.value = TextEditingValue(
                          text: cleaned,
                          selection: TextSelection.collapsed(offset: cleaned.length),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  // Submit button
                  GlassContainer(
                    padding: EdgeInsets.zero,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _validateCode,
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22c55e),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Continue',
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Help text
                  Text(
                    'Don\'t have a code? Contact your team administrator.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 40), // Extra bottom padding
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

