import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/features/dashboard/providers/workout_provider.dart';

class WorkoutHeader extends StatelessWidget {
  final int currentDay;
  final String protocolTitle;
  final WorkoutState state;
  final Duration timeUntilDeadline;
  final bool isCriticalPeriod;
  final VoidCallback onBack;

  const WorkoutHeader({
    super.key,
    required this.currentDay,
    required this.protocolTitle,
    required this.state,
    required this.timeUntilDeadline,
    required this.isCriticalPeriod,
    required this.onBack,
  });

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Color get _deadlineColor {
    final mins = timeUntilDeadline.inMinutes;
    if (mins <= 30) return AppColors.neonRed;
    if (mins <= 90) return const Color(0xFFFF8C00);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: Color(0xFF1E1E1E))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onBack,
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAY $currentDay // EXECUTION',
                      style: GoogleFonts.orbitron(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppColors.neonRed,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      protocolTitle.toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Deadline badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (isCriticalPeriod ? AppColors.neonRed : _deadlineColor).withOpacity(0.1),
                  border: Border.all(color: (isCriticalPeriod ? AppColors.neonRed : _deadlineColor).withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isCriticalPeriod ? 'CRITICAL WINDOW' : 'DEADLINE',
                      style: GoogleFonts.spaceMono(
                        fontSize: 7,
                        color: isCriticalPeriod ? AppColors.neonRed : AppColors.textMuted,
                        letterSpacing: 1,
                        fontWeight: isCriticalPeriod ? FontWeight.w900 : FontWeight.normal,
                      ),
                    ),
                    Text(
                      isCriticalPeriod ? 'DANGER' : _fmt(timeUntilDeadline),
                      style: GoogleFonts.orbitron(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isCriticalPeriod ? AppColors.neonRed : _deadlineColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Elapsed timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ELAPSED',
                      style: GoogleFonts.spaceMono(
                        fontSize: 7,
                        color: AppColors.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      _fmt(state.totalElapsed),
                      style: GoogleFonts.orbitron(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mission Progress Bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TOTAL MISSION PROGRESS', style: GoogleFonts.spaceMono(fontSize: 7, color: AppColors.textMuted, letterSpacing: 1)),
                        Text('${(state.sets.isEmpty ? 0 : (state.sets.where((s) => s.isComplete).length / state.sets.length * 100)).toInt()}%', style: GoogleFonts.spaceMono(fontSize: 8, color: AppColors.neonRed, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(1),
                      child: LinearProgressIndicator(
                        value: state.sets.isEmpty ? 0 : state.sets.where((s) => s.isComplete).length / state.sets.length,
                        backgroundColor: AppColors.surfaceContainerHighest,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonRed),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
