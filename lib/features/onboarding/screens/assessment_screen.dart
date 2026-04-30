import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';

class AssessmentScreen extends StatelessWidget {
  final int assessmentDay;

  const AssessmentScreen({super.key, required this.assessmentDay});

  @override
  Widget build(BuildContext context) {
    // Determine the day to show, bound it up to 3
    final int displayDay = assessmentDay > 3
        ? 3
        : (assessmentDay < 1 ? 1 : assessmentDay);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Brutalist Grid Pattern Background
          CustomPaint(
            size: Size.infinite,
            painter: _BrutalistGridPainter(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '3-DAY BASELINE',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: -2,
                    ),
                  ),
                  Text(
                    'ASSESSMENT',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: AppColors.neonRed,
                      height: 1.0,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Progress Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Blinking red dot
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1000),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: (value > 0.5 ? 1.0 : 0.2),
                              child: child,
                            );
                          },
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: AppColors.neonRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          'DAY $displayDay OF 3',
                          style: GoogleFonts.spaceMono(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // The Hook
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: AppColors.neonRed, width: 4)),
                    ),
                    child: Text(
                      'Before the AI builds your 28-day plan, you must prove your baseline. The camera will track your form. Do not cheat.',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // The Action
                  ElevatedButton(
                    onPressed: () {
                      context.push(AppRoutes.strengthTestSetup);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonRed,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text(
                      '[ START DAY $displayDay TEST ]',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrutalistGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceContainerHigh.withValues(alpha: 0.3)
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
