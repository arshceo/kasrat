import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';

/// Exercise detection state machine.
enum ExercisePhase { resting, descending, active, ascending }

/// Result of analyzing a single frame.
class PoseAnalysisResult {
  final double? leftMainAngle;
  final double? rightMainAngle;
  final double? effectiveAngle;
  final ExercisePhase phase;
  final int repCount;
  final bool isGoodForm;
  final bool holdTriggered;
  final bool holdPassed;
  final String? formFeedback;

  const PoseAnalysisResult({
    this.leftMainAngle,
    this.rightMainAngle,
    this.effectiveAngle,
    required this.phase,
    required this.repCount,
    required this.isGoodForm,
    this.holdTriggered = false,
    this.holdPassed = false,
    this.formFeedback,
  });
}

abstract class BaseExerciseTracker {
  ExercisePhase currentPhase = ExercisePhase.resting;
  int repCount = 0;
  DateTime? lastRepTime;
  int consecutiveLowConfidenceFrames = 0;
  String? lastFeedback;

  // Anti-cheat HOLD tracking
  bool _holdActive = false;
  DateTime? _holdStartTime;
  final Random _random = Random();
  int _nextHoldRep = -1;

  // Static hold tracking (seconds)
  bool isHold = false;
  DateTime? _activeStartTime;
  int _lastAccumulatedHoldSeconds = 0;

  BaseExerciseTracker() {
    _scheduleNextHold();
  }

  void _scheduleNextHold() {
    _nextHoldRep = repCount + 5 + _random.nextInt(11);
  }

  // The universal debounce
  void incrementRep() {
    if (isHold) return; // Holds use second-counting, not rep-counting
    final now = DateTime.now();
    if (lastRepTime == null ||
        now.difference(lastRepTime!) > const Duration(milliseconds: 450)) {
      repCount++;
      lastRepTime = now;
    }
  }

  void updateHoldTime() {
    if (!isHold) return;
    if (currentPhase == ExercisePhase.active) {
      if (_activeStartTime == null) {
        _activeStartTime = DateTime.now();
      } else {
        final elapsed = DateTime.now().difference(_activeStartTime!).inSeconds;
        repCount = _lastAccumulatedHoldSeconds + elapsed;
      }
    } else {
      if (_activeStartTime != null) {
        _lastAccumulatedHoldSeconds = repCount;
        _activeStartTime = null;
      }
    }
  }

  // Every specific exercise must implement this:
  PoseAnalysisResult processPose(Pose pose);

  void reset() {
    currentPhase = ExercisePhase.resting;
    repCount = 0;
    lastRepTime = null;
    consecutiveLowConfidenceFrames = 0;
    lastFeedback = null;
    _holdActive = false;
    _holdStartTime = null;
    _activeStartTime = null;
    _lastAccumulatedHoldSeconds = 0;
    _scheduleNextHold();
  }

  PoseAnalysisResult applyHoldLogic(
    double effectiveAngle,
    bool isGoodForm,
    String? feedback,
  ) {
    bool holdTriggered = false;
    bool holdPassed = false;

    if (repCount >= _nextHoldRep && !_holdActive) {
      _holdActive = true;
      _holdStartTime = DateTime.now();
      holdTriggered = true;
    }

    if (_holdActive) {
      holdTriggered = true;
      final elapsed = DateTime.now().difference(_holdStartTime!);
      if (elapsed >= ExerciseConstants.holdDuration) {
        _holdActive = false;
        holdPassed = true;
        _scheduleNextHold();
      }
    }

    return PoseAnalysisResult(
      leftMainAngle: effectiveAngle,
      rightMainAngle: effectiveAngle,
      effectiveAngle: effectiveAngle,
      phase: currentPhase,
      repCount: repCount,
      isGoodForm: isGoodForm,
      holdTriggered: holdTriggered,
      holdPassed: holdPassed,
      formFeedback: feedback,
    );
  }
}
