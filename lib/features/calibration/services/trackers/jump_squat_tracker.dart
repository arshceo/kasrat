import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../exercise_tracker.dart';
import '../pose_math.dart';

class JumpSquatTracker extends BaseExerciseTracker {
  double? _standingHipY;
  double? _standingTorsoLength;
  double? _smoothedLegAngle;

  @override
  void reset() {
    super.reset();
    _standingHipY = null;
    _standingTorsoLength = null;
    _smoothedLegAngle = null;
  }

  double _distance(PoseLandmark a, PoseLandmark b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
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

    final isLeft = leftShoulder.likelihood > rightShoulder.likelihood;
    final domShoulder = isLeft ? leftShoulder : rightShoulder;
    final domHip = landmarks[isLeft ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip];
    final domKnee = landmarks[isLeft ? PoseLandmarkType.leftKnee : PoseLandmarkType.rightKnee];
    final domAnkle = landmarks[isLeft ? PoseLandmarkType.leftAnkle : PoseLandmarkType.rightAnkle];

    if (domHip == null || domKnee == null || domAnkle == null ||
        domShoulder.likelihood < 0.6 || domHip.likelihood < 0.6 || domKnee.likelihood < 0.6 || domAnkle.likelihood < 0.6) {
      return PoseAnalysisResult(phase: currentPhase, repCount: repCount, isGoodForm: false, formFeedback: 'KEEP FULL BODY IN FRAME');
    }

    final rawLegAngle = PoseMath.calculateJointAngle(domHip, domKnee, domAnkle);
    _smoothedLegAngle = PoseMath.smoothAngle(rawLegAngle, _smoothedLegAngle ?? rawLegAngle, alpha: 0.35);
    final legAngle = _smoothedLegAngle!;

    // CALIBRATION: Only update when standing upright and resting.
    if (legAngle > 160 && currentPhase == ExercisePhase.resting) {
      if (_standingHipY == null) {
        _standingHipY = domHip.y;
        _standingTorsoLength = _distance(domShoulder, domHip);
      } else {
        _standingHipY = (_standingHipY! * 0.9) + (domHip.y * 0.1);
        _standingTorsoLength = (_standingTorsoLength! * 0.9) + (_distance(domShoulder, domHip) * 0.1);
      }
    }

    if (_standingHipY == null || _standingTorsoLength == null) {
      return PoseAnalysisResult(phase: currentPhase, repCount: repCount, isGoodForm: true, formFeedback: 'STAND STRAIGHT TO CALIBRATE');
    }

    // THE THRESHOLDS
    final squatThreshold = _standingHipY! + (_standingTorsoLength! * 0.20); 
    final jumpThreshold = _standingHipY! - (_standingTorsoLength! * 0.08); // 8% above standing height

    switch (currentPhase) {
      case ExercisePhase.resting:
        // Start the drop
        if (domHip.y > _standingHipY! + (_standingTorsoLength! * 0.05) || legAngle < 140) {
          currentPhase = ExercisePhase.descending;
        }
        break;
        
      case ExercisePhase.descending:
        // Deep enough for a jump squat?
        if (domHip.y > squatThreshold && legAngle < 110) {
          currentPhase = ExercisePhase.active; // In the hole, ready to launch
        } 
        // Bailed out of the squat entirely
        else if (legAngle > 160 && domHip.y < _standingHipY! + (_standingTorsoLength! * 0.10)) {
          currentPhase = ExercisePhase.resting; 
          isGoodForm = false;
          feedback = 'GO DEEPER';
        }
        break;
        
      case ExercisePhase.active:
        // AIRBORNE TRIGGER
        if (domHip.y < jumpThreshold) {
          currentPhase = ExercisePhase.ascending; 
        } 
        // THE RELAXED ESCAPE HATCH:
        // We ONLY fail them if they return to standing height AND start bending their knees 
        // for the next rep without ever hitting the jump threshold.
        else if (domHip.y >= jumpThreshold && domHip.y > _standingHipY! && legAngle < 130) {
          currentPhase = ExercisePhase.descending; // Reset into the next rep
          isGoodForm = false;
          feedback = 'JUMP HIGHER'; 
        }
        break;

      case ExercisePhase.ascending:
        // Waiting for the landing (hip drops back down to standing level)
        if (domHip.y >= _standingHipY! - (_standingTorsoLength! * 0.04)) {
          incrementRep(); // REP SECURED!
          
          if (legAngle < 140) {
            currentPhase = ExercisePhase.descending; // Continuous reps
          } else {
            currentPhase = ExercisePhase.resting; // Paused landing
          }
        }
        break;
    }

    return PoseAnalysisResult(
      effectiveAngle: legAngle,
      phase: currentPhase,
      repCount: repCount,
      isGoodForm: isGoodForm,
      formFeedback: feedback,
    );
  }
}
