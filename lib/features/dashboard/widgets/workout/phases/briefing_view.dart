import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/widgets/tactical_button.dart';
import 'package:kasrat_ai/features/dashboard/providers/workout_provider.dart';
import 'package:kasrat_ai/features/dashboard/widgets/workout/exercise_directive_card.dart';

class BriefingView extends StatelessWidget {
  final int currentDay;
  final String protocolTitle;
  final WorkoutState state;
  final String directiveTitle;
  final String coachNotice;
  final VoidCallback onStart;

  const BriefingView({
    super.key,
    required this.currentDay,
    required this.protocolTitle,
    required this.state,
    required this.directiveTitle,
    required this.coachNotice,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = state.sets.where((s) => s.isComplete).length;
    final progress = state.sets.isEmpty ? 0.0 : completedCount / state.sets.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.neonRed.withOpacity(0.3)),
              color: AppColors.neonRed.withOpacity(0.05),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '// MISSION BRIEFING',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    color: AppColors.neonRed,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  directiveTitle,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    border: const Border(
                      left: BorderSide(color: AppColors.neonRed, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tips_and_updates, size: 14, color: AppColors.neonRed),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          coachNotice,
                          style: GoogleFonts.spaceMono(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'GOALS TODAY: ${(1.0 + (currentDay - 1) * 0.025 * 100).toInt()}% OF BASELINE',
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    color: AppColors.neonRed,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (completedCount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('MISSION PROGRESS', style: GoogleFonts.spaceMono(fontSize: 8, color: AppColors.textMuted)),
                Text('${(progress * 100).toInt()}%', style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.neonRed, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonRed),
              minHeight: 2,
            ),
            const SizedBox(height: 20),
          ],
          Text('DIRECTIVES', style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.textMuted, letterSpacing: 2)),
          const SizedBox(height: 10),
          ..._buildGroupedList(),
          const SizedBox(height: 32),
          TacticalButton(
            onTap: onStart,
            soundType: TacticalSoundType.tap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              color: state.workoutStartTime == null ? AppColors.neonRed : AppColors.warning,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    state.workoutStartTime == null ? 'START WORKOUT' : 'RESUME WORKOUT',
                    style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedList() {
    final Map<String, List<dynamic>> grouped = {};
    for (final s in state.sets) {
      grouped.putIfAbsent(s.name, () => []).add(s);
    }

    return grouped.entries.map((entry) {
      final name = entry.key;
      final sets = entry.value;
      final completed = sets.where((s) => s.isComplete).length;
      return ExerciseDirectiveCard(
        exerciseName: name,
        sets: sets.cast(),
        isFullyComplete: completed == sets.length,
        isCurrent: false,
        completedSets: completed,
      );
    }).toList();
  }
}
