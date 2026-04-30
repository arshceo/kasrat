import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kasrat_ai/core/audio/fauj_audio_engine.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/widgets/tactical_button.dart';
import 'package:kasrat_ai/features/dashboard/providers/workout_provider.dart';

class RestingView extends StatefulWidget {
  final WorkoutState state;
  final Duration restElapsed;
  final VoidCallback onBegin;

  const RestingView({
    super.key,
    required this.state,
    required this.restElapsed,
    required this.onBegin,
  });

  @override
  State<RestingView> createState() => _RestingViewState();
}

class _RestingViewState extends State<RestingView> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isAutoProceeding = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = 60;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          if (!_isAutoProceeding) {
            _isAutoProceeding = true;
            widget.onBegin();
          }
        }
      });
    });
  }

  void _extendBreak() {
    setState(() {
      _remainingSeconds += 60;
    });
    FaujAudioEngine().forcePlay('radio_click.mp3');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final current = state.sets[state.currentIndex];
    final completedCount = state.sets.where((s) => s.isComplete).length;
    final totalSets = state.sets.length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, size: 48, color: AppColors.neonRed),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('EXERCISE ${state.currentIndex + 1} OF $totalSets', style: GoogleFonts.spaceMono(fontSize: 8, color: AppColors.textMuted, letterSpacing: 2)),
              Text('$completedCount DONE', style: GoogleFonts.spaceMono(fontSize: 8, color: AppColors.neonRed, fontWeight: FontWeight.bold)), 
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (state.currentIndex + 1) / totalSets,
            backgroundColor: AppColors.surfaceContainerHighest,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonRed),
            minHeight: 2,
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              children: [
                Text(state.currentIndex == 0 ? '// READY' : '// RECOVERY IN PROGRESS', style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.textMuted, letterSpacing: 2)),
                const SizedBox(height: 12),
                Text(
                  _formatSeconds(_remainingSeconds),
                  style: GoogleFonts.orbitron(fontSize: 48, fontWeight: FontWeight.w900, color: _remainingSeconds <= 10 ? AppColors.neonRed : Colors.white),
                ),
                const SizedBox(height: 12),
                Text(state.currentIndex == 0 ? 'Take a breath. Begin when ready.' : 'Recovering for the next set...', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TacticalButton(
                  onTap: _extendBreak,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.outlineVariant),
                      color: AppColors.surfaceContainerHigh,
                    ),
                    alignment: Alignment.center,
                    child: Text('+1 MIN EXTENSION', style: GoogleFonts.orbitron(fontSize: 10, color: Colors.white, letterSpacing: 1)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              border: Border.all(color: AppColors.neonRed.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text('NEXT UP:', style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.neonRed, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(current.name, style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 4),
                Text(current.isHold ? '${current.targetSeconds}S HOLD | SET ${current.setIndex + 1}' : '${current.targetReps} REPS | SET ${current.setIndex + 1}', style: GoogleFonts.spaceMono(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Spacer(),
          TacticalButton(
            onTap: widget.onBegin,
            soundType: TacticalSoundType.tap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              color: widget.state.currentIndex == 0 ? AppColors.neonRed : AppColors.warning,
              alignment: Alignment.center,
              child: Text(
                widget.state.currentIndex == 0 ? 'COMMENCE MISSION' : 'RESUME MISSION',
                style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSeconds(int s) {
    int mins = s ~/ 60;
    int secs = s % 60;
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(mins)}:${twoDigits(secs)}";
  }
}
