import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../exercise_tracker.dart';
import '../pose_math.dart';

class SitupTracker extends BaseExerciseTracker {
  double? _smoothedCoreAngle;

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
    if (leftShoulder == null || rightShoulder == null || leftHip == null || rightHip == null || leftKnee == null || rightKnee == null) {
      return PoseAnalysisResult(
        phase: currentPhase, 
        repCount: repCount, 
        isGoodForm: false, 
        formFeedback: 'FULL BODY REQUIRED'
      );
    }

    // 2. STRICT SIDE-PROFILE ENFORCEMENT
    final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();
    final torsoLength = (leftHip.y - leftShoulder.y).abs();
    
    if (shoulderWidth > (torsoLength * 0.45) && leftShoulder.likelihood > 0.6 && rightShoulder.likelihood > 0.6) {
      return PoseAnalysisResult(
        phase: currentPhase, 
        repCount: repCount, 
        isGoodForm: false, 
        formFeedback: 'TURN 90 DEGREES (SIDE VIEW)'
      );
    }

    // 3. IDENTIFY DOMINANT SIDE
    final isLeft = leftShoulder.likelihood > rightShoulder.likelihood;
    final domShoulder = isLeft ? leftShoulder : rightShoulder;
    final domHip = isLeft ? leftHip : rightHip;
    final domKnee = isLeft ? leftKnee : rightKnee;

    if (domShoulder.likelihood < 0.6 || domHip.likelihood < 0.6 || domKnee.likelihood < 0.6) {
      return PoseAnalysisResult(
        phase: currentPhase, 
        repCount: repCount, 
        isGoodForm: false, 
        formFeedback: 'SIDE PROFILE REQUIRED'
      );
    }

    // 4. THE FLEXION ANGLE (Accommodates the curved spine)
    final rawCoreAngle = PoseMath.calculateJointAngle(domShoulder, domHip, domKnee);
    _smoothedCoreAngle = PoseMath.smoothAngle(rawCoreAngle, _smoothedCoreAngle ?? rawCoreAngle, alpha: 0.3);
    final coreAngle = _smoothedCoreAngle!;

    // 5. THE ELEVATION LOCK (Kills the reverse crunch)
    final dy = (domShoulder.y - domHip.y).abs();
    final dx = (domShoulder.x - domHip.x).abs();
    final torsoSlope = atan2(dy, dx) * 180 / pi;

    // 6. THE STATE MACHINE
    switch (currentPhase) {
      case ExercisePhase.resting: 
        if (coreAngle > 105) currentPhase = ExercisePhase.descending; // Lying back
        break;
      case ExercisePhase.descending:
        if (coreAngle <= 100) currentPhase = ExercisePhase.active; // Starting the movement
        break;
      case ExercisePhase.active:
        // Must hit crunch depth (75°)
        if (coreAngle <= 75) { 
          // Must ALSO prove the shoulders left the floor
          if (torsoSlope > 18) {
            currentPhase = ExercisePhase.ascending;
          } else {
            isGoodForm = false;
            feedback = 'LIFT YOUR SHOULDERS'; // Caught the reverse crunch
          }
        }
        break;
      case ExercisePhase.ascending:
        // Returning to the floor
        if (coreAngle > 105) { 
          currentPhase = ExercisePhase.resting;
          incrementRep();
        } else if (coreAngle > 85 && coreAngle <= 100) {
           isGoodForm = false;
           feedback = 'SHOULDERS TO THE FLOOR';
        }
        break;
    }
    
    return PoseAnalysisResult(
      effectiveAngle: coreAngle, 
      phase: currentPhase, 
      repCount: repCount, 
      isGoodForm: isGoodForm, 
      formFeedback: feedback
    );
  }
}
