import 'package:flutter/material.dart';
import '../services/settings_service.dart';

/// Iron Discipline Color Palette
class AppColors {
  AppColors._();

  // Core
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceGlass = Color(0xD91A1A1A); // 85% opacity
  static const Color surfaceContainerHighest = Color(0xFF2A2A2A);
  static const Color surfaceContainerHigh = Color(0xFF242424);
  static const Color surfaceContainerLow = Color(0xFF161616);
  static const Color surfaceContainerLowest = Color(0xFF0D0D0D);
  static const Color outline = Color(0xFF444444);
  static const Color outlineVariant = Color(0xFF333333);

  // Accent
  static const Color neonRed = Color(0xFFFF0000);
  static const Color bloodOrange = Color(0xFFFF4500);
  static const Color crimson = Color(0xFFE50914);
  static const Color redGlow = Color(0x40FF0000); // 25% opacity for glows

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textMuted = Color(0xFF666666);

  // Status
  static const Color success = Color(0xFF00FF41);
  static const Color warning = Color(0xFFFFAA00);
  static const Color danger = Color(0xFFFF0033);

  // Skeleton overlay
  static const Color skeletonGood = Color(0xFF00FF41);
  static const Color skeletonBad = Color(0xFFFF0033);
  static const Color skeletonNeutral = Color(0xFF00BFFF);
}

/// ML Kit & Exercise Constants
class ExerciseConstants {
  ExerciseConstants._();

  static FormStrictness get _strictness => SettingsService().getFormStrictness;

  // Squat thresholds
  static double get squatDownAngle {
    switch (_strictness) {
      case FormStrictness.easy:
        return 120.0; // Very forgiving half-squat
      case FormStrictness.hard:
        return 90.0; // Ass to grass strict
      case FormStrictness.medium:
        return 100.0; // Relaxed from 90
    }
  }

  static double get squatUpAngle {
    switch (_strictness) {
      case FormStrictness.easy:
        return 150.0;
      case FormStrictness.hard:
        return 170.0;
      case FormStrictness.medium:
        return 160.0; // Standard standing
    }
  }

  static const double confidenceThreshold = 0.5; // ML Kit min confidence
  static const double squatSideLockMargin = 0.35;
  static const double squatHipDropThreshold = 0.08;
  static const double squatKneeDropThreshold = 0.04;
  
  static double get squatAngleSmoothing => 0.55; 
  static double get squatBaselineSmoothing => 0.15;

  // Anti-cheat HOLD
  static const Duration holdDuration = Duration(seconds: 3);
  static const double holdMovementThreshold = 5.0; // max pixel delta allowed

  // Strength Test
  static const Duration strengthTestTime = Duration(seconds: 60);

  // Pushup thresholds
  static double get pushupDownAngle {
    switch (_strictness) {
      case FormStrictness.easy:
        return 120.0; // Very forgiving arm bend for beginners (e.g. knee pushups)
      case FormStrictness.hard:
        return 80.0; // Chest to floor
      case FormStrictness.medium:
        return 90.0;
    }
  }

  static double get pushupUpAngle {
    switch (_strictness) {
      case FormStrictness.easy:
        return 145.0;
      case FormStrictness.hard:
        return 165.0;
      case FormStrictness.medium:
        return 160.0;
    }
  }

  // Lunge thresholds
  static double get lungeDownAngle {
    switch (_strictness) {
      case FormStrictness.easy:
        return 110.0;
      case FormStrictness.hard:
        return 85.0;
      case FormStrictness.medium:
        return 90.0;
    }
  }

  static double get lungeUpAngle {
    switch (_strictness) {
      case FormStrictness.easy:
        return 150.0;
      case FormStrictness.hard:
        return 170.0;
      case FormStrictness.medium:
        return 160.0;
    }
  }

  // Wall Sit thresholds
  static double get wallSitDownAngle {
    switch (_strictness) {
      case FormStrictness.easy:
        return 145.0; // Beginner hold
      case FormStrictness.hard:
        return 105.0; // Strict athletes
      case FormStrictness.medium:
        return 128.0; // Captures "effortful but high" positions
    }
  }
}

/// Route Names
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String bouncerLogin = '/login';
  static const String exerciseSelection = '/exercise-selection';
  static const String baselineTest = '/baseline-test';
  static const String languageSelection = '/language';
  static const String commanderSelection = '/commander';
  static const String strengthTestSetup = '/strength-test-setup';
  static const String strengthTest = '/strength-test-run';
  static const String dashboard = '/dashboard';
  static const String vault = '/vault';
  static const String records = '/records';
  static const String dailyRations = '/daily-rations';
  static const String workout = '/workout';
  static const String profile = '/profile';
  static const String alarm = '/alarm';
  static const String alarmSettings = '/alarm-settings';
  static const String challengeDetails = '/challenge-details';
  static const String armory = '/armory';
  static const String userMetrics = '/user-metrics';
  static const String leaderboard = '/leaderboard';
  static const String progressLog = '/progress-log';
  static const String rankUnlocked = '/rank-unlocked';
  static const String dietSetup = '/diet-setup';
  static const String dietPreview = '/diet-preview';
  static const String deploymentAuth = '/deployment-auth';
}

/// Commercial Constants
class CommercialConstants {
  CommercialConstants._();
  static const double collateralAmount = 200.0;
  static const double internationalCollateralAmount = 25.0;
}

/// App Strings (English defaults — will be localized)
class AppStrings {
  AppStrings._();

  static const String appName = 'USTAD AI';
  static const String tagline = 'DISCIPLINE AS A SERVICE';

  // Bouncer Login
  static const String unauthorizedPersonnel = 'UNAUTHORIZED\nPERSONNEL';
  static const String authenticateSubtext =
      'Authenticate to begin the 28-Day Protocol.';
  static const String continueWithGoogle = 'CONTINUE WITH GOOGLE';

  // Strength Test
  static const String strengthTestTitle = 'STRENGTH TEST';
  static const String strengthTestInstruction =
      "Let's see your real strength. GIVE ME MAXIMUM SQUATS IN 60 SECONDS.";
  static const String hold = 'HOLD!';
  static const String protocolInitialized = 'PROTOCOL INITIALIZED';

  // Dashboard
  static const String todaysDirective = "TODAY'S DIRECTIVE";
  static const String statusUnbroken = 'UNBROKEN';
  static const String statusBroken = 'BROKEN';

  // Nav
  static const String navMission = 'MISSION';
  static const String navVault = 'VAULT';
  static const String navRecords = 'RECORDS';
}

/// Asset Paths
class AppAssets {
  AppAssets._();

  static const String logoMain = 'assets/images/logo3.png';
  static const String logoPremium = 'assets/images/logo2.png';
  static const String logoMinimal = 'assets/images/logo1.png';
}
