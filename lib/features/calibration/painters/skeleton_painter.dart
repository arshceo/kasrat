import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import '../services/pose_analyzer.dart';
import '../services/pose_math.dart';

/// Custom painter for drawing ML Kit skeletal overlay on the camera feed.
class SkeletonPainter extends CustomPainter {
  final Pose? pose;
  final Size imageSize;
  final InputImageRotation rotation;
  final PoseAnalysisResult? analysisResult;
  final bool isFrontCamera;

  SkeletonPainter({
    required this.pose,
    required this.imageSize,
    required this.rotation,
    this.analysisResult,
    this.isFrontCamera = true,
  });

  // Skeletal connection pairs for drawing
  static const List<(PoseLandmarkType, PoseLandmarkType)> _connections = [
    // Torso
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
    // Left arm
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
    (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
    // Right arm
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
    (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
    // Left leg
    (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
    (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
    // Right leg
    (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
    (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (pose == null) return;

    final paintGood = Paint()
      ..color = AppColors.skeletonGood
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final paintBad = Paint()
      ..color = AppColors.skeletonBad
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final paintNeutral = Paint()
      ..color = AppColors.skeletonNeutral
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final jointPaint = Paint()..style = PaintingStyle.fill;

    final isGoodForm = analysisResult?.isGoodForm ?? true;
    final linePaint = isGoodForm ? paintGood : paintBad;

    // Draw connections
    for (final (start, end) in _connections) {
      final startLandmark = pose!.landmarks[start];
      final endLandmark = pose!.landmarks[end];
      if (startLandmark == null || endLandmark == null) continue;
      if (startLandmark.likelihood < ExerciseConstants.confidenceThreshold ||
          endLandmark.likelihood < ExerciseConstants.confidenceThreshold) {
        continue;
      }

      final p1 = _transformPoint(startLandmark, size);
      final p2 = _transformPoint(endLandmark, size);

      // Use highlight color for leg connections (key for squat tracking)
      final isLegConnection =
          (start == PoseLandmarkType.leftHip ||
              start == PoseLandmarkType.leftKnee ||
              start == PoseLandmarkType.rightHip ||
              start == PoseLandmarkType.rightKnee) &&
          (end == PoseLandmarkType.leftKnee ||
              end == PoseLandmarkType.leftAnkle ||
              end == PoseLandmarkType.rightKnee ||
              end == PoseLandmarkType.rightAnkle);

      canvas.drawLine(p1, p2, isLegConnection ? linePaint : paintNeutral);
    }

    // Collect all essential landmarks from our connections list
    final essentialLandmarks = <PoseLandmarkType>{};
    for (final (start, end) in _connections) {
      essentialLandmarks.add(start);
      essentialLandmarks.add(end);
    }

    // Draw only essential joints
    for (final landmarkType in essentialLandmarks) {
      final landmark = pose!.landmarks[landmarkType];
      if (landmark == null ||
          landmark.likelihood < ExerciseConstants.confidenceThreshold) {
        continue;
      }

      final point = _transformPoint(landmark, size);

      // Larger dots for knee joints
      final isKnee =
          landmark.type == PoseLandmarkType.leftKnee ||
          landmark.type == PoseLandmarkType.rightKnee;

      jointPaint.color = isGoodForm
          ? AppColors.skeletonGood
          : AppColors.skeletonBad;

      canvas.drawCircle(point, isKnee ? 8 : 5, jointPaint);

      // Glow on knee joints
      if (isKnee) {
        final glowPaint = Paint()
          ..color =
              (isGoodForm ? AppColors.skeletonGood : AppColors.skeletonBad)
                  .withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(point, 12, glowPaint);
      }
    }

    // Draw angle arc at knees
    _drawKneeAngle(
      canvas,
      size,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.leftAnkle,
      isGoodForm,
    );
    _drawKneeAngle(
      canvas,
      size,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.rightAnkle,
      isGoodForm,
    );
  }

  void _drawKneeAngle(
    Canvas canvas,
    Size size,
    PoseLandmarkType hipType,
    PoseLandmarkType kneeType,
    PoseLandmarkType ankleType,
    bool isGood,
  ) {
    final hip = pose!.landmarks[hipType];
    final knee = pose!.landmarks[kneeType];
    final ankle = pose!.landmarks[ankleType];
    if (hip == null || knee == null || ankle == null) return;

    final kneePoint = _transformPoint(knee, size);
    final angle = PoseMath.calculateJointAngle(hip, knee, ankle);

    // Draw angle text
    final textSpan = TextSpan(
      text: '${angle.toInt()}°',
      style: TextStyle(
        color: isGood ? AppColors.skeletonGood : AppColors.skeletonBad,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 4),
        ],
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(kneePoint.dx + 14, kneePoint.dy - 8));
  }

  Offset _transformPoint(PoseLandmark landmark, Size canvasSize) {
    // If ML Kit rotated the image 90/270 degrees, the absolute image bounds swapped.
    final bool isRotated =
        rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;

    final double absoluteImageWidth = isRotated ? imageSize.height : imageSize.width;
    final double absoluteImageHeight = isRotated ? imageSize.width : imageSize.height;

    final scaleX = canvasSize.width / absoluteImageWidth;
    final scaleY = canvasSize.height / absoluteImageHeight;

    // Use uniform scaling to maintain aspect ratio (BoxFit.cover style)
    final scale = math.max(scaleX, scaleY);

    final offsetX = (canvasSize.width - (absoluteImageWidth * scale)) / 2;
    final offsetY = (canvasSize.height - (absoluteImageHeight * scale)) / 2;

    double x = (landmark.x * scale) + offsetX;
    double y = (landmark.y * scale) + offsetY;

    if (isFrontCamera) {
      x = canvasSize.width - x;
    }

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant SkeletonPainter oldDelegate) {
    return oldDelegate.pose != pose ||
        oldDelegate.analysisResult != analysisResult;
  }
}
