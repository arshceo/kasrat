import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/auth/screens/bouncer_login_screen.dart';
import '../../features/onboarding/screens/language_selection_screen.dart';
import '../../features/onboarding/screens/commander_selection_screen.dart';
import '../../features/onboarding/screens/exercise_selection_screen.dart';
import '../../features/onboarding/screens/baseline_test_screen.dart';
import '../../features/onboarding/screens/user_metrics_screen.dart';
import '../../features/calibration/screens/calibration_screen.dart';
import '../../features/calibration/screens/calibration_setup_screen.dart';
import '../../features/calibration/services/pose_analyzer.dart';
import '../../features/armory/screens/armory_screen.dart';
import '../../features/records/screens/records_screen.dart';
import '../../features/armory/screens/challenge_detail_screen.dart';
import '../../features/armory/models/protocol.dart';
import '../../features/armory/screens/deployment_auth_screen.dart';
import '../../features/diet/screens/daily_rations_screen.dart';
import '../../features/diet/screens/diet_setup_screen.dart';
import '../../features/diet/screens/diet_preview_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/shell/screens/app_shell.dart';
import '../../features/alarm/screens/alarm_screen.dart';
import '../../features/alarm/screens/alarm_settings_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/leaderboard/screens/leaderboard_screen.dart';
import '../../features/profile/screens/progress_log_screen.dart';
import '../../features/dashboard/screens/workout_execution_screen.dart';
import '../../features/dashboard/screens/rank_unlocked_screen.dart';

class AppRouter {
  AppRouter._();

  static GoRouter get router => _buildRouter();

  static GoRouter _buildRouter() => GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isOnAuthPage = state.matchedLocation == AppRoutes.bouncerLogin;
      final isOnSplash = state.matchedLocation == AppRoutes.splash;

      // If logged in and on splash, skip it and go to dashboard
      if (isOnSplash && isLoggedIn) return AppRoutes.dashboard;

      // Let splash screen handle its own navigation for non-logged in users
      if (isOnSplash) return null;

      // Redirect to login if not authenticated
      if (!isLoggedIn && !isOnAuthPage) return AppRoutes.bouncerLogin;

      // If logged in and on auth page, we should go to dashboard. Navigation to language selection should only happen explicitly.
      if (isLoggedIn && isOnAuthPage) return AppRoutes.dashboard;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.bouncerLogin,
        builder: (context, state) => const BouncerLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.languageSelection,
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.commanderSelection,
        builder: (context, state) => const CommanderSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.strengthTestSetup,
        name: 'strength_test_setup',
        builder: (context, state) => const CalibrationSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.exerciseSelection,
        builder: (context, state) => const ExerciseSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.baselineTest,
        builder: (context, state) => const BaselineTestScreen(),
      ),
      GoRoute(
        path: AppRoutes.userMetrics,
        builder: (context, state) => const UserMetricsScreen(),
      ),
      GoRoute(
        path: AppRoutes.strengthTest,
        name: 'strength_test_run',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final recalibrate =
              state.uri.queryParameters['recalibrate'] == 'true';
          return CalibrationScreen(
            isFirstTime: !recalibrate,
            exerciseType:
                (extra?['exerciseType'] as ExerciseType?) ?? ExerciseType.squat,
            durationSeconds: (extra?['durationSeconds'] as int?) ?? 60,
            isBaseline: (extra?['isBaseline'] as bool?) ?? false,
            baselineStep: (extra?['baselineStep'] as int?) ?? 1,
            totalSteps: (extra?['totalSteps'] as int?) ?? 1,
            targetReps: (extra?['targetReps'] as int?),
            exerciseName: (extra?['exerciseName'] as String?),
            setIndex: (extra?['setIndex'] as int?),
            sessionStartTime: (extra?['sessionStartTime'] as DateTime?),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DashboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.armory,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ArmoryScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.leaderboard,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: LeaderboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.records,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: RecordsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.dailyRations,
        builder: (context, state) => const DailyRationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.workout,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return WorkoutExecutionScreen(
            protocol: extra?['protocol'] as Protocol? ?? staticProtocols.first,
            currentDay: extra?['currentDay'] as int? ?? 1,
            resumeData: extra?['resumeData'] as Map<String, dynamic>?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.challengeDetails,
        builder: (context, state) {
          final extra = state.extra as Protocol?;
          return ChallengeDetailScreen(
            protocol: extra ?? staticProtocols.first,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.alarm,
        builder: (context, state) => AlarmScreen(),
      ),
      GoRoute(
        path: AppRoutes.alarmSettings,
        builder: (context, state) => const AlarmSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.progressLog,
        builder: (context, state) => const ProgressLogScreen(),
      ),
      GoRoute(
        path: AppRoutes.rankUnlocked,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CustomTransitionPage(
            key: state.pageKey,
            child: RankUnlockedScreen(
              rankName: extra['rankName'] as String? ?? 'RECRUIT',
              insigniaPath:
                  extra['insigniaPath'] as String? ??
                  'assets/images/recruit.png',
              isSilent: extra['isSilent'] as bool? ?? false,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 500),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.dietSetup,
        builder: (context, state) => const DietSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.dietPreview,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return DietPreviewScreen(
            dietPlan: extra['dietPlan'] as Map<String, dynamic>? ?? {},
          );
        },
      ),
      GoRoute(
        path: AppRoutes.deploymentAuth,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return DeploymentAuthScreen(
            protocolId: extra['protocolId'] as String? ?? 'UNKNOWN',
            protocolTitle: extra['protocolTitle'] as String? ?? 'CHALLENGE',
            durationDays: extra['durationDays'] as int? ?? 0,
            userName: extra['userName'] as String? ?? 'RECRUIT',
          );
        },
      ),
    ],
  );
}
