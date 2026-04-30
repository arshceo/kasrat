import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_type.dart';
import 'exercise_tracker.dart';
import 'trackers/pushup_tracker.dart';
import 'trackers/squat_trackers.dart';
import 'trackers/plank_tracker.dart';
import 'trackers/lunge_tracker.dart';
import 'trackers/wall_sit_tracker.dart';
import 'trackers/situp_tracker.dart';
import 'trackers/jump_squat_tracker.dart';
import 'trackers/burpee_tracker.dart';

export 'exercise_type.dart';
export 'exercise_tracker.dart' show ExercisePhase, PoseAnalysisResult;

/// Core exercise analysis engine for Ustad AI.
class PoseAnalyzer {
  BaseExerciseTracker? _activeTracker;
  final bool _forceSideOnlyPushup;
  ExerciseType? _currentType;

  int get repCount => _activeTracker?.repCount ?? 0;
  ExercisePhase get currentPhase => _activeTracker?.currentPhase ?? ExercisePhase.resting;

  PoseAnalyzer({bool forceSideOnlyPushup = true})
    : _forceSideOnlyPushup = forceSideOnlyPushup;

  void reset() {
    _activeTracker?.reset();
  }

  PoseAnalysisResult analyzePose(Pose pose, ExerciseType type) {
    if (_activeTracker == null || _currentType != type) {
      _currentType = type;
      switch (type) {
        case ExerciseType.pushup:
          _activeTracker = PushupTracker(forceSideOnlyPushup: _forceSideOnlyPushup);
          break;
        case ExerciseType.squat:
          _activeTracker = SquatTracker();
          break;
        case ExerciseType.jumpSquat:
          _activeTracker = JumpSquatTracker();
          break;
        case ExerciseType.situp:
          _activeTracker = SitupTracker();
          break;
        case ExerciseType.lunge:
          _activeTracker = LungeTracker();
          break;
        case ExerciseType.burpee:
          _activeTracker = BurpeeTracker();
          break;
        case ExerciseType.plank:
          _activeTracker = PlankTimer();
          break;
        case ExerciseType.wallSit:
          _activeTracker = WallSitTracker();
          break;
        case ExerciseType.jumpingJacks:
        case ExerciseType.pullup:
        case ExerciseType.crunch:
          // Fallback or generic tracker
          _activeTracker = null; 
          break;
      }
    }

    if (_activeTracker == null) {
      return const PoseAnalysisResult(
        phase: ExercisePhase.resting,
        repCount: 0,
        isGoodForm: false,
        formFeedback: 'UNKNOWN EXERCISE',
      );
    }

    // ==========================================
    // THE GLOBAL ANTI-GHOST KILL SWITCH
    // ==========================================
    final landmarks = pose.landmarks;
    final lShoulder = landmarks[PoseLandmarkType.leftShoulder]?.likelihood ?? 0.0;
    final rShoulder = landmarks[PoseLandmarkType.rightShoulder]?.likelihood ?? 0.0;
    final lHip = landmarks[PoseLandmarkType.leftHip]?.likelihood ?? 0.0;
    final rHip = landmarks[PoseLandmarkType.rightHip]?.likelihood ?? 0.0;
    final maxCoreConfidence = [lShoulder, rShoulder, lHip, rHip].reduce(max);

    if (maxCoreConfidence < 0.6) {
      _activeTracker!.consecutiveLowConfidenceFrames++;
      if (_activeTracker!.consecutiveLowConfidenceFrames > 3) {
        return PoseAnalysisResult(
          phase: _activeTracker!.currentPhase,
          repCount: _activeTracker!.repCount,
          isGoodForm: false,
          formFeedback: 'TARGET LOST. STEP IN FRAME.',
        );
      }
      return PoseAnalysisResult(
        phase: _activeTracker!.currentPhase,
        repCount: _activeTracker!.repCount,
        isGoodForm: false,
      );
    }
    _activeTracker!.consecutiveLowConfidenceFrames = 0;

    // Route the valid frame to the active tracker
    return _activeTracker!.processPose(pose);
  }
}
