import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseMath {
  static double calculateJointAngle(PoseLandmark? a, PoseLandmark? b, PoseLandmark? c) {
    if (a == null || b == null || c == null) return 180.0;
    final radians = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x);
    var angle = radians.abs() * 180 / pi;
    if (angle > 180) angle = 360 - angle;
    return angle;
  }

  static double smoothAngle(double rawAngle, double previousAngle, {double alpha = 0.3}) {
    if (previousAngle == -1.0) return rawAngle;
    return (rawAngle * alpha) + (previousAngle * (1.0 - alpha));
  }
}
