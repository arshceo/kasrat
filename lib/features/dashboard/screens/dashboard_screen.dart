import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/widgets/tactical_button.dart';
import '../providers/dashboard_provider.dart';

// Modular Widgets
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_background.dart';
import '../widgets/urgency_sidebar.dart';
import '../widgets/directive_section.dart';
import '../widgets/asset_telemetry_grid.dart';
import '../widgets/daily_rations_card.dart';
import '../widgets/commence_drill_section.dart';
import '../widgets/active_mission_calendar.dart';
import '../widgets/pre_mission_section.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Local UI state
  final List<bool> _rationsChecked = [];
  bool _hasRedirected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).initialize();
    });
  }

  Future<void> _checkActiveWorkout(DashboardState state) async {
    if (_hasRedirected) return;
    final prefs = await SharedPreferences.getInstance();
    final savedWorkout = prefs.getString('active_workout_state');
    if (savedWorkout != null && mounted && state.activeProtocol != null) {
      final data = jsonDecode(savedWorkout) as Map<String, dynamic>;
      if (data['day'] == state.currentDay) {
        _hasRedirected = true;
        context.push(
          AppRoutes.workout,
          extra: {'protocol': state.activeProtocol, 'currentDay': state.currentDay},
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const DashboardBackground(),
          if (state.isSubscriber && (state.timeLeft > Duration.zero || state.isCriticalPeriod))
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: UrgencySidebar(
                isCriticalPeriod: state.isCriticalPeriod,
                timeLeft: state.timeLeft,
                criticalTimeLeft: state.criticalTimeLeft,
              ),
            ),
          SafeArea(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.neonRed))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DashboardHeader(
                        rank: state.rank,
                        fullName: state.fullName,
                        isSubscriber: state.isSubscriber,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(26, 24, 20, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!state.isSubscriber || state.protocolTitle == 'NO ACTIVE MISSION')
                                PreMissionSection(
                                  hasCompletedBaseline: state.hasCompletedBaseline,
                                  hasCompletedMetrics: state.hasCompletedMetrics,
                                  protocolTitle: state.protocolTitle,
                                  pendingCode: state.pendingCode,
                                  onDeploy: () {
                                    if (state.activeProtocol != null) {
                                      context.push(
                                        AppRoutes.deploymentAuth,
                                        extra: {
                                          'protocolId': state.activeProtocol!.id,
                                          'protocolTitle': state.activeProtocol!.title,
                                          'durationDays': state.activeProtocol!.durationDays,
                                          'userName': state.fullName,
                                        },
                                      );
                                    } else {
                                      StatefulNavigationShell.of(context).goBranch(1);
                                    }
                                  },
                                )
                              else ...[
                                DirectiveSection(
                                  isSubscriber: state.isSubscriber,
                                  protocolTitle: state.protocolTitle,
                                  workoutTime: state.profileData?['preferred_workout_time'] ?? '24H',
                                  directiveTitle: state.protocolTitle, // Fallback to protocol title for now or dynamic
                                ),
                                const SizedBox(height: 24),
                                ActiveMissionCalendar(
                                  currentDay: state.currentDay,
                                  totalDays: state.totalDays,
                                  protocolStartDate: state.protocolStartDate,
                                ),
                                const SizedBox(height: 16),
                                  CommenceDrillSection(
                                    isCriticalPeriod: state.isCriticalPeriod,
                                    activeProtocol: state.activeProtocol,
                                    profileData: state.profileData,
                                    activeWorkoutData: state.activeWorkoutData,
                                    currentDay: state.currentDay,
                                  ),
                              ],
                              if (state.isSubscriber) ...[
                                const SizedBox(height: 16),
                                AssetTelemetryGrid(profileData: state.profileData),
                              ],
                              /* -- HIDING DIET PLAN FOR NOW --
                              if (state.hasDietPlan && state.dietPlan != null) ...[
                                DailyRationsCard(
                                  dietPlan: state.dietPlan!,
                                  rationsChecked: state.rationsChecked,
                                  dailyCalories: state.dailyCalories,
                                  onToggle: (index, val) {
                                    ref.read(dashboardProvider.notifier).toggleRation(index, val);
                                  },
                                ),
                                const SizedBox(height: 16),
                              ] else
                                _buildSimpleCTA(
                                  label: 'CONSTRUCT DIET PROTOCOL',
                                  onTap: () => context.push(AppRoutes.dietSetup),
                                ),
                              */
                              const SizedBox(height: 48),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleCTA({required String label, required VoidCallback onTap}) {
    return TacticalButton(
      soundType: TacticalSoundType.nav,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(color: AppColors.neonRed),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.orbitron(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
