import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';

/// Animated rep counter with scale + glow on each rep increment.
class RepCounterWidget extends StatelessWidget {
  final int count;
  final String? label;

  const RepCounterWidget({
    super.key,
    required this.count,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(count),
      tween: Tween(begin: 1.2, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    letterSpacing: 4,
                  ),
                ),
              if (label != null) const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonRed.withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  count.toString().padLeft(2, '0'),
                  style: GoogleFonts.rajdhani(
                    fontSize: 120,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neonRed,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
