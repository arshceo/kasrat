import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmProtocolService {
  static const int alarmId = 777;
  static StreamSubscription<AlarmSettings>? _ringSubscription;

  static Future<void> init() async {
    await Alarm.init();
    
    // Listen for alarm triggers to update Supabase status to 'active'
    _ringSubscription?.cancel();
    _ringSubscription = Alarm.ringStream.stream.listen((settings) async {
      if (settings.id == alarmId) {
        await _transitionToActive();
      }
    });
  }

  /// Transition the latest 'pending' challenge to 'active' and set deadline
  static Future<void> _transitionToActive() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Find the latest pending challenge
      final latest = await supabase
          .from('daily_challenges')
          .select('id')
          .eq('user_id', user.id)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (latest != null) {
        final deadline = DateTime.now().add(const Duration(hours: 2));
        
        await supabase.from('daily_challenges').update({
          'status': 'active',
          'deadline_time': deadline.toIso8601String(),
        }).eq('id', latest['id']);

        // Legacy profile sync
        await supabase.from('profiles').update({
          'challenge_status': 'active',
        }).eq('id', user.id);
        
        debugPrint('SYSTEM: Challenge ${latest['id']} is now ACTIVE. Deadline: $deadline');
      }
    } catch (e) {
      debugPrint('Error transitioning to active: $e');
    }
  }

  /// Schedules a daily repeating alarm.
  static Future<void> setDailyAlarm(int hour, int minute) async {
    final now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: scheduledTime,
      assetAudioPath: 'assets/audio/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      volumeSettings: VolumeSettings.fade(
        volume: 1.0,
        fadeDuration: const Duration(seconds: 3),
      ),
      notificationSettings: NotificationSettings(
        title: 'USTAD PROTOCOL INITIATED',
        body: '2-HOUR WINDOW STARTING NOW. COMMAND CENTER AWAITS.',
        stopButton: 'DISMISS',
      ),
      warningNotificationOnKill: true,
    );

    await Alarm.set(alarmSettings: alarmSettings);

    final box = Hive.box('alarm_settings');
    await box.put('is_active', true);
    await box.put('hour', hour);
    await box.put('minute', minute);
    // Note: We don't set scheduled_deadline here anymore as it's set in DB when it rings
    // But for local fallback/UI we can keep it (Time + 2h)
    await box.put('scheduled_deadline', scheduledTime.add(const Duration(hours: 2)).toIso8601String());

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client.from('profiles').update({
        'daily_alarm_time': '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00',
      }).eq('id', user.id);
      
      // Ensure a pending challenge exists for this new alarm schedule
      final existing = await Supabase.instance.client
          .from('daily_challenges')
          .select('id')
          .eq('user_id', user.id)
          .eq('status', 'pending')
          .maybeSingle();
          
      if (existing == null) {
        await Supabase.instance.client.from('daily_challenges').insert({
          'user_id': user.id,
          'status': 'pending',
          'stake_amount': 500, // Default stake
        });
      }
    }
  }

  /// The "Life or Death" check. Evaluates if the user missed their window.
  static Future<void> evaluatePenalty() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Check the latest active challenge from Supabase
      final latest = await supabase
          .from('daily_challenges')
          .select('id, deadline_time, status')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (latest != null) {
        final deadline = DateTime.parse(latest['deadline_time']);
        if (DateTime.now().isAfter(deadline)) {
          // Check if it was completed today (workout logs)
          final profile = await supabase.from('profiles').select('workout_logs').eq('id', user.id).single();
          final List logs = profile['workout_logs'] ?? [];
          final today = DateTime.now();
          final wasDone = logs.any((l) {
            final d = DateTime.parse(l['date']);
            return d.year == today.year && d.month == today.month && d.day == today.day && l['type'] != 'CHALLENGE_FAILURE';
          });

          if (!wasDone) {
            debugPrint('SYSTEM: DEADLINE BREACHED. EXECUTING FORFEIT.');
            await _executeForfeit(latest['id']);
          } else {
            // It was done! Mark challenge as completed
            await supabase.from('daily_challenges').update({'status': 'completed'}).eq('id', latest['id']);
          }
        }
      }
    } catch (e) {
      debugPrint('Error evaluating penalty: $e');
    }
  }

  static Future<void> _executeForfeit(String challengeId) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('daily_challenges').update({
        'status': 'failed',
      }).eq('id', challengeId);

      await supabase.from('profiles').update({
        'staked_balance': 0,
        'challenge_status': 'failed',
      }).eq('id', user.id);

      final box = Hive.box('alarm_settings');
      await box.put('challenge_failed', true);
      
      debugPrint('SYSTEM: COLLATERAL FORFEITED IN DB.');
    } catch (e) {
      debugPrint('CRITICAL ERROR: Failed to execute forfeit: $e');
    }
  }

  static Future<void> stopAlarm() async {
    if (await Alarm.isRinging(alarmId)) {
      await Alarm.stop(alarmId);
    }
  }
}
