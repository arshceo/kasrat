import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';

/// Animated rep counter with scale + glow on each rep increment.
class RepCounterWidget extends StatelessWidget {
  final int count;
  final int? target;
  final String? label;

  const RepCounterWidget({
    super.key,
    required this.count,
    this.target,
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
        final isTargetMet = target != null && count >= target!;

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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: (isTargetMet ? AppColors.success : AppColors.neonRed)
                          .withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        count.toString().padLeft(2, '0'),
                        style: GoogleFonts.rajdhani(
                          fontSize: 120,
                          fontWeight: FontWeight.w700,
                          color: isTargetMet ? AppColors.success : AppColors.neonRed,
                          height: 1.0,
                        ),
                      ),
                      if (target != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '/',
                          style: GoogleFonts.rajdhani(
                            fontSize: 40,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          target.toString().padLeft(2, '0'),
                          style: GoogleFonts.rajdhani(
                            fontSize: 60,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
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
