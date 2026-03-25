import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../core/constants/app_constants.dart';

enum ExerciseType { squat, pushup, plank }

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

/// Core exercise analysis engine for Ustad AI.
class PoseAnalyzer {
  ExercisePhase _currentPhase = ExercisePhase.resting;
  int _repCount = 0;

  // Anti-cheat HOLD tracking
  bool _holdActive = false;
  DateTime? _holdStartTime;
  final Random _random = Random();
  int _nextHoldRep = -1;

  // Side-locking for stability
  bool? _lockedIsLeftLegDominant;
  int _consecutiveLowConfidenceFrames = 0;
  double? _smoothedSquatAngle;
  double? _smoothedPushupAngle;
  double? _standingHipDepth;
  double? _standingKneeDepth;
  int _standingBaselineFrames = 0;

  int get repCount => _repCount;
  ExercisePhase get currentPhase => _currentPhase;

  PoseAnalyzer() {
    _scheduleNextHold();
  }

  void reset() {
    _currentPhase = ExercisePhase.resting;
    _repCount = 0;
    _holdActive = false;
    _holdStartTime = null;
    _lockedIsLeftLegDominant = null;
    _consecutiveLowConfidenceFrames = 0;
    _smoothedSquatAngle = null;
    _standingHipDepth = null;
    _standingKneeDepth = null;
    _standingBaselineFrames = 0;
    _scheduleNextHold();
  }

  void _scheduleNextHold() {
    _nextHoldRep = _repCount + 5 + _random.nextInt(11);
  }

  static double calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final radians = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x);
    var angle = radians.abs() * 180 / pi;
    if (angle > 180) angle = 360 - angle;
    return angle;
  }

  PoseAnalysisResult analyzePose(Pose pose, ExerciseType type) {
    final landmarks = pose.landmarks;

    if (type == ExerciseType.squat) {
      return _analyzeSquat(landmarks);
    } else if (type == ExerciseType.pushup) {
      return _analyzePushup(landmarks);
    } else if (type == ExerciseType.plank) {
      return _analyzePlank(landmarks);
    }

    return PoseAnalysisResult(
      phase: _currentPhase,
      repCount: _repCount,
      isGoodForm: false,
    );
  }

  PoseAnalysisResult _analyzeSquat(
    Map<PoseLandmarkType, PoseLandmark> landmarks,
  ) {
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

    // Choose the most visible leg, completely ignoring the occluded far leg.
    // Added stability: lock onto the dominant leg to prevent wobbling if the AI gets confused mid-rep.
    bool isLeftLegDominant;
    if (_lockedIsLeftLegDominant != null) {
      isLeftLegDominant = _lockedIsLeftLegDominant!;

      // Check if our locked leg is still visible
      final lockedLikelihood = isLeftLegDominant
          ? leftLikelihood
          : rightLikelihood;
      if (lockedLikelihood < ExerciseConstants.confidenceThreshold - 0.15) {
        _consecutiveLowConfidenceFrames++;
        if (_consecutiveLowConfidenceFrames > 6) {
          // Unlock after a short loss of confidence, then reacquire the clearer side.
          _lockedIsLeftLegDominant = null;
          isLeftLegDominant = leftLikelihood >= rightLikelihood;
        }
      } else {
        _consecutiveLowConfidenceFrames = 0;
      }
    } else {
      isLeftLegDominant = leftLikelihood >= rightLikelihood;

      // Lock if we have a very clear view of the dominant leg
      final maxLikelihood = max(leftLikelihood, rightLikelihood);
      if (maxLikelihood > ExerciseConstants.confidenceThreshold) {
        _lockedIsLeftLegDominant = isLeftLegDominant;
        _consecutiveLowConfidenceFrames = 0;
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
      return PoseAnalysisResult(
        phase: _currentPhase,
        repCount: _repCount,
        isGoodForm: false,
        formFeedback: 'STEP INTO FRAME',
      );
    }

    if (dominantHip.likelihood < ExerciseConstants.confidenceThreshold ||
        dominantKnee.likelihood < ExerciseConstants.confidenceThreshold) {
      return PoseAnalysisResult(
        phase: _currentPhase,
        repCount: _repCount,
        isGoodForm: false,
        formFeedback: 'LOW VISIBILITY',
      );
    }

    final hasShoulders = leftShoulder != null && rightShoulder != null;
    final shoulderWidth = hasShoulders
        ? (leftShoulder.x - rightShoulder.x).abs()
        : 0.0;
    final torsoLength = hasShoulders
        ? (dominantHip.y - leftShoulder.y).abs()
        : 1.0;

    // Front profile if both shoulders are visible and horizontally separated somewhat reasonably
    final isFrontProfile =
        hasShoulders &&
        leftShoulder.likelihood > 0.5 &&
        rightShoulder.likelihood > 0.5 &&
        (shoulderWidth > torsoLength * 0.35);

    // Process angles
    double rawAngle = calculateAngle(dominantHip, dominantKnee, dominantAnkle);

    // If facing the camera, the 2D joint angle often stays near 180 due to foreshortening.
    // We synthesize an effective angle interpreting the Y-axis compression of the femur.
    if (isFrontProfile) {
      final femurY = dominantKnee.y - dominantHip.y; // Positive when standing
      final tibiaY = (dominantAnkle.y - dominantKnee.y).abs().clamp(
        1.0,
        double.infinity,
      );
      final depthRatio = (femurY / tibiaY).clamp(-0.5, 1.2);
      // ratio ~ 1.0 = standing (180 deg)
      // ratio ~ 0.0 = parallel (90 deg)
      final syntheticAngle = 90.0 + (depthRatio * 90.0);

      // Use the smaller (more bent) of the two to aggressively detect depth from the front
      rawAngle = min(rawAngle, syntheticAngle);
    }

    _smoothedSquatAngle = _smoothedSquatAngle == null
        ? rawAngle
        : (_smoothedSquatAngle! * (1 - ExerciseConstants.squatAngleSmoothing)) +
              (rawAngle * ExerciseConstants.squatAngleSmoothing);
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

    final legLength = sqrt(
      pow(dominantHip.x - dominantAnkle.x, 2) +
          pow(dominantHip.y - dominantAnkle.y, 2),
    );
    final normalizedLegLength = legLength < 1 ? 1.0 : legLength;
    final currentHipDepth = dominantHip.y / normalizedLegLength;
    final currentKneeDepth = dominantKnee.y / normalizedLegLength;

    final standingBaselineReady =
        _standingHipDepth != null &&
        _standingKneeDepth != null &&
        _standingBaselineFrames > 2;
    final supportFootAnchored =
        dominantFootVisibility > ExerciseConstants.confidenceThreshold &&
        dominantFootVisibility >=
            oppositeFootVisibility - ExerciseConstants.squatSideLockMargin;

    if (_currentPhase == ExercisePhase.resting &&
        effectiveAngle >= ExerciseConstants.squatUpAngle - 3 &&
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
    } else if (_currentPhase == ExercisePhase.resting &&
        effectiveAngle >= ExerciseConstants.squatUpAngle - 3) {
      _standingBaselineFrames = 0;
    }

    final hipDropFromStand = standingBaselineReady
        ? currentHipDepth - _standingHipDepth!
        : 0.0;
    final kneeDropFromStand = standingBaselineReady
        ? currentKneeDepth - _standingKneeDepth!
        : 0.0;

    final squatMotionConfirmed =
        !standingBaselineReady ||
        (hipDropFromStand >= ExerciseConstants.squatHipDropThreshold &&
            kneeDropFromStand >= ExerciseConstants.squatKneeDropThreshold);

    // Check back straightness using shoulder-hip-knee relationship on the dominant side
    final dominantShoulder = isLeftLegDominant
        ? landmarks[PoseLandmarkType.leftShoulder]
        : landmarks[PoseLandmarkType.rightShoulder];

    bool isGoodForm = true;
    String? feedback;

    if (dominantShoulder != null &&
        dominantShoulder.likelihood > ExerciseConstants.confidenceThreshold) {
      final backAngle = calculateAngle(
        dominantShoulder,
        dominantHip,
        dominantKnee,
      );
      // In a deep squat from the side, a proper neutral spine leans forward.
      // 60 degrees was too strict for many healthy squats. Let's relax it to 35.
      if (backAngle < 35) {
        isGoodForm = false;
        feedback = 'KEEP CHEST UP';
      }
    }

    switch (_currentPhase) {
      case ExercisePhase.resting:
        // Begin moving down if angle drops below top standing threshold
        if (effectiveAngle < ExerciseConstants.squatUpAngle - 10 &&
            squatMotionConfirmed)
          _currentPhase = ExercisePhase.descending;
        break;
      case ExercisePhase.descending:
        if (effectiveAngle <= ExerciseConstants.squatDownAngle) {
          _currentPhase = ExercisePhase.active;
        } else if (effectiveAngle >= ExerciseConstants.squatUpAngle - 10) {
          _currentPhase = ExercisePhase.resting;
          isGoodForm = false;
          feedback = 'FULL DEPTH REQUIRED';
        }
        break;
      case ExercisePhase.active:
        // Transition to ascending once they start standing up out of the hole
        if (effectiveAngle > ExerciseConstants.squatDownAngle + 10) {
          _currentPhase = ExercisePhase.ascending;
        }
        break;
      case ExercisePhase.ascending:
        // Only count a rep when they reach full standing
        if (effectiveAngle >= ExerciseConstants.squatUpAngle - 10) {
          _currentPhase = ExercisePhase.resting;
          _repCount++;
        } else if (effectiveAngle <= ExerciseConstants.squatDownAngle) {
          // If they dip back down before standing, reset to active
          _currentPhase = ExercisePhase.active;
          isGoodForm = false;
          feedback = 'STAND UP FULLY';
        }
        break;
    }

    return _applyHoldLogic(
      effectiveAngle,
      effectiveAngle,
      effectiveAngle,
      isGoodForm,
      feedback,
    );
  }

  PoseAnalysisResult _analyzePushup(
    Map<PoseLandmarkType, PoseLandmark> landmarks,
  ) {
    bool isGoodForm = true;
    String? feedback;

    final nose = landmarks[PoseLandmarkType.nose];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow = landmarks[PoseLandmarkType.rightElbow];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];

    // Additional checkpoints for full body lock
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];

final hasLeftArm = leftShoulder != null && leftElbow != null && leftWrist != null
        && leftShoulder.likelihood > 0.4 && leftElbow.likelihood > 0.4 && leftWrist.likelihood > 0.4;
    final hasRightArm = rightShoulder != null && rightElbow != null && rightWrist != null
        && rightShoulder.likelihood > 0.4 && rightElbow.likelihood > 0.4 && rightWrist.likelihood > 0.4;

    if (!hasLeftArm && !hasRightArm) {
      return PoseAnalysisResult(
        phase: _currentPhase,
        repCount: _repCount,
        isGoodForm: false,
        formFeedback: 'ARMS NOT VISIBLE',
      );
    }

    final leftLikelihood = hasLeftArm ? (leftShoulder.likelihood + leftElbow.likelihood + leftWrist.likelihood) / 3 : 0.0;
    final rightLikelihood = hasRightArm ? (rightShoulder.likelihood + rightElbow.likelihood + rightWrist.likelihood) / 3 : 0.0;

    final bool isLeftDominant = leftLikelihood > rightLikelihood;
    final domShoulder = isLeftDominant ? leftShoulder! : rightShoulder!;
    final domElbow = isLeftDominant ? leftElbow! : rightElbow!;
    final domWrist = isLeftDominant ? leftWrist! : rightWrist!;
    // Use the hips/knees from the SAME side as the dominant arm to ensure valid geometric pairs
    final domHip = isLeftDominant ? leftHip : rightHip;
    final domKnee = isLeftDominant ? leftKnee : rightKnee;
    final domAnkle = isLeftDominant ? leftAnkle : rightAnkle;

    // Front vs Side profile checks
    final hasBothShoulders = leftShoulder != null && rightShoulder != null;
    final shoulderWidth = hasBothShoulders ? (leftShoulder.x - rightShoulder.x).abs() : 0.0;
    
    // Check likelihoods to prevent falsely assuming a solid front profile just because landmarks exist
    final isFrontProfile = hasBothShoulders && hasLeftArm && hasRightArm && 
        leftShoulder.likelihood > 0.6 &&
        rightShoulder.likelihood > 0.6 &&
        shoulderWidth > 0.15; // Normalized width threshold. If side profile, shoulderWidth approaches 0.

    double rawAngle = 180.0;

    if (isFrontProfile) {
      final lAngle = calculateAngle(leftShoulder, leftElbow, leftWrist);
      final rAngle = calculateAngle(rightShoulder, rightElbow, rightWrist);

      if ((lAngle - rAngle).abs() > 45) {
        isGoodForm = false;
        feedback = 'KEEP ARMS EVEN';
      }

      // Synthesize angle based on Y compression for front view
      final avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
      final avgWristY = (leftWrist.y + rightWrist.y) / 2;
      final armLength = sqrt(pow(leftShoulder.x - leftWrist.x, 2) + pow(leftShoulder.y - leftWrist.y, 2));
      
      final yDist = (avgShoulderY - avgWristY).abs();
      // ratio 1.0 = fully standing (Y distance is full arm length)
      // ratio 0.0 = fully down (Y distance is 0, wrists level with shoulders)
      final ratio = (yDist / (armLength < 1 ? 1 : armLength)).clamp(0.0, 1.0);
      final syntheticAngle = 90.0 + (ratio * 90.0);
      
      // Use the minimum of true 2D angle and synthetic angle
      rawAngle = min(min(lAngle, rAngle), syntheticAngle);

      // Relaxed Anti-cheat: Enforce horizontal torso using foreshortening check.
      if (domHip != null) {
         final torsoDy = (domHip.y - avgShoulderY).abs();
         if (torsoDy > shoulderWidth * 2.5) { // very permissive to allow strange camera angles
            isGoodForm = false;
            feedback = 'GET HORIZONTAL';
         }
      }
    } else {
      // Side Profile
      rawAngle = calculateAngle(domShoulder, domElbow, domWrist);

      if (domHip != null && domAnkle != null && domHip.likelihood > 0.5 && domAnkle.likelihood > 0.5) {
        // Back straightness
        final backAngle = calculateAngle(domShoulder, domHip, domAnkle);
        if (backAngle < 145) { // lowered from 155 to be more forgiving
          isGoodForm = false;
          feedback = 'KEEP BACK STRAIGHT';
        }

        // Knees locked
        if (domKnee != null && domKnee.likelihood > 0.5) {
          final kneeAngle = calculateAngle(domHip, domKnee, domAnkle);
          if (kneeAngle < 140) {
            isGoodForm = false;
            feedback = 'STRAIGHTEN KNEES';
          }
        }

        // Relaxed Horizontal anti-cheat
        final bodySlopeAngle = atan2((domAnkle.y - domShoulder.y).abs(), (domAnkle.x - domShoulder.x).abs()) * 180 / pi;
        if (bodySlopeAngle > 75) {
          isGoodForm = false;
          feedback = 'GET HORIZONTAL';
        }
      } else if (domHip != null && domHip.likelihood > 0.5) {
        // Partial body (Ankle missing, Hip visible)
        final torsoSlopeAngle = atan2((domHip.y - domShoulder.y).abs(), (domHip.x - domShoulder.x).abs()) * 180 / pi;
        if (torsoSlopeAngle > 75) {
          isGoodForm = false;
          feedback = 'GET HORIZONTAL';
        }
      } else {
        // Only torso/shoulder/face visible (severe partial)
        if (nose != null && nose.likelihood > 0.5) {
          final verticalStandAngle = atan2((domShoulder.y - nose.y).abs(), (domShoulder.x - nose.x).abs()) * 180 / pi;
          if (verticalStandAngle > 75) {
            isGoodForm = false;
            feedback = 'GET HORIZONTAL';
          }
        }
      }
    }

    _smoothedPushupAngle = _smoothedPushupAngle == null
        ? rawAngle
        : (_smoothedPushupAngle! * (1 - ExerciseConstants.squatAngleSmoothing)) +
            (rawAngle * ExerciseConstants.squatAngleSmoothing);
    final effectiveAngle = _smoothedPushupAngle!;

    switch (_currentPhase) {
      case ExercisePhase.resting:
        if (effectiveAngle < ExerciseConstants.pushupUpAngle - 10)
          _currentPhase = ExercisePhase.descending;
        break;
      case ExercisePhase.descending:
        if (effectiveAngle <= ExerciseConstants.pushupDownAngle) {
          _currentPhase = ExercisePhase.active;
        } else if (effectiveAngle >= ExerciseConstants.pushupUpAngle - 10) {
          _currentPhase = ExercisePhase.resting;
          isGoodForm = false;
          feedback = 'GO DEEPER';
        }
        break;
      case ExercisePhase.active:
        if (effectiveAngle > ExerciseConstants.pushupDownAngle + 10)
          _currentPhase = ExercisePhase.ascending;
        break;
      case ExercisePhase.ascending:
        if (effectiveAngle >= ExerciseConstants.pushupUpAngle - 10) {
          _currentPhase = ExercisePhase.resting;
          _repCount++;
        } else if (effectiveAngle <= ExerciseConstants.pushupDownAngle) {
          _currentPhase = ExercisePhase.active;
          isGoodForm = false;
          feedback = 'PUSH UP FULLY';
        }
        break;
    }

    // Pass the same angle for both arms to the hold logic (it expects L/R/Effective)
    return _applyHoldLogic(
      effectiveAngle,
      effectiveAngle,
      effectiveAngle,
      isGoodForm,
      feedback,
    );
  }

  PoseAnalysisResult _analyzePlank(
    Map<PoseLandmarkType, PoseLandmark> landmarks,
  ) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];

    if (leftShoulder == null || leftHip == null || leftAnkle == null) {
      return PoseAnalysisResult(
        phase: _currentPhase,
        repCount: _repCount,
        isGoodForm: false,
        formFeedback: 'SIDE PROFILE REQUIRED',
      );
    }

    final bodyAngle = calculateAngle(leftShoulder, leftHip, leftAnkle);
    final isGoodForm = bodyAngle >= 160 && bodyAngle <= 190;
    String? feedback;
    if (!isGoodForm) {
      feedback = bodyAngle < 160 ? 'LOWER YOUR HIPS' : 'RAISE YOUR HIPS';
    }

    // Plank has no reps, just form tracking. Reps simulate continuous valid state.
    // If good form, we fake a "rep" locally or just return the static state.
    _currentPhase = ExercisePhase.active;

    return PoseAnalysisResult(
      leftMainAngle: bodyAngle,
      rightMainAngle: bodyAngle,
      effectiveAngle: bodyAngle,
      phase: _currentPhase,
      repCount: 0,
      isGoodForm: isGoodForm,
      formFeedback: feedback,
    );
  }

  PoseAnalysisResult _applyHoldLogic(
    double leftAngle,
    double rightAngle,
    double effectiveAngle,
    bool isGoodForm,
    String? feedback,
  ) {
    bool holdTriggered = false;
    bool holdPassed = false;

    if (_repCount >= _nextHoldRep && !_holdActive) {
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
      leftMainAngle: leftAngle,
      rightMainAngle: rightAngle,
      effectiveAngle: effectiveAngle,
      phase: _currentPhase,
      repCount: _repCount,
      isGoodForm: isGoodForm,
      holdTriggered: holdTriggered,
      holdPassed: holdPassed,
      formFeedback: feedback,
    );
  }
}
