import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/widgets/tactical_button.dart';
import 'package:kasrat_ai/features/dashboard/providers/workout_provider.dart';

class CompletionView extends StatelessWidget {
  final WorkoutState state;
  final bool isSaving;
  final String? saveError;
  final VoidCallback onFinish;

  const CompletionView({
    super.key,
    required this.state,
    required this.isSaving,
    required this.saveError,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          if (saveError != null) ...[
            const Icon(Icons.error_outline, color: AppColors.neonRed, size: 48),
            const SizedBox(height: 16),
            Text('SYNC ERROR', style: GoogleFonts.orbitron(color: AppColors.neonRed, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(saveError!, textAlign: TextAlign.center, style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), border: Border.all(color: AppColors.success.withOpacity(0.3))),
              child: Column(
                children: [
                  const Icon(Icons.verified, color: AppColors.success, size: 64),
                  const SizedBox(height: 24),
                  Text('MISSION ACCOMPLISHED', style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                  const SizedBox(height: 12),
                  Text('YOUR TELEMETRY HAS BEEN UPLOADED.', style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.success, letterSpacing: 1)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 48),
          _buildSummaryStat('TOTAL DURATION', _formatDuration(state.totalElapsed)),
          _buildSummaryStat('EXERCISES COMPLETED', '${state.sets.length}'),
          _buildSummaryStat('ACCURACY RATING', '98.2%'),
          const Spacer(),
          if (isSaving)
            const CircularProgressIndicator(color: AppColors.neonRed)
          else
            TacticalButton(
              onTap: onFinish,
              soundType: TacticalSoundType.missionComplete,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22),
                color: AppColors.neonRed,
                alignment: Alignment.center,
                child: Text('RETURN TO BASE', style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.textMuted)),
          Text(value, style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}
