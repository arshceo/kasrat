import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/audio/fauj_audio_engine.dart';
import 'package:kasrat_ai/core/services/settings_service.dart';

class RankUnlockedScreen extends StatefulWidget {
  final String rankName;
  final String insigniaPath;
  final bool isSilent;

  const RankUnlockedScreen({
    super.key,
    required this.rankName,
    required this.insigniaPath,
    this.isSilent = false,
  });

  @override
  State<RankUnlockedScreen> createState() => _RankUnlockedScreenState();
}

class _RankUnlockedScreenState extends State<RankUnlockedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _shakeAnimation;

  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Initial scale starts massive, slams into 1.0 quickly
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 10.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInQuint)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.1,
        ).chain(CurveTween(curve: const ElasticOutCurve(0.8))),
        weight: 30,
      ),
      TweenSequenceItem(tween: ConstantTween(1.1), weight: 50),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 90),
    ]).animate(_controller);

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20), // wait for slam
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: -1.0,
        ).chain(CurveTween(curve: Curves.bounceInOut)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -1.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.bounceInOut)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: -0.5,
        ).chain(CurveTween(curve: Curves.bounceInOut)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -0.5,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 50),
    ]).animate(_controller);

    _controller.forward();

    // Trigger sounds and haptics at specific moments
    Future.delayed(const Duration(milliseconds: 100), () {
      FaujAudioEngine().forcePlay('long_beep.mp3'); // Suspense
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      // The moment of impact
      HapticFeedback.heavyImpact();
      HapticFeedback.vibrate();
      FaujAudioEngine().forcePlay('metal_door_close.mp3'); // Huge slam sound
    });

    // Voice Feedback (Male Commanding Voice)
    if (!widget.isSilent) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          _announceRank();
        }
      });
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      // Small echo
      HapticFeedback.mediumImpact();
    });
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setPitch(0.5); // Deeper male-like tone
    await _tts.setSpeechRate(0.45); // Slower, more commanding
    await _tts.setVolume(1.0);
  }

  Future<void> _announceRank() async {
    if (!SettingsService().isAudioEnabled) return;
    final String rank = widget.rankName.toUpperCase();
    await _tts.speak('Good job. You are now a $rank.');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Pure Brutalist Black
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final shakeDist = _shakeAnimation.value * 15.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              // No background flashes, strictly binary
              Center(
                child: Transform.translate(
                  offset: Offset(
                    (Random().nextDouble() - 0.5) * shakeDist,
                    (Random().nextDouble() - 0.5) * shakeDist,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Telemetry Header
                      Opacity(
                        opacity: _controller.value > 0.4 ? 1.0 : 0.0,
                        child: Container(
                          width: 200, // Narrowed from 260
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SYS_AUTH: VERIFIED',
                                style: GoogleFonts.spaceMono(
                                  color: const Color(0xFF555555),
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'CL_LVL: ALPHA', // Shortened for middle positioning
                                style: GoogleFonts.spaceMono(
                                  color: const Color(0xFF555555),
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Targeted Badge Area
                      Opacity(
                        opacity: _opacityAnimation.value,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Targeting Brackets
                              SizedBox(
                                width: 220, // Slightly tighter brackets
                                height: 220,
                                child: CustomPaint(
                                  painter: _BrutalTargetPainter(),
                                ),
                              ),

                              // The Insignia (with Luma Key)
                              ColorFiltered(
                                colorFilter: const ColorFilter.matrix([
                                  1,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                  0,
                                  1,
                                  1,
                                  1,
                                  0,
                                  -0.1,
                                ]),
                                child: Image.asset(
                                  widget.insigniaPath,
                                  width: 170, // Slightly smaller for better fit
                                  height: 170,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Telemetry Footer
                      Opacity(
                        opacity: _controller.value > 0.4 ? 1.0 : 0.0,
                        child: Container(
                          width: 200, // Narrowed from 260
                          padding: const EdgeInsets.only(top: 8),
                          alignment: Alignment.center,
                          child: Text(
                            'TS: ${DateTime.now().toIso8601String().substring(0, 19)}', // Shortened timestamp
                            style: GoogleFonts.spaceMono(
                              color: const Color(0xFF555555),
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Rank Title: Strict White Monospace
                      Opacity(
                        opacity: _controller.value > 0.35 ? 1.0 : 0.0,
                        child: Text(
                          widget.rankName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceMono(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tactical Acknowledge Button
              if (_controller.value > 0.8)
                Positioned(
                  bottom: 50,
                  left: 40,
                  right: 40,
                  child: GestureDetector(
                    onTap: () {
                      FaujAudioEngine().playTap();
                      context.pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.neonRed, // Use Primary Red
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '[ ACKNOWLEDGE ]',
                        style: GoogleFonts.spaceMono(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BrutalTargetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const cornerLength = 20.0;

    // Top Left
    canvas.drawLine(Offset.zero, const Offset(cornerLength, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, cornerLength), paint);

    // Top Right
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint,
    );

    // Bottom Left
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - cornerLength),
      paint,
    );

    // Bottom Right
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - cornerLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
