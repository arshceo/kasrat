import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';

class UrgencySidebar extends StatelessWidget {
  final bool isCriticalPeriod;
  final Duration timeLeft;
  final Duration criticalTimeLeft;

  const UrgencySidebar({
    super.key,
    required this.isCriticalPeriod,
    required this.timeLeft,
    required this.criticalTimeLeft,
  });

  String _formatDuration(Duration d) {
    return '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      alignment: Alignment.center,
      child: RotatedBox(
        quarterTurns: 3,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isCriticalPeriod ? 'CRITICAL DEADLINE: ' : 'WORKOUT DEADLINE: ',
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isCriticalPeriod
                    ? AppColors.neonRed
                    : AppColors.textMuted.withValues(alpha: 0.5),
                letterSpacing: 1,
              ),
            ),
            Text(
              isCriticalPeriod
                  ? _formatDuration(criticalTimeLeft)
                  : _formatDuration(timeLeft),
              style: GoogleFonts.orbitron(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: isCriticalPeriod
                    ? AppColors.neonRed
                    : Colors.white.withValues(alpha: 0.9),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
