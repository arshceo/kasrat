import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kasrat_ai/core/models/ai_protocol_models.dart';

class UstadAiService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ChallengeBlueprint>> generateChallengeDossier({
    required int pushupMax,
    required int squatMax,
    required String? age,
    required String? gender,
    required double? weightKg,
    required double? heightCm,
    required int durationDays,
    required String primaryGoal,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'ustad-ai-engine',
        body: {
          'action': 'generate_dossier',
          'payload': {
            'pushupMax': pushupMax,
            'squatMax': squatMax,
            'age': age,
            'gender': gender,
            'weight_kg': weightKg,
            'height_cm': heightCm,
            'durationDays': durationDays,
            'primaryGoal': primaryGoal,
          },
        },
      );

      final dynamic rawData = response.data;
      if (rawData is List) {
        return rawData
            .map((json) {
              final blueprint = ChallengeBlueprint.fromJson(json as Map<String, dynamic>);
              // Filter out removed exercises
              blueprint.coreArsenal.removeWhere((ex) => 
                ex.toUpperCase() == 'BURPEE' || 
                ex.toUpperCase() == 'BURPEES' ||
                ex.toUpperCase() == 'JUMP SQUAT' ||
                ex.toUpperCase() == 'JUMP_SQUAT'
              );
              return blueprint;
            })
            .toList();
      } else if (rawData is Map) {
        final blueprint = ChallengeBlueprint.fromJson(rawData as Map<String, dynamic>);
        blueprint.coreArsenal.removeWhere((ex) => 
          ex.toUpperCase() == 'BURPEE' || 
          ex.toUpperCase() == 'BURPEES' ||
          ex.toUpperCase() == 'JUMP SQUAT' ||
          ex.toUpperCase() == 'JUMP_SQUAT'
        );
        return [blueprint];
      }
      return [];
    } catch (e) {
      throw Exception(
        "Failed to generate Challenge Dossier via Edge Function: $e",
      );
    }
  }

  Future<DailyMission> generateDailyMission({
    required int currentDay,
    required String primaryGoal,
    required String jsonTelemetryLog,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'ustad-ai-engine',
        body: {
          'action': 'generate_mission',
          'payload': {
            'currentDay': currentDay,
            'primaryGoal': primaryGoal,
            'jsonTelemetryLog': jsonTelemetryLog,
          },
        },
      );

      // The Edge Function returns a direct JSON map based on Gemini's output
      final jsonMap = response.data as Map<String, dynamic>;
      final mission = DailyMission.fromJson(jsonMap);
      
      // Filter out removed exercises
      mission.exercises.removeWhere((ex) => 
        ex.toUpperCase() == 'BURPEE' || 
        ex.toUpperCase() == 'BURPEES' ||
        ex.toUpperCase() == 'JUMP SQUAT' ||
        ex.toUpperCase() == 'JUMP_SQUAT'
      );
      
      return mission;
    } catch (e) {
      throw Exception("Failed to generate Daily Mission via Edge Function: $e");
    }
  }
}
