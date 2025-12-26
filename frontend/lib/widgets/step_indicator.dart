import 'package:flutter/material.dart';
import 'dart:ui';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1.5),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: constraints.maxWidth * progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF22c55e),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

