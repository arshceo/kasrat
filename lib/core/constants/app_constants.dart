import 'package:flutter/material.dart';

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

  // Squat thresholds
  static const double squatDownAngle = 90.0; // θ below this = squatting
  static const double squatUpAngle = 160.0; // θ above this = standing
  static const double confidenceThreshold = 0.5; // ML Kit min confidence
  static const double squatSideLockMargin = 0.35;
  static const double squatHipDropThreshold = 0.10;
  static const double squatKneeDropThreshold = 0.05;
  static const double squatAngleSmoothing = 0.25;
  static const double squatBaselineSmoothing = 0.15;

  // Anti-cheat HOLD
  static const Duration holdDuration = Duration(seconds: 3);
  static const double holdMovementThreshold = 5.0; // max pixel delta allowed

  // Calibration
  static const Duration calibrationTime = Duration(seconds: 60);

  // Pushup thresholds
  static const double pushupDownAngle = 90.0;
  static const double pushupUpAngle = 160.0;

  // Lunge thresholds
  static const double lungeDownAngle = 90.0;
  static const double lungeUpAngle = 160.0;
}

/// Route Names
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String bouncerLogin = '/login';
  static const String languageSelection = '/onboarding/language';
  static const String commanderSelection = '/onboarding/commander';
  static const String calibrationSetup = '/calibration/setup';
  static const String calibration = '/calibration';
  static const String dashboard = '/dashboard';
  static const String vault = '/vault';
  static const String records = '/records';
  static const String dailyRations = '/daily-rations';
  static const String workout = '/workout';
  static const String profile = '/profile';
  static const String alarm = '/alarm';
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

  // Calibration
  static const String calibrationTitle = 'CALIBRATION TEST';
  static const String calibrationInstruction =
      "Let's see how weak you are. GIVE ME MAXIMUM SQUATS IN 60 SECONDS.";
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
