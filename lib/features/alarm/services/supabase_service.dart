import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';

class SupabaseService {
  static final _supabase = Supabase.instance.client;

  // DIRECT PENALTY EXECUTION
  static Future<void> enforceAlarmPenalty() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return; // Failsafe

    try {
      // Option A: If you are tracking balance as an integer
      // This directly deducts collateral from the user's database record.
      await _supabase.rpc('deduct_penalty', params: {
        'user_id': user.id,
        'amount': CommercialConstants.collateralAmount
      });

      // Option B: If you don't have an RPC function setup yet, use direct update (uncomment below)
      /*
      await _supabase.from('users')
          .update({'deposit_active': false, 'status': 'PENALIZED'})
          .eq('id', user.id);
      */
      
      debugPrint('SYSTEM: Collateral Forfeited.');
    } catch (e) {
      debugPrint('CRITICAL ERROR: Failed to enforce penalty - $e');
    }
  }

  // SURVIVAL EXECUTION
  static Future<void> recordMissionSuccess() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('missions')
          .insert({'user_id': user.id, 'status': 'COMPLETED', 'date': DateTime.now().toIso8601String()});
      debugPrint('SYSTEM: Mission Success Recorded.');
    } catch (e) {
      debugPrint('Error logging success: $e');
    }
  }
}
