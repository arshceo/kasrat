import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';

/// Horizontal countdown timer bar — drains left to right, red gradient.
class TimerBarWidget extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;

  const TimerBarWidget({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final progress = remainingSeconds / totalSeconds;
    final isUrgent = remainingSeconds <= 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Time text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TIME REMAINING',
              style: GoogleFonts.orbitron(
                fontSize: 8,
                color: AppColors.textMuted,
                letterSpacing: 3,
              ),
            ),
            Text(
              '${remainingSeconds}s',
              style: GoogleFonts.orbitron(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isUrgent ? AppColors.neonRed : AppColors.textPrimary,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Bar
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 900),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: LinearGradient(
                  colors: isUrgent
                      ? [AppColors.neonRed, AppColors.bloodOrange]
                      : [AppColors.neonRed, AppColors.crimson],
                ),
                boxShadow: isUrgent
                    ? [
                        BoxShadow(
                          color: AppColors.neonRed.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
