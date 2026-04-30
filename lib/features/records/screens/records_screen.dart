import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
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
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await GeminiService.getMissionHistory();
    if (mounted) {
      int totalReps = 0;
      int completed = 0;
      int failed = 0;
      
      for (final log in logs) {
        if (log['type'] == 'CHALLENGE_FAILURE') {
           failed++;
           continue;
        }
        
        final exercises = (log['exercises'] as List?) ?? [];
        for (final ex in exercises) {
           totalReps += (ex['actualReps'] as int?) ?? 0;
        }
        
        if (log['status'] == 'completed') {
          completed++;
        } else {
          failed++;
        }
      }
      setState(() {
        _logs = logs;
        _totalReps = totalReps;
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
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.neonRed,
                      ),
                    )
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
          const Icon(
            Icons.receipt_long_outlined,
            color: AppColors.neonRed,
            size: 18,
          ),
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
            style: GoogleFonts.orbitron(
              fontSize: 8,
              color: AppColors.textMuted,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: AppColors.surfaceContainerHighest,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _statBlock('TOTAL REPS', '$_totalReps', AppColors.neonRed),
              ),
              _verticalDivider(),
              Expanded(
                child: _statBlock(
                  'COMPLETED',
                  '$_completedDays',
                  AppColors.neonRed,
                ),
              ),
              _verticalDivider(),
              Expanded(
                child: _statBlock('FAILED', '$_failedDays', AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStrengthProgress(),
        ],
      ),
    );
  }

  Widget _buildStrengthProgress() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STRENGTH EVOLUTION',
            style: GoogleFonts.spaceMono(
              fontSize: 8,
              color: AppColors.textMuted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
               _evolutionItem('MAX PUSHUPS', _getMaxFromLogs('PUSHUP')),
               _evolutionItem('MAX SQUATS', _getMaxFromLogs('SQUAT')),
            ],
          ),
        ],
      ),
    );
  }

  int _getMaxFromLogs(String keyword) {
    int max = 0;
    for (final log in _logs) {
      final exercises = (log['exercises'] as List?) ?? [];
      for (final ex in exercises) {
        if (ex['exercise'].toString().toUpperCase().contains(keyword)) {
          final reps = (ex['actualReps'] as int?) ?? 0;
          if (reps > max) max = reps;
        }
      }
    }
    return max;
  }

  Widget _evolutionItem(String label, int value) {
    return Column(
      children: [
        Text(
          '$value',
          style: GoogleFonts.orbitron(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.spaceMono(
            fontSize: 7,
            color: AppColors.neonRed,
            letterSpacing: 1,
          ),
        ),
      ],
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
          style: GoogleFonts.orbitron(
            fontSize: 7,
            color: AppColors.textMuted,
            letterSpacing: 2,
          ),
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
      itemBuilder: (context, index) {
        return _buildLogCard(_logs[index], index);
      },
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log, int index) {
    final type = log['type'] as String? ?? 'MISSION_LOG';
    final status = log['status'] as String? ?? 'completed';
    final isCompleted = status == 'completed';
    final dayNumber = log['day'] as int? ?? (index + 1);
    final isExpanded = _expandedIndex == index;

    if (type == 'CHALLENGE_FAILURE') {
      final dateStr = log['date'] as String? ?? '';
      final date = DateTime.tryParse(dateStr) ?? DateTime.now();
      return _buildFailureCard(log, dayNumber, date);
    }

    final exercises = (log['exercises'] as List?) ?? [];
    final duration = log['totalElapsedSeconds'] as int? ?? 0;

    int totalActual = 0;
    int totalTarget = 0;
    for (final ex in exercises) {
      totalActual += (ex['actualReps'] as int?) ?? 0;
      totalTarget += (ex['targetReps'] as int?) ?? 0;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedIndex = isExpanded ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          border: Border(
            left: BorderSide(
              color: isCompleted ? AppColors.neonRed : AppColors.danger,
              width: 4,
            ),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Day block
                  Container(
                    width: 44,
                    height: 44,
                    color: (isCompleted ? AppColors.neonRed : AppColors.danger)
                        .withOpacity(0.1),
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
                          'SESSION: ${exercises.length} DRILLS',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalActual / $totalTarget TOTAL REPS  ·  ${_formatSeconds(duration)}',
                          style: GoogleFonts.orbitron(
                            fontSize: 8,
                            color: AppColors.textSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                ],
              ),
            ),
            if (isExpanded) ...[
              const Divider(color: Color(0xFF2A2A2A), height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: exercises.map((ex) {
                    final exName = ex['exercise'] as String? ?? 'UNKNOWN';
                    final exActual = ex['actualReps'] as int? ?? 0;
                    final exTarget = ex['targetReps'] as int? ?? 0;
                    final exTime = ex['timeToComplete'] as int? ?? 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt,
                              color: AppColors.neonRed, size: 12),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              exName.toUpperCase(),
                              style: GoogleFonts.spaceMono(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '$exActual/$exTarget REPS',
                            style: GoogleFonts.orbitron(
                              fontSize: 9,
                              color: exActual >= exTarget
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatSeconds(exTime),
                            style: GoogleFonts.spaceMono(
                              fontSize: 9,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              _buildSocialShareButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFailureCard(Map<String, dynamic> log, int day, DateTime date) {
     return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1111),
        border: Border(
          left: BorderSide(
            color: AppColors.danger,
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              color: AppColors.danger.withOpacity(0.1),
              alignment: Alignment.center,
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHALLENGE FAILED',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.danger,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'REASON: ${log['reason']?.toString().replaceAll('_', ' ') ?? "UNKNOWN"}',
                    style: GoogleFonts.orbitron(
                      fontSize: 8,
                      color: AppColors.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: AppColors.danger.withOpacity(0.2),
              child: Text(
                'FORFEITED',
                style: GoogleFonts.orbitron(
                  fontSize: 8,
                  color: AppColors.danger,
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

  Widget _buildSocialShareButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.share, size: 14, color: AppColors.textPrimary),
        label: Text(
          '[ DECLASSIFY TO INSTAGRAM ]',
          style: GoogleFonts.orbitron(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 2,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.surfaceContainerHighest),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        ),
      ),
    );
  }

  String _formatSeconds(int s) {
    if (s < 60) return '${s}s';
    final mins = s ~/ 60;
    final secs = s % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
              child: const Icon(
                Icons.fitness_center,
                color: AppColors.neonRed,
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '// DATABASE EMPTY',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.danger,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'YOU HAVE PROVEN NOTHING YET.',
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                fontSize: 10,
                color: AppColors.textSecondary,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
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
