import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../widgets/glass_container.dart';
import '../../services/auth_service.dart';

class OtpVerificationPage extends StatefulWidget {
  final String userId;
  final String email;
  final String userName;

  const OtpVerificationPage({
    super.key,
    required this.userId,
    required this.email,
    required this.userName,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (index == 5 && value.length == 1) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit code'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.verifyOtp(widget.userId, otp);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);

    try {
      await _authService.resendOtp(widget.userId);
      if (mounted) {
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully. Please check your email.'),
            backgroundColor: Color(0xFF22c55e),
            behavior: SnackBarBehavior.floating,
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
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0d2818),
              const Color(0xFF1a4d2e),
              const Color(0xFF0f2e1a),
              const Color(0xFF052e16),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            _buildLiquidBackground(),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        _buildBackButton(),
                        const SizedBox(height: 32),
                        _buildHeader(),
                        const SizedBox(height: 40),
                        _buildOtpFields(),
                        const SizedBox(height: 32),
                        _buildVerifyButton(),
                        const SizedBox(height: 24),
                        _buildResendButton(),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiquidBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _LiquidGlassPainter(),
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: GlassContainer(
        width: 48,
        height: 48,
        isCircular: true,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(24),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify Your Email',
          style: GoogleFonts.inter(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a 6-digit code to',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.email,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF22c55e),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: TextFormField(
                  controller: _otpControllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                  onChanged: (value) => _onOtpChanged(index, value),
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color(0xFF22c55e),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVerifyButton() {
    return GlassContainer(
      width: double.infinity,
      height: 56,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(28),
      color: const Color(0xFF22c55e),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _verifyOtp,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Verify',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendButton() {
    return Center(
      child: TextButton(
        onPressed: _isResending ? null : _resendOtp,
        child: _isResending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Resend Code',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
      ),
    );
  }
}

class _LiquidGlassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..shader = RadialGradient(
        center: Alignment.topRight,
        radius: 1.3,
        colors: [
          const Color(0xFF22c55e).withValues(alpha: 0.12),
          const Color(0xFF16a34a).withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final paint2 = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomLeft,
        radius: 1.2,
        colors: [
          const Color(0xFF22c55e).withValues(alpha: 0.1),
          const Color(0xFF16a34a).withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint1);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

