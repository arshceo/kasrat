import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../exercise_tracker.dart';
import '../pose_math.dart';

class LungeTracker extends BaseExerciseTracker {
  double? _smoothedFrontAngle;
  double? _smoothedBackAngle;

  @override
  void reset() {
    super.reset();
    _smoothedFrontAngle = null;
    _smoothedBackAngle = null;
  }

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
    if (leftHip == null ||
        rightHip == null ||
        leftKnee == null ||
        rightKnee == null ||
        leftAnkle == null ||
        rightAnkle == null ||
        leftShoulder == null ||
        rightShoulder == null) {
      consecutiveLowConfidenceFrames++;
      if (consecutiveLowConfidenceFrames > 3) {
        return PoseAnalysisResult(
          phase: currentPhase,
          repCount: repCount,
          isGoodForm: false,
          formFeedback: 'STEP INTO FRAME',
        );
      }
      return PoseAnalysisResult(
        phase: currentPhase,
        repCount: repCount,
        isGoodForm: true,
      );
    }
    consecutiveLowConfidenceFrames = 0;

    // 2. IDENTIFY FRONT AND BACK LEGS (Crucial Fix)
    // Assume side profile. The leg further forward on the X axis is the plant leg.
    // We check the absolute difference. The leg with the ankle furthest from the hip horizontally is in front.
    final leftLegReach = (leftAnkle.x - leftHip.x).abs();
    final rightLegReach = (rightAnkle.x - rightHip.x).abs();

    final isLeftLegFront = leftLegReach > rightLegReach;

    final frontHip = isLeftLegFront ? leftHip : rightHip;
    final frontKnee = isLeftLegFront ? leftKnee : rightKnee;
    final frontAnkle = isLeftLegFront ? leftAnkle : rightAnkle;

    final backHip = isLeftLegFront ? rightHip : leftHip;
    final backKnee = isLeftLegFront ? rightKnee : leftKnee;
    final backAnkle = isLeftLegFront ? rightAnkle : leftAnkle;

    // Use dominant shoulder based on profile
    final domShoulder = leftShoulder.likelihood > rightShoulder.likelihood
        ? leftShoulder
        : rightShoulder;

    // 3. ANGLE CALCULATIONS
    final rawFrontAngle = PoseMath.calculateJointAngle(
      frontHip,
      frontKnee,
      frontAnkle,
    );
    final rawBackAngle = PoseMath.calculateJointAngle(
      backHip,
      backKnee,
      backAnkle,
    );

    _smoothedFrontAngle = PoseMath.smoothAngle(
      rawFrontAngle,
      _smoothedFrontAngle ?? rawFrontAngle,
      alpha: 0.3,
    );
    _smoothedBackAngle = PoseMath.smoothAngle(
      rawBackAngle,
      _smoothedBackAngle ?? rawBackAngle,
      alpha: 0.3,
    );

    final frontAngle = _smoothedFrontAngle!;
    final backAngle = _smoothedBackAngle!;

    // 4. THE SPLIT STANCE & POSTURE LOCKS
    final torsoLength = _distance(domShoulder, frontHip);
    final ankleSeparation = _distance(frontAnkle, backAnkle);
    final hasSplitStance =
        ankleSeparation > (torsoLength * 0.80); // Needs a wide base

    // Check torso lean (Are they bowing forward?)
    final dx = (domShoulder.x - frontHip.x).abs();
    final dy = (domShoulder.y - frontHip.y).abs();
    final torsoLean =
        atan2(dx, dy) * 180 / pi; // 0 is straight up, 90 is parallel to floor

    // 5. THE STATE MACHINE (Based on BOTH knees bending)
    switch (currentPhase) {
      case ExercisePhase.resting:
        // Standing mostly straight. If either knee starts to bend significantly, we are descending.
        if (frontAngle < 150 || backAngle < 150) {
          currentPhase = ExercisePhase.descending;
        }
        break;

      case ExercisePhase.descending:
        // A perfect lunge hits roughly 90 degrees on BOTH knees
        if (frontAngle <= 100 && backAngle <= 100) {
          if (!hasSplitStance) {
            isGoodForm = false;
            feedback = 'STEP OUT FURTHER';
          } else if (torsoLean > 35) {
            isGoodForm = false;
            feedback = 'KEEP CHEST UP'; // Prevents bowing forward
          } else {
            currentPhase = ExercisePhase.active; // Reached the bottom safely
          }
        }
        // If they abort and stand back up early
        else if (frontAngle >= 160 && backAngle >= 160) {
          currentPhase = ExercisePhase.resting;
          isGoodForm = false;
          feedback = 'DROP BACK KNEE LOWER';
        }
        break;

      case ExercisePhase.active:
        // They hit the bottom. When they start pushing back up, change phase.
        if (frontAngle > 115 || backAngle > 115) {
          currentPhase = ExercisePhase.ascending;
        }
        break;

      case ExercisePhase.ascending:
        // Standing back up straight
        if (frontAngle > 155 && backAngle > 155) {
          currentPhase = ExercisePhase.resting;
          incrementRep();
          feedback = 'GOOD LUNGE';
        }
        // If they bounce back down without standing up fully
        else if (frontAngle <= 100 && backAngle <= 100) {
          currentPhase = ExercisePhase.active;
          isGoodForm = false;
          feedback = 'STAND UP FULLY';
        }
        break;
    }

    // We return the front angle to the UI for the progress bar, as it's the primary working leg
    return PoseAnalysisResult(
      effectiveAngle: frontAngle,
      phase: currentPhase,
      repCount: repCount,
      isGoodForm: isGoodForm,
      formFeedback: feedback,
    );
  }
}
