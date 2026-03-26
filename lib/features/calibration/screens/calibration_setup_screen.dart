import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../features/calibration/services/pose_analyzer.dart';

/// Screen A-01b: Pre-flight calibration setup.
/// User selects exercise type and timer duration.
class CalibrationSetupScreen extends StatefulWidget {
  const CalibrationSetupScreen({super.key});

  @override
  State<CalibrationSetupScreen> createState() => _CalibrationSetupScreenState();
}

class _CalibrationSetupScreenState extends State<CalibrationSetupScreen> {
  ExerciseType _selectedExercise = ExerciseType.squat;
  int _selectedDuration = 60; // seconds

  final List<int> _durations = [30, 60, 90, 120];

  void _launchCalibration() {
    if (!mounted) return;
    context.push(
      AppRoutes.calibration,
      extra: {
        'exerciseType': _selectedExercise,
        'durationSeconds': _selectedDuration,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildExerciseSelector(),
                    const SizedBox(height: 20),
                    _buildTimerSelector(),
                    const SizedBox(height: 32),
                    _buildStartButton(),
                    const SizedBox(height: 16),
                    _buildSkipButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'DRILL CONFIGURATION',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('// SELECT EXERCISE'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _exerciseCard(
                ExerciseType.squat,
                Icons.accessibility_new,
                'SQUATS',
                'HIP-KNEE ANGLE',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _exerciseCard(
                ExerciseType.pushup,
                Icons.fitness_center,
                'PUSH-UPS',
                'ELBOW-SHOULDER ANGLE',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _exerciseCard(
    ExerciseType type,
    IconData icon,
    String label,
    String sub,
  ) {
    final selected = _selectedExercise == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedExercise = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.neonRed.withValues(alpha: 0.08)
              : const Color(0xFF1A1A1A),
          border: Border(
            left: BorderSide(
              color: selected ? AppColors.neonRed : const Color(0xFF2A2A2A),
              width: 4,
            ),
            top: BorderSide(
              color: selected
                  ? AppColors.neonRed.withValues(alpha: 0.3)
                  : const Color(0xFF2A2A2A),
            ),
            right: BorderSide(
              color: selected
                  ? AppColors.neonRed.withValues(alpha: 0.3)
                  : const Color(0xFF2A2A2A),
            ),
            bottom: BorderSide(
              color: selected
                  ? AppColors.neonRed.withValues(alpha: 0.3)
                  : const Color(0xFF2A2A2A),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.neonRed : AppColors.textMuted,
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: GoogleFonts.orbitron(
                fontSize: 7,
                color: selected ? AppColors.neonRed : AppColors.textMuted,
                letterSpacing: 1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 16,
              child: selected
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      color: AppColors.neonRed,
                      child: Text(
                        'SELECTED',
                        style: GoogleFonts.orbitron(
                          fontSize: 7,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('// SET TIMER'),
        const SizedBox(height: 12),
        Row(
          children: _durations.map((d) {
            final selected = _selectedDuration == d;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: d != _durations.last ? 8 : 0),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDuration = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: selected
                        ? AppColors.neonRed
                        : const Color(0xFF1A1A1A),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(
                          '${d}S',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          d == 60 ? 'DEFAULT' : '',
                          style: GoogleFonts.orbitron(
                            fontSize: 7,
                            color: selected
                                ? Colors.white70
                                : Colors.transparent,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _launchCalibration,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        color: AppColors.neonRed,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(
              'START DRILL',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.dashboard),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        child: Text(
          'SKIP ASSESSMENT →',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 2,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.orbitron(
        fontSize: 9,
        color: AppColors.neonRed,
        letterSpacing: 3,
      ),
    );
  }
}
