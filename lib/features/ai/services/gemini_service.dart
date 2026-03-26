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
      throw Exception('Workout plan generation failed: ${response.data}');
    }

    return response.data as Map<String, dynamic>;
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
      throw Exception('Diet plan generation failed: ${response.data}');
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

  /// Get workout history
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

  /// Log a drill attempt without changing day/streak progression.
  static Future<void> logCalibrationDrill({
    required String exerciseType,
    required int completedReps,
    required int durationSeconds,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

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
  }
}
