import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import '../exercise_tracker.dart';
import '../pose_math.dart';

class PushupTracker extends BaseExerciseTracker {
  double? _smoothedAngle;
  double? _topDepth;
  int _topDepthFrames = 0;
  final bool forceSideOnlyPushup;

  PushupTracker({this.forceSideOnlyPushup = true});

  double _distance(PoseLandmark a, PoseLandmark b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
  }

  @override
  void reset() {
    super.reset();
    _smoothedAngle = null;
    _topDepth = null;
    _topDepthFrames = 0;
  }

  @override
  PoseAnalysisResult processPose(Pose pose) {
    final landmarks = pose.landmarks;
    bool isGoodForm = true;
    String? feedback;
    bool sideBottomReached = false;
    bool sideTopReached = false;
    double sideDepthDrop = 0.0;

    final nose = landmarks[PoseLandmarkType.nose];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow = landmarks[PoseLandmarkType.rightElbow];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];

    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];

    double rawAngle = 180.0;

    final hasLeftArm =
        leftShoulder != null &&
        leftElbow != null &&
        leftWrist != null &&
        leftShoulder.likelihood > 0.4 &&
        leftElbow.likelihood > 0.4 &&
        leftWrist.likelihood > 0.4;
    final hasRightArm =
        rightShoulder != null &&
        rightElbow != null &&
        rightWrist != null &&
        rightShoulder.likelihood > 0.4 &&
        rightElbow.likelihood > 0.4 &&
        rightWrist.likelihood > 0.4;

    if (!hasLeftArm && !hasRightArm) {
      return applyHoldLogic(rawAngle, false, 'ARMS NOT VISIBLE');
    }

    final leftLikelihood = hasLeftArm
        ? leftShoulder.likelihood + leftElbow.likelihood + leftWrist.likelihood
        : 0.0;
    final rightLikelihood = hasRightArm
        ? rightShoulder.likelihood +
              rightElbow.likelihood +
              rightWrist.likelihood
        : 0.0;

    final hasBothWrists =
        leftWrist != null &&
        leftWrist.likelihood > 0.4 &&
        rightWrist != null &&
        rightWrist.likelihood > 0.4;
    final wristWidth = hasBothWrists ? (leftWrist.x - rightWrist.x).abs() : 0.0;

    final hasBothShoulders = leftShoulder != null && rightShoulder != null;
    final shoulderWidth = hasBothShoulders
        ? (leftShoulder.x - rightShoulder.x).abs()
        : 0.0;

    final strongArmScore = max(leftLikelihood, rightLikelihood);
    final weakArmScore = min(leftLikelihood, rightLikelihood);
    final sideDominantArm =
        (hasLeftArm != hasRightArm) ||
        (strongArmScore > 0.0 && weakArmScore < strongArmScore * 0.62);

    var isFrontProfile =
        !sideDominantArm &&
        ((hasBothWrists && wristWidth > 0.17) ||
            (hasBothShoulders &&
                leftShoulder.likelihood > 0.5 &&
                rightShoulder.likelihood > 0.5 &&
                shoulderWidth > 0.22));
    if (forceSideOnlyPushup) {
      isFrontProfile = false;
    }

    final leftArmLength = hasLeftArm
        ? _distance(leftShoulder, leftElbow) + _distance(leftElbow, leftWrist)
        : 0.0;
    final rightArmLength = hasRightArm
        ? _distance(rightShoulder, rightElbow) +
              _distance(rightElbow, rightWrist)
        : 0.0;
    final leftDominanceScore = leftLikelihood + (leftArmLength * 1.4);
    final rightDominanceScore = rightLikelihood + (rightArmLength * 1.4);
    final isLeftDominant = leftDominanceScore >= rightDominanceScore;
    final domShoulder = isLeftDominant ? leftShoulder! : rightShoulder!;
    final domElbow = isLeftDominant ? leftElbow! : rightElbow!;
    final domWrist = isLeftDominant ? leftWrist! : rightWrist!;
    final domHip = isLeftDominant ? leftHip : rightHip;
    final domAnkle = isLeftDominant ? leftAnkle : rightAnkle;

    // ==========================================
    // THE PLANK LOCK (ANTI-CHEAT)
    // ==========================================

    // 1. Force the AI to see the torso. A floating arm is not a pushup.
    if (domHip == null || domHip.likelihood < 0.5) {
      return applyHoldLogic(180.0, false, 'SHOW YOUR TORSO & HIPS');
    }

    // 2. Calculate the Torso Slope.
    // 0° = perfectly horizontal (floor). 90° = standing vertically.
    final torsoSlopeRadians = atan2(
      (domHip.y - domShoulder.y).abs(),
      (domHip.x - domShoulder.x).abs(),
    );
    final torsoSlopeDegrees = torsoSlopeRadians * 180 / pi;

    // 3. The Guillotine: If the body is angled higher than 45 degrees, they are standing.
    if (torsoSlopeDegrees > 45) {
      // Freeze the state machine and force a fail.
      return applyHoldLogic(180.0, false, 'GET ON THE FLOOR');
    }

    final domElbowAngle = PoseMath.calculateJointAngle(
      domShoulder,
      domElbow,
      domWrist,
    );
    final lockoutAngleThreshold = isFrontProfile ? 145.0 : 138.0;
    final armsLockoutReached = domElbowAngle >= lockoutAngleThreshold;

    if (isFrontProfile) {
      _topDepthFrames = 0;
      final armLength =
          _distance(domShoulder, domElbow) + _distance(domElbow, domWrist);

      final headY = nose != null && domShoulder.likelihood < 0.6
          ? nose.y
          : domShoulder.y;
      final yDiff = (headY - domWrist.y).abs();

      final safeArmLength = max(armLength, 0.1);
      final ratio = (yDiff / (safeArmLength * 0.9)).clamp(0.0, 1.0);

      rawAngle = 90.0 + (ratio * 90.0);
      if (domWrist.y < headY) {
        rawAngle = 180.0;
      }

      if (domHip.likelihood > 0.4) {
        if (ratio < 0.3) {
          final hipDrop = (domHip.y - domWrist.y).abs();
          if (hipDrop > safeArmLength * 0.7) {
            isGoodForm = false;
            feedback = 'LOWER YOUR HIPS';
          }
        }
      }
    } else {
      final armLength =
          _distance(domShoulder, domElbow) + _distance(domElbow, domWrist);
      final safeArmLength = max(armLength, 0.1);
      final upperArmLength = max(_distance(domShoulder, domElbow), 0.1);
      final currentDepth = ((domWrist.y - domShoulder.y) / safeArmLength).clamp(
        -0.3,
        1.6,
      );

      if (currentPhase == ExercisePhase.resting) {
        _topDepthFrames++;
        if (_topDepth == null) {
          _topDepth = currentDepth;
        } else {
          _topDepth =
              (_topDepth! * (1 - ExerciseConstants.squatBaselineSmoothing)) +
              (currentDepth * ExerciseConstants.squatBaselineSmoothing);
        }
      }

      final baselineReady = _topDepth != null && _topDepthFrames >= 2;

      sideDepthDrop = baselineReady
          ? (_topDepth! - currentDepth).clamp(0.0, 1.2)
          : 0.0;
      sideTopReached = !baselineReady || sideDepthDrop <= 0.04;

      final dropProgress = (sideDepthDrop / 0.08).clamp(0.0, 1.0);
      final syntheticAngle = 175.0 - (dropProgress * 95.0);
      rawAngle = syntheticAngle;

      final shoulderDepthReached =
          domShoulder.y >= (domElbow.y - (upperArmLength * 0.30));

      final shoulderCloseToWrist =
          (domWrist.y - domShoulder.y) <= (safeArmLength * 0.55);

      final reachedBottomFromDrop = baselineReady && sideDepthDrop >= 0.06;

      if (shoulderDepthReached ||
          shoulderCloseToWrist ||
          reachedBottomFromDrop) {
        sideBottomReached = true;
        rawAngle = min(rawAngle, ExerciseConstants.pushupDownAngle - 8);
      }

      if (domWrist.y < domElbow.y - (upperArmLength * 0.1)) {
        isGoodForm = false;
        feedback = 'KEEP HAND PLANTED';
        rawAngle = max(rawAngle, ExerciseConstants.pushupUpAngle);
      }

      if (domHip.likelihood > 0.4 &&
          domAnkle != null &&
          domAnkle.likelihood > 0.4) {
        final backAngle = PoseMath.calculateJointAngle(
          domShoulder,
          domHip,
          domAnkle,
        );
        if (backAngle < 145) {
          isGoodForm = false;
          feedback = 'KEEP BACK STRAIGHT';
        }
      }
    }

    _smoothedAngle = PoseMath.smoothAngle(
      rawAngle,
      _smoothedAngle ?? rawAngle,
      alpha: 0.3,
    );
    final effectiveAngle = _smoothedAngle!;

    switch (currentPhase) {
      case ExercisePhase.resting:
        if (isFrontProfile) {
          if (effectiveAngle < ExerciseConstants.pushupUpAngle - 10) {
            currentPhase = ExercisePhase.descending;
          }
        } else {
          if (sideDepthDrop >= 0.03) {
            currentPhase = ExercisePhase.descending;
          }
        }
        break;
      case ExercisePhase.descending:
        if (effectiveAngle <= ExerciseConstants.pushupDownAngle ||
            sideBottomReached) {
          currentPhase = ExercisePhase.active;
        } else if (effectiveAngle >= ExerciseConstants.pushupUpAngle - 10) {
          currentPhase = ExercisePhase.resting;
          isGoodForm = false;
          feedback = 'GO DEEPER';
        }
        break;
      case ExercisePhase.active:
        if (effectiveAngle > ExerciseConstants.pushupDownAngle + 10) {
          currentPhase = ExercisePhase.ascending;
        }
        break;
      case ExercisePhase.ascending:
        if (effectiveAngle >= ExerciseConstants.pushupUpAngle - 10 ||
            (!isFrontProfile && sideTopReached)) {
          if (armsLockoutReached) {
            currentPhase = ExercisePhase.resting;
            incrementRep();
            feedback = 'GOOD PUSHUP';
          } else {
            isGoodForm = false;
            feedback = 'LOCK OUT ARMS';
          }
        } else if (effectiveAngle <= ExerciseConstants.pushupDownAngle ||
            sideBottomReached) {
          currentPhase = ExercisePhase.active;
          isGoodForm = false;
          feedback = 'PUSH UP FULLY';
        }
        break;
    }

    return applyHoldLogic(effectiveAngle, isGoodForm, feedback);
  }
}
