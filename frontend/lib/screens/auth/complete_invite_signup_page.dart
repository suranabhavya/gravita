import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_text_field.dart';
import '../../services/auth_service.dart';
import '../../services/invitation_service.dart';
import '../../services/api_service.dart';
import 'otp_verification_page.dart';

class CompleteInviteSignupPage extends StatefulWidget {
  final Map<String, dynamic> invitationData;
  final String tokenOrCode;

  const CompleteInviteSignupPage({
    super.key,
    required this.invitationData,
    required this.tokenOrCode,
  });

  @override
  State<CompleteInviteSignupPage> createState() => _CompleteInviteSignupPageState();
}

class _CompleteInviteSignupPageState extends State<CompleteInviteSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _invitationService = InvitationService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _completeSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = widget.invitationData['invitation']?['email'] ?? '';
      
      // Step 1: Create user account
      final step1Result = await _authService.signupStep1(
        _nameController.text.trim(),
        email,
        _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        _passwordController.text,
      );

      final userId = step1Result['user']?['id'] ?? step1Result['userId'];

      // Step 2: Verify OTP (user needs to verify email)
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationPage(
              userId: userId,
              email: email,
              onVerified: () async {
                // After OTP verification, accept invitation and navigate to home
                await _acceptInvitation(userId);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acceptInvitation(String userId) async {
    try {
      print('[CompleteInviteSignupPage] Accepting invitation...');
      // Accept invitation (assigns user to team/role and returns new token)
      final result = await _invitationService.acceptInvitation(widget.tokenOrCode);
      print('[CompleteInviteSignupPage] Invitation accepted successfully');
      
      // Update JWT token with new companyId
      if (result['access_token'] != null) {
        await ApiService.saveToken(result['access_token']);
        print('[CompleteInviteSignupPage] Updated JWT token with new companyId');
      }
      
      // Navigation will happen from OTP page context
    } catch (e) {
      print('[CompleteInviteSignupPage] Error accepting invitation: $e');
      // Re-throw error so OTP page can handle it
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final company = widget.invitationData['company'];
    final inviter = widget.invitationData['inviter'];
    final team = widget.invitationData['team'];
    final email = widget.invitationData['invitation']?['email'] ?? '';

    return Scaffold(
      body: Container(
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
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Invitation info card
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You\'re invited!',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (company != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.business,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                company['name'] ?? 'Company',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (inviter != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Invited by ${inviter['name'] ?? 'Team Admin'}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (team != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.group_work,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                team['name'] ?? 'Team',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Title
                  Text(
                    'Complete Your Profile',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your account to join',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Email (read-only)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Email',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        child: Text(
                          email,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Name
                  GlassTextField(
                    label: 'Full Name',
                    controller: _nameController,
                    hintText: 'John Doe',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Phone (optional)
                  GlassTextField(
                    label: 'Phone (optional)',
                    controller: _phoneController,
                    hintText: '+1 234 567 8900',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  // Password
                  GlassTextField(
                    label: 'Password',
                    controller: _passwordController,
                    hintText: 'Create a strong password',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Confirm Password
                  GlassTextField(
                    label: 'Confirm Password',
                    controller: _confirmPasswordController,
                    hintText: 'Re-enter your password',
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  // Submit button
                  GlassContainer(
                    padding: EdgeInsets.zero,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _completeSignup,
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
                                  'Create Account',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

