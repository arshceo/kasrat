import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../exercise_tracker.dart';
import '../pose_math.dart';

class LungeTracker extends BaseExerciseTracker {
  double? _smoothedActiveAngle;

  @override
  void reset() { super.reset(); _smoothedActiveAngle = null; }

  double _distance(PoseLandmark a, PoseLandmark b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
  }

  @override
  PoseAnalysisResult processPose(Pose pose) {
    bool isGoodForm = true;
    String? feedback;
    
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    // 1. THE JOINT GUILLOTINE
    if (leftHip == null || rightHip == null || leftKnee == null || rightKnee == null || 
        leftAnkle == null || rightAnkle == null || leftShoulder == null) {
      consecutiveLowConfidenceFrames++;
      if (consecutiveLowConfidenceFrames > 3) return PoseAnalysisResult(phase: currentPhase, repCount: repCount, isGoodForm: false, formFeedback: 'STEP INTO FRAME');
      return PoseAnalysisResult(phase: currentPhase, repCount: repCount, isGoodForm: true);
    }
    consecutiveLowConfidenceFrames = 0;

    final rawLeftAngle = PoseMath.calculateJointAngle(leftHip, leftKnee, leftAnkle);
    final rawRightAngle = PoseMath.calculateJointAngle(rightHip, rightKnee, rightAnkle);
    final rawActiveAngle = rawLeftAngle < rawRightAngle ? rawLeftAngle : rawRightAngle;
    final trailingAngle = rawLeftAngle > rawRightAngle ? rawLeftAngle : rawRightAngle;

    _smoothedActiveAngle = PoseMath.smoothAngle(rawActiveAngle, _smoothedActiveAngle ?? rawActiveAngle, alpha: 0.3);
    final activeAngle = _smoothedActiveAngle!;

    // 2. THE SPLIT STANCE LOCK
    final torsoLength = _distance(leftShoulder, leftHip);
    final ankleSeparation = (leftAnkle.x - rightAnkle.x).abs();
    final hasSplitStance = ankleSeparation > (torsoLength * 0.45);

    switch (currentPhase) {
      case ExercisePhase.resting:
        if (rawLeftAngle > 160 && rawRightAngle > 160 && activeAngle < 140) {
          currentPhase = ExercisePhase.descending;
        }
        break;
      case ExercisePhase.descending:
        if (activeAngle <= 100) {
          if (hasSplitStance) {
            currentPhase = ExercisePhase.active;
          } else {
            isGoodForm = false;
            feedback = 'STEP OUT FURTHER';
          }
        } else if (activeAngle >= 160 && trailingAngle >= 160) {
          currentPhase = ExercisePhase.resting;
          isGoodForm = false;
          feedback = 'DROP KNEE LOWER';
        }
        break;
      case ExercisePhase.active:
        if (activeAngle > 110) currentPhase = ExercisePhase.ascending;
        break;
      case ExercisePhase.ascending:
        if (rawLeftAngle > 155 && rawRightAngle > 155) {
          currentPhase = ExercisePhase.resting;
          incrementRep();
        } else if (activeAngle <= 100) {
          currentPhase = ExercisePhase.active;
          isGoodForm = false;
          feedback = 'DRIVE UP. NO RESTING.';
        }
        break;
    }
    return PoseAnalysisResult(effectiveAngle: activeAngle, phase: currentPhase, repCount: repCount, isGoodForm: isGoodForm, formFeedback: feedback);
  }
}
