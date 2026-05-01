import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/widgets/tactical_button.dart';
import '../../armory/models/protocol.dart';
import '../providers/workout_provider.dart';

class CommenceDrillSection extends ConsumerWidget {
  final bool isCriticalPeriod;
  final Protocol? activeProtocol;
  final Map<String, dynamic>? profileData;
  final Map<String, dynamic>? activeWorkoutData;
  final int currentDay;

  const CommenceDrillSection({
    super.key,
    required this.isCriticalPeriod,
    this.activeProtocol,
    this.profileData,
    this.activeWorkoutData,
    required this.currentDay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (isCriticalPeriod) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.neonRed.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.neonRed, width: 2),
            ),
            child: Column(
              children: [
                Text(
                  'CRITICAL TIME PERIOD',
                  style: GoogleFonts.orbitron(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.neonRed,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'FAILING TO COMPLETE MISSION WILL FORFEIT DEPOSIT',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // START/RESUME WORKOUT CTA
        Builder(builder: (context) {
          final isResume = activeWorkoutData != null && 
              ((activeWorkoutData?['currentIndex'] ?? 0) > 0 || 
               activeWorkoutData?['phase'] != 'briefing');
          
          String progressText = '';
          if (isResume) {
            final sets = activeWorkoutData?['sets'] as List?;
            final currentIndex = activeWorkoutData?['currentIndex'] as int? ?? 0;
            if (sets != null && sets.isNotEmpty) {
              final progress = (currentIndex / sets.length * 100).toInt();
              progressText = '$progress%';
            }
          }

          return TacticalButton(
            soundType: isResume ? TacticalSoundType.tap : TacticalSoundType.mouseClick,
            onTap: () async {
              final protocol = activeProtocol ??
                  staticProtocols.firstWhere(
                    (p) => p.id == (profileData?['protocol_id'] as String?),
                    orElse: () => staticProtocols.isNotEmpty
                        ? staticProtocols.first
                        : const Protocol(
                            id: 'fallback',
                            title: 'ACTIVE DRILL',
                            durationDays: 28,
                            difficulty: 'MEDIUM',
                            bgIcon: Icons.fitness_center,
                            exerciseFocus: 'FULL BODY',
                            outcomes: [],
                            exercises: [],
                            instructions: [],
                            description: '',
                            tags: [],
                            imagePath: 'assets/images/placeholder.png',
                            isRecommended: false,
                          ),
                  );

              // If it's NOT a resume, clear any stale state before navigating
              if (!isResume) {
                await ref.read(workoutProvider.notifier).clearSavedState();
              }

              if (context.mounted) {
                context.push(
                  AppRoutes.workout,
                  extra: {
                    'protocol': protocol, 
                    'currentDay': currentDay,
                    'resumeData': isResume ? activeWorkoutData : null,
                  },
                );
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: isResume ? Colors.amber[700] : AppColors.neonRed,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isResume ? 'RESUME WORKOUT' : 'COMMENCE WORKOUT',
                    style: GoogleFonts.orbitron(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                  if (progressText.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        progressText,
                        style: GoogleFonts.spaceMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Icon(
                    isResume ? Icons.play_arrow : Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
