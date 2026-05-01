import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kasrat_ai/features/leaderboard/logic/league_engine.dart';
import 'package:kasrat_ai/features/armory/models/protocol.dart';
import 'package:kasrat_ai/features/ai/services/gemini_service.dart';

class DashboardState {
  final Map<String, dynamic>? profileData;
  final String rank;
  final String fullName;
  final Protocol? activeProtocol;
  final String protocolTitle;
  final int currentDay;
  final int totalDays;
  final DateTime? protocolStartDate;
  final Duration timeLeft;
  final Duration criticalTimeLeft;
  final bool isCriticalPeriod;
  final bool isLoading;
  final bool isSubscriber;
  final bool hasCompletedBaseline;
  final bool hasCompletedMetrics;
  final bool hasDietPlan;
  final bool hasFailedChallenge;
  final Map<String, dynamic>? dietPlan;
  final int? dailyCalories;
  final List<bool> rationsChecked;
  final Map<String, dynamic>? activeWorkoutData;
  final String? pendingCode;
  final bool isWorkoutDoneToday;

  DashboardState({
    this.profileData,
    this.rank = 'RECRUIT',
    this.fullName = 'SOLDIER',
    this.activeProtocol,
    this.protocolTitle = 'NO ACTIVE MISSION',
    this.currentDay = 1,
    this.totalDays = 28,
    this.protocolStartDate,
    this.timeLeft = Duration.zero,
    this.criticalTimeLeft = Duration.zero,
    this.isCriticalPeriod = false,
    this.isLoading = true,
    this.isSubscriber = false,
    this.hasCompletedBaseline = false,
    this.hasCompletedMetrics = false,
    this.hasDietPlan = false,
    this.hasFailedChallenge = false,
    this.dietPlan,
    this.dailyCalories,
    this.rationsChecked = const [],
    this.activeWorkoutData,
    this.pendingCode,
    this.isWorkoutDoneToday = false,
  });

  DashboardState copyWith({
    Map<String, dynamic>? profileData,
    String? rank,
    String? fullName,
    Protocol? activeProtocol,
    String? protocolTitle,
    int? currentDay,
    int? totalDays,
    DateTime? protocolStartDate,
    Duration? timeLeft,
    Duration? criticalTimeLeft,
    bool? isCriticalPeriod,
    bool? isLoading,
    bool? isSubscriber,
    bool? hasCompletedBaseline,
    bool? hasCompletedMetrics,
    bool? hasDietPlan,
    bool? hasFailedChallenge,
    Map<String, dynamic>? dietPlan,
    int? dailyCalories,
    List<bool>? rationsChecked,
    Map<String, dynamic>? activeWorkoutData,
    String? pendingCode,
    bool? isWorkoutDoneToday,
  }) {
    return DashboardState(
      profileData: profileData ?? this.profileData,
      rank: rank ?? this.rank,
      fullName: fullName ?? this.fullName,
      activeProtocol: activeProtocol ?? this.activeProtocol,
      protocolTitle: protocolTitle ?? this.protocolTitle,
      currentDay: currentDay ?? this.currentDay,
      totalDays: totalDays ?? this.totalDays,
      protocolStartDate: protocolStartDate ?? this.protocolStartDate,
      timeLeft: timeLeft ?? this.timeLeft,
      criticalTimeLeft: criticalTimeLeft ?? this.criticalTimeLeft,
      isCriticalPeriod: isCriticalPeriod ?? this.isCriticalPeriod,
      isLoading: isLoading ?? this.isLoading,
      isSubscriber: isSubscriber ?? this.isSubscriber,
      hasCompletedBaseline: hasCompletedBaseline ?? this.hasCompletedBaseline,
      hasCompletedMetrics: hasCompletedMetrics ?? this.hasCompletedMetrics,
      hasDietPlan: hasDietPlan ?? this.hasDietPlan,
      hasFailedChallenge: hasFailedChallenge ?? this.hasFailedChallenge,
      dietPlan: dietPlan ?? this.dietPlan,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      rationsChecked: rationsChecked ?? this.rationsChecked,
      activeWorkoutData: activeWorkoutData ?? this.activeWorkoutData,
      pendingCode: pendingCode ?? this.pendingCode,
      isWorkoutDoneToday: isWorkoutDoneToday ?? this.isWorkoutDoneToday,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier() : super(DashboardState());

  StreamSubscription? _profileSubscription;
  StreamSubscription? _terminalSubscription;
  Timer? _countdownTimer;

  void initialize() {
    // Cancel existing to prevent leaks or duplicates
    _profileSubscription?.cancel();
    _terminalSubscription?.cancel();
    _profileSubscription = null;
    _terminalSubscription = null;
    
    _fetchInitialProfile();
    _setupProfileStream();
    _setupTerminalStream();
    _startCountdown();
    _checkDietStatus();
  }

  Future<void> _fetchInitialProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final res = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (res != null) {
        final currentData = state.profileData ?? {};
        final updatedData = {...currentData, ...res};
        _updateFromProfile(updatedData);
      }
    }
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _terminalSubscription?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _setupTerminalStream() {
    if (_terminalSubscription != null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _terminalSubscription = Supabase.instance.client
          .from('terminals')
          .stream(primaryKey: ['id'])
          .eq('id', user.id)
          .listen((data) {
            if (data.isNotEmpty && mounted) {
              final code = data.first['code'] as String?;
              state = state.copyWith(pendingCode: code);
            }
          });
    }
  }

  void _setupProfileStream() {
    if (_profileSubscription != null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _profileSubscription = Supabase.instance.client
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', user.id)
          .listen((data) {
            if (data.isNotEmpty) {
              final currentData = state.profileData ?? {};
              final updatedData = {...currentData, ...data.first};
              _updateFromProfile(updatedData);
            }
          });
    }
  }

  void _updateFromProfile(Map<String, dynamic> res) async {
    final hasBaseline =
        (res['baseline_squats'] ?? 0) > 0 && (res['baseline_pushups'] ?? 0) > 0;

    final rank = LeagueEngine.calculateLeague(
      pushups: (res['max_pushups'] as int?) ?? 0,
      squats: (res['max_squats'] as int?) ?? 0,
      situps: (res['max_situps'] as int?) ?? 0,
      challengesWon: (res['challenges_won'] as int?) ?? 0,
      hasCompletedBaseline: hasBaseline,
    );

    Protocol? activeProtocol;
    String protocolTitle = 'NO ACTIVE MISSION';
    int totalDays = 28;
    int currentDay = 1;
    DateTime? startDate;

    final protocolId = res['protocol_id'] as String?;
    if (protocolId != null) {
      // PRIORITY 1: Look up the full protocol from the static list using the ID.
      // staticProtocols contains all exercises, instructions, and outcomes.
      // active_protocol_data from the website only has title + durationDays.
      final staticMatch = staticProtocols.where((p) => p.id == protocolId).firstOrNull;

      if (staticMatch != null) {
        // Found in static list — use the complete, fully-populated Protocol
        activeProtocol = staticMatch;
        protocolTitle = staticMatch.title.toUpperCase();
        totalDays = staticMatch.durationDays;
        debugPrint('✅ Protocol loaded from staticProtocols: ${staticMatch.id}');
      } else {
        // Not in static list — check ai_challenge_dossiers first
        final dossiers = res['ai_challenge_dossiers'] as List<dynamic>?;
        Map<String, dynamic>? dossierMatch;
        if (dossiers != null) {
          dossierMatch = dossiers
              .map((d) => d as Map<String, dynamic>)
              .where((d) => d['id'] == protocolId)
              .firstOrNull;
        }

        if (dossierMatch != null) {
          activeProtocol = _parseProtocol(protocolId, dossierMatch);
          
          // CRITICAL: If AI protocol is missing exercises, try to fetch from engine
          if (activeProtocol.exercises.isEmpty && protocolId.startsWith('ai_gen_')) {
            debugPrint('🔄 AI Protocol exercises empty. Fetching from engine...');
            _fetchAIRoutine(activeProtocol, res);
          }
          
          protocolTitle = activeProtocol.title.toUpperCase();
          totalDays = activeProtocol.durationDays;
          debugPrint('✅ Protocol loaded from ai_challenge_dossiers: $protocolId, exercises=${activeProtocol.exercises}');
        } else {
          // Fallback to active_protocol_data (might be incomplete if from web)
          debugPrint('❌ protocolId=$protocolId not in static or dossiers. Trying active_protocol_data...');
          final rawProtocolData = res['active_protocol_data'];
          Map<String, dynamic>? activeProtocolMap;
          if (rawProtocolData is Map) {
            activeProtocolMap = rawProtocolData.map((k, v) => MapEntry(k.toString(), v));
          } else if (rawProtocolData is String) {
            try { activeProtocolMap = json.decode(rawProtocolData) as Map<String, dynamic>?; } catch (_) {}
          }

          if (activeProtocolMap != null && activeProtocolMap['title'] != null) {
            protocolTitle = activeProtocolMap['title'].toString().toUpperCase();
            totalDays = int.tryParse(activeProtocolMap['durationDays'].toString()) ?? 28;
            activeProtocol = _parseProtocol(protocolId, activeProtocolMap);
            
            // Try engine fallback for web-synced data too
            if (activeProtocol.exercises.isEmpty && protocolId.startsWith('ai_gen_')) {
              _fetchAIRoutine(activeProtocol, res);
            }
            
            debugPrint('⚠️ Fallback protocol: exercises=${activeProtocol.exercises}');
          }
        }
      }

      final startDateStr = res['protocol_start_date'] as String?;
      if (startDateStr != null) {
        try {
          startDate = DateTime.parse(startDateStr);
          currentDay = DateTime.now().difference(startDate).inDays + 1;
          currentDay = currentDay.clamp(1, totalDays);
        } catch (_) {
          currentDay = 1;
        }
      }
    }

    Map<String, dynamic>? activeWorkoutData;
    final rawWorkoutData = res['active_workout_state'];
    if (rawWorkoutData != null) {
      if (rawWorkoutData is Map) {
        activeWorkoutData = rawWorkoutData.map((k, v) => MapEntry(k.toString(), v));
      } else if (rawWorkoutData is String) {
        try {
          activeWorkoutData = json.decode(rawWorkoutData) as Map<String, dynamic>?;
        } catch (_) {}
      }
    }

    bool isWorkoutDoneToday = false;
    if (startDate != null) {
      final logs = (res['workout_logs'] as List?) ?? [];
      final completedDays = logs.where((l) => l['type'] != 'CHALLENGE_FAILURE').length;
      final daysSinceStart = DateTime.now().difference(startDate).inDays;
      final expectedDay = daysSinceStart + 1;
      isWorkoutDoneToday = completedDays >= expectedDay;
    }

    String? pendingCode;
    try {
      if (res['is_paid'] != true && protocolId != null) {
        final terminalRes = await Supabase.instance.client
            .from('terminals')
            .select('code')
            .eq('id', res['id'])
            .maybeSingle();
        if (terminalRes != null) {
          pendingCode = terminalRes['code'] as String?;
        }
      }
    } catch (e) {
      debugPrint('Error fetching pending code: $e');
    } finally {
      state = state.copyWith(
        profileData: res,
        rank: rank,
        fullName: (res['display_name'] as String?)?.toUpperCase() ?? 'RECRUIT',
        activeProtocol: activeProtocol,
        protocolTitle: protocolTitle,
        totalDays: totalDays,
        currentDay: currentDay,
        protocolStartDate: startDate,
        isSubscriber: res['is_paid'] == true,
        hasCompletedBaseline: hasBaseline,
        hasCompletedMetrics:
            (res['height_cm'] ?? 0) > 0 && (res['weight_kg'] ?? 0) > 0,
        activeWorkoutData: activeWorkoutData,
        pendingCode: pendingCode,
        isWorkoutDoneToday: isWorkoutDoneToday,
        isLoading: false,
      );
    }
  }

  Protocol _parseProtocol(String id, Map<dynamic, dynamic> data) {
    return Protocol(
      id: id,
      title: data['title']?.toString() ?? 'ACTIVE MISSION',
      durationDays: int.tryParse(data['durationDays'].toString()) ?? 28,
      difficulty: data['difficulty']?.toString() ?? 'MEDIUM',
      bgIcon: IconData(
        int.tryParse(data['bgIconCode']?.toString() ?? '0xf309') ?? 0xf309,
        fontFamily: 'MaterialIcons',
      ),
      exerciseFocus: data['exerciseFocus']?.toString() ?? 'FULL BODY',
      outcomes:
          (data['outcomes'] as List?)?.map((e) => e.toString()).toList() ?? [],
      exercises:
          (data['exercises'] as List?)?.map((e) => e.toString()).toList() ?? [],
      instructions:
          (data['instructions'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      description: data['description']?.toString() ?? '',
      tags: (data['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      imagePath:
          data['imagePath']?.toString() ?? 'assets/images/placeholder.png',
      isRecommended: data['isRecommended'] == true,
    );
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    if (state.profileData == null) return;

    final now = DateTime.now();
    final timeStr = state.profileData?['preferred_workout_time'] ?? '24H';
    DateTime deadline;

    if (timeStr == '24H' || timeStr == 'FLEXIBLE (24H)' || timeStr.isEmpty) {
      deadline = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else {
      try {
        final parts = timeStr.trim().split(' ');
        final timeParts = parts[0].split(':');
        int hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final isPm = parts.length > 1 && parts[1].toUpperCase() == 'PM';
        if (isPm && hour < 12) hour += 12;
        if (!isPm && hour == 12) hour = 0;
        deadline = DateTime(now.year, now.month, now.day, hour, minute);
      } catch (_) {
        deadline = DateTime(now.year, now.month, now.day, 23, 59, 59);
      }
    }

    bool isFailed = false;
    bool isCritical = false;
    Duration remain = Duration.zero;
    Duration criticalRemain = Duration.zero;

    if (state.isSubscriber &&
        state.protocolStartDate != null &&
        state.protocolTitle != 'NO ACTIVE MISSION') {
      final logs = (state.profileData!['workout_logs'] as List?) ?? [];
      
      // Determine if today is a rest day
      // For now, if exercises list is not empty, assume it's a workout day
      final bool hasExercises = state.activeProtocol?.exercises.isNotEmpty ?? false;

      final now = DateTime.now();
      final daysSinceStart = now.difference(state.protocolStartDate!).inDays;
      // Note: We don't use expectedDay = daysSinceStart + 1 here because 
      // daysSinceStart is 0 on the first day.
      
      // Check if user has already completed today's workout
      final bool isDoneToday = state.isWorkoutDoneToday;

      if (isDoneToday) {
        // Workout finished, deadline pushed to tomorrow
        deadline = deadline.add(const Duration(days: 1));
        remain = deadline.difference(now);
      } else if (!hasExercises) {
        // Rest day: No failure possible, countdown to tomorrow
        deadline = deadline.add(const Duration(days: 1));
        remain = deadline.difference(now);
      } else {
        // Active workout day and not done
        remain = deadline.difference(now);
        
        // Critical Logic: If deadline passed, enter 2-hour grace period
        if (remain.isNegative) {
          final criticalDeadline = deadline.add(const Duration(hours: 2));
          final critDiff = criticalDeadline.difference(now);
          
          if (critDiff.isNegative) {
            isFailed = true;
          } else {
            isCritical = true;
            criticalRemain = critDiff;
          }
        }
        
        // Anti-Skip Logic: If user missed the previous day entirely
        // completedDays only counts successful MISSION_LOG entries
        final completedDays = logs.where((l) => l['type'] != 'CHALLENGE_FAILURE').length;
        if (completedDays < daysSinceStart) {
           isFailed = true;
        }
      }
    } else {
      // No active mission or not a subscriber, no countdown
      remain = Duration.zero;
      isCritical = false;
    }

    if (isFailed && !state.hasFailedChallenge && !state.isLoading) {
      _failMission('DEADLINE_EXPIRED');
    }

    state = state.copyWith(
      timeLeft: remain.isNegative ? Duration.zero : remain,
      isCriticalPeriod: isCritical,
      criticalTimeLeft: criticalRemain,
      hasFailedChallenge: isFailed,
    );
  }

  bool _isFailing = false;
  Future<void> _failMission(String reason) async {
    if (_isFailing) return;
    _isFailing = true;
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _isFailing = false;
      return;
    }

    try {
      debugPrint('🚨 MISSION FAILURE DETECTED: $reason');
      
      // 1. Get current stats
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('challenges_lost, workout_logs')
          .eq('id', user.id)
          .single();

      final int currentLost = (profile['challenges_lost'] as int?) ?? 0;
      final List logs = List.from(profile['workout_logs'] ?? []);

      // 2. Add failure entry
      logs.add({
        'type': 'CHALLENGE_FAILURE',
        'reason': reason,
        'date': DateTime.now().toIso8601String(),
        'protocol_id': state.activeProtocol?.id,
        'day': state.currentDay,
      });

      // 3. Update DB
      await Supabase.instance.client.from('profiles').update({
        'is_paid': false,
        'protocol_id': null,
        'active_protocol_data': null,
        'challenges_lost': currentLost + 1,
        'workout_logs': logs,
        'staked_balance': 0, // CRITICAL: Wipe balance on failure
        'challenge_status': 'failed',
      }).eq('id', user.id);

      debugPrint('✅ Database updated for mission failure.');
      
      // 4. Force refresh
      initialize();
    } catch (e) {
      debugPrint('CRITICAL: Failed to process mission failure: $e');
    } finally {
      _isFailing = false;
    }
  }

  Future<void> _checkDietStatus() async {
    final response = await GeminiService.getActiveDietPlan();
    if (response != null && response['plan_json'] != null) {
      final plan = response['plan_json'] as Map<String, dynamic>;
      state = state.copyWith(
        hasDietPlan: true,
        dietPlan: plan,
        dailyCalories: int.tryParse(plan['daily_calories']?.toString() ?? ''),
        rationsChecked: List<bool>.filled(
          (plan['meals'] as List?)?.length ?? 0,
          false,
        ),
      );
    } else {
      state = state.copyWith(hasDietPlan: false, dietPlan: null);
    }
  }

  void toggleRation(int index, bool value) {
    if (state.rationsChecked.length > index) {
      final newRations = List<bool>.from(state.rationsChecked);
      newRations[index] = value;
      state = state.copyWith(rationsChecked: newRations);
    }
  }

  Future<void> _fetchAIRoutine(Protocol protocol, Map<String, dynamic> profile) async {
    try {
      final routine = await GeminiService.getAIProtocolRoutine(
        protocolId: protocol.id,
        title: protocol.title,
        difficulty: protocol.difficulty,
        focus: protocol.exerciseFocus,
      );

      final exercises = (routine['exercises'] as List?)?.map((e) => e.toString()).toList() ?? [];
      if (exercises.isNotEmpty) {
        debugPrint('✅ AI Routine fetched successfully: $exercises');
        
        final updatedProtocol = Protocol(
          id: protocol.id,
          title: protocol.title,
          durationDays: protocol.durationDays,
          difficulty: protocol.difficulty,
          bgIcon: protocol.bgIcon,
          exerciseFocus: protocol.exerciseFocus,
          outcomes: protocol.outcomes,
          exercises: exercises,
          instructions: (routine['instructions'] as List?)?.map((e) => e.toString()).toList() ?? protocol.instructions,
          description: routine['description']?.toString() ?? protocol.description,
          tags: protocol.tags,
          imagePath: protocol.imagePath,
          isRecommended: protocol.isRecommended,
        );
        
        if (mounted) {
          state = state.copyWith(activeProtocol: updatedProtocol);
        }

        // Persist to DB
        final dossiers = List<dynamic>.from(profile['ai_challenge_dossiers'] ?? []);
        final index = dossiers.indexWhere((d) => (d as Map)['id'] == protocol.id);
        
        final newDossier = updatedProtocol.toJson();
        if (index != -1) {
          dossiers[index] = newDossier;
        } else {
          dossiers.add(newDossier);
        }

        await Supabase.instance.client.from('profiles').update({
          'ai_challenge_dossiers': dossiers,
        }).eq('id', profile['id']);
      }
    } catch (e) {
      debugPrint('Error fetching AI routine: $e');
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
      return DashboardNotifier();
    });
