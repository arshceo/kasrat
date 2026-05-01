import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';

class ActiveMissionScreen extends StatefulWidget {
  const ActiveMissionScreen({super.key});

  @override
  State<ActiveMissionScreen> createState() => _ActiveMissionScreenState();
}

class _ActiveMissionScreenState extends State<ActiveMissionScreen>
    with SingleTickerProviderStateMixin {
  // Mock data for the UI
  final int _currentDay = 15;
  final int _totalDays = 28;

  // Ration checklist state
  final List<bool> _rationsChecked = [false, false, false];
  late Timer _countdownTimer;
  Duration _timeLeft = const Duration(hours: 4, minutes: 12, seconds: 55);

  bool _isLoadingBaseline = true;
  int _baselineSquats = -1;
  int _baselinePushups = -1;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.1, end: 0.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startCountdown();
    _fetchBaseline();
  }

  Future<void> _fetchBaseline() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingBaseline = false);
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('baseline_squats, baseline_pushups')
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _baselineSquats = response?['baseline_squats'] ?? -1;
          _baselinePushups = response?['baseline_pushups'] ?? -1;
          _isLoadingBaseline = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBaseline = false);
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft.inSeconds > 0) {
        setState(() {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Grid Pattern & Ghost Text
          _buildBackground(),

          // Urgency Meter (Left Edge)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 6,
            child: Container(
              color: AppColors.surfaceContainerHighest,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.65,
                    width: double.infinity,
                    color: AppColors.neonRed,
                    // Simulate the shadow glow effect
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonRed.withValues(alpha: 0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Scrollable Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      26,
                      24,
                      20,
                      32,
                    ), // Left padding accounts for urgency meter
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDirectiveHeader(),
                        const SizedBox(height: 32),

                        _buildBentoGrid(),
                        const SizedBox(height: 32),

                        _buildDailyRations(),
                        const SizedBox(height: 48),

                        _buildCommenceDrillCTA(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        // Industrial Grid (using a custom painter or faint repeating containers)
        Positioned.fill(child: CustomPaint(painter: _GridPainter())),
        // Ghost Text
        Positioned(
          right: -80,
          bottom: 100,
          child: Transform.rotate(
            angle: -0.1,
            child: Text(
              'STRIVE',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 180,
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

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: AppColors.background.withValues(alpha: 0.95),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal, color: AppColors.neonRed, size: 24),
              const SizedBox(width: 12),
              Text(
                'MISSION BRIEFING',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.neonRed,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(width: 32, height: 2, color: AppColors.neonRed),
              const SizedBox(width: 8),
              Text(
                'SECURE LINE',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neonRed,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectiveHeader() {
    final bool needsBaseline =
        !_isLoadingBaseline && (_baselineSquats <= 0 || _baselinePushups <= 0);

    if (needsBaseline) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push(AppRoutes.baselineTest);
        },
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) => Container(
            decoration: BoxDecoration(
              color: AppColors.neonRed.withValues(alpha: _pulseAnimation.value),
              border: Border.all(
                color: AppColors.neonRed.withValues(
                  alpha: _pulseAnimation.value * 2,
                ),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonRed.withValues(
                    alpha: _pulseAnimation.value,
                  ),
                  blurRadius: 20 * _pulseAnimation.value,
                  spreadRadius: 2 * _pulseAnimation.value,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'UNLOCK\nYOUR PLAN',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: AppColors.neonRed,
                          letterSpacing: -3,
                          height: 0.9,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.lock_open_rounded,
                      color: AppColors.neonRed,
                      size: 40,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'GIVE YOUR BEST IN TWO SIMPLE EXERCISES TO UNLOCK YOUR CUSTOM 28-DAY CHALLENGE.',
                  style: GoogleFonts.inter(
                    // Simpler font choice
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  color: AppColors.neonRed,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'START YOUR TEST',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.neonRed, width: 6)),
      ),
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MISSION ACTIVE',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -3,
              height: 1.0,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.lock_outline,
            'COLLATERAL: ₹${CommercialConstants.collateralAmount.toInt()}',
            AppColors.neonRed,
          ),
          const SizedBox(height: 4),
          _buildInfoRow(
            Icons.location_on_outlined,
            'LOCATION: PUNJAB',
            Colors.white,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: AppColors.neonRed.withValues(alpha: 0.2),
            child: Text(
              'NO DEVIATIONS AUTHORIZED.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.neonRed,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildBentoGrid() {
    return Row(
      children: [
        // Deployment Progress
        Expanded(
          flex: 3,
          child: Container(
            color: AppColors.surfaceContainerLow,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEPLOYMENT',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$_currentDay',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -2,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      '/$_totalDays',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 4,
                  width: double.infinity,
                  color: AppColors.surfaceContainerHighest,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: _currentDay / _totalDays,
                    child: Container(color: AppColors.neonRed),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Security Status
        Expanded(
          flex: 2,
          child: Container(
            color: AppColors.surfaceContainerHighest,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ASSETS',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                const Icon(Icons.lock, color: AppColors.neonRed, size: 24),
                const SizedBox(height: 4),
                Text(
                  '₹${CommercialConstants.collateralAmount.toInt()}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyRations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MANIFEST_ID: ALPHA-01',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'STATUS: ACTIVE',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        _buildRationItem(
          index: 0,
          time: '0800',
          items: ['4 Boiled Eggs', '1 Banana'],
          bgColor: AppColors.surfaceContainerLow,
        ),
        _buildRationItem(
          index: 1,
          time: '1300',
          items: ['2 Roti', '1 Bowl Dal', 'Dahi'],
          bgColor: AppColors.surfaceContainerHighest,
        ),
        _buildRationItem(
          index: 2,
          time: '1900',
          items: ['200g Paneer', 'Salad'],
          bgColor: AppColors.surfaceContainerLow,
        ),
      ],
    );
  }

  Widget _buildRationItem({
    required int index,
    required String time,
    required List<String> items,
    required Color bgColor,
  }) {
    final isChecked = _rationsChecked[index];

    return InkWell(
      onTap: () {
        HapticFeedback.heavyImpact();
        setState(() {
          _rationsChecked[index] = !_rationsChecked[index];
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isChecked ? AppColors.surfaceContainerLowest : bgColor,
          border: Border(
            bottom: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.15),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        time,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: isChecked
                              ? AppColors.textMuted
                              : AppColors.neonRed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'HRS',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            color: isChecked
                                ? AppColors.textMuted
                                : AppColors.neonRed,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isChecked
                                  ? AppColors.textMuted.withValues(alpha: 0.5)
                                  : Colors.white,
                              letterSpacing: -0.5,
                              decoration: isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: isChecked
                                  ? AppColors.neonRed
                                  : null,
                              decorationThickness: isChecked ? 2.0 : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Custom Checkbox
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isChecked ? AppColors.neonRed : Colors.transparent,
                border: Border.all(
                  color: isChecked ? AppColors.neonRed : AppColors.outline,
                  width: 3,
                ),
              ),
              child: isChecked
                  ? const Icon(Icons.check, color: Colors.black, size: 32)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommenceDrillCTA() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_timeLeft.inHours);
    final minutes = twoDigits(_timeLeft.inMinutes.remainder(60));
    final seconds = twoDigits(_timeLeft.inSeconds.remainder(60));

    return Column(
      children: [
        // Ticking Clock
        Text(
          '// T-MINUS $hours:$minutes:$seconds UNTIL FORFEIT',
          style: GoogleFonts.spaceMono(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.neonRed,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        // START DRILL CTA
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              context.push(AppRoutes.strengthTestSetup);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonRed,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'START DRILL',
                  style: GoogleFonts.orbitron(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceContainerHigh.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    const double spacing = 40.0;

    // Draw vertical lines
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
