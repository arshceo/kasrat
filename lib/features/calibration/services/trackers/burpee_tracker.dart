import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../exercise_tracker.dart';
import '../pose_math.dart';

class BurpeeTracker extends BaseExerciseTracker {
  double? _smoothedTorsoSlope;

  @override
  void reset() {
    super.reset();
    _smoothedTorsoSlope = null;
  }

  @override
  PoseAnalysisResult processPose(Pose pose) {
    bool isGoodForm = true;
    String? feedback;

    final landmarks = pose.landmarks;
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];

    if (leftShoulder == null || rightShoulder == null) {
      return PoseAnalysisResult(phase: currentPhase, repCount: repCount, isGoodForm: false, formFeedback: 'FULL BODY REQUIRED');
    }

    // 1. DOMINANT SIDE DETECTION (Omnidirectional Tracking)
    final isLeft = leftShoulder.likelihood > rightShoulder.likelihood;
    final domShoulder = isLeft ? leftShoulder : rightShoulder;
    final domHip = landmarks[isLeft ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip];
    final domKnee = landmarks[isLeft ? PoseLandmarkType.leftKnee : PoseLandmarkType.rightKnee];
    final domAnkle = landmarks[isLeft ? PoseLandmarkType.leftAnkle : PoseLandmarkType.rightAnkle];

    // 2. THE JOINT GUILLOTINE
    if (domHip == null || domKnee == null || domAnkle == null ||
        domShoulder.likelihood < 0.5 || domHip.likelihood < 0.5 || domAnkle.likelihood < 0.5) {
      return PoseAnalysisResult(phase: currentPhase, repCount: repCount, isGoodForm: false, formFeedback: 'KEEP FULL BODY IN FRAME');
    }

    // 3. MEASUREMENT A: TORSO SLOPE (0° = Floor, 90° = Standing)
    final dy = (domHip.y - domShoulder.y).abs();
    final dx = (domHip.x - domShoulder.x).abs();
    final rawTorsoSlope = atan2(dy, dx) * 180 / pi;

    _smoothedTorsoSlope = PoseMath.smoothAngle(rawTorsoSlope, _smoothedTorsoSlope ?? rawTorsoSlope, alpha: 0.3);
    final torsoSlope = _smoothedTorsoSlope!;

    // 4. MEASUREMENT B: BODY EXTENSION ANGLE (Replaces pixel math)
    // 180° = Perfectly straight plank/standing. < 120° = Crouching/Bending.
    final bodyExtensionAngle = PoseMath.calculateJointAngle(domShoulder, domHip, domAnkle);

    // 5. THE STATE MACHINE
    switch (currentPhase) {
      case ExercisePhase.resting:
        // Torso drops below 50°
        if (torsoSlope < 50) currentPhase = ExercisePhase.descending;
        break;
      case ExercisePhase.descending:
        // Torso hits the floor zone
        if (torsoSlope < 35) {
          // To beat the "Toe-Touch Exploit", the body MUST be extended into a straight line
          if (bodyExtensionAngle > 145) {
            currentPhase = ExercisePhase.active; // True plank position reached
          } else {
            isGoodForm = false;
            feedback = 'KICK LEGS BACK INTO PLANK';
          }
        }
        break;
      case ExercisePhase.active:
        // Starting to stand back up
        if (torsoSlope > 45) currentPhase = ExercisePhase.ascending;
        break;
      case ExercisePhase.ascending:
        // Torso is upright again
        if (torsoSlope > 70) {
          // Must stand all the way up (unbend the hips)
          if (bodyExtensionAngle > 150) {
            currentPhase = ExercisePhase.resting;
            incrementRep(); // Secure the rep
          } else {
            isGoodForm = false;
            feedback = 'STAND ALL THE WAY UP';
          }
        } else if (torsoSlope < 40) {
          // Bailed out of the ascent
          currentPhase = ExercisePhase.active;
        }
        break;
    }

    return PoseAnalysisResult(
      effectiveAngle: torsoSlope, 
      phase: currentPhase, 
      repCount: repCount, 
      isGoodForm: isGoodForm, 
      formFeedback: feedback
    );
  }
}
