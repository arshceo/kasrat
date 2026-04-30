import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/features/dashboard/models/exercise_set.dart';

class ExerciseDirectiveCard extends StatelessWidget {
  final String exerciseName;
  final List<ExerciseSet> sets;
  final bool isFullyComplete;
  final bool isCurrent;
  final int completedSets;

  const ExerciseDirectiveCard({
    super.key,
    required this.exerciseName,
    required this.sets,
    required this.isFullyComplete,
    required this.isCurrent,
    required this.completedSets,
  });

  @override
  Widget build(BuildContext context) {
    final firstSet = sets.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFullyComplete ? AppColors.surfaceContainerLow : AppColors.surfaceContainerHigh,
        border: Border.all(
          color: isCurrent ? AppColors.neonRed : AppColors.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isFullyComplete ? Icons.check_circle : (completedSets > 0 ? Icons.play_circle_filled : Icons.circle_outlined),
            color: isFullyComplete || completedSets > 0 ? AppColors.neonRed : AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exerciseName.toUpperCase(),
                  style: GoogleFonts.orbitron(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isFullyComplete ? AppColors.textMuted : Colors.white,
                    letterSpacing: 1,
                    decoration: isFullyComplete ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('${sets.length} SETS', style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.neonRed, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text('|', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    const SizedBox(width: 8),
                    Text(
                      firstSet.isHold ? '${firstSet.targetSeconds}S HOLD' : '${firstSet.targetReps} REPS',
                      style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.textSecondary),
                    ),
                    if (completedSets > 0 && !isFullyComplete) ...[
                      const SizedBox(width: 8),
                      Text('($completedSets DONE)', style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.success)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
