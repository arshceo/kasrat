import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/widgets/tactical_button.dart';
import 'dart:io';

import 'package:kasrat_ai/core/audio/fauj_audio_engine.dart';
import '../painters/skeleton_painter.dart';
import '../services/pose_analyzer.dart';
import '../widgets/rep_counter_widget.dart';
import '../widgets/timer_bar_widget.dart';
import '../../ai/services/gemini_service.dart';
import 'package:kasrat_ai/core/services/settings_service.dart';

/// Screen A-02: "The Calibration Test" — Day 0 Baseline.
///
/// Full-screen camera with ML Kit skeletal overlay.
/// Massive rep counter, 60-second countdown, Ustad instructions.
class CalibrationScreen extends StatefulWidget {
  final bool isFirstTime;
  final ExerciseType exerciseType;
  final int durationSeconds; // 0 = unlimited (use isBaseline mode)
  final bool isBaseline;
  final int baselineStep; // 1 = squats, 2 = pushups
  final int totalSteps;    // How many exercises in the workout
  final int? targetReps;   // AI-set rep target for today (null = max effort baseline)

  final String? exerciseName;
  final int? setIndex;
  final DateTime? sessionStartTime;

  const CalibrationScreen({
    super.key,
    this.isFirstTime = true,
    this.exerciseType = ExerciseType.squat,
    this.durationSeconds = 60,
    this.isBaseline = false,
    this.baselineStep = 1,
    this.totalSteps = 1,
    this.targetReps,
    this.exerciseName,
    this.setIndex,
    this.sessionStartTime,
  });

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen>
    with WidgetsBindingObserver {
  // Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  // ML Kit
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    ),
  );

  bool _isProcessing = false;
  bool _isHandlingExcuse = false; // Pauses logic when interacting with Ustad

  // Analysis
  final PoseAnalyzer _poseAnalyzer = PoseAnalyzer();
  Pose? _currentPose;
  PoseAnalysisResult? _latestResult;
  Size? _imageSize;
  InputImageRotation _imageRotation = InputImageRotation.rotation0deg;
  int _inferenceTimeMs = 0;

  // Timer
  Timer? _countdownTimer;
  int _remainingSeconds = 60;
  int _elapsedSeconds = 0; // For stopwatch mode
  bool _isCalibrationActive = false;
  bool _isExerciseStarted = false;
  bool _isCalibrationComplete = false;

  // Baseline idle-stop detection (5 second pause = done)
  Timer? _idleTimer;
  int _lastIdleRepCount = 0;
  int _idleCountdownSeconds = 10;

  // Pre-exercise countdown
  bool _isCountingDown = false;
  int _preCountdownSeconds = 10;
  Timer? _preCountdownTimer;

  // TTS for rep counting & countdown
  final FlutterTts _tts = FlutterTts();
  int _lastSpokenRep = 0;
  final List<String> _repWords = [
    '', 'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', 'SIX', 'SEVEN', 'EIGHT', 'NINE', 'TEN',
    'ELEVEN', 'TWELVE', 'THIRTEEN', 'FOURTEEN', 'FIFTEEN', 'SIXTEEN', 'SEVENTEEN', 'EIGHTEEN', 'NINETEEN', 'TWENTY',
    'TWENTY ONE', 'TWENTY TWO', 'TWENTY THREE', 'TWENTY FOUR', 'TWENTY FIVE', 'TWENTY SIX', 'TWENTY SEVEN', 'TWENTY EIGHT', 'TWENTY NINE', 'THIRTY',
  ];

  // Camera switching
  bool _isFrontCamera = true;
  int _currentCameraIndex = 0;
  DateTime _lastProcessTime = DateTime.fromMillisecondsSinceEpoch(0);
  CustomPaint? _customPaint;

  // Drill results
  int _completedReps = 0;
  int? _previousBestReps;
  bool _isLoadingPreviousBest = false;

  // UI state
  CalibrationPhase _phase = CalibrationPhase.warmup;
  bool _showHold = false;
  bool _isGeneratingPlan = false;
  bool _showDevStats = false; // Toggle for ML performance data
  bool _isLandscape = false;
  bool _isFinishing = false; // Guard to prevent multi-pop

  void _toggleOrientation() {
    setState(() {
      _isLandscape = !_isLandscape;
      if (_isLandscape) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remainingSeconds = widget.durationSeconds;
    _initCamera();
    _initTts();
  }

  String get _exerciseName => widget.exerciseType.displayName;
  String get _exerciseNamePlural => widget.exerciseType.pluralName;
  String get _exerciseDbType => widget.exerciseType.dbType;

  String get _drillTitle {
    if (widget.isBaseline) {
      return 'STEP ${widget.baselineStep} OF 2 — $_exerciseNamePlural';
    }
    return '$_exerciseName DRILL';
  }

  String get _ustadInstruction {
    final isHold = widget.exerciseType.isHold;
    if (widget.targetReps != null) {
      return isHold
          ? 'HOLD YOUR ${widget.exerciseType.displayName} FOR ${widget.targetReps} SECONDS. GIVE MAXIMUM EFFORT.'
          : 'TODAY\'S TARGET: ${widget.targetReps} ${widget.exerciseType.pluralName}. PUSH YOUR LIMIT.';
    }
    if (widget.isBaseline || widget.durationSeconds == 0) {
      return isHold
          ? 'HOLD YOUR $_exerciseName FOR AS LONG AS POSSIBLE.'
          : 'SHOW US YOUR MAXIMUM $_exerciseNamePlural. GIVE YOUR BEST.';
    }
    return isHold
        ? 'HOLD YOUR $_exerciseName FOR ${widget.durationSeconds} SECONDS.'
        : 'DO AS MANY $_exerciseNamePlural AS YOU CAN IN ${widget.durationSeconds} SECONDS.';
  }

  Future<void> _loadPreviousBest() async {
    setState(() => _isLoadingPreviousBest = true);
    try {
      final best = await GeminiService.getBestCompletedRepsForExercise(
        exerciseType: _exerciseDbType,
      );
      if (!mounted) return;
      setState(() {
        _previousBestReps = best;
        _isLoadingPreviousBest = false;
      });
    } catch (e) {
      debugPrint('Previous best fetch error: $e');
      if (!mounted) return;
      setState(() => _isLoadingPreviousBest = false);
    }
  }

  void _startCalibrationMode() {
    _startPreCountdown();
  }

  void _startPreCountdown() {
    if (_isCountingDown) return;
    setState(() {
      _isCountingDown = true;
      _preCountdownSeconds = 10;
    });
    _tts.stop().then((_) {
      Future.delayed(const Duration(milliseconds: 30), () {
        if (mounted) _tts.speak('Get ready!');
      });
    });
    _preCountdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _preCountdownSeconds--);
      if (_preCountdownSeconds > 0) {
        _tts.stop().then((_) {
          Future.delayed(const Duration(milliseconds: 30), () {
            if (mounted) _tts.speak('$_preCountdownSeconds');
          });
        });
      } else {
        t.cancel();
        _tts.stop().then((_) {
          Future.delayed(const Duration(milliseconds: 30), () {
            if (mounted) _tts.speak('GO!');
          });
        });
        setState(() => _isCountingDown = false);
        _startCalibration();
      }
    });
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(0.9);
      await _tts.awaitSpeakCompletion(false);
    } catch (e) {
      debugPrint('TTS Init Error: $e');
    }
  }

  void _speakRepIfNew(int repCount) {
    if (!SettingsService().isAudioEnabled) return;
    
    if (repCount > _lastSpokenRep && repCount > 0) {
      if (widget.exerciseType.isHold && repCount % 5 != 0) {
        return;
      }
      
      _lastSpokenRep = repCount;
      final word = repCount < _repWords.length ? _repWords[repCount] : '$repCount';
      
      _tts.stop().then((_) {
        Future.delayed(const Duration(milliseconds: 30), () {
          if (mounted) _tts.speak(word);
        });
      });
    }
  }

  DateTime _lastFeedbackTime = DateTime.fromMillisecondsSinceEpoch(0);
  String? _lastSpokenFeedback;

  void _speakFeedbackIfNew(String? feedback) {
    if (!SettingsService().isAudioEnabled) return;
    if (feedback == null || feedback.isEmpty) return;
    final now = DateTime.now();
    
    if (now.difference(_lastFeedbackTime).inSeconds < 6) return;
    if (feedback == _lastSpokenFeedback && now.difference(_lastFeedbackTime).inSeconds < 10) return;
      
    String? ttsText;
    switch (feedback) {
      case 'LIFT YOUR SHOULDERS': ttsText = 'Lift shoulders'; break;
      case 'SHOULDERS TO THE FLOOR': ttsText = 'Shoulders down'; break;
      case 'TURN 90 DEGREES (SIDE VIEW)': ttsText = 'Turn sideways'; break;
      case 'LOWER YOUR HIPS': ttsText = 'Hips down'; break;
      case 'KEEP HAND PLANTED': ttsText = 'Hand flat'; break;
      case 'KEEP BACK STRAIGHT': ttsText = 'Back straight'; break;
      case 'GO DEEPER': ttsText = 'Go lower'; break;
      case 'LOCK OUT ARMS': ttsText = 'Lock arms'; break;
      case 'PUSH UP FULLY': ttsText = 'Push up'; break;
      case 'SHOW YOUR TORSO & HIPS': ttsText = 'Move back'; break;
      case 'GET OFF THE FLOOR': ttsText = 'Off the floor'; break;
      case 'LIFT HIPS OFF THE FLOOR': ttsText = 'Hips up'; break;
      case 'HIPS TOO LOW (SAGGING)': ttsText = 'Hips too low'; break;
      case 'HIPS TOO HIGH (PIKING)': ttsText = 'Hips too high'; break;
      case 'KEEP FEET PLANTED': ttsText = 'Feet flat'; break;
      case 'KEEP CHEST UP': ttsText = 'Chest up'; break;
      case 'FULL DEPTH REQUIRED': ttsText = 'More depth'; break;
      case 'STAND UP FULLY': ttsText = 'Stand up'; break;
      case 'SIDE PROFILE REQUIRED': ttsText = 'Turn sideways'; break;
      case 'FULL BODY REQUIRED': ttsText = 'Move back'; break;
      case 'STEP INTO FRAME': ttsText = 'Move back'; break;
      case 'LOW VISIBILITY': ttsText = 'Target lost'; break;
      case 'CHEST MUST NEARLY TOUCH FLOOR': ttsText = 'Go lower'; break;
    }

    if (ttsText != null) {
      _tts.stop().then((_) {
        Future.delayed(const Duration(milliseconds: 30), () {
          if (mounted) _tts.speak(ttsText!);
        });
      });
      _lastSpokenFeedback = feedback;
      _lastFeedbackTime = now;
    }
  }

  Future<void> _disposeCamera() async {
    _isCameraInitialized = false;
    final controller = _cameraController;
    _cameraController = null;
    if (mounted) setState(() {});

    try {
      await controller?.stopImageStream();
    } catch (_) {}
    await controller?.dispose();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _preCountdownTimer?.cancel();
    _idleTimer?.cancel();
    _tts.stop();
    final controller = _cameraController;
    _cameraController = null;
    _isCameraInitialized = false;
    controller?.dispose();
    _poseDetector.close();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera({CameraLensDirection? preferredDirection}) async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;

    final direction = preferredDirection ?? CameraLensDirection.front;
    final camera = _cameras!.firstWhere(
      (c) => c.lensDirection == direction,
      orElse: () => _cameras!.first,
    );
    _isFrontCamera = camera.lensDirection == CameraLensDirection.front;
    _currentCameraIndex = _cameras!.indexOf(camera);

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;
      await _cameraController!.startImageStream(_processImage);
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    setState(() => _isCameraInitialized = false);
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
    final newDirection = _isFrontCamera
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    await _initCamera(preferredDirection: newDirection);
  }

  Future<void> _processImage(CameraImage image) async {
    if (!_isCalibrationActive || _isProcessing) return;

    final now = DateTime.now();
    if (now.difference(_lastProcessTime).inMilliseconds < 100) return;

    _isProcessing = true;
    _lastProcessTime = now;

    try {
      final startTracker = DateTime.now();
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) return;

      final poses = await _poseDetector.processImage(inputImage);
      final endTracker = DateTime.now();

      if (poses.isNotEmpty && mounted) {
        _currentPose = poses.first;

        if (_isHandlingExcuse) {
          setState(() {});
          return;
        }

        final result = _poseAnalyzer.analyzePose(poses.first, widget.exerciseType);

        if (!_isExerciseStarted) {
          if (widget.exerciseType.isHold) {
            if (result.phase == ExercisePhase.active) {
              _isExerciseStarted = true;
              _tts.stop().then((_) {
                Future.delayed(const Duration(milliseconds: 30), () {
                  if (mounted) _tts.speak("HOLD START");
                });
              });
            }
          } else {
            if (result.repCount > 0) _isExerciseStarted = true;
          }
        }

        setState(() {
          _inferenceTimeMs = endTracker.difference(startTracker).inMilliseconds;
          _latestResult = result;
          _imageSize = Size(image.width.toDouble(), image.height.toDouble());

          if (result.holdTriggered && !_showHold) _showHold = true;
          if (result.holdPassed) _showHold = false;
        });

        _speakRepIfNew(result.repCount);

        if (widget.targetReps != null && result.repCount >= widget.targetReps!) {
          _endCalibration();
          return;
        }

        if (!result.isGoodForm && result.formFeedback != null) {
          _speakFeedbackIfNew(result.formFeedback);
        }
      }
    } catch (e) {
      debugPrint('Pose detection error: $e');
    } finally {
      if (mounted) _isProcessing = false;
    }
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _convertCameraImage(CameraImage image) {
    final camera = _cameras![_currentCameraIndex];
    final sensorOrientation = camera.sensorOrientation;

    // 2. Get the current UI rotation (Landscape vs Portrait)
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      // Since we don't have a native orientation plugin, we infer from our internal state
      final deviceOrientation = _isLandscape ? DeviceOrientation.landscapeLeft : DeviceOrientation.portraitUp;
      var rotationCompensation = _orientations[deviceOrientation];
      if (rotationCompensation == null) return null;

      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;
    _imageRotation = rotation;

    // 3. Assemble the InputImage metadata
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    if (image.planes.isEmpty) return null;

    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // <-- THIS FIXES YOUR X/Y AXIS
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  void _startCalibration() {
    FaujAudioEngine().playStartBeep();
    _poseAnalyzer.reset();
    _lastSpokenRep = 0;

    if (widget.exerciseType.allowsLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      _isLandscape = true;
    }

    setState(() {
      _phase = CalibrationPhase.active;
      _isCalibrationActive = true;
      _isExerciseStarted = false;
      _remainingSeconds = widget.durationSeconds;
      _completedReps = 0;
      _previousBestReps = null;
      _idleCountdownSeconds = 15;
      _lastIdleRepCount = 0;
    });

    _countdownTimer?.cancel();
    _idleTimer?.cancel();

    if (!widget.isBaseline && widget.targetReps == null && widget.durationSeconds > 0) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_isHandlingExcuse) return;
        setState(() {
          if (!_isExerciseStarted) return;
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
            if (_remainingSeconds == 10) {
              _tts.stop().then((_) {
                Future.delayed(const Duration(milliseconds: 30), () {
                  if (mounted) _tts.speak("Ten seconds remaining. Push it!");
                });
              });
            }
            if (_remainingSeconds <= 5 && _remainingSeconds > 0) {
              _tts.stop().then((_) {
                Future.delayed(const Duration(milliseconds: 30), () {
                  if (mounted) _tts.speak("$_remainingSeconds");
                });
              });
            }
          } else {
            timer.cancel();
            _endCalibration();
          }
        });
      });
    } else if (widget.targetReps != null) {
      _elapsedSeconds = 0;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_isHandlingExcuse) return;
        setState(() {
          if (_isExerciseStarted && !_isCalibrationComplete) _elapsedSeconds++;
        });
      });
    } else {
      _elapsedSeconds = 0;
      _idleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) { timer.cancel(); return; }
        if (_isHandlingExcuse) return;

        setState(() {
          if (!_isExerciseStarted) return;
          _elapsedSeconds++;
          final currentReps = _latestResult?.repCount ?? 0;
          if (currentReps > _lastIdleRepCount) {
            _lastIdleRepCount = currentReps;
            _idleCountdownSeconds = 15;
          } else if (_lastIdleRepCount > 0) {
            _idleCountdownSeconds--;
            if (_idleCountdownSeconds == 5) {
              _tts.stop().then((_) {
                Future.delayed(const Duration(milliseconds: 30), () {
                  if (mounted) _tts.speak('Test will end in 5');
                });
              });
            } else if (_idleCountdownSeconds > 0 && _idleCountdownSeconds < 5) {
              _tts.stop().then((_) {
                Future.delayed(const Duration(milliseconds: 30), () {
                  if (mounted) _tts.speak('$_idleCountdownSeconds');
                });
              });
            }
            if (_idleCountdownSeconds <= 0) {
              timer.cancel();
              _endCalibration();
            }
          }
        });
      });
    }
  }

  Future<void> _endCalibration() async {
    if (_isFinishing) return;
    _isFinishing = true;

    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      setState(() => _isLandscape = false);
    }

    _countdownTimer?.cancel();
    _idleTimer?.cancel();
    final finalReps = _latestResult?.repCount ?? 0;

    if (!widget.isBaseline) await _loadPreviousBest();

    setState(() {
      _isCalibrationActive = false;
      _isCalibrationComplete = true;
      _completedReps = finalReps;
    });

    try {
      await GeminiService.logCalibrationDrill(
        exerciseType: _exerciseDbType,
        completedReps: finalReps,
        durationSeconds: widget.durationSeconds == 0 ? _elapsedSeconds : widget.durationSeconds,
      );
    } catch (e) {
      debugPrint('Failed to save drill record: $e');
    }

    if (widget.isBaseline) {
      setState(() => _phase = CalibrationPhase.results);
      await _saveBaselineResult(finalReps);
    } else {
      _tts.stop().then((_) {
        Future.delayed(const Duration(milliseconds: 30), () {
          if (mounted) _tts.speak("Good job.");
        });
      });
      setState(() => _phase = CalibrationPhase.success);

      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        Navigator.of(context).pop(<String, dynamic>{
          'completedReps': finalReps,
          'elapsedSeconds': widget.durationSeconds == 0 ? _elapsedSeconds : widget.durationSeconds,
        });
      }
    }
  }

  Future<void> _saveBaselineResult(int reps) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        if (widget.exerciseType == ExerciseType.squat) {
          await Supabase.instance.client.from('profiles').update({'baseline_squats': reps}).eq('id', user.id);
        } else if (widget.exerciseType == ExerciseType.pushup) {
          await Supabase.instance.client.from('profiles').update({'baseline_pushups': reps}).eq('id', user.id);
        }
      }
    } catch (e) {
      debugPrint('Failed to save baseline: $e');
    }
  }

  String get _displayTitle {
    if (widget.isBaseline) return 'BASELINE TEST';
    if (widget.exerciseName != null) {
      if (widget.setIndex != null) return '${widget.exerciseName} | SET ${widget.setIndex}';
      return widget.exerciseName!;
    }
    return AppStrings.strengthTestTitle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background Camera ───────────────────────────────────
          Positioned.fill(child: _buildCameraPreview()),

          // ── Silhouette Overlay (Side-profile guidance) ──────────
          if ((widget.exerciseType == ExerciseType.squat || widget.exerciseType == ExerciseType.wallSit) &&
              (_phase == CalibrationPhase.warmup || _isCountingDown))
            Positioned.fill(
              child: CustomPaint(painter: SquatSilhouettePainter()),
            ),

          // ── UI Layer Gradient ───────────────────────────────────
          _buildOverlayGradient(),

          // ── Skeleton overlay ────────────────────────────────────
          if (_currentPose != null && _imageSize != null)
            CustomPaint(
              painter: SkeletonPainter(
                pose: _currentPose,
                imageSize: _imageSize!,
                rotation: _imageRotation,
                analysisResult: _latestResult,
                isFrontCamera: _isFrontCamera,
              ),
            ),

          // ── UI Elements ─────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // MISSION TELEMETRY BAR
                if (!_isLandscape)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      border: Border(bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          style: IconButton.styleFrom(backgroundColor: Colors.black26),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'LIVE TELEMETRY',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 8,
                                  color: AppColors.neonRed,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _displayTitle.toUpperCase(),
                                style: GoogleFonts.orbitron(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (widget.sessionStartTime != null)
                          _buildSessionTimerLabel()
                        else
                          const SizedBox(width: 40), 
                      ],
                    ),
                  ),

                // Timer bar & Controls
                if (_isCalibrationActive)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, _isLandscape ? 4 : 8, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: (widget.isBaseline || widget.durationSeconds == 0)
                              ? _buildStopwatchLabel(
                                  '${(_elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}',
                                  _isExerciseStarted && _idleCountdownSeconds <= 8,
                                )
                              : TimerBarWidget(
                                  remainingSeconds: _remainingSeconds,
                                  totalSeconds: widget.durationSeconds,
                                ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _switchCamera,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.neonRed.withValues(alpha: 0.4)),
                              color: AppColors.surfaceGlass,
                            ),
                            child: const Icon(Icons.cameraswitch, color: AppColors.neonRed, size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (widget.exerciseType.allowsLandscape)
                          GestureDetector(
                            onTap: _toggleOrientation,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _isLandscape ? AppColors.neonRed : AppColors.textMuted.withValues(alpha: 0.3),
                                ),
                                color: AppColors.surfaceGlass,
                              ),
                              child: Icon(
                                _isLandscape ? Icons.screen_lock_landscape : Icons.screen_rotation,
                                color: _isLandscape ? AppColors.neonRed : AppColors.textMuted,
                                size: 20,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _showDevStats = !_showDevStats),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _showDevStats ? AppColors.neonRed : AppColors.textMuted.withValues(alpha: 0.3),
                              ),
                              color: AppColors.surfaceGlass,
                            ),
                            child: Icon(
                              _showDevStats ? Icons.analytics : Icons.analytics_outlined,
                              color: _showDevStats ? AppColors.neonRed : AppColors.textMuted,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // HOLD warning
                if (_showHold) _buildHoldOverlay(),

                // Rep counter
                if (_isCalibrationActive)
                  Expanded(
                    child: Center(
                      child: RepCounterWidget(
                        count: _latestResult?.repCount ?? 0,
                        target: widget.targetReps,
                        label: widget.exerciseType.isHold ? 'SECONDS' : 'REPS',
                      ),
                    ),
                  ),

                // Form feedback
                if (_latestResult?.formFeedback != null && _isCalibrationActive)
                  Padding(
                    padding: EdgeInsets.only(top: _isLandscape ? 4 : 12),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.2),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.6)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          _latestResult!.formFeedback!,
                          style: GoogleFonts.orbitron(
                            fontSize: 10,
                            color: AppColors.danger,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),

                SizedBox(height: _isLandscape ? 8 : 20),

                // Bottom controls
                _buildBottomPanel(),
              ],
            ),
          ),

          // ── Overlays (Wrapped in ScrollViews to prevent overflow) ───────────
          if (_phase == CalibrationPhase.results) _buildResultsOverlay(),
          if (_phase == CalibrationPhase.success) _buildSuccessOverlay(),
          if (_phase == CalibrationPhase.warmup) _buildWarmupOverlay(),
          if (_isCountingDown) _buildCountdownOverlay(),
          if ((widget.isBaseline || widget.durationSeconds == 0) && _isExerciseStarted && _idleCountdownSeconds <= 5 && !_isCalibrationComplete)
            _buildIdleEndingOverlay(),

          // ── Development FPS Counter ───────────
          _buildDevelopmentFpsOverlay(),
        ],
      ),
    );
  }

  Widget _buildDevelopmentFpsOverlay() {
    if (!_showDevStats) return const SizedBox.shrink();
    return Positioned(
      top: _isLandscape ? 60 : 120, 
      left: 16,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            border: Border.all(color: AppColors.neonRed),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('DEV STATS', style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.neonRed, letterSpacing: 2)),
              const SizedBox(height: 4),
              Text('ML INFERENCE: ${_inferenceTimeMs}ms', style: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
              Text('MAX FPS: ${_inferenceTimeMs > 0 ? (1000 / _inferenceTimeMs).toStringAsFixed(1) : "0.0"}', style: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    
    // Fill the entire screen and crop overflow to avoid letterboxing
    return SizedBox.expand(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            double deviceRatio = size.width / size.height;
            double cameraRatio = controller.value.aspectRatio;
            
            // Flutter's CameraPreview automatically handles portrait/landscape aspect ratio flipping internally.
            bool isPortrait = size.width < size.height;
            double effectiveCameraRatio = isPortrait ? (1 / cameraRatio) : cameraRatio;
            
            double scale = 1.0;
            if (effectiveCameraRatio > deviceRatio) {
              scale = effectiveCameraRatio / deviceRatio;
            } else {
              scale = deviceRatio / effectiveCameraRatio;
            }
            
            return Transform.scale(
              scale: scale,
              child: Center(
                child: AspectRatio(
                  aspectRatio: effectiveCameraRatio,
                  child: CameraPreview(controller),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStopwatchLabel(String timeStr, bool isWarning) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: isWarning ? AppColors.neonRed : Colors.white10),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: isWarning ? AppColors.neonRed : AppColors.textSecondary, size: 14),
          const SizedBox(width: 8),
          Text(timeStr, style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(width: 12),
          Container(width: 1, height: 10, color: Colors.white24),
          const SizedBox(width: 12),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                !_isExerciseStarted ? (widget.exerciseType.isHold ? 'GET IN POSITION' : 'START FIRST REP') : isWarning ? 'STOP DETECTED — $_idleCountdownSeconds' : 'MAX EFFORT MODE',
                style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: isWarning ? AppColors.neonRed : AppColors.textSecondary, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withValues(alpha: 0.7),
            Colors.transparent,
            Colors.transparent,
            AppColors.background.withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.2, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    return Container(
      color: AppColors.background.withValues(alpha: 0.95),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('GET READY', style: GoogleFonts.orbitron(fontSize: 13, color: AppColors.textMuted, letterSpacing: 6)),
                SizedBox(height: _isLandscape ? 10 : 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: Text('$_preCountdownSeconds', key: ValueKey(_preCountdownSeconds), style: GoogleFonts.rajdhani(fontSize: _isLandscape ? 100 : 160, fontWeight: FontWeight.w900, color: AppColors.neonRed, height: 1)),
                ),
                SizedBox(height: _isLandscape ? 10 : 20),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'POSITION FOR ${widget.exerciseType.pluralName.toUpperCase()}', 
                    style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 3),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdleEndingOverlay() {
    return Container(
      color: AppColors.background.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ENDING IN', style: GoogleFonts.orbitron(fontSize: 24, color: AppColors.neonRed, letterSpacing: 6, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Text('$_idleCountdownSeconds', key: ValueKey('idle_$_idleCountdownSeconds'), style: GoogleFonts.rajdhani(fontSize: _isLandscape ? 100 : 180, fontWeight: FontWeight.w900, color: AppColors.neonRed, height: 1)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAbortAttempt() async {
    setState(() => _isHandlingExcuse = true);
    _tts.stop().then((_) { Future.delayed(const Duration(milliseconds: 30), () { if (mounted) _tts.speak("Are you quitting? Explain yourself."); }); });

    final excuseController = TextEditingController();
    bool isEvaluating = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(side: const BorderSide(color: AppColors.neonRed)),
              title: Text("// QUIT TEST?", style: GoogleFonts.orbitron(color: AppColors.neonRed, fontWeight: FontWeight.bold, letterSpacing: 2)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("DO YOU REALLY WANT TO STOP?", style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: excuseController,
                      maxLines: 2,
                      maxLength: 100,
                      style: GoogleFonts.spaceGrotesk(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Why are you stopping? Tell the Ustad...",
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceGlass,
                        border: InputBorder.none,
                        counterStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.neonRed.withValues(alpha: 0.3))),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.neonRed)),
                      ),
                    ),
                    if (isEvaluating) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonRed))),
                          const SizedBox(width: 12),
                          Text("USTAD EVALUATING EXCUSE...", style: GoogleFonts.orbitron(color: AppColors.neonRed, fontSize: 10, letterSpacing: 1)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isEvaluating ? null : () => Navigator.of(ctx).pop(),
                  child: Text("NEVERMIND", style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonRed),
                  onPressed: isEvaluating ? null : () async {
                    if (excuseController.text.trim().isEmpty) return;
                    setModalState(() => isEvaluating = true);
                    final response = await GeminiService.evaluateExcuse(excuseController.text.trim());
                    setModalState(() => isEvaluating = false);
                    if (!mounted || !ctx.mounted) return;
                    _tts.stop().then((_) { Future.delayed(const Duration(milliseconds: 30), () { if (mounted) _tts.speak(response); }); });
                    Navigator.of(ctx).pop();
                    if (response.startsWith('APPROVED')) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(response, style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1, color: Colors.black)), backgroundColor: AppColors.success, duration: const Duration(seconds: 4)));
                      _endCalibration();
                    } else {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(response, style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)), backgroundColor: AppColors.danger, duration: const Duration(seconds: 4)));
                    }
                  },
                  child: Text("SUBMIT EXCUSE", style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
    setState(() => _isHandlingExcuse = false);
  }

  Widget _buildHoldOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      margin: EdgeInsets.only(bottom: _isLandscape ? 5 : 20),
      decoration: BoxDecoration(
        color: AppColors.neonRed.withValues(alpha: 0.2),
        border: Border.all(color: AppColors.neonRed, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(AppStrings.hold, style: GoogleFonts.rajdhani(fontSize: _isLandscape ? 40 : 64, fontWeight: FontWeight.w700, color: AppColors.neonRed, letterSpacing: 8)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('DO NOT MOVE FOR 3 SECONDS', style: GoogleFonts.orbitron(fontSize: 10, color: AppColors.textPrimary, letterSpacing: 3)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    if (_isCalibrationActive) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, _isLandscape ? 6 : 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(border: Border.all(color: AppColors.neonRed.withValues(alpha: 0.4))),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.exerciseType.displayName.toUpperCase(),
                    style: GoogleFonts.orbitron(fontSize: 10, color: AppColors.neonRed, letterSpacing: 1),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 3,
              child: GestureDetector(
                onTap: _handleAbortAttempt,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.surfaceGlass, border: Border.all(color: AppColors.danger)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 12),
                      const SizedBox(width: 4),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('ABORT', style: GoogleFonts.orbitron(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: (_latestResult?.isGoodForm ?? false) ? AppColors.success.withValues(alpha: 0.4) : AppColors.danger.withValues(alpha: 0.4)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    (_latestResult?.isGoodForm ?? false) ? 'FORM: OK' : 'FORM: FIX',
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      color: (_latestResult?.isGoodForm ?? false) ? AppColors.success : AppColors.danger,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildWarmupOverlay() {
    return Container(
      color: AppColors.background.withValues(alpha: 0.9),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView( // Prevents overflow on small screens / landscape
            padding: EdgeInsets.all(_isLandscape ? 16 : 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _drillTitle,
                  style: GoogleFonts.rajdhani(fontSize: _isLandscape ? 28 : 36, fontWeight: FontWeight.w700, color: AppColors.neonRed, letterSpacing: 6),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: _isLandscape ? 20 : 40),
                Container(
                  padding: EdgeInsets.all(_isLandscape ? 16 : 24),
                  decoration: BoxDecoration(color: AppColors.surfaceGlass, border: Border.all(color: AppColors.neonRed.withValues(alpha: 0.3))),
                  child: Column(
                    children: [
                      Text('// USTAD SPEAKS', style: GoogleFonts.orbitron(fontSize: 9, color: AppColors.neonRed, letterSpacing: 3)),
                      const SizedBox(height: 16),
                      Text(
                        _ustadInstruction,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.rajdhani(fontSize: _isLandscape ? 18 : 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: _isLandscape ? 16 : 16),
                _ruleItem('1', 'POSITION FULL BODY IN FRAME'),
                ..._getExerciseSpecificRules(),
                _ruleItem('4', 'IF USTAD SAYS HOLD — FREEZE'),
                SizedBox(height: _isLandscape ? 20 : 40),
                SizedBox(
                  width: double.infinity,
                  child: TacticalButton(
                    onTap: _isCameraInitialized ? _startCalibrationMode : () {},
                    soundType: TacticalSoundType.missionComplete,
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.neonRed, borderRadius: BorderRadius.circular(4)),
                      padding: EdgeInsets.symmetric(vertical: _isLandscape ? 16 : 24, horizontal: 20),
                      alignment: Alignment.center,
                      child: Text(
                        _isCameraInitialized ? 'START ${_exerciseName.toUpperCase()} DRILL' : 'INITIALIZING CAMERA...',
                        style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 3, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ruleItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Container(
            width: 24, height: 24, alignment: Alignment.center,
            decoration: BoxDecoration(border: Border.all(color: AppColors.neonRed.withValues(alpha: 0.4))),
            child: Text(number, style: GoogleFonts.orbitron(fontSize: 10, color: AppColors.neonRed, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.orbitron(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 1))),
        ],
      ),
    );
  }

  Widget _buildResultsOverlay() {
    final totalScore = _completedReps;
    final previousBestText = _isLoadingPreviousBest ? '...' : (_previousBestReps?.toString() ?? 'N/A');

    return Container(
      color: AppColors.background.withValues(alpha: 0.95),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView( // Overflow protection
            padding: EdgeInsets.all(_isLandscape ? 16 : 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_exerciseName DRILL COMPLETE',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rajdhani(fontSize: _isLandscape ? 24 : 30, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 4),
                ),
                const SizedBox(height: 12),
                Container(width: 80, height: 2, color: AppColors.neonRed),
                SizedBox(height: _isLandscape ? 20 : 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRecordNode(widget.exerciseType.isHold ? 'SECONDS' : 'TOTAL REPS', '$_completedReps'),
                    if (widget.targetReps != null)
                      _buildRecordNode('TARGET', '${widget.targetReps}')
                    else if (widget.durationSeconds == 0)
                      _buildRecordNode('ELAPSED', '${(_elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}')
                    else
                      _buildRecordNode('PREVIOUS BEST', previousBestText),
                  ],
                ),
                SizedBox(height: _isLandscape ? 20 : 40),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.surfaceGlass, border: Border.all(color: AppColors.neonRed.withValues(alpha: 0.2))),
                  child: Column(
                    children: [
                      Text('// ASSESSMENT', style: GoogleFonts.orbitron(fontSize: 9, color: AppColors.neonRed, letterSpacing: 3)),
                      const SizedBox(height: 12),
                      Text(
                        _previousBestReps != null && _completedReps > _previousBestReps!
                            ? 'NEW PERSONAL BEST. KEEP THIS STANDARD.'
                            : _getAssessment(totalScore),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.rajdhani(fontSize: _isLandscape ? 16 : 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: _isLandscape ? 20 : 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _disposeCamera();
                      if (mounted) context.go(AppRoutes.strengthTestSetup);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: _isLandscape ? 14 : 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: const BorderSide(color: AppColors.neonRed)),
                    ),
                    child: Text('REPERFORM TEST', style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 2.5, color: AppColors.neonRed)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isGeneratingPlan
                        ? null
                        : () async {
                            setState(() => _isGeneratingPlan = true);
                            await _disposeCamera();
                            if (widget.isBaseline) {
                              if (mounted) Navigator.of(context).pop();
                            } else {
                              if (mounted) {
                                Navigator.of(context).pop(<String, dynamic>{
                                  'completedReps': _completedReps,
                                  'elapsedSeconds': widget.durationSeconds == 0 ? _elapsedSeconds : widget.durationSeconds,
                                });
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonRed,
                      padding: EdgeInsets.symmetric(vertical: _isLandscape ? 16 : 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text(
                      _isGeneratingPlan ? 'SAVING...' : (widget.isBaseline ? 'SAVE RESULT  ✓' : 'SAVE RESULT'),
                      style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 3, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: AppColors.background.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 80),
            const SizedBox(height: 24),
            Text('GOOD JOB', style: GoogleFonts.orbitron(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
            const SizedBox(height: 12),
            Text('DRILL DATA SECURED', style: GoogleFonts.spaceMono(fontSize: 12, color: AppColors.success, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordNode(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.rajdhani(fontSize: _isLandscape ? 36 : 48, fontWeight: FontWeight.w700, color: AppColors.neonRed, height: 1.0)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.orbitron(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 2)),
      ],
    );
  }

  String _getAssessment(int score) {
    if (score < 12) return 'BASELINE CAPTURED. WE BUILD FROM HERE.';
    if (score < 25) return 'SOLID WORK. NEXT DRILL: CLEANER DEPTH AND RHYTHM.';
    if (score < 40) return 'STRONG OUTPUT. MAINTAIN FORM UNDER FATIGUE.';
    return 'ELITE BASELINE. NOW PROVE IT CONSISTENTLY.';
  }

  List<Widget> _getExerciseSpecificRules() {
    switch (widget.exerciseType) {
      case ExerciseType.squat: return [_ruleItem('2', 'BREAK 90° AT THE KNEE'), _ruleItem('3', 'STAND FULLY BETWEEN EACH REP')];
      case ExerciseType.pushup: return [_ruleItem('2', 'ARMS SHOULDER-WIDTH APART'), _ruleItem('3', 'CHEST MUST NEARLY TOUCH FLOOR')];
      case ExerciseType.jumpSquat: return [_ruleItem('2', 'EXPLOSIVE JUMP AT THE TOP'), _ruleItem('3', 'LAND SOFTLY ON YOUR FEET')];
      case ExerciseType.lunge: return [_ruleItem('2', 'BACK KNEE MUST NEARLY TOUCH FLOOR'), _ruleItem('3', 'KEEP TORSO UPRIGHT')];
      case ExerciseType.situp: return [_ruleItem('2', 'ELBOWS MUST TOUCH KNEES'), _ruleItem('3', 'SHOULDERS MUST TOUCH FLOOR')];
      case ExerciseType.burpee: return [_ruleItem('2', 'FULL CHEST-TO-FLOOR CONTACT'), _ruleItem('3', 'VERTICAL JUMP AND CLAP')];
      case ExerciseType.plank: return [_ruleItem('2', 'MAINTAIN A STRAIGHT LINE'), _ruleItem('3', 'NO SAGGING OR ARCHING HIPS')];
      case ExerciseType.wallSit: return [_ruleItem('2', 'LEAN AGAINST THE WALL'), _ruleItem('3', 'HOLD TILL THE TIMER ENDS')];
      case ExerciseType.jumpingJacks: return [_ruleItem('2', 'ARMS OVER HEAD'), _ruleItem('3', 'FEET WIDE APART')];
      case ExerciseType.pullup: return [_ruleItem('2', 'CHIN OVER BAR'), _ruleItem('3', 'FULL EXTENSION AT BOTTOM')];
      case ExerciseType.crunch: return [_ruleItem('2', 'LIFT SHOULDERS OFF MAT'), _ruleItem('3', 'TIGHTEN CORE AT TOP')];
    }
  }

  Widget _buildSessionTimerLabel() {
    final now = DateTime.now();
    final diff = now.difference(widget.sessionStartTime ?? now);
    final formatted = _formatDuration(diff);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(border: Border.all(color: AppColors.neonRed.withValues(alpha: 0.3)), color: AppColors.neonRed.withValues(alpha: 0.05)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('TOTAL ELAPSED', style: GoogleFonts.spaceMono(fontSize: 6, color: AppColors.neonRed, fontWeight: FontWeight.bold, letterSpacing: 1)),
          Text(formatted, style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}:${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    } else {
      return '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    }
  }
}

class SquatSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.neonRed.withValues(alpha: 0.6)..strokeWidth = 20..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final headPaint = Paint()..color = AppColors.neonRed.withValues(alpha: 0.8)..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height * 0.45;
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - 180), width: 60, height: 75), headPaint);
    canvas.drawLine(Offset(cx, cy - 140), Offset(cx, cy + 40), paint);
    canvas.drawLine(Offset(cx, cy + 40), Offset(cx + 80, cy + 60), paint);
    canvas.drawLine(Offset(cx + 80, cy + 60), Offset(cx + 60, cy + 200), paint);
    canvas.drawLine(Offset(cx, cy - 100), Offset(cx + 120, cy - 100), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum CalibrationPhase { warmup, active, results, success }
