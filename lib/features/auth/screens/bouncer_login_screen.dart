import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../services/auth_service.dart';

/// Screen A-01: "UNAUTHORIZED PERSONNEL" — the bouncer login.
class BouncerLoginScreen extends StatefulWidget {
  const BouncerLoginScreen({super.key});

  @override
  State<BouncerLoginScreen> createState() => _BouncerLoginScreenState();
}

class _BouncerLoginScreenState extends State<BouncerLoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _scanlineController;
  late Animation<double> _scanlinePosition;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scanlineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _scanlinePosition = Tween<double>(
      begin: -0.1,
      end: 1.1,
    ).animate(_scanlineController);
  }

  @override
  void dispose() {
    _scanlineController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.signInWithGoogle();
      if (mounted) {
        context.go(AppRoutes.languageSelection);
      }
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background pattern
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          // Scanline effect
          AnimatedBuilder(
            animation: _scanlinePosition,
            builder: (context, _) {
              return Positioned(
                top: size.height * _scanlinePosition.value,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.neonRed.withValues(alpha: 0.4),
                        AppColors.neonRed.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Urgency meters (Left)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 8,
            child: Container(color: AppColors.surfaceContainerLow),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 8,
            child: FractionallySizedBox(
              heightFactor: 1.0,
              alignment: Alignment.topCenter,
              child: Container(color: AppColors.neonRed),
            ),
          ),

          // Urgency meters (Right)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 8,
            child: Container(color: AppColors.surfaceContainerLow),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 8,
            child: FractionallySizedBox(
              heightFactor: 0.3,
              alignment: Alignment.topCenter,
              child: Container(color: AppColors.neonRed),
            ),
          ),

          // Center content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Navigation
                  Row(
                    children: [
                      const Icon(
                        Icons.security,
                        color: AppColors.neonRed,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'USTAD AI',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.neonRed,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Main Body
                  Row(
                    children: [
                      Container(width: 8, height: 8, color: AppColors.neonRed),
                      const SizedBox(width: 8),
                      Text(
                        'TERMINAL: AUTH_REQUIRED',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          color: AppColors.neonRed,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Massive Headline
                  Text(
                    'UNAUTHORIZED\nPERSONNEL',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: size.width * 0.12 > 48 ? 48 : size.width * 0.12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      height: 0.85,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Technical Subtext
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: AppColors.neonRed, width: 4),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 16),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textSecondary,
                          height: 1.2,
                        ),
                        children: [
                          const TextSpan(
                            text: 'You are not active in the system. ',
                          ),
                          TextSpan(
                            text: 'Authenticate',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const TextSpan(
                            text: ' to begin the 28-Day Protocol.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          color: AppColors.danger,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.background,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Typically we'd load google icon asset here
                                const Icon(Icons.login, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'CONTINUE WITH GOOGLE',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // System Metrics decoration
                  Container(
                    padding: const EdgeInsets.only(top: 24, bottom: 32),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppColors.surfaceGlass.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _metricItem('ACCESS_LEVEL', 'ZERO_CLEARANCE'),
                            _metricItem('SYSTEM_TIME', '03:44:12_UTC'),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _metricItem('IP_ADDR', '192.XXX.X.X'),
                            _metricItem('LATENCY', '2.4MS'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textMuted
          .withValues(alpha: 0.03) // Very subtle
      ..strokeWidth = 1.0;
    const spacing = 40.0;
    // Scanlines
    for (double y = 0; y < size.height; y += 2) {
      if (y % 4 == 0) continue;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical grid
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
