import 'package:flutter/material.dart';
import 'dart:ui';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final double blur;
  final bool isCircular;

  const GlassContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.blur = 30.0,
    this.isCircular = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final radius = isCircular 
        ? BorderRadius.circular((width ?? height ?? 100) / 2)
        : (borderRadius ?? BorderRadius.circular(28));

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (color ?? Colors.white).withValues(alpha: 0.25),
                  (color ?? Colors.white).withValues(alpha: 0.1),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

