import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';

class WorkoutStatBlock extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const WorkoutStatBlock({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: AppColors.textMuted),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 8,
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
