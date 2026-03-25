import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../ai/services/gemini_service.dart';

/// Screen B-02: EXERTION LOGS — Full workout history, streak data, performance stats.
/// Design: Stitch "Exertion Logs" HTML — brutalist, zero rounding, command-terminal feel.
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  // Mock stats (computed from logs or DB)
  int _totalReps = 0;
  int _completedDays = 0;
  int _failedDays = 0;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await GeminiService.getWorkoutHistory();
    if (mounted) {
      int total = 0;
      int completed = 0;
      int failed = 0;
      for (final log in logs) {
        total += (log['completed_reps'] as int?) ?? 0;
        if (log['status'] == 'completed') {
          completed++;
        } else {
          failed++;
        }
      }
      setState(() {
        _logs = logs;
        _totalReps = total;
        _completedDays = completed;
        _failedDays = failed;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (!_isLoading && _logs.isNotEmpty) _buildStatsRow(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.neonRed))
                  : _logs.isEmpty
                      ? _buildEmptyState()
                      : _buildLogList(),
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
          const Icon(Icons.receipt_long_outlined, color: AppColors.neonRed, size: 18),
          const SizedBox(width: 10),
          Text(
            'EXERTION LOGS',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          Text(
            '${_logs.length} ENTRIES',
            style: GoogleFonts.orbitron(fontSize: 8, color: AppColors.textMuted, letterSpacing: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: AppColors.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(child: _statBlock('TOTAL REPS', '$_totalReps', AppColors.neonRed)),
          _verticalDivider(),
          Expanded(child: _statBlock('COMPLETED', '$_completedDays', AppColors.neonRed)),
          _verticalDivider(),
          Expanded(child: _statBlock('FAILED', '$_failedDays', AppColors.danger)),
        ],
      ),
    );
  }

  Widget _statBlock(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: color,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.orbitron(fontSize: 7, color: AppColors.textMuted, letterSpacing: 2),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 40, color: const Color(0xFF2A2A2A));
  }

  Widget _buildLogList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: _logs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildLogCard(_logs[index], index),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log, int index) {
    final status = log['status'] as String? ?? 'pending';
    final isCompleted = status == 'completed';
    final exerciseType = (log['exercise_type'] as String?)?.toUpperCase() ?? 'EXERCISE';
    final completedReps = log['completed_reps'] as int? ?? 0;
    final targetReps = log['target_reps'] as int? ?? 0;
    final duration = log['duration_seconds'] as int? ?? 0;
    final dayNumber = log['day_number'] as int? ?? index + 1;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        border: Border(
          left: BorderSide(
            color: isCompleted ? AppColors.neonRed : AppColors.danger,
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Day block
            Container(
              width: 44,
              height: 44,
              color: isCompleted
                  ? AppColors.neonRed.withValues(alpha: 0.1)
                  : AppColors.danger.withValues(alpha: 0.1),
              alignment: Alignment.center,
              child: Text(
                'D$dayNumber',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isCompleted ? AppColors.neonRed : AppColors.danger,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exerciseType,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completedReps / $targetReps REPS  ·  ${duration}S',
                    style: GoogleFonts.orbitron(
                      fontSize: 8,
                      color: AppColors.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: (isCompleted ? AppColors.neonRed : AppColors.danger).withValues(alpha: 0.1),
              child: Text(
                isCompleted ? 'DONE' : 'FAIL',
                style: GoogleFonts.orbitron(
                  fontSize: 8,
                  color: isCompleted ? AppColors.neonRed : AppColors.danger,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              color: AppColors.surfaceContainerHighest,
              alignment: Alignment.center,
              child: const Icon(Icons.fitness_center, color: AppColors.neonRed, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              'NO RECORDS YET',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first workout drill to see exertion logs here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surfaceContainerHighest,
              child: Text(
                '// COMMENCE DRILL FROM COMMAND TAB',
                style: GoogleFonts.orbitron(
                  fontSize: 9,
                  color: AppColors.neonRed,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
