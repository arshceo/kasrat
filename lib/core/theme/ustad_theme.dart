import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

/// The "Iron Discipline" theme — pure black, neon red, brutalist typography.
class UstadTheme {
  UstadTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonRed,
        secondary: AppColors.bloodOrange,
        surface: AppColors.surface,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _headlineBrutal.copyWith(fontSize: 18),
        iconTheme: const IconThemeData(color: AppColors.neonRed),
      ),
      // Bottom Nav
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.neonRed,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      // Cards
      cardTheme: CardThemeData(
        color: AppColors.surfaceGlass,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(
            color: AppColors.redGlow,
            width: 1,
          ),
        ),
      ),
      // Elevated Button (primary CTA)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: _bodyOps.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
          elevation: 0,
        ),
      ),
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.neonRed,
          side: const BorderSide(color: AppColors.neonRed, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: _bodyOps.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
      ),
      // Text
      textTheme: TextTheme(
        displayLarge: _headlineBrutal.copyWith(fontSize: 48),
        displayMedium: _headlineBrutal.copyWith(fontSize: 36),
        displaySmall: _headlineBrutal.copyWith(fontSize: 28),
        headlineLarge: _headlineBrutal.copyWith(fontSize: 24),
        headlineMedium: _headlineBrutal.copyWith(fontSize: 20),
        headlineSmall: _headlineBrutal.copyWith(fontSize: 18),
        titleLarge: _bodyOps.copyWith(
            fontSize: 18, fontWeight: FontWeight.w700),
        titleMedium: _bodyOps.copyWith(
            fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: _bodyOps.copyWith(
            fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: _bodyOps.copyWith(fontSize: 16),
        bodyMedium: _bodyOps.copyWith(fontSize: 14),
        bodySmall: _bodyOps.copyWith(fontSize: 12),
        labelLarge: _bodyOps.copyWith(
            fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2),
        labelMedium: _bodyOps.copyWith(
            fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5),
        labelSmall: _bodyOps.copyWith(
            fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 1),
      ),
      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.textMuted,
        thickness: 0.5,
      ),
      // Icon
      iconTheme: const IconThemeData(
        color: AppColors.neonRed,
        size: 24,
      ),
      useMaterial3: true,
    );
  }

  // ── Custom Text Styles ───────────────────────────────────────────────

  /// Massive brutalist headline — Rajdhani Bold
  static TextStyle get _headlineBrutal => GoogleFonts.rajdhani(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: 4,
        height: 1.1,
      );

  /// Tech-ops body text — Orbitron
  static TextStyle get _bodyOps => GoogleFonts.orbitron(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w400,
        letterSpacing: 1,
        height: 1.4,
      );

  // ── Exported Custom Styles ───────────────────────────────────────────

  /// The massive rep counter (120pt neon red)
  static TextStyle get counterMassive => GoogleFonts.rajdhani(
        color: AppColors.neonRed,
        fontSize: 120,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        height: 1.0,
      );

  /// Timer display
  static TextStyle get timerDisplay => GoogleFonts.orbitron(
        color: AppColors.textPrimary,
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: 4,
      );

  /// Status label (e.g. "UNBROKEN")
  static TextStyle get statusLabel => GoogleFonts.orbitron(
        color: AppColors.success,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 3,
      );

  /// Directive text (e.g. "DAY 14: 20 PUSHUPS")
  static TextStyle get directiveText => GoogleFonts.rajdhani(
        color: AppColors.textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        height: 1.2,
      );

  /// Section header (smaller brutal)
  static TextStyle get sectionHeader => GoogleFonts.rajdhani(
        color: AppColors.neonRed,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 4,
      );
}
