import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import '../exercise_tracker.dart';
import '../pose_math.dart';

class SquatTracker extends BaseExerciseTracker {
  bool? _lockedIsLeftLegDominant;
  double? _smoothedSquatAngle;
  double? _standingHipDepth;
  double? _standingKneeDepth;
  int _standingBaselineFrames = 0;

  @override
  void reset() {
    super.reset();
    _lockedIsLeftLegDominant = null;
    _smoothedSquatAngle = null;
    _standingHipDepth = null;
    _standingKneeDepth = null;
    _standingBaselineFrames = 0;
  }

  @override
  PoseAnalysisResult processPose(Pose pose) {
    final landmarks = pose.landmarks;
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final leftHeel = landmarks[PoseLandmarkType.leftHeel];
    final leftFootIndex = landmarks[PoseLandmarkType.leftFootIndex];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
    final rightHeel = landmarks[PoseLandmarkType.rightHeel];
    final rightFootIndex = landmarks[PoseLandmarkType.rightFootIndex];

    double sideScore({
      required PoseLandmark? hip,
      required PoseLandmark? knee,
      required PoseLandmark? ankle,
      required PoseLandmark? heel,
      required PoseLandmark? footIndex,
    }) {
      final footVisibility = [
        ankle?.likelihood ?? 0,
        heel?.likelihood ?? 0,
        footIndex?.likelihood ?? 0,
      ].reduce(max);

      return ((hip?.likelihood ?? 0) * 0.7) +
          ((knee?.likelihood ?? 0) * 0.85) +
          (footVisibility * 1.45);
    }

    final leftLikelihood = sideScore(
      hip: leftHip,
      knee: leftKnee,
      ankle: leftAnkle,
      heel: leftHeel,
      footIndex: leftFootIndex,
    );
    final rightLikelihood = sideScore(
      hip: rightHip,
      knee: rightKnee,
      ankle: rightAnkle,
      heel: rightHeel,
      footIndex: rightFootIndex,
    );

    bool isLeftLegDominant;
    if (_lockedIsLeftLegDominant != null) {
      isLeftLegDominant = _lockedIsLeftLegDominant!;

      final lockedLikelihood = isLeftLegDominant
          ? leftLikelihood
          : rightLikelihood;
      if (lockedLikelihood < ExerciseConstants.confidenceThreshold - 0.15) {
        consecutiveLowConfidenceFrames++;
        if (consecutiveLowConfidenceFrames > 6) {
          _lockedIsLeftLegDominant = null;
          isLeftLegDominant = leftLikelihood >= rightLikelihood;
        }
      } else {
        consecutiveLowConfidenceFrames = 0;
      }
    } else {
      isLeftLegDominant = leftLikelihood >= rightLikelihood;

      final maxLikelihood = max(leftLikelihood, rightLikelihood);
      if (maxLikelihood > ExerciseConstants.confidenceThreshold) {
        _lockedIsLeftLegDominant = isLeftLegDominant;
        consecutiveLowConfidenceFrames = 0;
      }
    }

    final dominantHip = isLeftLegDominant ? leftHip : rightHip;
    final dominantKnee = isLeftLegDominant ? leftKnee : rightKnee;
    final dominantAnkle = isLeftLegDominant ? leftAnkle : rightAnkle;
    final dominantHeel = isLeftLegDominant ? leftHeel : rightHeel;
    final dominantFootIndex = isLeftLegDominant
        ? leftFootIndex
        : rightFootIndex;
    final oppositeAnkle = isLeftLegDominant ? rightAnkle : leftAnkle;
    final oppositeHeel = isLeftLegDominant ? rightHeel : leftHeel;
    final oppositeFootIndex = isLeftLegDominant
        ? rightFootIndex
        : leftFootIndex;

    if (dominantHip == null || dominantKnee == null || dominantAnkle == null) {
      return applyHoldLogic(180.0, false, 'STEP INTO FRAME');
    }

    if (dominantHip.likelihood < ExerciseConstants.confidenceThreshold ||
        dominantKnee.likelihood < ExerciseConstants.confidenceThreshold) {
      return applyHoldLogic(180.0, false, 'LOW VISIBILITY');
    }

    final hasShoulders = leftShoulder != null && rightShoulder != null;
    final shoulderWidth = hasShoulders
        ? (leftShoulder.x - rightShoulder.x).abs()
        : 0.0;
    final torsoLength = hasShoulders
        ? (dominantHip.y - leftShoulder.y).abs()
        : 1.0;

    final isFrontProfile =
        hasShoulders &&
        leftShoulder.likelihood > 0.5 &&
        rightShoulder.likelihood > 0.5 &&
        (shoulderWidth > torsoLength * 0.35);

    bool isGoodForm = true;
    String? feedback;

    double rawAngle = PoseMath.calculateJointAngle(
      dominantHip,
      dominantKnee,
      dominantAnkle,
    );

    final ankleDiff = oppositeAnkle != null
        ? (dominantAnkle.y - oppositeAnkle.y).abs()
        : 0.0;

    final isAnkleLifted =
        oppositeAnkle != null &&
        dominantAnkle.likelihood > 0.4 &&
        oppositeAnkle.likelihood > 0.4 &&
        (ankleDiff > torsoLength * 0.35);

    if (isAnkleLifted) {
      rawAngle = 180.0;
      isGoodForm = false;
      feedback = 'KEEP FEET PLANTED';
    } else {
      if (isFrontProfile) {
        final femurY = dominantKnee.y - dominantHip.y;
        final tibiaY = (dominantAnkle.y - dominantKnee.y).abs().clamp(
          1.0,
          double.infinity,
        );

        final depthRatio = (femurY / tibiaY).clamp(-0.5, 1.2);
        final syntheticAngle = 90.0 + (depthRatio * 90.0);

        rawAngle = min(rawAngle, syntheticAngle);
      }
    }

    _smoothedSquatAngle = PoseMath.smoothAngle(
      rawAngle,
      _smoothedSquatAngle ?? rawAngle,
      alpha: 0.3,
    );
    final effectiveAngle = _smoothedSquatAngle!;

    double averageVisibility(List<PoseLandmark?> landmarks) {
      final visible = landmarks.whereType<PoseLandmark>().toList(
        growable: false,
      );
      if (visible.isEmpty) return 0.0;
      return visible.fold<double>(
            0.0,
            (sum, landmark) => sum + landmark.likelihood,
          ) /
          visible.length;
    }

    final dominantFootVisibility = averageVisibility([
      dominantAnkle,
      dominantHeel,
      dominantFootIndex,
    ]);
    final oppositeFootVisibility = averageVisibility([
      oppositeAnkle,
      oppositeHeel,
      oppositeFootIndex,
    ]);

    final currentHipDepth = dominantHip.y / torsoLength;
    final currentKneeDepth = dominantKnee.y / torsoLength;

    final standingBaselineReady =
        _standingHipDepth != null &&
        _standingKneeDepth != null &&
        _standingBaselineFrames > 2;
    final supportFootAnchored =
        dominantFootVisibility > ExerciseConstants.confidenceThreshold &&
        dominantFootVisibility >=
            oppositeFootVisibility - ExerciseConstants.squatSideLockMargin;

    if (currentPhase == ExercisePhase.resting &&
        effectiveAngle >= ExerciseConstants.squatUpAngle - 15 &&
        supportFootAnchored) {
      _standingBaselineFrames++;
      if (_standingHipDepth == null || _standingKneeDepth == null) {
        _standingHipDepth = currentHipDepth;
        _standingKneeDepth = currentKneeDepth;
      } else {
        _standingHipDepth =
            (_standingHipDepth! *
                (1 - ExerciseConstants.squatBaselineSmoothing)) +
            (currentHipDepth * ExerciseConstants.squatBaselineSmoothing);
        _standingKneeDepth =
            (_standingKneeDepth! *
                (1 - ExerciseConstants.squatBaselineSmoothing)) +
            (currentKneeDepth * ExerciseConstants.squatBaselineSmoothing);
      }
    } else if (currentPhase == ExercisePhase.resting &&
        effectiveAngle >= ExerciseConstants.squatUpAngle - 15) {
      _standingBaselineFrames = 0;
    }

    final hipDropFromStand = standingBaselineReady
        ? currentHipDepth - _standingHipDepth!
        : 0.0;
    final kneeDropFromStand = standingBaselineReady
        ? currentKneeDepth - _standingKneeDepth!
        : 0.0;

    final squatMotionConfirmed =
        standingBaselineReady &&
        (hipDropFromStand >= ExerciseConstants.squatHipDropThreshold &&
            kneeDropFromStand >= ExerciseConstants.squatKneeDropThreshold);

    final dominantShoulder = isLeftLegDominant
        ? landmarks[PoseLandmarkType.leftShoulder]
        : landmarks[PoseLandmarkType.rightShoulder];

    if (dominantShoulder != null &&
        dominantShoulder.likelihood > ExerciseConstants.confidenceThreshold) {
      final backAngle = PoseMath.calculateJointAngle(
        dominantShoulder,
        dominantHip,
        dominantKnee,
      );
      if (backAngle < 35) {
        isGoodForm = false;
        feedback = 'KEEP CHEST UP';
      }
    }

    switch (currentPhase) {
      case ExercisePhase.resting:
        if (effectiveAngle < ExerciseConstants.squatUpAngle - 10 &&
            squatMotionConfirmed) {
          currentPhase = ExercisePhase.descending;
        }
        break;
      case ExercisePhase.descending:
        if (effectiveAngle <= ExerciseConstants.squatDownAngle) {
          currentPhase = ExercisePhase.active;
        } else if (effectiveAngle >= ExerciseConstants.squatUpAngle - 10) {
          currentPhase = ExercisePhase.resting;
          isGoodForm = false;
          feedback = 'FULL DEPTH REQUIRED';
        }
        break;
      case ExercisePhase.active:
        if (effectiveAngle > ExerciseConstants.squatDownAngle + 10) {
          currentPhase = ExercisePhase.ascending;
        }
        break;
      case ExercisePhase.ascending:
        if (effectiveAngle >= ExerciseConstants.squatUpAngle - 10) {
          currentPhase = ExercisePhase.resting;
          incrementRep();
          feedback = 'GOOD SQUAT';
        }
        break;
    }

    return applyHoldLogic(effectiveAngle, isGoodForm, feedback);
  }
}
