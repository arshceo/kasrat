import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exercise_set.dart';
import '../../armory/models/protocol.dart';
import 'package:kasrat_ai/core/models/exercise_type.dart';

enum WorkoutPhase { briefing, resting, exercising, completed }

class WorkoutState {
  final List<ExerciseSet> sets;
  final int currentIndex;
  final WorkoutPhase phase;
  final DateTime? workoutStartTime;
  final DateTime? restStartTime;
  final Duration elapsedDuringActive; // To handle paused/resumed workout
  final bool isLoading;
  final String? error;

  WorkoutState({
    this.sets = const [],
    this.currentIndex = 0,
    this.phase = WorkoutPhase.briefing,
    this.workoutStartTime,
    this.restStartTime,
    this.elapsedDuringActive = Duration.zero,
    this.isLoading = true,
    this.error,
  });

  WorkoutState copyWith({
    List<ExerciseSet>? sets,
    int? currentIndex,
    WorkoutPhase? phase,
    DateTime? workoutStartTime,
    DateTime? restStartTime,
    Duration? elapsedDuringActive,
    bool? isLoading,
    String? error,
  }) {
    return WorkoutState(
      sets: sets ?? this.sets,
      currentIndex: currentIndex ?? this.currentIndex,
      phase: phase ?? this.phase,
      workoutStartTime: workoutStartTime ?? this.workoutStartTime,
      restStartTime: restStartTime ?? this.restStartTime,
      elapsedDuringActive: elapsedDuringActive ?? this.elapsedDuringActive,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  Duration get totalElapsed {
    if (workoutStartTime == null) return elapsedDuringActive;
    return DateTime.now().difference(workoutStartTime!) + elapsedDuringActive;
  }
}

class WorkoutNotifier extends StateNotifier<WorkoutState> {
  WorkoutNotifier() : super(WorkoutState());

  Timer? _ticker;

  void startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.phase != WorkoutPhase.briefing &&
          state.phase != WorkoutPhase.completed) {
        state = state.copyWith(); // Trigger rebuild for timer
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> initialize(
    Protocol protocol,
    int currentDay, {
    Map<String, dynamic>? resumeData,
  }) async {
    state = state.copyWith(isLoading: true);

    Map<String, dynamic>? data;
    bool shouldAttemptResume = resumeData != null;

    if (shouldAttemptResume) {
      data = resumeData;
    } else {
      // We only fallback to shared preferences if we are NOT explicitly 
      // starting a fresh session. But for now, let's look at prefs 
      // only if we haven't been given any resumeData.
      // To fix the "Commence" button issue, we should probably 
      // have a way to know if it was an EXPLICIT fresh start.
      // For now, if resumeData is null, we'll still check prefs 
      // but we'll be more careful.
      final prefs = await SharedPreferences.getInstance();
      final savedDataStr = prefs.getString('active_workout_state');
      if (savedDataStr != null) {
        try {
          data = jsonDecode(savedDataStr);
        } catch (_) {}
      }
    }

    final storedData = data;
    if (storedData != null) {
      try {
        if (storedData['protocolId'] == protocol.id ||
            storedData['protocolId'] == 'current') {
          final List<dynamic> setsJson = storedData['sets'];
          final sets = setsJson.map((s) => ExerciseSet.fromJson(s)).toList();

          state = state.copyWith(
            sets: sets,
            currentIndex: storedData['currentIndex'] ?? 0,
            phase: WorkoutPhase.values.firstWhere(
              (v) => v.name == (storedData['phase'] ?? 'exercising'),
              orElse: () => WorkoutPhase.exercising,
            ),
            workoutStartTime: storedData['startTime'] != null
                ? DateTime.parse(storedData['startTime'])
                : null,
            elapsedDuringActive: Duration(
              seconds: storedData['elapsedSeconds'] ?? 0,
            ),
            isLoading: false,
          );
          startTicker();
          return;
        }
      } catch (e) {
        // Fallback to fresh init
      }
    }

    // Fresh initialization
    final sets = _buildSets(protocol, currentDay);
    state = state.copyWith(
      sets: sets,
      currentIndex: 0,
      phase: WorkoutPhase.briefing,
      isLoading: false,
    );
  }

  List<ExerciseSet> _buildSets(Protocol protocol, int day) {
    final List<ExerciseSet> sets = [];
    final multiplier = 1.0 + (day - 1) * 0.05; // 5% daily progression

    for (final exerciseName in protocol.exercises) {
      int baseReps = 10;
      int? targetSeconds;
      bool isHold = false;

      final name = exerciseName.toLowerCase();
      if (name.contains('pushup')) {
        baseReps = 12;
      } else if (name.contains('squat'))
        baseReps = 15;
      else if (name.contains('situp'))
        baseReps = 15;
      else if (name.contains('plank')) {
        isHold = true;
        targetSeconds = 60;
      } else if (name.contains('wall sit')) {
        isHold = true;
        targetSeconds = 45;
      } else if (name.contains('lunge'))
        baseReps = 10;
      else if (name.contains('jack'))
        baseReps = 20;

      final targetSecondsCount = targetSeconds != null
          ? (targetSeconds * multiplier).toInt()
          : null;
      final targetRepsCount = isHold
          ? (targetSecondsCount ?? 0)
          : (baseReps * multiplier).toInt();

      const numSets = 3;

      for (int i = 0; i < numSets; i++) {
        sets.add(
          ExerciseSet(
            name: exerciseName.toUpperCase(),
            targetReps: targetRepsCount,
            targetSeconds: targetSecondsCount,
            type: _mapToExerciseType(exerciseName),
            isHold: isHold,
            setIndex: i,
            totalSets: numSets,
          ),
        );
      }
    }
    return sets;
  }

  ExerciseType _mapToExerciseType(String name) {
    final n = name.toLowerCase();
    if (n.contains('pushup')) return ExerciseType.pushup;
    if (n.contains('squat')) return ExerciseType.squat;
    if (n.contains('situp')) return ExerciseType.situp;
    if (n.contains('plank')) return ExerciseType.plank;
    if (n.contains('burpee')) return ExerciseType.burpee;
    if (n.contains('jack')) return ExerciseType.jumpingJacks;
    if (n.contains('wall sit')) return ExerciseType.wallSit;
    if (n.contains('pullup')) return ExerciseType.pullup;
    if (n.contains('lunge')) return ExerciseType.lunge;
    if (n.contains('crunch')) return ExerciseType.crunch;
    return ExerciseType.pushup;
  }

  void startWorkout() {
    state = state.copyWith(
      phase: WorkoutPhase.exercising, // Go straight to exercise
      workoutStartTime: DateTime.now(),
      elapsedDuringActive: Duration.zero,
    );
    startTicker();
    saveState();
  }

  // Called when exercise screen returns
  void completeSet(int actualReps, Duration timeTaken) {
    final sets = List<ExerciseSet>.from(state.sets);
    sets[state.currentIndex].actualReps = actualReps;
    sets[state.currentIndex].timeToComplete = timeTaken;
    sets[state.currentIndex].isComplete = true;

    final isLast = state.currentIndex == sets.length - 1;
    if (isLast) {
      state = state.copyWith(sets: sets, phase: WorkoutPhase.completed);
      _ticker?.cancel();
      clearSavedState();
    } else {
      state = state.copyWith(
        sets: sets,
        currentIndex: state.currentIndex + 1,
        phase: WorkoutPhase.resting,
        restStartTime: DateTime.now(),
      );
      saveState();
    }
  }

  void abortExercise() {
    state = state.copyWith(phase: WorkoutPhase.briefing);
    saveState();
  }

  void goBackToBriefing() {
    state = state.copyWith(phase: WorkoutPhase.briefing);
    saveState();
  }

  void resumeWorkout() {
    if (state.phase == WorkoutPhase.briefing &&
        state.workoutStartTime != null) {
      state = state.copyWith(phase: WorkoutPhase.exercising);
      saveState();
    }
  }

  String getDirectiveTitle(Protocol protocol, int day) {
    final focus = protocol.exerciseFocus.toUpperCase();

    if (day == 1) return 'INITIATION PROTOCOL';
    if (day == protocol.durationDays) return 'FINAL ASCENSION';

    final themes = [
      'IRON WILL',
      'CORE STABILITY',
      'TACTICAL STRENGTH',
      'ENDURANCE LIMIT',
      'PEAK OUTPUT',
      'NEURAL DRIVE',
      'RESILIENCE DRILL',
      'OVERPOWER',
      'PRECISION VOLLEY',
    ];

    final index = (day + focus.length) % themes.length;
    return 'OPERATION: ${themes[index]}';
  }

  String getCoachNotice(int day) {
    if (day % 7 == 0) {
      return 'MILESTONE REACHED. PUSH BEYOND YOUR COMFORT ZONE TODAY.';
    }
    if (day == 1) {
      return 'FORM IS TEMPORARY, CLASS IS PERMANENT. DO NOT RUSH THE REPS.';
    }

    final themes = [
      'KEEP YOUR CORE TIGHT DURING ALL MOVEMENTS.',
      'EXHALE ON THE EFFORT. INHALE ON THE RETURN.',
      'CONTROL THE DESCENT. DON\'T LET GRAVITY DO THE WORK.',
      'AI IS WATCHING YOUR DEPTH. GO LOWER.',
      'HYDRATION IS AMMUNITION. DRINK UP.',
      'REST IS NOT WEAKNESS. RECHARGE FOR THE NEXT SET.',
    ];
    return themes[day % themes.length];
  }

  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'protocolId': 'current',
      'day': 1,
      'currentIndex': state.currentIndex,
      'phase': state.phase.name,
      'sets': state.sets.map((s) => s.toJson()).toList(),
      'startTime': state.workoutStartTime?.toIso8601String(),
      'elapsedSeconds': state.elapsedDuringActive.inSeconds,
    };
    final jsonStr = jsonEncode(data);
    await prefs.setString('active_workout_state', jsonStr);

    // Sync with Supabase
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client
          .from('profiles')
          .update({'active_workout_state': data})
          .eq('id', user.id);
    }
  }

  Future<void> clearSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_workout_state');

    // Clear from Supabase
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client
          .from('profiles')
          .update({'active_workout_state': null})
          .eq('id', user.id);
    }
  }
}

final workoutProvider = StateNotifierProvider<WorkoutNotifier, WorkoutState>((
  ref,
) {
  return WorkoutNotifier();
});
