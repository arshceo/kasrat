import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../exercise_tracker.dart';
import '../pose_math.dart';

class SitupTracker extends BaseExerciseTracker {
  double? _smoothedCoreAngle;

  // HELPER: True 2D Distance (Fixes the "Turn 90 Degrees" bug when lying flat)
  double _distance(PoseLandmark a, PoseLandmark b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
  }

  @override
  void reset() {
    super.reset();
    _smoothedCoreAngle = null;
  }

  @override
  PoseAnalysisResult processPose(Pose pose) {
    bool isGoodForm = true;
    String? feedback;

    final landmarks = pose.landmarks;
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];

    // 1. THE JOINT GUILLOTINE
    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null ||
        leftKnee == null ||
        rightKnee == null) {
      return PoseAnalysisResult(
        phase: currentPhase,
        repCount: repCount,
        isGoodForm: false,
        formFeedback: 'FULL BODY REQUIRED',
      );
    }

    // 2. STRICT SIDE-PROFILE ENFORCEMENT (FIXED)
    final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();

    // Using true distance. If we only used 'Y', lying flat makes torsoLength 0!
    final torsoLength = _distance(leftShoulder, leftHip);

    if (shoulderWidth > (torsoLength * 0.45) &&
        leftShoulder.likelihood > 0.6 &&
        rightShoulder.likelihood > 0.6) {
      return PoseAnalysisResult(
        phase: currentPhase,
        repCount: repCount,
        isGoodForm: false,
        formFeedback: 'TURN 90 DEGREES (SIDE VIEW)',
      );
    }

    // 3. IDENTIFY DOMINANT SIDE
    final isLeft = leftShoulder.likelihood > rightShoulder.likelihood;
    final domShoulder = isLeft ? leftShoulder : rightShoulder;
    final domHip = isLeft ? leftHip : rightHip;
    final domKnee = isLeft ? leftKnee : rightKnee;

    if (domShoulder.likelihood < 0.6 ||
        domHip.likelihood < 0.6 ||
        domKnee.likelihood < 0.6) {
      return PoseAnalysisResult(
        phase: currentPhase,
        repCount: repCount,
        isGoodForm: false,
        formFeedback: 'SIDE PROFILE REQUIRED',
      );
    }

    // 4. THE FLEXION ANGLE (For cheat-detection)
    final rawCoreAngle = PoseMath.calculateJointAngle(
      domShoulder,
      domHip,
      domKnee,
    );
    _smoothedCoreAngle = PoseMath.smoothAngle(
      rawCoreAngle,
      _smoothedCoreAngle ?? rawCoreAngle,
      alpha: 0.3,
    );
    final coreAngle = _smoothedCoreAngle!;

    // 5. THE ELEVATION LOCK (Relative to the floor: 0° is flat, 90° is straight up)
    final dy = (domShoulder.y - domHip.y).abs();
    final dx = (domShoulder.x - domHip.x).abs();
    final torsoSlope = atan2(dy, dx) * 180 / pi;

    // 6. THE STATE MACHINE (Rewritten for the 45-degree sit-up arc)
    switch (currentPhase) {
      case ExercisePhase.resting:
        // Lying flat on the floor (torsoSlope is near 0).
        // When they lift their back past 20 degrees, the rep begins.
        if (torsoSlope > 20) {
          currentPhase = ExercisePhase.ascending; // Going UP
        }
        break;

      case ExercisePhase.ascending:
        // Approaching the top of the sit-up.
        // We set the target to 40° to perfectly capture that ~45° arc you mentioned.
        if (torsoSlope >= 40) {
          currentPhase = ExercisePhase.active; // Reached the peak!
        } else if (coreAngle < 70 && torsoSlope < 30) {
          // Anti-cheat: They are bringing their knees to their chest without lifting their back
          isGoodForm = false;
          feedback = 'SIT ALL THE WAY UP';
        }
        break;

      case ExercisePhase.active:
        // They hit the top, now they must start going back down
        if (torsoSlope < 35) {
          currentPhase = ExercisePhase.descending; // Going DOWN
        }
        break;

      case ExercisePhase.descending:
        // Returning to the floor.
        // We use 18° instead of 0° because shoulder blades hit the floor before the spine is perfectly flat.
        if (torsoSlope <= 18) {
          currentPhase = ExercisePhase.resting; // Back at the bottom
          incrementRep();
          feedback = 'GOOD SIT-UP';
        } else if (torsoSlope > 18 && torsoSlope < 30) {
          isGoodForm = false;
          feedback = 'SHOULDERS TO THE FLOOR';
        }
        break;
    }

    return PoseAnalysisResult(
      effectiveAngle:
          torsoSlope, // Passing torsoSlope back makes it easier to debug the UI
      phase: currentPhase,
      repCount: repCount,
      isGoodForm: isGoodForm,
      formFeedback: feedback,
    );
  }
}
