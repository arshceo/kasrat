import 'package:supabase_flutter/supabase_flutter.dart';

class DietGeminiService {
  static final _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>?> generateDietPlan({
    required String goal,
    required String preference,
    required String location,
    required String budget,
    required String exclusions,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'generate-diet-plan',
        body: {
          'goal': goal,
          'preference': preference,
          'location': location,
          'budget': budget,
          'exclusions': exclusions,
        },
      );

      if (response.status != 200) {
        return null;
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('DIET GENERATION ERROR: $e');
      return null;
    }
  }
}
