import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_text_field.dart';
import '../../widgets/step_indicator.dart';
import '../../services/auth_service.dart';
import 'otp_verification_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  int _currentStep = 1;
  
  // Step 1: Personal Info
  final _step1FormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Step 2: Company Info
  final _step2FormKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _industryController = TextEditingController();
  final _sizeController = TextEditingController();
  String _companyType = 'supplier';
  bool _isLoading = false;

  // Step 3: Invite Members
  final _step3FormKey = GlobalKey<FormState>();
  final List<TextEditingController> _emailControllers = [TextEditingController()];

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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _industryController.dispose();
    _sizeController.dispose();
    for (var controller in _emailControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _animateStepChange() {
    _controller.reset();
    _controller.forward();
  }

  Future<void> _handleStep1() async {
    if (!_step1FormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _currentStep = 2;
    });
    _animateStepChange();
  }

  Future<void> _handleStep2() async {
    if (!_step2FormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _currentStep = 3;
    });
    _animateStepChange();
  }

  Future<void> _handleStep3() async {
    final emails = _emailControllers
        .map((c) => c.text.trim())
        .where((email) => email.isNotEmpty)
        .toList();

    if (emails.isNotEmpty) {
      for (final email in emails) {
        if (!email.contains('@')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter valid email addresses'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.completeSignup(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        password: _passwordController.text,
        companyName: _companyNameController.text.trim(),
        companyType: _companyType,
        industry: _industryController.text.trim().isEmpty ? null : _industryController.text.trim(),
        size: _sizeController.text.trim().isEmpty ? null : _sizeController.text.trim(),
        memberEmails: emails.isEmpty ? null : emails,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OtpVerificationPage(
              userId: result['userId'] as String,
              email: result['email'] as String,
              userName: result['user']['name'] as String,
            ),
          ),
        );
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

  void _addEmailField() {
    setState(() {
      _emailControllers.add(TextEditingController());
    });
  }

  void _removeEmailField(int index) {
    if (_emailControllers.length > 1) {
      setState(() {
        _emailControllers[index].dispose();
        _emailControllers.removeAt(index);
      });
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
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildStepIndicator(),
                        const SizedBox(height: 16),
                        _buildBackButton(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildCurrentStep(),
                        ),
                      ),
                    ),
                  ),
                ],
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
            onTap: () {
              if (_currentStep > 1) {
                setState(() => _currentStep--);
                _animateStepChange();
              } else {
                Navigator.pop(context);
              }
            },
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

  Widget _buildStepIndicator() {
    return StepIndicator(currentStep: _currentStep, totalSteps: 3);
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return _buildStep1();
    }
  }

  Widget _buildStep1() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Personal Information', 'Tell us about yourself'),
          const SizedBox(height: 32),
          GlassTextField(
            label: 'Full Name',
            hintText: 'Enter your full name',
            controller: _nameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
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
            label: 'Phone (Optional)',
            hintText: 'Enter your phone number',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
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
          const SizedBox(height: 20),
          GlassTextField(
            label: 'Confirm Password',
            hintText: 'Confirm your password',
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              onPressed: () {
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
              },
            ),
          ),
          const SizedBox(height: 40),
          _buildContinueButton('Continue', _handleStep1),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Company Information', 'Tell us about your company'),
          const SizedBox(height: 32),
          GlassTextField(
            label: 'Company Name',
            hintText: 'Enter company name',
            controller: _companyNameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter company name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildCompanyTypeSelector(),
          const SizedBox(height: 20),
          GlassTextField(
            label: 'Industry (Optional)',
            hintText: 'e.g., Automotive, Manufacturing',
            controller: _industryController,
          ),
          const SizedBox(height: 20),
          GlassTextField(
            label: 'Company Size (Optional)',
            hintText: 'e.g., Small, Medium, Large',
            controller: _sizeController,
          ),
          const SizedBox(height: 40),
          _buildContinueButton('Continue', _handleStep2),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Form(
      key: _step3FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Invite Team Members', 'Add your team (optional)'),
          const SizedBox(height: 8),
          Text(
            'Leave empty if you don\'t want to invite anyone now',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          ...List.generate(_emailControllers.length, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: index < _emailControllers.length - 1 ? 16 : 0),
              child: Row(
                children: [
                  Expanded(
                    child: GlassTextField(
                      hintText: 'team.member@example.com',
                      controller: _emailControllers[index],
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  if (_emailControllers.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: GlassContainer(
                        width: 48,
                        height: 48,
                        isCircular: true,
                        padding: EdgeInsets.zero,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _removeEmailField(index),
                            borderRadius: BorderRadius.circular(24),
                            child: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          _buildAddEmailButton(),
          const SizedBox(height: 40),
          _buildContinueButton('Complete Setup', () => _handleStep3()),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Company Type',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildTypeOption('supplier', 'Supplier'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeOption('recycler', 'Recycler'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption(String value, String label) {
    final isSelected = _companyType == value;
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(16),
      color: isSelected ? const Color(0xFF22c55e) : Colors.white,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _companyType = value);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF22c55e),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddEmailButton() {
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addEmailField,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Another Email',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton(String text, VoidCallback onPressed) {
    return GlassContainer(
      width: double.infinity,
      height: 56,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(28),
      color: const Color(0xFF22c55e),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : onPressed,
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
                    text,
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
