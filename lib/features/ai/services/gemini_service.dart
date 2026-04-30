import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for calling Gemini-powered Supabase Edge Functions.
class GeminiService {
  static final _supabase = Supabase.instance.client;

  /// Generate a 28-day workout plan via Gemini.
  static Future<Map<String, dynamic>> generateWorkoutPlan({
    required int calibrationScore,
    required String language,
  }) async {
    final response = await _supabase.functions.invoke(
      'generate-workout-plan',
      body: {'calibration_score': calibrationScore, 'language': language},
    );

    if (response.status != 200) {
      throw Exception('Workout plan generation failed: \${response.data}');
    }

    final data = response.data as Map<String, dynamic>;
    
    // Filter out removed exercises if present in the plan
    if (data['plan'] != null && data['plan'] is Map) {
      final plan = data['plan'] as Map;
      plan.forEach((day, dayData) {
        if (dayData is Map && dayData['exercises'] is List) {
          final exercises = dayData['exercises'] as List;
          exercises.removeWhere((ex) {
            final name = ex.toString().toUpperCase();
            return name.contains('BURPEE') || name.contains('JUMP SQUAT') || name.contains('JUMP_SQUAT');
          });
        }
      });
    }

    return data;
  }

  /// Generate a localized diet plan via Gemini.
  static Future<Map<String, dynamic>> generateDietPlan({
    required String budgetTier,
    required String language,
    String region = 'north_india',
  }) async {
    final response = await _supabase.functions.invoke(
      'generate-diet-plan',
      body: {'budget_tier': budgetTier, 'language': language, 'region': region},
    );

    if (response.status != 200) {
      throw Exception('Diet plan generation failed: \${response.data}');
    }

    return response.data as Map<String, dynamic>;
  }

  /// Get active workout plan from DB
  static Future<Map<String, dynamic>?> getActiveWorkoutPlan() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('workout_plans')
        .select()
        .eq('user_id', user.id)
        .eq('is_active', true)
        .maybeSingle();

    return response;
  }

  /// Get active diet plan from DB
  static Future<Map<String, dynamic>?> getActiveDietPlan() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('diet_plans')
        .select()
        .eq('user_id', user.id)
        .eq('is_active', true)
        .order('generated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response;
  }

  /// Log a completed workout
  static Future<void> logWorkout({
    required int dayNumber,
    required String exerciseType,
    required int targetReps,
    required int completedReps,
    int holdsPassed = 0,
    int holdsFailed = 0,
    double? formScore,
    int? durationSeconds,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('daily_logs').insert({
      'user_id': user.id,
      'day_number': dayNumber,
      'exercise_type': exerciseType,
      'target_reps': targetReps,
      'completed_reps': completedReps,
      'hold_challenges_passed': holdsPassed,
      'hold_challenges_failed': holdsFailed,
      'form_score': formScore,
      'duration_seconds': durationSeconds,
      'completed_at': DateTime.now().toIso8601String(),
      'status': completedReps >= targetReps ? 'completed' : 'failed',
    });

    // Update streak
    await _supabase
        .from('profiles')
        .update({
          'current_day': dayNumber + 1,
          'streak_status': completedReps >= targetReps ? 'unbroken' : 'broken',
        })
        .eq('id', user.id);
  }

  static Future<List<Map<String, dynamic>>> getWorkoutHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('daily_logs')
        .select()
        .eq('user_id', user.id)
        .order('day_number', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get mission history from profiles (structured session logs)
  static Future<List<Map<String, dynamic>>> getMissionHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('profiles')
        .select('workout_logs')
        .eq('id', user.id)
        .single();

    final logs = (response['workout_logs'] as List<dynamic>?) ?? [];
    // Convert to list of maps and sort by date descending
    final list = logs.map((l) => l as Map<String, dynamic>).toList();
    list.sort((a, b) {
       final da = DateTime.tryParse(a['date'] ?? '') ?? DateTime(2000);
       final db = DateTime.tryParse(b['date'] ?? '') ?? DateTime(2000);
       return db.compareTo(da);
    });
    return list;
  }

  /// Get all-time best completed reps for one exercise.
  static Future<int?> getBestCompletedRepsForExercise({
    required String exerciseType,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('daily_logs')
        .select('completed_reps')
        .eq('user_id', user.id)
        .eq('exercise_type', exerciseType)
        .order('completed_reps', ascending: false)
        .limit(1);

    final records = List<Map<String, dynamic>>.from(response);
    if (records.isEmpty) return null;
    return records.first['completed_reps'] as int?;
  }

  /// Get aggregated bests for each duration of a specific exercise
  static Future<Map<int, int>> getExerciseRecords({
    required String exerciseType,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {};

    final response = await _supabase
        .from('daily_logs')
        .select('completed_reps, duration_seconds')
        .eq('user_id', user.id)
        .eq('exercise_type', exerciseType);

    final logs = List<Map<String, dynamic>>.from(response);
    final bests = <int, int>{};

    for (final log in logs) {
      final duration = log['duration_seconds'] as int? ?? 0;
      final reps = log['completed_reps'] as int? ?? 0;
      if (!bests.containsKey(duration) || reps > bests[duration]!) {
        bests[duration] = reps;
      }
    }

    return bests;
  }

  /// Log a drill attempt without changing day/streak progression.
  static Future<void> logCalibrationDrill({
    required String exerciseType,
    required int completedReps,
    required int durationSeconds,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // 1. Log to history
    await _supabase.from('daily_logs').insert({
      'user_id': user.id,
      'day_number': 0,
      'exercise_type': exerciseType,
      'target_reps': completedReps,
      'completed_reps': completedReps,
      'hold_challenges_passed': 0,
      'hold_challenges_failed': 0,
      'duration_seconds': durationSeconds,
      'completed_at': DateTime.now().toIso8601String(),
      'status': 'completed',
    });

    // 2. Update Profile High Scores (Max Reps)
    final profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    String colName = 'max_pushups';
    if (exerciseType.toLowerCase().contains('squat')) colName = 'max_squats';
    if (exerciseType.toLowerCase().contains('situp')) colName = 'max_situps';

    final int currentMax = (profile[colName] as int?) ?? 0;
    if (completedReps > currentMax) {
      await _supabase
          .from('profiles')
          .update({colName: completedReps})
          .eq('id', user.id);
    }
  }

  static Future<String> evaluateExcuse(String excuse) async {
    try {
      final response = await _supabase.functions.invoke(
        'evaluate-excuse',
        body: {'excuse': excuse},
      );

      if (response.status != 200) {
        return "DRILL INSTRUCTOR IS BUSY. GET MOVING!";
      }

      final data = response.data as Map<String, dynamic>;
      return data['response'] ?? "ZERO EXCUSES ALLOWED!";
    } catch (e) {
      return "COMMS SILENT. START RUNNING!";
    }
  }
}
