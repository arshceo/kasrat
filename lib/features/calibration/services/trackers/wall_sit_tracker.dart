import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import '../exercise_tracker.dart';
import '../pose_math.dart';

class WallSitTracker extends BaseExerciseTracker {
  double? _smoothedLegAngle;
  double? _smoothedBackAngle;

  WallSitTracker() {
    isHold = true;
  }

  @override
  void reset() {
    super.reset();
    _smoothedLegAngle = null;
    _smoothedBackAngle = null;
  }

  @override
  PoseAnalysisResult processPose(Pose pose) {
    final landmarks = pose.landmarks;

    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];

    if (leftShoulder == null || rightShoulder == null) {
      return PoseAnalysisResult(
        phase: currentPhase,
        repCount: repCount,
        isGoodForm: false,
        formFeedback: 'FULL BODY REQUIRED',
      );
    }

    // 1. DOMINANT SIDE DETECTION
    final isLeft = leftShoulder.likelihood > rightShoulder.likelihood;

    final domShoulder = isLeft ? leftShoulder : rightShoulder;
    final domHip =
        landmarks[isLeft
            ? PoseLandmarkType.leftHip
            : PoseLandmarkType.rightHip];
    final domKnee =
        landmarks[isLeft
            ? PoseLandmarkType.leftKnee
            : PoseLandmarkType.rightKnee];
    final domAnkle =
        landmarks[isLeft
            ? PoseLandmarkType.leftAnkle
            : PoseLandmarkType.rightAnkle];

    // 2. THE JOINT GUILLOTINE
    if (domHip == null ||
        domKnee == null ||
        domAnkle == null ||
        domHip.likelihood < 0.4 ||
        domKnee.likelihood < 0.4) {
      currentPhase = ExercisePhase.resting;
      updateHoldTime();
      return PoseAnalysisResult(
        phase: currentPhase,
        repCount: repCount,
        isGoodForm: false,
        formFeedback: 'SIDE PROFILE REQUIRED',
      );
    }

    final rawLegAngle = PoseMath.calculateJointAngle(domHip, domKnee, domAnkle);
    final rawBackAngle = PoseMath.calculateJointAngle(
      domShoulder,
      domHip,
      domKnee,
    );

    _smoothedLegAngle = PoseMath.smoothAngle(
      rawLegAngle,
      _smoothedLegAngle ?? rawLegAngle,
      alpha: 0.2,
    );
    _smoothedBackAngle = PoseMath.smoothAngle(
      rawBackAngle,
      _smoothedBackAngle ?? rawBackAngle,
      alpha: 0.2,
    );

    final legAngle = _smoothedLegAngle!;
    final backAngle = _smoothedBackAngle!;

    final downThreshold =
        ExerciseConstants.wallSitDownAngle; // Ensure this is ~110 in constants
    final isLegsParallel = legAngle >= 60 && legAngle <= downThreshold;
    final isBackStraight =
        backAngle >= 65 &&
        backAngle <= 145; // Generous range for leaning against wall

    bool isGoodForm = true;
    String? feedback;

    if (isLegsParallel && isBackStraight) {
      currentPhase = ExercisePhase.active;
    } else {
      currentPhase = ExercisePhase.resting;
      isGoodForm = false;
      if (!isLegsParallel) {
        feedback = legAngle > downThreshold ? 'SINK LOWER' : 'HIPS TOO LOW';
      } else if (!isBackStraight)
        feedback = 'KEEP BACK ON WALL';
    }

    updateHoldTime();
    return PoseAnalysisResult(
      effectiveAngle: legAngle,
      phase: currentPhase,
      repCount: repCount,
      isGoodForm: isGoodForm,
      formFeedback: feedback,
    );
  }
}
