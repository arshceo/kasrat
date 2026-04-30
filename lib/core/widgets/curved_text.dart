import 'package:flutter/material.dart';

class CurvedText extends StatelessWidget {
  final String text;
  final double radius;
  final TextStyle textStyle;
  final double startAngle;

  const CurvedText({
    super.key,
    required this.text,
    required this.radius,
    required this.textStyle,
    this.startAngle = 0.0, // Top center
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CurvedTextPainter(
        text: text,
        radius: radius,
        textStyle: textStyle,
        startAngle: startAngle,
      ),
      size: Size(radius * 2, radius * 2),
    );
  }
}

class _CurvedTextPainter extends CustomPainter {
  final String text;
  final double radius;
  final TextStyle textStyle;
  final double startAngle;

  _CurvedTextPainter({
    required this.text,
    required this.radius,
    required this.textStyle,
    required this.startAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Approximate angle per character
    const double angleStep = 0.22;

    // 0 is Top Center in this logic (translate(0, -radius))
    final double totalAngle = (text.length - 1) * angleStep;
    double currentAngle = startAngle - (totalAngle / 2);

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      textPainter.text = TextSpan(text: char, style: textStyle);
      textPainter.layout();

      final charWidth = textPainter.width;

      canvas.save();
      // Rotate such that 0 is top
      canvas.rotate(currentAngle);

      // Move to the radius (top center when rotation is 0)
      canvas.translate(0, -radius);

      // Draw the character
      textPainter.paint(canvas, Offset(-charWidth / 2, 0));

      canvas.restore();

      currentAngle += angleStep;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
