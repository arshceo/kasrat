import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../exercise_tracker.dart';
import '../pose_math.dart';

class PlankTimer extends BaseExerciseTracker {
  double? _smoothedBodyAngle;

  PlankTimer() {
    isHold = true;
  }

  @override
  void reset() {
    super.reset();
    _smoothedBodyAngle = null;
  }

  double _distance(PoseLandmark a, PoseLandmark b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
  }

  @override
  PoseAnalysisResult processPose(Pose pose) {
    final landmarks = pose.landmarks;

    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];

    // 1. THE JOINT GUILLOTINE
    if (leftShoulder == null || rightShoulder == null || leftHip == null || rightHip == null || leftAnkle == null || rightAnkle == null) {
      currentPhase = ExercisePhase.resting;
      updateHoldTime();
      return PoseAnalysisResult(
        phase: currentPhase, 
        repCount: repCount, 
        isGoodForm: false, 
        formFeedback: 'FULL BODY REQUIRED'
      );
    }

    // 2. IDENTIFY DOMINANT SIDE
    final isLeft = leftShoulder.likelihood > rightShoulder.likelihood;
    final domShoulder = isLeft ? leftShoulder : rightShoulder;
    final domElbow = isLeft ? leftElbow : rightElbow;
    final domWrist = isLeft ? leftWrist : rightWrist;
    final domHip = isLeft ? leftHip : rightHip;
    final domAnkle = isLeft ? leftAnkle : rightAnkle;

    if (domShoulder.likelihood < 0.6 || domHip.likelihood < 0.6 || domAnkle.likelihood < 0.6 || domElbow == null || domWrist == null) {
      currentPhase = ExercisePhase.resting;
      updateHoldTime();
      return PoseAnalysisResult(
        phase: currentPhase, 
        repCount: repCount, 
        isGoodForm: false, 
        formFeedback: 'SIDE PROFILE REQUIRED'
      );
    }

    // 3. THE BODY STRAIGHTNESS CHECK (For telemetry)
    final rawBodyAngle = PoseMath.calculateJointAngle(domShoulder, domHip, domAnkle);
    _smoothedBodyAngle = PoseMath.smoothAngle(rawBodyAngle, _smoothedBodyAngle ?? rawBodyAngle, alpha: 0.2);
    final bodyAngle = _smoothedBodyAngle!;

    // 4. THE LASER LINE PROTOCOL (Absolute Y-Coordinate Check)
    final upperArmLength = _distance(domShoulder, domElbow);
    final bodyLength = _distance(domShoulder, domAnkle);
    final supportY = max(domElbow.y, domWrist.y); 
    final shoulderElevation = supportY - domShoulder.y;

    // Calculate exactly where the hip SHOULD be if the body was a perfect steel beam
    final dx = domAnkle.x - domShoulder.x;
    final ratio = dx == 0 ? 0.5 : (domHip.x - domShoulder.x) / dx;
    final expectedHipY = domShoulder.y + (domAnkle.y - domShoulder.y) * ratio;

    // Measure the actual sag (Positive value means the hip is falling toward the floor)
    final hipDeviation = domHip.y - expectedHipY;

    bool isGoodForm = true;
    String? feedback;

    // GATE A: Are the shoulders actually elevated off the floor?
    if (shoulderElevation < (upperArmLength * 0.45)) {
      isGoodForm = false;
      feedback = 'GET OFF THE FLOOR';
    } 
    // GATE B: Are the hips literally resting on the floor? (Hip Y is too close to Elbow Y)
    else if (domHip.y >= (domElbow.y - (bodyLength * 0.05))) {
      isGoodForm = false;
      feedback = 'LIFT HIPS OFF THE FLOOR';
    }
    // GATE C: Is the user sagging slightly? (Deviating more than 6% of body length below the laser line)
    else if (hipDeviation > (bodyLength * 0.06)) {
      isGoodForm = false;
      feedback = 'HIPS TOO LOW (SAGGING)';
    }
    // GATE D: Is the user piking? (Deviating more than 12% above the laser line)
    else if (hipDeviation < -(bodyLength * 0.12)) {
      isGoodForm = false;
      feedback = 'HIPS TOO HIGH';
    }

    if (isGoodForm) {
      currentPhase = ExercisePhase.active; 
    } else {
      currentPhase = ExercisePhase.resting; 
    }

    updateHoldTime();

    return PoseAnalysisResult(
      effectiveAngle: bodyAngle,
      phase: currentPhase,
      repCount: repCount, 
      isGoodForm: isGoodForm,
      formFeedback: feedback,
    );
  }
}
