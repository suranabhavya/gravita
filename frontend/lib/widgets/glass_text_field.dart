import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class GlassTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? suffixIcon;

  const GlassTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label!,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: TextFormField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                validator: validator,
                onChanged: onChanged,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  suffixIcon: suffixIcon,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

