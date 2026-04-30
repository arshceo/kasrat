import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';

class DashboardBackground extends StatelessWidget {
  const DashboardBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: DashboardGridPainter())),
        Positioned(
          right: -80,
          bottom: 100,
          child: Transform.rotate(
            angle: -0.1,
            child: Text(
              'USTAD',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 150,
                fontWeight: FontWeight.w900,
                color: AppColors.surfaceContainerHigh.withValues(alpha: 0.2),
                letterSpacing: -10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DashboardGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceContainerHigh.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    const double spacing = 40.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
