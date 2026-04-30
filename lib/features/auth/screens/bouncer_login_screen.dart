import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/audio/fauj_audio_engine.dart';
import '../services/auth_service.dart';

class BouncerLoginScreen extends StatefulWidget {
  const BouncerLoginScreen({super.key});

  @override
  State<BouncerLoginScreen> createState() => _BouncerLoginScreenState();
}

class _BouncerLoginScreenState extends State<BouncerLoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggeredController;
  late AnimationController _pulseController;

  late Animation<double> _glowFadeAnim;
  late Animation<double> _glowPulseAnim;

  late Animation<Offset> _logoSlideAnim;
  late Animation<double> _logoFadeAnim;

  late Animation<double> _buttonScaleAnim;
  late Animation<double> _buttonFadeAnim;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Intro sequence (0.0s to 1.5s)
    _staggeredController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Infinite pulse sequence
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Phase 1: Glow Fade In (0.0s - 0.8s) -> Interval 0.0 to 0.533
    _glowFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.0, 0.533, curve: Curves.easeIn),
      ),
    );

    // Continual 5% Pulse (scale 1.0 to 1.05)
    _glowPulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // Phase 2: Logo and Text Slide & Fade (0.4s - 1.0s) -> Interval 0.266 to 0.666
    _logoSlideAnim =
        Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _staggeredController,
            curve: const Interval(0.266, 0.666, curve: Curves.easeOutCubic),
          ),
        );
    _logoFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.266, 0.666, curve: Curves.easeOut),
      ),
    );

    // Phase 3: Button Scale & Fade (1.0s - 1.5s) -> Interval 0.666 to 1.0
    _buttonScaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.666, 1.0, curve: Curves.easeOutBack),
      ),
    );
    _buttonFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.666, 1.0, curve: Curves.easeOut),
      ),
    );

    _staggeredController.forward();
  }

  @override
  void dispose() {
    _staggeredController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    FaujAudioEngine().playTap();
    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.signInWithGoogle();
      if (mounted) {
        final isComplete = await AuthService.isOnboardingComplete();
        if (mounted) {
          if (isComplete) {
            context.go(AppRoutes.dashboard);
          } else {
            context.go(AppRoutes.exerciseSelection);
          }
        }
      }
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        final errorMsg = e.toString().toLowerCase();
        final isCancel =
            errorMsg.contains('cancel') || errorMsg.contains('abort');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCancel
                  ? 'Sign-in cancelled.'
                  : 'Authentication failed. Please try again.',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            backgroundColor: const Color(0xFF1A1A1A), // Minimal dark grey
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF333333), width: 1),
            ),
            margin: const EdgeInsets.only(bottom: 32, left: 32, right: 32),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            elevation: 0,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Deep, pure black background
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Glow (Phase 1 + Infinite Pulse)
          Center(
            child: FadeTransition(
              opacity: _glowFadeAnim,
              child: ScaleTransition(
                scale: _glowPulseAnim,
                child: Container(
                  width: size.width * 1.8,
                  height: size.width * 1.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.neonRed.withValues(alpha: 0.12),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // The Hero Content (Phase 2)
          Center(
            child: SlideTransition(
              position: _logoSlideAnim,
              child: FadeTransition(
                opacity: _logoFadeAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AppAssets.logoMain,
                      width: size.width * 0.45,
                      height: size.width * 0.45,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'USTAD AI',
                      style: GoogleFonts.orbitron(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 10, // Wide-spaced Orbitron
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'YOUR PERSONAL DRILL INSTRUCTOR.',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF888888), // Muted grey color
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // The Action (Phase 3)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: ScaleTransition(
                  scale: _buttonScaleAnim,
                  child: FadeTransition(
                    opacity: _buttonFadeAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 64, // Massive, premium button
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleGoogleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Colors.black,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Google 'G' logo
                                      Image.network(
                                        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Google_%22G%22_Logo.svg/512px-Google_%22G%22_Logo.svg.png',
                                        width: 24,
                                        height: 24,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Text(
                                                'G',
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.black,
                                                ),
                                              );
                                            },
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'CONTINUE WITH GOOGLE',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'By proceeding, you accept the Rules of Engagement.',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            color: const Color(0xFF666666),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
