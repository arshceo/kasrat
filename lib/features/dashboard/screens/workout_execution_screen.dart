import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/audio/fauj_audio_engine.dart';
import '../../armory/models/protocol.dart';
import '../providers/workout_provider.dart';
import 'package:kasrat_ai/core/models/exercise_type.dart';

// Modular Widgets
import '../widgets/workout/workout_header.dart';
import '../widgets/workout/phases/briefing_view.dart';
import '../widgets/workout/phases/resting_view.dart';
import '../widgets/workout/phases/completion_view.dart';

class WorkoutExecutionScreen extends ConsumerStatefulWidget {
  final Protocol protocol;
  final int currentDay;
  final Map<String, dynamic>? resumeData;

  const WorkoutExecutionScreen({
    super.key,
    required this.protocol,
    required this.currentDay,
    this.resumeData,
  });

  @override
  ConsumerState<WorkoutExecutionScreen> createState() =>
      _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState
    extends ConsumerState<WorkoutExecutionScreen> {
  DateTime? _workoutDeadline;
  Timer? _deadlineTimer;
  Duration _timeUntilDeadline = const Duration(hours: 2);

  bool _isSaving = false;
  String? _saveError;

  final TextEditingController _repController = TextEditingController();
  final FocusNode _repFocusNode = FocusNode();

  bool get _isCriticalPeriod {
    if (_workoutDeadline == null) return false;
    final now = DateTime.now();
    return now.isAfter(_workoutDeadline!) &&
        now.isBefore(_workoutDeadline!.add(const Duration(hours: 2)));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(workoutProvider.notifier)
          .initialize(
            widget.protocol,
            widget.currentDay,
            resumeData: widget.resumeData,
          );

      final state = ref.read(workoutProvider);
      // Only auto-begin if we are in exercising phase AND we explicitly came from a resume action.
      // This prevents "Commence Workout" from jumping straight to camera if there's stale state.
      if (state.phase == WorkoutPhase.exercising && widget.resumeData != null) {
        _onBeginExercise();
      }
    });
    _startDeadlineTimer();
    _loadProfileAndDeadline();
  }

  @override
  void dispose() {
    _deadlineTimer?.cancel();
    _repController.dispose();
    _repFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProfileAndDeadline() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('preferred_workout_time')
        .eq('id', user.id)
        .maybeSingle();

    if (mounted) {
      setState(() {
        _workoutDeadline = _calculateDeadline(
          profile?['preferred_workout_time'],
        );
      });
    }
  }

  DateTime _calculateDeadline(String? timeStr) {
    final now = DateTime.now();
    if (timeStr == null ||
        timeStr == '24H' ||
        timeStr == 'FLEXIBLE (24H)' ||
        timeStr.isEmpty) {
      return DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
    try {
      final parts = timeStr.trim().split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final isPm = parts.length > 1 && parts[1].toUpperCase() == 'PM';

      if (isPm && hour < 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;

      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (_) {
      return DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
  }

  void _startDeadlineTimer() {
    _deadlineTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final deadline = _workoutDeadline;
      if (deadline == null) return;

      final now = DateTime.now();
      final diff = deadline.difference(now);

      final criticalDeadline = deadline.add(const Duration(hours: 2));
      if (now.isAfter(criticalDeadline)) {
        _deadlineTimer?.cancel();
        _handleMissionFailure();
        return;
      }

      setState(() {
        _timeUntilDeadline = diff.isNegative ? Duration.zero : diff;
      });
    });
  }

  Future<void> _handleMissionFailure() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('workout_logs, challenges_failed')
            .eq('id', user.id)
            .single();
        final List<dynamic> logs =
            (profile['workout_logs'] as List<dynamic>?) ?? [];
        final int failedCount = (profile['challenges_failed'] as int?) ?? 0;

        final failureLog = {
          'date': DateTime.now().toIso8601String(),
          'day': widget.currentDay,
          'protocolId': widget.protocol.id,
          'protocolTitle': widget.protocol.title,
          'status': 'failed',
          'type': 'CHALLENGE_FAILURE',
          'reason': 'CRITICAL_DEADLINE_EXPIRED_DURING_SESSION',
        };

        await Supabase.instance.client
            .from('profiles')
            .update({
              'protocol_id': null,
              'active_protocol_data': null,
              'challenges_failed': failedCount + 1,
              'workout_logs': [...logs, failureLog],
            })
            .eq('id', user.id);

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surfaceContainerHigh,
              title: Text(
                'COMMUNICATIONS CUT',
                style: GoogleFonts.orbitron(
                  color: AppColors.neonRed,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Text(
                'Critical deadline expired. The Warzone has reclaimed your deposit. Assignment terminated.',
                style: GoogleFonts.spaceMono(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go(AppRoutes.dashboard);
                  },
                  child: Text(
                    'RETURN TO BASE',
                    style: GoogleFonts.orbitron(color: AppColors.neonRed),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in mission failure: $e');
      if (mounted) context.go(AppRoutes.dashboard);
    }
  }

  void _onBackInvoked() {
    final state = ref.read(workoutProvider);

    // If mission hasn't started or is already done, allow exit
    if (state.workoutStartTime == null ||
        state.phase == WorkoutPhase.completed) {
      context.pop();
      return;
    }

    _showAbortConfirmation(state);
  }

  void _showAbortConfirmation(WorkoutState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.neonRed, width: 2),
          borderRadius: BorderRadius.zero,
        ),
        title: Text(
          'ABORT MISSION?',
          style: GoogleFonts.orbitron(
            color: AppColors.neonRed,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WARNING: DRILL IN PROGRESS',
              style: GoogleFonts.spaceMono(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Exiting now will abort this specific session. You are required to finish the remaining objectives before your daily deadline.',
              style: GoogleFonts.spaceMono(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'FAILURE TO COMPLETE PROTOCOL BY DEADLINE WILL RESULT IN:',
              style: GoogleFonts.spaceMono(
                color: AppColors.neonRed,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '• CHALLENGE FAILURE\n• FORFEITURE OF DEPOSIT',
              style: GoogleFonts.spaceMono(
                color: AppColors.neonRed,
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'RESUME DRILL',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonRed,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              ref.read(workoutProvider.notifier).clearSavedState();
              context.go(AppRoutes.dashboard);
            },
            child: Text(
              'ABORT MISSION',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onStartWorkout() {
    FaujAudioEngine().forcePlay('long_beep.mp3');
    HapticFeedback.heavyImpact();

    final state = ref.read(workoutProvider);
    if (state.workoutStartTime == null) {
      ref.read(workoutProvider.notifier).startWorkout();
      _onBeginExercise();
    } else {
      ref.read(workoutProvider.notifier).resumeWorkout();
      final updatedState = ref.read(workoutProvider);
      if (updatedState.phase == WorkoutPhase.exercising) {
        _onBeginExercise();
      }
    }
  }

  Future<void> _onBeginExercise() async {
    HapticFeedback.mediumImpact();
    FaujAudioEngine().forcePlay('beep.mp3');

    final workoutState = ref.read(workoutProvider);
    final currentSet = workoutState.sets[workoutState.currentIndex];
    final exerciseStartTime = DateTime.now();

    final result = await context.push<Map<String, dynamic>?>(
      AppRoutes.strengthTest,
      extra: {
        'exerciseType': currentSet.type,
        'exerciseName': currentSet.name,
        'setIndex': currentSet.setIndex + 1,
        'totalSets': currentSet.totalSets,
        'durationSeconds': currentSet.isHold
            ? (currentSet.targetSeconds ?? 60)
            : 0,
        'isBaseline': false,
        'baselineStep': workoutState.currentIndex + 1,
        'totalSteps': workoutState.sets.length,
        'targetReps': currentSet.targetReps,
        'sessionStartTime': workoutState.workoutStartTime,
      },
    );

    if (!mounted) return;

    if (result == null) {
      ref.read(workoutProvider.notifier).abortExercise();
      return;
    }

    final timeToComplete = DateTime.now().difference(exerciseStartTime);
    final repsFromCamera = result['completedReps'] as int? ?? 0;

    // Automatically complete the set with ML data
    ref
        .read(workoutProvider.notifier)
        .completeSet(repsFromCamera, timeToComplete);
  }

  Future<void> _onFinishAndSync() async {
    setState(() => _isSaving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final state = ref.read(workoutProvider);

      final exerciseLogs = state.sets
          .map(
            (s) => {
              'exercise': s.name,
              'targetReps': s.targetReps,
              'actualReps': s.actualReps ?? 0,
              'timeToComplete': s.timeToComplete?.inSeconds ?? 0,
              'restAfterSeconds': s.restTakenAfter?.inSeconds ?? 0,
              'completed': s.isComplete,
            },
          )
          .toList();

      final workoutLog = {
        'date': DateTime.now().toIso8601String(),
        'day': widget.currentDay,
        'protocolId': widget.protocol.id,
        'totalElapsedSeconds': state.totalElapsed.inSeconds,
        'exercises': exerciseLogs,
      };

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('workout_logs, max_pushups, max_squats')
          .eq('id', user.id)
          .maybeSingle();

      final existingLogs = (profile?['workout_logs'] as List<dynamic>?) ?? [];
      final updatedLogs = [...existingLogs, workoutLog];

      int newMaxPushups = profile?['max_pushups'] ?? 0;
      int newMaxSquats = profile?['max_squats'] ?? 0;

      for (final s in state.sets) {
        if (s.type == ExerciseType.pushup && s.actualReps! > newMaxPushups) {
          newMaxPushups = s.actualReps!;
        }
        if ((s.type == ExerciseType.squat ||
                s.type == ExerciseType.jumpingJacks) &&
            s.actualReps! > newMaxSquats) {
          newMaxSquats = s.actualReps!;
        }
      }

      await Supabase.instance.client
          .from('profiles')
          .update({
            'workout_logs': updatedLogs,
            'max_pushups': newMaxPushups,
            'max_squats': newMaxSquats,
            'last_workout_date': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      if (mounted) context.go(AppRoutes.dashboard);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onBackInvoked();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              WorkoutHeader(
                currentDay: widget.currentDay,
                protocolTitle: widget.protocol.title,
                state: workoutState,
                timeUntilDeadline: _timeUntilDeadline,
                isCriticalPeriod: _isCriticalPeriod,
                onBack: _onBackInvoked,
              ),
              Expanded(child: _buildBody(workoutState)),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomAction(workoutState),
      ),
    );
  }

  Widget _buildBody(WorkoutState state) {
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.neonRed),
            const SizedBox(height: 16),
            Text(
              'LOADING MISSION DATA...',
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: AppColors.textMuted,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
    }

    final notifier = ref.read(workoutProvider.notifier);

    switch (state.phase) {
      case WorkoutPhase.briefing:
        return BriefingView(
          currentDay: widget.currentDay,
          protocolTitle: widget.protocol.title,
          state: state,
          directiveTitle: notifier.getDirectiveTitle(
            widget.protocol,
            widget.currentDay,
          ),
          coachNotice: notifier.getCoachNotice(widget.currentDay),
          onStart: _onStartWorkout,
        );
      case WorkoutPhase.exercising:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.videocam_outlined,
                color: AppColors.neonRed,
                size: 48,
              ),
              const SizedBox(height: 24),
              Text(
                'INITIALIZING SENSORS...',
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'PREPARING MISSION ZONE',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      case WorkoutPhase.resting:
        final restElapsed = state.restStartTime != null
            ? DateTime.now().difference(state.restStartTime!)
            : Duration.zero;
        return RestingView(
          state: state,
          restElapsed: restElapsed,
          onBegin: _onBeginExercise,
        );
      case WorkoutPhase.completed:
        return CompletionView(
          state: state,
          isSaving: _isSaving,
          saveError: _saveError,
          onFinish: _onFinishAndSync,
        );
    }
  }

  Widget? _buildBottomAction(WorkoutState state) {
    if (state.phase == WorkoutPhase.briefing && state.workoutStartTime == null) {
      return null;
    }
    if (state.phase == WorkoutPhase.completed) return null;

    return const SizedBox.shrink();
  }
}
