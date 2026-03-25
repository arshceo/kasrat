import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pedometer/pedometer.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> with SingleTickerProviderStateMixin {
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  late AudioPlayer _audioPlayer;
  
  int _initialSteps = -1;
  int _stepsTaken = 0;
  final int _stepsRequired = 20;
  
  String _pedestrianStatus = 'unknown';
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _startAlarmAudio();
    _initPedometer();
    
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _pulseController.addListener(() {
      setState(() {});
    });
  }

  void _startAlarmAudio() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      // Play the generated Ustad AI TTS alarm sound
      await _audioPlayer.play(AssetSource('audio/alarm.wav'));
    } catch (_) {}
  }

  void _initPedometer() {
    try {
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
      _stepCountStream = Pedometer.stepCountStream;

      _stepCountStream.listen(_onStepCount).onError(_onStepCountError);
      _pedestrianStatusStream.listen(_onPedestrianStatusChanged).onError(_onPedestrianStatusError);
    } catch (e) {
      debugPrint('Pedometer initialization error: $e');
    }
  }

  void _onStepCount(StepCount event) {
    setState(() {
      if (_initialSteps == -1) {
        _initialSteps = event.steps;
      }
      _stepsTaken = event.steps - _initialSteps;
    });
  }

  void _onStepCountError(error) {
    debugPrint('Step Count Error: $error');
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) {
    setState(() {
      _pedestrianStatus = event.status;
    });
  }

  void _onPedestrianStatusError(error) {
    debugPrint('Pedestrian Status Error: $error');
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canDismiss = _stepsTaken >= _stepsRequired;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.neonRed.withValues(alpha: _pulseController.value * 0.5), 
              width: 4
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.neonRed),
                        const SizedBox(width: 8),
                        Text(
                          'PROTOCOL: WAKE',
                          style: GoogleFonts.orbitron(
                            color: AppColors.neonRed,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'SYS_ACTIVE',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Giant Clock
              Center(
                child: Text(
                  DateFormat('HH:mm').format(_currentTime),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 120,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    color: AppColors.textPrimary,
                    letterSpacing: -4,
                  ),
                ),
              ),
              Center(
                child: Text(
                  DateFormat('ss').format(_currentTime),
                  style: GoogleFonts.rajdhani(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neonRed,
                  ),
                ),
              ),

              const Spacer(),

              // Command Block
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGlass,
                  border: const Border(
                    left: BorderSide(color: AppColors.neonRed, width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DIRECTIVE:',
                      style: GoogleFonts.orbitron(
                        color: AppColors.neonRed,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'TURN ON THE LIGHTS.\nWALK $_stepsRequired STEPS.',
                      style: GoogleFonts.rajdhani(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sensor Data Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSensorReadout(
                        'STEPS',
                        '$_stepsTaken / $_stepsRequired',
                        canDismiss ? Colors.green : AppColors.neonRed,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSensorReadout(
                        'STATUS',
                        _pedestrianStatus.toUpperCase(),
                        AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Dismissal Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: ElevatedButton(
                  onPressed: canDismiss ? () {
                    // Turn off alarm and navigate to dashboard
                    context.go(AppRoutes.dashboard);
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canDismiss ? AppColors.neonRed : AppColors.surface,
                    disabledBackgroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    shape: const RoundedRectangleBorder(),
                    side: BorderSide(
                      color: canDismiss ? Colors.transparent : AppColors.outlineVariant,
                    ),
                  ),
                  child: Text(
                    canDismiss ? 'DISMISS ALARM' : 'COMPLETE GOALS TO UNLOCK',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: canDismiss ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              
              // Failure Warning
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Center(
                  child: Text(
                    'SNOOZE DISABLED. PENALTY PROTOCOL ACTIVE IN 120s.',
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorReadout(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.orbitron(
              color: AppColors.textMuted,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
