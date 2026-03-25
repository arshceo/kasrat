import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/constants/app_constants.dart';
import '../painters/skeleton_painter.dart';
import '../services/pose_analyzer.dart';
import '../widgets/rep_counter_widget.dart';
import '../widgets/timer_bar_widget.dart';
import '../../ai/services/gemini_service.dart';

/// Screen A-02: "The Calibration Test" — Day 0 Baseline.
///
/// Full-screen camera with ML Kit skeletal overlay.
/// Massive rep counter, 60-second countdown, Ustad instructions.
class CalibrationScreen extends StatefulWidget {
  final bool isFirstTime;
  final ExerciseType exerciseType;
  final int durationSeconds;
  final bool voiceTriggerEnabled;

  const CalibrationScreen({
    super.key,
    this.isFirstTime = true,
    this.exerciseType = ExerciseType.squat,
    this.durationSeconds = 60,
    this.voiceTriggerEnabled = false,
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
  bool _isCalibrationActive = false;
  bool _isCalibrationComplete = false;

  // Pre-exercise countdown
  bool _isCountingDown = false;
  int _preCountdownSeconds = 10;
  Timer? _preCountdownTimer;

  // TTS for rep counting & countdown
  final FlutterTts _tts = FlutterTts();
  int _lastSpokenRep = 0;
  final List<String> _repWords = [
    '',
    'ONE',
    'TWO',
    'THREE',
    'FOUR',
    'FIVE',
    'SIX',
    'SEVEN',
    'EIGHT',
    'NINE',
    'TEN',
    'ELEVEN',
    'TWELVE',
    'THIRTEEN',
    'FOURTEEN',
    'FIFTEEN',
    'SIXTEEN',
    'SEVENTEEN',
    'EIGHTEEN',
    'NINETEEN',
    'TWENTY',
    'TWENTY ONE',
    'TWENTY TWO',
    'TWENTY THREE',
    'TWENTY FOUR',
    'TWENTY FIVE',
    'TWENTY SIX',
    'TWENTY SEVEN',
    'TWENTY EIGHT',
    'TWENTY NINE',
    'THIRTY',
  ];

  // Voice STOP/GO detection
  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListeningForGo = false;

  // Camera switching
  bool _isFrontCamera = true;
  int _currentCameraIndex = 0;

  // Exercise tracking
  final int _squatReps = 0;
  final int _pushupReps = 0;
  final int _plankSeconds = 0;

  // UI state
  CalibrationPhase _phase = CalibrationPhase.warmup;
  bool _showHold = false;
  bool _isGeneratingPlan = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remainingSeconds = widget.durationSeconds;
    _initCamera();
    _initTts();
    if (widget.voiceTriggerEnabled) {
      _initSpeech().then((_) {
        // Preëmptively listen for GO if we are in warmup phase
        if (_phase == CalibrationPhase.warmup && !_isCountingDown) {
          _startVoiceGoListener();
        }
      });
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.85);
    await _tts.setVolume(1.0);
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (e) => debugPrint('STT Error: $e'),
      onStatus: (status) => debugPrint('STT Status: $status'),
    );
  }

  /// 10-second pre-exercise countdown with TTS
  void _startPreCountdown() {
    if (_isCountingDown) return;
    _stopListeningForGo();
    setState(() {
      _isCountingDown = true;
      _preCountdownSeconds = 10;
    });
    _tts.speak('Get ready!');
    _preCountdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _preCountdownSeconds--);
      if (_preCountdownSeconds > 0) {
        _tts.speak('$_preCountdownSeconds');
      } else {
        t.cancel();
        _tts.speak('GO!');
        setState(() => _isCountingDown = false);
        _startCalibration();
      }
    });
  }

  /// Speak rep number if it changed
  void _speakRepIfNew(int repCount) {
    if (repCount > _lastSpokenRep && repCount > 0) {
      _lastSpokenRep = repCount;
      final word = repCount < _repWords.length
          ? _repWords[repCount]
          : '$repCount';
      _tts.speak(word);
    }
  }

  DateTime _lastFeedbackTime = DateTime.fromMillisecondsSinceEpoch(0);
  String? _lastSpokenFeedback;

  void _speakFeedbackIfNew(String? feedback) {
    if (feedback == null || feedback.isEmpty) return;
    final now = DateTime.now();
    if (feedback != _lastSpokenFeedback ||
        now.difference(_lastFeedbackTime).inSeconds > 4) {
      if (feedback == 'FULL DEPTH REQUIRED') {
        _tts.speak('More depth!');
      } else if (feedback == 'STAND UP FULLY') {
        _tts.speak('Stand up!');
      } else if (feedback == 'CHEST MUST NEARLY TOUCH FLOOR' ||
          feedback == 'GO DEEPER') {
        _tts.speak('Go lower!');
      }
      _lastSpokenFeedback = feedback;
      _lastFeedbackTime = now;
    }
  }

  /// Start voice GO listener
  void _startVoiceGoListener() {
    if (!_speechAvailable || !widget.voiceTriggerEnabled) return;
    setState(() => _isListeningForGo = true);
    _speech.listen(
      onResult: (r) {
        if (r.recognizedWords.toUpperCase().contains('GO') && mounted) {
          _speech.stop();
          _startPreCountdown();
        }
      },
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(minutes: 5),
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  void _stopListeningForGo() {
    _speech.stop();
    setState(() => _isListeningForGo = false);
  }

  /// Start voice STOP listener
  void _startVoiceStopListener() {
    if (!_speechAvailable || !widget.voiceTriggerEnabled) return;
    _speech.listen(
      onResult: (r) {
        if (r.recognizedWords.toUpperCase().contains('STOP') && mounted) {
          _speech.stop();
          _endCalibration();
        }
      },
      listenFor: const Duration(minutes: 30),
      pauseFor: const Duration(minutes: 30),
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> _disposeCamera() async {
    // CRITICAL: Set flag to false SYNCHRONOUSLY first so no rebuild
    // can reach _buildCameraPreview with a disposed/null controller.
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
    _tts.stop();
    _speech.stop();
    final controller = _cameraController;
    _cameraController = null;
    _isCameraInitialized = false;
    controller?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
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
    if (_isProcessing || !_isCalibrationActive) return;

    _isProcessing = true;

    try {
      final startTracker = DateTime.now();

      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final poses = await _poseDetector.processImage(inputImage);

      final endTracker = DateTime.now();

      if (poses.isNotEmpty && mounted) {
        // Always use the exercise chosen on the setup screen
        final result = _poseAnalyzer.analyzePose(
          poses.first,
          widget.exerciseType,
        );

        setState(() {
          _inferenceTimeMs = endTracker.difference(startTracker).inMilliseconds;
          _currentPose = poses.first;
          _latestResult = result;
          _imageSize = Size(image.width.toDouble(), image.height.toDouble());

          // Handle HOLD state
          if (result.holdTriggered && !_showHold) {
            _showHold = true;
          }
          if (result.holdPassed) {
            _showHold = false;
          }
        });

        // TTS rep counting (outside setState to avoid reentrance)
        _speakRepIfNew(result.repCount);

        // Form feedback TTS
        if (!result.isGoodForm && result.formFeedback != null) {
          _speakFeedbackIfNew(result.formFeedback);
        }
      }
    } catch (e) {
      debugPrint('Pose detection error: $e');
    }

    _isProcessing = false;
  }

  InputImage? _convertCameraImage(CameraImage image) {
    final camera = _cameras![_currentCameraIndex];

    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;
    _imageRotation = rotation;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void _startCalibration() {
    _poseAnalyzer.reset();
    _lastSpokenRep = 0;
    final phase = widget.exerciseType == ExerciseType.squat
        ? CalibrationPhase.squat
        : CalibrationPhase.pushup;
    setState(() {
      _phase = phase;
      _isCalibrationActive = true;
      _remainingSeconds = widget.durationSeconds;
    });
    _startVoiceStopListener();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          timer.cancel();
          _endCalibration();
        }
      });
    });
  }

  void _endCalibration() {
    _countdownTimer?.cancel();
    setState(() {
      _isCalibrationActive = false;
      _isCalibrationComplete = true;
      _phase = CalibrationPhase.results;
    });
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

          // ── Silhouette Overlay (Squats Only) ────────────────────
          if (widget.exerciseType == ExerciseType.squat &&
              (_phase == CalibrationPhase.warmup || _isCountingDown))
            Positioned.fill(
              child: CustomPaint(painter: SquatSilhouettePainter()),
            ),

          // ── UI Layer ────────────────────────────────────────────
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
                // Timer bar (top) + camera switch button
                if (_isCalibrationActive)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TimerBarWidget(
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
                              border: Border.all(
                                color: AppColors.neonRed.withValues(alpha: 0.4),
                              ),
                              color: AppColors.surfaceGlass,
                            ),
                            child: const Icon(
                              Icons.cameraswitch,
                              color: AppColors.neonRed,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // HOLD warning overlay
                if (_showHold) _buildHoldOverlay(),

                // Rep counter / Tracker (center)
                if (_isCalibrationActive)
                  RepCounterWidget(
                    count: _phase == CalibrationPhase.plank
                        ? _plankSeconds
                        : _latestResult?.repCount ?? 0,
                    label: _phase == CalibrationPhase.plank
                        ? 'SECONDS'
                        : 'REPS',
                  ),

                // Form feedback
                if (_latestResult?.formFeedback != null && _isCalibrationActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.2),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        _latestResult!.formFeedback!,
                        style: GoogleFonts.orbitron(
                          fontSize: 10,
                          color: AppColors.danger,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                const Spacer(),

                // Bottom controls
                _buildBottomPanel(),
              ],
            ),
          ),

          // ── Results overlay ─────────────────────────────────────
          if (_isCalibrationComplete) _buildResultsOverlay(),

          // ── Warmup overlay ──────────────────────────────────────
          if (_phase == CalibrationPhase.warmup) _buildWarmupOverlay(),

          // ── Pre-exercise countdown overlay ─────────────────────
          if (_isCountingDown) _buildCountdownOverlay(),

          // ── Development FPS Counter ──────────────────────────────
          _buildDevelopmentFpsOverlay(),
        ],
      ),
    );
  }

  Widget _buildDevelopmentFpsOverlay() {
    return Positioned(
      top: 60,
      left: 16,
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
            Text(
              'DEV STATS',
              style: GoogleFonts.orbitron(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.neonRed,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ML INFERENCE: ${_inferenceTimeMs}ms',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'MAX POTENTIAL FPS: ${_inferenceTimeMs > 0 ? (1000 / _inferenceTimeMs).toStringAsFixed(1) : "0.0"}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    // Take a local, null-safe snapshot to avoid the race condition where
    // setState(_isCameraInitialized=false) is scheduled but a rebuild fires
    // before it executes, accessing a disposed controller.
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize!.height,
          height: controller.value.previewSize!.width,
          child: CameraPreview(controller),
        ),
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'GET READY',
              style: GoogleFonts.orbitron(
                fontSize: 13,
                color: AppColors.textMuted,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                '$_preCountdownSeconds',
                key: ValueKey(_preCountdownSeconds),
                style: GoogleFonts.rajdhani(
                  fontSize: 160,
                  fontWeight: FontWeight.w900,
                  color: AppColors.neonRed,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.exerciseType == ExerciseType.squat
                  ? 'POSITION FOR SQUATS'
                  : 'POSITION FOR PUSH-UPS',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoldOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.neonRed.withValues(alpha: 0.2),
        border: Border.all(color: AppColors.neonRed, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.hold,
            style: GoogleFonts.rajdhani(
              fontSize: 64,
              fontWeight: FontWeight.w700,
              color: AppColors.neonRed,
              letterSpacing: 8,
            ),
          ),
          Text(
            'DO NOT MOVE FOR 3 SECONDS',
            style: GoogleFonts.orbitron(
              fontSize: 10,
              color: AppColors.textPrimary,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    if (_isCalibrationActive) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Phase indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.neonRed.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                _phase.name.toUpperCase(),
                style: GoogleFonts.orbitron(
                  fontSize: 9,
                  color: AppColors.neonRed,
                  letterSpacing: 2,
                ),
              ),
            ),
            // Form status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: (_latestResult?.isGoodForm ?? false)
                      ? AppColors.success.withValues(alpha: 0.4)
                      : AppColors.danger.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                (_latestResult?.isGoodForm ?? false)
                    ? 'FORM: GOOD'
                    : 'FORM: FIX',
                style: GoogleFonts.orbitron(
                  fontSize: 9,
                  color: (_latestResult?.isGoodForm ?? false)
                      ? AppColors.success
                      : AppColors.danger,
                  letterSpacing: 2,
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
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Calibration header
              Text(
                AppStrings.calibrationTitle,
                style: GoogleFonts.rajdhani(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neonRed,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 40),

              // Instructions
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGlass,
                  border: Border.all(
                    color: AppColors.neonRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '// USTAD SPEAKS',
                      style: GoogleFonts.orbitron(
                        fontSize: 9,
                        color: AppColors.neonRed,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.calibrationInstruction,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rajdhani(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.4,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Rules
              _ruleItem('1', 'POSITION YOUR FULL BODY IN FRAME'),
              if (widget.exerciseType == ExerciseType.squat) ...[
                _ruleItem('2', 'SQUATS MUST BREAK 90° AT THE KNEE'),
                _ruleItem('3', 'STAND FULLY BETWEEN EACH REP'),
              ] else ...[
                _ruleItem('2', 'ARMS SHOULDER-WIDTH APART'),
                _ruleItem('3', 'CHEST MUST NEARLY TOUCH FLOOR'),
              ],
              _ruleItem('4', 'IF THE USTAD SAYS HOLD — FREEZE'),

              const SizedBox(height: 40),

              // Start button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCameraInitialized ? _startPreCountdown : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonRed,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    _isCameraInitialized
                        ? (widget.voiceTriggerEnabled
                              ? 'SAY "GO" OR PRESS TO START'
                              : 'START ACCLIMATIZATION')
                        : 'INITIALIZING CAMERA...',
                    style: GoogleFonts.orbitron(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (widget.isFirstTime) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () async {
                      // Skip directly to dashboard without scoring
                      await _disposeCamera();
                      if (mounted) context.go(AppRoutes.dashboard);
                    },
                    child: Text(
                      'SKIP ASSESSMENT →',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: AppColors.textMuted,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ],
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
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.neonRed.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              number,
              style: GoogleFonts.orbitron(
                fontSize: 10,
                color: AppColors.neonRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.orbitron(
                fontSize: 10,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsOverlay() {
    final totalScore = _squatReps + _pushupReps + _plankSeconds;
    return Container(
      color: AppColors.background.withValues(alpha: 0.95),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.protocolInitialized,
                style: GoogleFonts.rajdhani(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Container(width: 60, height: 2, color: AppColors.success),
              const SizedBox(height: 40),

              // Score breakdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildScoreNode('SQUATS', _squatReps),
                  _buildScoreNode('PUSHUPS', _pushupReps),
                  _buildScoreNode('PLANK', _plankSeconds, unit: 'S'),
                ],
              ),
              const SizedBox(height: 40),

              // Assessment
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGlass,
                  border: Border.all(
                    color: AppColors.neonRed.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '// ASSESSMENT',
                      style: GoogleFonts.orbitron(
                        fontSize: 9,
                        color: AppColors.neonRed,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getAssessment(totalScore),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rajdhani(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isGeneratingPlan
                      ? null
                      : () async {
                          setState(() => _isGeneratingPlan = true);
                          try {
                            await GeminiService.generateWorkoutPlan(
                              calibrationScore: totalScore,
                              language: 'en',
                            );
                          } catch (e) {
                            debugPrint('Plan generation error: $e');
                          }
                          // Dispose camera BEFORE navigation to prevent leak
                          await _disposeCamera();
                          if (mounted) context.go(AppRoutes.dashboard);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonRed,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    _isGeneratingPlan
                        ? 'GENERATING PROTOCOL...'
                        : 'ACCEPT PROTOCOL',
                    style: GoogleFonts.orbitron(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: Colors.white,
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

  Widget _buildScoreNode(String label, int score, {String unit = ''}) {
    return Column(
      children: [
        Text(
          '$score$unit',
          style: GoogleFonts.rajdhani(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: AppColors.neonRed,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.orbitron(
            fontSize: 10,
            color: AppColors.textSecondary,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  String _getAssessment(int score) {
    if (score < 30) {
      return 'PATHETIC. THE USTAD EXPECTED AS MUCH.\nYOU HAVE 28 DAYS TO PROVE HIM WRONG.';
    } else if (score < 60) {
      return 'WEAK, BUT NOT HOPELESS.\nTHE PROTOCOL WILL FIX YOU.';
    } else if (score < 90) {
      return 'ACCEPTABLE.\nBUT YOU HAVEN\'T EARNED THE USTAD\'S RESPECT YET.';
    } else {
      return 'IMPRESSIVE. THE USTAD IS... SLIGHTLY LESS DISAPPOINTED.\nLET\'S SEE IF YOU CAN MAINTAIN THIS FOR 28 DAYS.';
    }
  }
}

/// Custom painter for the side-profile Squat Silhouette
class SquatSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neonRed.withValues(alpha: 0.6)
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final headPaint = Paint()
      ..color = AppColors.neonRed.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // Base coordinates
    final cx = size.width / 2;
    // Lower slightly so the head is in the upper third
    final cy = size.height * 0.45;

    // Head (facing Right)
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy - 180), width: 60, height: 75),
      headPaint,
    );

    // Spine
    canvas.drawLine(Offset(cx, cy - 140), Offset(cx, cy + 40), paint);

    // Thigh (angled slightly to create mild squat stance)
    canvas.drawLine(Offset(cx, cy + 40), Offset(cx + 80, cy + 60), paint);

    // Calf (straight down to the ground)
    canvas.drawLine(Offset(cx + 80, cy + 60), Offset(cx + 60, cy + 200), paint);

    // Arm (reaching straight forward parallel to ground)
    canvas.drawLine(Offset(cx, cy - 100), Offset(cx + 120, cy - 100), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum CalibrationPhase { warmup, squat, pushup, plank, results }
