import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/theme/ustad_theme.dart';
import 'package:kasrat_ai/core/widgets/curved_text.dart';

/// Boot splash — glitch effect, then route to login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _glitchOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _glitchOffset =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: 8), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 8, end: -6), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -6, end: 4), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 4, end: -2), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -2, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.4, 0.7, curve: Curves.easeInOut),
          ),
        );

    _controller.forward();

    // Navigate after animation
    Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        context.go(AppRoutes.bouncerLogin);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Center(
            child: Opacity(
              opacity: _fadeIn.value,
              child: Transform.translate(
                offset: Offset(_glitchOffset.value, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App Logo
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Image.asset(
                          AppAssets.logoMain,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Text(
                            AppStrings.appName,
                            style: UstadTheme.counterMassive.copyWith(
                              fontSize: 48,
                              letterSpacing: 12,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -30,
                          child: CurvedText(
                            text: 'USTAD AI',
                            radius: 100,
                            startAngle: 0.0,
                            textStyle: GoogleFonts.orbitron(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.tagline,
                      style: UstadTheme.sectionHeader.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 6,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Scanline bar
                    SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(
                        backgroundColor: AppColors.surface,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.neonRed,
                        ),
                        minHeight: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
