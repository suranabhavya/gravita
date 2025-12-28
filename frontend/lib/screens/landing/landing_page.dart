import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glass_container.dart';
import '../auth/login_page.dart';
import '../auth/signup_page.dart';
import '../auth/invite_code_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 1.0, curve: Curves.elasticOut)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildLogo(),
                        ),
                        const SizedBox(height: 32),
                        _buildTitle(),
                        const SizedBox(height: 12),
                        _buildSubtitle(),
                        const Spacer(flex: 3),
                        _buildActionButtons(),
                        const SizedBox(height: 40),
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

  Widget _buildLogo() {
    return GlassContainer(
      width: 140,
      height: 140,
      isCircular: true,
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF22c55e),
      child: const Icon(
        Icons.recycling,
        size: 90,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Gravita',
      style: GoogleFonts.inter(
        fontSize: 52,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -1.5,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Recycling Marketplace',
      style: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.75),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildRoundedButton(
          text: 'Login',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          isPrimary: true,
        ),
                  const SizedBox(height: 14),
                  _buildRoundedButton(
                    text: 'Create New Company',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupPage()),
                      );
                    },
                    isPrimary: false,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Don\'t have an account yet?',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  // const SizedBox(height: 4),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InviteCodePage(),
                        ),
                      );
                    },
                    child: Text(
                      'Join with Invite Code',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
      ],
    );
  }

  Widget _buildRoundedButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return GlassContainer(
      width: double.infinity,
      height: 56,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(28),
      color: isPrimary ? const Color(0xFF22c55e) : Colors.white,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isPrimary
                    ? Colors.white
                    : const Color(0xFF22c55e),
                letterSpacing: 0.2,
              ),
            ),
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
        center: Alignment.topLeft,
        radius: 1.5,
        colors: [
          const Color(0xFF22c55e).withValues(alpha: 0.15),
          const Color(0xFF16a34a).withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final paint2 = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomRight,
        radius: 1.2,
        colors: [
          const Color(0xFF10b981).withValues(alpha: 0.12),
          const Color(0xFF059669).withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path1 = Path()
      ..moveTo(size.width * 0.1, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.1,
        size.width * 0.7,
        size.height * 0.25,
      )
      ..quadraticBezierTo(
        size.width * 0.95,
        size.height * 0.35,
        size.width,
        size.height * 0.3,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    final path2 = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.65,
        size.width * 0.5,
        size.height * 0.75,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.85,
        size.width,
        size.height * 0.8,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

