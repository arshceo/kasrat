import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/auth/screens/bouncer_login_screen.dart';
import '../../features/onboarding/screens/language_selection_screen.dart';
import '../../features/onboarding/screens/commander_selection_screen.dart';
import '../../features/calibration/screens/calibration_screen.dart';
import '../../features/calibration/screens/calibration_setup_screen.dart';
import '../../features/calibration/services/pose_analyzer.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/vault/screens/vault_screen.dart';
import '../../features/records/screens/records_screen.dart';
import '../../features/diet/screens/daily_rations_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/shell/screens/app_shell.dart';
import '../../features/alarm/screens/alarm_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isOnAuthPage = state.matchedLocation == AppRoutes.bouncerLogin;
      final isOnSplash = state.matchedLocation == AppRoutes.splash;

      // Let splash screen handle its own navigation
      if (isOnSplash) return null;

      // Redirect to login if not authenticated
      if (!isLoggedIn && !isOnAuthPage) return AppRoutes.bouncerLogin;

      // If logged in and on auth page, go to language selection or dashboard
      if (isLoggedIn && isOnAuthPage) return AppRoutes.languageSelection;

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
        path: AppRoutes.calibrationSetup,
        builder: (context, state) => const CalibrationSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.calibration,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final recalibrate =
              state.uri.queryParameters['recalibrate'] == 'true';
          return CalibrationScreen(
            isFirstTime: !recalibrate,
            exerciseType:
                (extra?['exerciseType'] as ExerciseType?) ?? ExerciseType.squat,
            durationSeconds: (extra?['durationSeconds'] as int?) ?? 60,
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.vault,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: VaultScreen()),
          ),
          GoRoute(
            path: AppRoutes.records,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: RecordsScreen()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.dailyRations,
        builder: (context, state) => const DailyRationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.alarm,
        builder: (context, state) => const AlarmScreen(),
      ),
    ],
  );
}
