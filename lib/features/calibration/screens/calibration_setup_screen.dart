import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/widgets/tactical_button.dart';
import 'package:kasrat_ai/core/audio/fauj_audio_engine.dart';

import '../services/exercise_type.dart';
import '../../auth/services/auth_service.dart';
import '../../ai/services/gemini_service.dart';

class CalibrationSetupScreen extends StatefulWidget {
  const CalibrationSetupScreen({super.key});

  @override
  State<CalibrationSetupScreen> createState() => _CalibrationSetupScreenState();
}

class _CalibrationSetupScreenState extends State<CalibrationSetupScreen> {
  ExerciseType _selectedExercise = ExerciseType.squat;
  int _selectedDuration = 60; // seconds
  Map<String, dynamic>? _profile;
  Map<ExerciseType, Map<int, int>> _allExerciseRecords = {};
  bool _isFetchingRecords = false;

  String _toDbName(ExerciseType type) {
    return type.dbType;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AuthService.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
        });
      }
      _fetchExerciseRecords();
    } catch (_) {
      // Profile load failed, but we can still try to fetch records
    }
  }

  Future<void> _fetchExerciseRecords() async {
    if (_isFetchingRecords) return;
    setState(() => _isFetchingRecords = true);

    try {
      final Map<ExerciseType, Map<int, int>> records = {};
      for (final type in ExerciseType.values) {
        final data = await GeminiService.getExerciseRecords(
          exerciseType: _toDbName(type),
        );
        records[type] = data;
      }

      if (mounted) {
        setState(() {
          _allExerciseRecords = records;
          _isFetchingRecords = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching records: $e');
      if (mounted) setState(() => _isFetchingRecords = false);
    }
  }

  void _showCustomDurationDialog() {
    final minController = TextEditingController();
    final secController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'SET CUSTOM DURATION',
          style: GoogleFonts.orbitron(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
        content: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: minController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'MIN',
                  hintStyle: TextStyle(color: Colors.white24),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.neonRed),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              ':',
              style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: secController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'SEC',
                  hintStyle: TextStyle(color: Colors.white24),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.neonRed),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              final mins = int.tryParse(minController.text) ?? 0;
              final secs = int.tryParse(secController.text) ?? 0;
              final totalSeconds = (mins * 60) + secs;
              if (totalSeconds > 0) {
                setState(() => _selectedDuration = totalSeconds);
                Navigator.pop(context);
              }
            },
            child: const Text(
              'SET',
              style: TextStyle(color: AppColors.neonRed),
            ),
          ),
        ],
      ),
    );
  }

  void _launchCalibration() {
    if (!mounted) return;
    context.push(
      AppRoutes.strengthTest,
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
                    const SizedBox(height: 12),
                    _buildRecordsRegistry(),
                    const SizedBox(height: 24),
                    _buildTimerSelector(),
                    const SizedBox(height: 32),
                    _buildStartButton(),
                    const SizedBox(height: 16),
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
          Expanded(
            child: Text(
              'STRENGTH TEST CONFIGURATION',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.orbitron(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.neonRed,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildExerciseSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('// SELECT TEST EXERCISE'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.3,
          children: [
            _exerciseCard(
              ExerciseType.squat,
              Icons.accessibility_new,
              'SQUATS',
              'HIP-KNEE ANGLE',
              pb: _profile?['baseline_squats'] as int?,
            ),
            _exerciseCard(
              ExerciseType.pushup,
              Icons.fitness_center,
              'PUSH-UPS',
              'ARM ANGLE',
              pb: _profile?['baseline_pushups'] as int?,
            ),

            _exerciseCard(
              ExerciseType.lunge,
              Icons.directions_walk,
              'LUNGES',
              '90° KNEES',
            ),
            _exerciseCard(
              ExerciseType.situp,
              Icons.airline_seat_recline_normal,
              'SIT-UPS',
              'CORE ANGLE',
            ),

            _exerciseCard(
              ExerciseType.plank,
              Icons.horizontal_rule,
              'PLANK',
              'BACK ALIGNMENT',
            ),
            _exerciseCard(
              ExerciseType.wallSit,
              Icons.event_seat,
              'WALL SIT',
              '90° HOLD',
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
    String sub, {
    int? pb,
  }) {
    final selected = _selectedExercise == type;
    return GestureDetector(
      onTap: () {
        FaujAudioEngine().playMouseClick();
        setState(() => _selectedExercise = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: selected ? AppColors.neonRed : AppColors.textMuted,
                  size: 20,
                ),
                if (pb != null && pb > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.neonRed.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'PB: $pb',
                      style: GoogleFonts.spaceMono(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neonRed,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.orbitron(
                fontSize: 6,
                color: selected ? AppColors.neonRed : AppColors.textMuted,
              ),
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
        _sectionLabel('// SET TEST DURATION'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...[30, 60, 90, 120].map((d) {
              final selected = _selectedDuration == d;
              return GestureDetector(
                onTap: () {
                  FaujAudioEngine().playMouseClick();
                  setState(() => _selectedDuration = d);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.neonRed
                        : const Color(0xFF1A1A1A),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : const Color(0xFF2A2A2A),
                    ),
                  ),
                  child: Text(
                    '${d}s',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }),
            GestureDetector(
              onTap: () {
                FaujAudioEngine().playMouseClick();
                setState(() => _selectedDuration = 0);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _selectedDuration == 0
                      ? AppColors.neonRed
                      : const Color(0xFF1A1A1A),
                  border: Border.all(
                    color: _selectedDuration == 0
                        ? Colors.transparent
                        : const Color(0xFF2A2A2A),
                  ),
                ),
                child: Text(
                  _selectedExercise.isHold ? 'MAX HOLD' : 'MAX REPS',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _selectedDuration == 0
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: _showCustomDurationDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: !([30, 60, 90, 120, 0].contains(_selectedDuration))
                      ? AppColors.neonRed
                      : const Color(0xFF1A1A1A),
                  border: Border.all(
                    color: !([30, 60, 90, 120, 0].contains(_selectedDuration))
                        ? Colors.transparent
                        : const Color(0xFF2A2A2A),
                  ),
                ),
                child: Text(
                  !([30, 60, 90, 120, 0].contains(_selectedDuration))
                      ? (_selectedDuration >= 60
                            ? '${_selectedDuration ~/ 60}:${(_selectedDuration % 60).toString().padLeft(2, '0')}'
                            : '${_selectedDuration}s')
                      : 'CUSTOM',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: !([30, 60, 90, 120, 0].contains(_selectedDuration))
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecordsRegistry() {
    final records = _allExerciseRecords[_selectedExercise] ?? {};
    if (records.isEmpty && !_isFetchingRecords) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        border: Border.all(color: AppColors.neonRed.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '// RECORDS REGISTRY',
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neonRed,
                  letterSpacing: 2,
                ),
              ),
              if (_isFetchingRecords)
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1,
                    color: AppColors.neonRed,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (records.isEmpty && !_isFetchingRecords)
            Text(
              'NO MISSION DATA RECORDED YET.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: records.entries.map((entry) {
                final duration = entry.key;
                final best = entry.value;
                final isMax = duration == 0;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    border: Border(
                      left: BorderSide(color: AppColors.neonRed, width: 2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isMax ? (_selectedExercise.isHold ? 'MAX HOLD' : 'MAX REPS') : '${duration}S GOAL',
                        style: GoogleFonts.orbitron(
                          fontSize: 8,
                          color: AppColors.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$best',
                            style: GoogleFonts.rajdhani(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _selectedExercise.isHold ? 'SEC' : 'REPS',
                            style: GoogleFonts.rajdhani(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return TacticalButton(
      onTap: _launchCalibration,
      soundType: TacticalSoundType.nav,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        color: AppColors.neonRed,
        alignment: Alignment.center,
        child: Text(
          'START DRILL',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
