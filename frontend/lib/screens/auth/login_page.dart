import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_text_field.dart';
import '../../services/auth_service.dart';
import '../../providers/permission_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        // Load permission context after successful login
        final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
        await permissionProvider.loadPermissionContext();
        
        Navigator.of(context).pushReplacementNamed('/home');
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          _buildBackButton(),
                          const SizedBox(height: 32),
                          _buildHeader(),
                          const SizedBox(height: 40),
                          _buildFormFields(),
                          const SizedBox(height: 28),
                          _buildLoginButton(),
                          const Spacer(),
                        ],
                      ),
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
          'Welcome Back',
          style: GoogleFonts.inter(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        GlassTextField(
          label: 'Email',
          hintText: 'Enter your email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        GlassTextField(
          label: 'Password',
          hintText: 'Enter your password',
          controller: _passwordController,
          obscureText: _obscurePassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return GlassContainer(
      width: double.infinity,
      height: 56,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(28),
      color: const Color(0xFF22c55e),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleLogin,
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
                    'Login',
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
        radius: 1.4,
        colors: [
          const Color(0xFF10b981).withValues(alpha: 0.1),
          const Color(0xFF059669).withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path1 = Path()
      ..moveTo(size.width * 0.8, size.height * 0.15)
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.1,
        size.width * 0.3,
        size.height * 0.2,
      )
      ..quadraticBezierTo(
        0,
        size.height * 0.3,
        0,
        size.height * 0.4,
      )
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    final path2 = Path()
      ..moveTo(size.width, size.height * 0.6)
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.65,
        size.width * 0.4,
        size.height * 0.7,
      )
      ..quadraticBezierTo(
        size.width * 0.1,
        size.height * 0.75,
        0,
        size.height * 0.7,
      )
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
