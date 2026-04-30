import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import '../models/protocol.dart';
import 'package:kasrat_ai/core/audio/fauj_audio_engine.dart';
import 'package:kasrat_ai/core/widgets/tactical_button.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final Protocol protocol;

  const ChallengeDetailScreen({super.key, required this.protocol});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> with WidgetsBindingObserver {
  String _selectedWindow = 'civilian';
  TimeOfDay _customOperatorTime = const TimeOfDay(hour: 5, minute: 0);
  bool _isLoading = true;
  bool _hasCompletedBaseline = false;
  bool _isPaid = false;
  int _userPushups = 0;
  int _userSquats = 0;
  bool _isInternational = false;
  String _currency = 'INR';
  String _currencySymbol = '₹';


  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocale();
    _fetchProfileStatus();
  }

  void _checkLocale() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final countryCode = locale.countryCode;
    _isInternational = countryCode != 'IN' && countryCode != null;
    _currency = _isInternational ? 'USD' : 'INR';
    _currencySymbol = _isInternational ? '\$' : '₹';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchProfileStatus();
    }
  }

  Future<void> _fetchProfileStatus() async {
    _isPaid = false; // FORCED FALSE FOR TESTING
    _isLoading = true;
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profileMap = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (profileMap != null && mounted) {
          setState(() {
            _userPushups = profileMap['baseline_pushups'] ?? 0;
            _userSquats = profileMap['baseline_squats'] ?? 0;
            // _isPaid = profileMap['is_paid'] ?? false; // Disabled for testing
            _hasCompletedBaseline = _userPushups > 0 && _userSquats > 0;
            _isLoading = false;
          });
          return;
        }
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error fetching profile status: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _customOperatorTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            textTheme: GoogleFonts.spaceMonoTextTheme(
              ThemeData.dark().textTheme,
            ),
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonRed,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _customOperatorTime = picked;
      });
    }
  }

  String get _formattedOperatorTime {
    final h = _customOperatorTime.hourOfPeriod == 0
        ? 12
        : _customOperatorTime.hourOfPeriod;
    final m = _customOperatorTime.minute.toString().padLeft(2, '0');
    final p = _customOperatorTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '${h.toString().padLeft(2, '0')}:$m $p';
  }

  Future<void> _initiatePayment() async {
    HapticFeedback.heavyImpact();
    
    // Reset payment status for new deployment session
    final user = Supabase.instance.client.auth.currentUser;
    String userName = 'RECRUIT';

    if (user != null) {
      // Get user name for terminal display
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();
      
      if (profile != null) {
        userName = profile['full_name'] ?? 'RECRUIT';
      }

      await Supabase.instance.client
          .from('profiles')
          .update({'is_paid': false})
          .eq('id', user.id);
    }

    // Redirect to Deployment Auth Screen
    if (mounted) {
      context.push(
        AppRoutes.deploymentAuth,
        extra: {
          'protocolId': widget.protocol.id,
          'protocolTitle': widget.protocol.title,
          'durationDays': widget.protocol.durationDays,
          'userName': userName,
        },
      );
    }
  }

  Future<void> _simulateEnrollment() async {
    HapticFeedback.heavyImpact();
    setState(() => _isLoading = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ERROR: NO ACTIVE USER SESSION',
              style: GoogleFonts.spaceMono(color: Colors.white),
            ),
            backgroundColor: AppColors.neonRed,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      // PLAY LONG BEEP FOR START
      FaujAudioEngine().playStartBeep();

      // Simulate backend processing and DB update
      final windowModeParam = _selectedWindow == 'operator'
          ? '24H' // Default to 24H if operator isn't fully implemented in DB schema
          : '24H';

      // Serialize protocol for persistence
      final protocolData = {
        'id': widget.protocol.id,
        'title': widget.protocol.title,
        'durationDays': widget.protocol.durationDays,
        'difficulty': widget.protocol.difficulty,
        'bgIconCode': widget.protocol.bgIcon.codePoint,
        'exerciseFocus': widget.protocol.exerciseFocus,
        'outcomes': widget.protocol.outcomes,
        'exercises': widget.protocol.exercises,
        'instructions': widget.protocol.instructions,
        'description': widget.protocol.description,
        'tags': widget.protocol.tags,
        'imagePath': widget.protocol.imagePath,
        'isRecommended': widget.protocol.isRecommended,
      };

      await Supabase.instance.client
          .from('profiles')
          .update({
            'is_paid': true,
            'protocol_id': widget.protocol.id,
            'active_protocol_data': protocolData,
            'protocol_start_date': DateTime.now().toIso8601String(),
            'window_mode': _selectedWindow == 'civilian' ? '24H' : 'OPERATOR',
            'preferred_workout_time': _selectedWindow == 'civilian'
                ? '24H'
                : _formattedOperatorTime,
            'current_day': 1, // Reset for override
            'collateral_amount': CommercialConstants.collateralAmount, // Update stake amount
          })
          .eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'MISSION LOCKED: ENROLLMENT SUCCESSFUL',
              style: GoogleFonts.spaceMono(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Success sound/haptic
        HapticFeedback.mediumImpact();

        // Redirect to Dashboard
        context.go('/dashboard');
      }
    } catch (e) {
      debugPrint('Enrollment simulation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ERROR: SYSTEM OVERRIDE FAILED',
              style: GoogleFonts.spaceMono(color: Colors.white),
            ),
            backgroundColor: AppColors.neonRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLockMissionModal() {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 32,
                bottom: MediaQuery.of(modalContext).padding.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'CHALLENGE SETTINGS',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'DAILY WORKOUT TRIGGER',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.neonRed,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildConfigOption(
                      title: '[ UNRESTRICTED DEPLOYMENT ]',
                      subtitle: 'COMPLETE ANYTIME',
                      description:
                          'Complete your workout anytime before midnight. Great for busy routines.',
                      isSelected: _selectedWindow == 'civilian',
                      onTap: () =>
                          setModalState(() => _selectedWindow = 'civilian'),
                    ),
                    const SizedBox(height: 12),
                    _buildConfigOption(
                      title: '[ TACTICAL TIMEFRAME ]',
                      subtitle: 'STRICT TIME SLOT',
                      description:
                          'Set a specific daily workout time. You have a 30-minute window to start.',
                      isSelected: _selectedWindow == 'operator',
                      onTap: () =>
                          setModalState(() => _selectedWindow = 'operator'),
                    ),
                    if (_selectedWindow == 'operator') ...[
                      const SizedBox(height: 16),
                      TacticalButton(
                        soundType: TacticalSoundType.mouseClick,
                        onTap: () async {
                          await _pickCustomTime();
                          setModalState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            border: Border.all(
                              color: AppColors.neonRed.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ASSIGNED TIME',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    '30 MIN MAX',
                                    style: GoogleFonts.inter(
                                      color: AppColors.neonRed,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                color: AppColors.background,
                                child: Text(
                                  _formattedOperatorTime,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    const SizedBox(height: 12),
                    Text(
                      'ASSET FORFEITURE AUTHORIZED. ONE MISSED DAY = COMPLETE LOSS OF ASSETS.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TacticalButton(
                      soundType: TacticalSoundType.start,
                      onTap: () {
                        Navigator.pop(modalContext);
                        _initiatePayment();
                      },
                      child: Container(
                        width: double.infinity,
                        color: AppColors.neonRed,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'COMMIT & START CHALLENGE',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCostRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceMono(
              color: isTotal ? Colors.white : AppColors.textSecondary,
              fontSize: isTotal ? 14 : 11,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceMono(
              color: isTotal ? AppColors.neonRed : Colors.white,
              fontSize: isTotal ? 16 : 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigOption({
    required String title,
    required String subtitle,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return TacticalButton(
      soundType: TacticalSoundType.mouseClick,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceContainerHigh
              : AppColors.surfaceContainerLow,
          border: Border.all(
            color: isSelected ? AppColors.neonRed : AppColors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSelected ? '[X]' : '[ ]',
              style: GoogleFonts.spaceMono(
                color: isSelected ? AppColors.neonRed : AppColors.outline,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.neonRed
                          : AppColors.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: Container(
              color: AppColors.surfaceContainerHighest,
              child: Column(
                children: [
                  Expanded(flex: 1, child: Container(color: AppColors.neonRed)),
                  Expanded(flex: 2, child: Container()),
                ],
              ),
            ),
          ),

          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.neonRed),
                  )
                : Column(
                    children: [
                      Container(
                        color: Colors.black,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TacticalButton(
                              soundType: TacticalSoundType.mouseClick,
                              onTap: () => Navigator.pop(context),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.arrow_back_ios,
                                    color: AppColors.neonRed,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '// CLASSIFIED DOSSIER.',
                                    style: GoogleFonts.spaceMono(
                                      color: AppColors.neonRed,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.protocol.title.toUpperCase(),
                              maxLines: 2,
                              style: GoogleFonts.spaceMono(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(height: 1, color: Colors.white),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 24,
                            bottom: 180,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.asset(
                                  widget.protocol.imagePath,
                                  height: 220,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 220,
                                        color:
                                            AppColors.surfaceContainerHighest,
                                        child: Icon(
                                          widget.protocol.bgIcon,
                                          size: 60,
                                          color: AppColors.neonRed.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  _buildInfoBadge(
                                    Icons.timer_outlined,
                                    '${widget.protocol.durationDays} DAYS',
                                  ),
                                  _buildInfoBadge(
                                    Icons.fitness_center_outlined,
                                    widget.protocol.exerciseFocus,
                                  ),
                                  _buildInfoBadge(
                                    Icons.trending_up,
                                    widget.protocol.difficulty,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 48),

                              Text(
                                'EXERCISES INVOLVED',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: widget.protocol.exercises
                                    .map(
                                      (ex) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppColors.outlineVariant,
                                          ),
                                          color: AppColors.surfaceContainerLow,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.play_arrow_rounded,
                                              color: AppColors.neonRed,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              ex,
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),

                              const SizedBox(height: 48),

                              Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1A1A1A),
                                  border: Border(
                                    left: BorderSide(
                                      color: AppColors.neonRed,
                                      width: 4,
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SYSTEM RATIONALE',
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'BASED ON YOUR BASELINE RESULTS (PUSHUPS: $_userPushups, SQUATS: $_userSquats), THIS PROTOCOL IS CALIBRATED TO... ${widget.protocol.description.toUpperCase()}',
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              Container(
                                color: AppColors.surfaceContainerHigh,
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline,
                                          color: AppColors.neonRed,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'CHALLENGE OUTCOMES',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    ...widget.protocol.outcomes
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                          return _buildManifestRow(
                                            '0${entry.key + 1}',
                                            entry.value,
                                            'TARGETED RESULT',
                                            isHighlight: entry.key % 2 == 0,
                                          );
                                        }),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              Text(
                                'LIVE SYSTEM PREVIEW',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.outlineVariant,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Image.asset(
                                          'assets/images/athlete_focus.jpg',
                                          fit: BoxFit.cover,
                                          alignment: Alignment.topCenter,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                                    color: Colors.black87,
                                                  ),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.black.withValues(
                                                  alpha: 0.8,
                                                ),
                                                Colors.transparent,
                                              ],
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: TacticalButton(
                                          soundType:
                                              TacticalSoundType.mouseClick,
                                          onTap: () {},
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.neonRed
                                                  .withValues(alpha: 0.9),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.neonRed
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 20,
                                                  spreadRadius: 5,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.play_arrow_rounded,
                                              color: Colors.white,
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 16,
                                        left: 16,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'FORM TRACKING AI',
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              'REAL-TIME DEPTH & SKELETON ANALYSIS',
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          color: AppColors.neonRed,
                                          child: Text(
                                            'LIVE PREVIEW',
                                            style: GoogleFonts.spaceMono(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 48),

                              Text(
                                'ENROLLMENT ROADMAP',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...widget.protocol.instructions
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: AppColors.neonRed
                                                  .withValues(alpha: 0.1),
                                              border: Border.all(
                                                color: AppColors.neonRed,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${entry.key + 1}',
                                                style: GoogleFonts.spaceMono(
                                                  color: AppColors.neonRed,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              entry.value,
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 13,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                              const SizedBox(height: 180),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom
                    : 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.background,
                    AppColors.background.withValues(alpha: 0.9),
                    Colors.transparent,
                  ],
                  stops: const [0.7, 0.9, 1.0],
                ),
              ),
              child: _isLoading
                  ? const SizedBox.shrink()
                  : TacticalButton(
                      soundType: TacticalSoundType.tap,
                      onTap: _hasCompletedBaseline
                          ? _showLockMissionModal
                          : () {
                              HapticFeedback.heavyImpact();
                              context.push(AppRoutes.strengthTestSetup);
                            },
                      child: Container(
                        width: double.infinity,
                        color: AppColors.neonRed,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _hasCompletedBaseline
                                  ? 'LOCK MISSION'
                                  : 'ASSESSMENT REQUIRED',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              _hasCompletedBaseline
                                  ? Icons.lock_open
                                  : Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManifestRow(
    String numStr,
    String title,
    String subtitle, {
    required bool isHighlight,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppColors.surfaceContainerHighest
            : AppColors.surfaceContainerLow,
        border: Border(
          left: BorderSide(
            color: isHighlight ? AppColors.neonRed : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            numStr,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isHighlight ? AppColors.neonRed : AppColors.outlineVariant,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.neonRed, size: 12),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.spaceMono(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
