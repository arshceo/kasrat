import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import '../../calibration/services/exercise_type.dart';

/// Onboarding Step 2 (Post-Exercise-Selection):
/// Brief intro / lobby before the actual camera-based baseline tests.
///
/// Flow: ExerciseSelectionScreen → BaselineTestScreen → CalibrationScreen (squats)
///       → CalibrationScreen (pushups) → Dashboard
///
/// This screen shows the user what is about to happen and gives them
/// an explicit SKIP option if they don't want to test right now.
class BaselineTestScreen extends StatefulWidget {
  const BaselineTestScreen({super.key});

  @override
  State<BaselineTestScreen> createState() => _BaselineTestScreenState();
}

class _BaselineTestScreenState extends State<BaselineTestScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isSkipping = false;
  bool _isLoading = true;

  int _baselineSquats = -1;
  int _baselinePushups = -1;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fetchBaselines();
  }

  Future<void> _fetchBaselines() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
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
          // Force anything null or <= 0 into the -1 (unrecorded) bucket for the onboarding phase
          final dynamic sVal = response?['baseline_squats'];
          final dynamic pVal = response?['baseline_pushups'];
          
          _baselineSquats = (sVal is num && sVal > 0) ? sVal.toInt() : -1;
          _baselinePushups = (pVal is num && pVal > 0) ? pVal.toInt() : -1;
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching baselines: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _skipAndGoToDashboard() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSkipping = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('profiles').update({
          'onboarding_complete': true,
        }).eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Failed to mark onboarding complete: $e');
    }
    if (mounted) {
      context.go(AppRoutes.userMetrics);
    }
  }

  void _startTest(ExerciseType type) async {
    HapticFeedback.heavyImpact();
    // Navigate to calibration and wait for it to finish
    await context.push(
      AppRoutes.strengthTest,
      extra: {
        'exerciseType': type,
        'durationSeconds': 0, // 0 = unlimited (stop on 5s pause)
        'isBaseline': true,
        'baselineStep': type == ExerciseType.squat ? 1 : 2,
        'totalSteps': 2,
      },
    );
    // When returning, refresh the screen
    _fetchBaselines();
  }

  Future<void> _finalizeOnboarding() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client.from('profiles').update({
        'onboarding_complete': true,
      }).eq('id', user.id);
    }
    
    // Determine awarded rank (likely Recruit for baselines, but could be higher if they maxed it)
    final profileData = await Supabase.instance.client
        .from('profiles')
        .select('current_league')
        .eq('id', user?.id ?? '')
        .maybeSingle();
        
    final String league = profileData?['current_league'] ?? 'RECRUIT';
    final String rankAsset = league.toUpperCase().contains('COMMANDO') 
        ? 'assets/images/commando.png'
        : league.toUpperCase().contains('SOLDIER')
            ? 'assets/images/soldier.png'
            : 'assets/images/recruit.png';
    
    if (mounted) {
      setState(() => _isLoading = false);
      // Show the Jaw-Dropping Rank Unlock Screen First
      await context.push(AppRoutes.rankUnlocked, extra: {
        'rankName': league.toUpperCase().split(' (')[0], // Remove ' (Candidate)' if present
        'insigniaPath': rankAsset,
      });
      
      // After acknowledgement, proceed
      if (mounted) context.go(AppRoutes.userMetrics);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Grid background
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
          // Left red urgency strip
          Positioned(
            left: 0, top: 0, bottom: 0, width: 6,
            child: Container(color: AppColors.neonRed),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 24, 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E1E1E))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.neonRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'STEP 2 OF 2 · STRENGTH TEST',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  color: AppColors.neonRed,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'HOW\nMANY\nREPS?',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 0.85,
              letterSpacing: -2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Context paragraph
          Container(
            padding: const EdgeInsets.only(left: 14),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AppColors.neonRed, width: 3)),
            ),
            child: Text(
              'Show your strength.\n'
              'The camera will count your reps automatically.\n'
              'Give your best effort to unlock perfect challenges for you.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Exercise 1: SQUATS
          _ExerciseBlock(
            step: '01',
            name: 'SQUATS',
            instruction: 'Show your peak performance in squats. Quality counts.',
            icon: Icons.accessibility_new,
            score: _baselineSquats,
            pulseAnimation: _pulseAnimation,
            onTap: () => _startTest(ExerciseType.squat),
          ),

          const SizedBox(height: 2),
          Container(height: 1, color: AppColors.surfaceContainerHighest),
          const SizedBox(height: 2),

          // Exercise 2: PUSH-UPS
          _ExerciseBlock(
            step: '02',
            name: 'PUSH-UPS',
            instruction: 'Give your maximum push-ups. Full range of motion.',
            icon: Icons.fitness_center,
            score: _baselinePushups,
            pulseAnimation: _pulseAnimation,
            onTap: () => _startTest(ExerciseType.pushup),
          ),

          const SizedBox(height: 40),

          // Rules box
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.surfaceContainerLow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '// HOW IT WORKS',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    color: AppColors.neonRed,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _ruleRow('AI counts your reps. No cheating.'),
                _ruleRow('We stop the set if you pause too long.'),
                _ruleRow('Your results stay private on your device.'),
                _ruleRow('We build your personal plan from this.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ruleRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            color: AppColors.neonRed,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Color(0xFF1E1E1E))),
      ),
      child: Column(
        children: [
          // Urgency text
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                (_baselineSquats >= 0 && _baselinePushups >= 0)
                    ? '// DATA COLLECTION COMPLETE. FINALIZE NOW.'
                    : '// ATTENTION: PROVE YOUR POWER TO CONTINUE',
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.neonRed.withValues(alpha: _pulseAnimation.value),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          // Main CTA: Finalize or Start first missing
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_baselineSquats != -1 && _baselinePushups != -1)
                    ? _finalizeOnboarding
                    : () {
                        if (_baselineSquats == -1) {
                          _startTest(ExerciseType.squat);
                        } else {
                          _startTest(ExerciseType.pushup);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonRed.withValues(alpha: _pulseAnimation.value),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  elevation: 0,
                  side: BorderSide(
                    color: AppColors.neonRed.withValues(alpha: _pulseAnimation.value),
                    width: 2,
                  ),
                ),
                child: Text(
                  (_baselinePushups != -1 && _baselineSquats != -1)
                      ? 'PROCEED TO PHYSICAL STATS  →'
                      : (_baselineSquats != -1)
                          ? 'PROCEED TO TEST TWO  →'
                          : 'START TEST ONE  →',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.black.withValues(alpha: _pulseAnimation.value.clamp(0.8, 1.0)),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Skip
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _isSkipping ? null : _skipAndGoToDashboard,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: AppColors.textMuted,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: _isSkipping
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textMuted,
                      ),
                    )
                  : Text(
                      'SKIP FOR NOW — I\'LL DO IT LATER',
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        letterSpacing: 1.5,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.textMuted,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseBlock extends StatelessWidget {
  final String step;
  final String name;
  final String instruction;
  final IconData icon;
  final int score;
  final Animation<double> pulseAnimation;
  final VoidCallback onTap;

  const _ExerciseBlock({
    required this.step,
    required this.name,
    required this.instruction,
    required this.icon,
    this.score = -1,
    required this.pulseAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // -1 means NOT STARTED, 0+ means RECORDED
    final bool isDone = score >= 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDone ? Colors.white.withValues(alpha: 0.02) : Colors.transparent,
        border: Border.all(
          color: isDone ? AppColors.surfaceContainerHighest : AppColors.surfaceContainerLow,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // State Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDone ? AppColors.neonRed.withValues(alpha: 0.1) : Colors.transparent,
                  border: Border.all(
                    color: isDone ? AppColors.neonRed.withValues(alpha: 0.3) : AppColors.surfaceContainerHigh,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isDone ? Icons.check_rounded : icon,
                    color: isDone ? AppColors.neonRed : AppColors.textMuted,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Body
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP $step // $name',
                      style: GoogleFonts.spaceMono(
                        fontSize: 9,
                        color: isDone ? AppColors.textMuted : AppColors.neonRed,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDone ? name : name, // Name always first
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDone ? 'RECORDED PERFORMANCE: $score REPS' : instruction,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDone ? AppColors.neonRed : AppColors.textSecondary,
                        fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // Action Button area
              const SizedBox(width: 12),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDone ? Colors.transparent : AppColors.neonRed,
                      border: Border.all(
                        color: isDone ? AppColors.textMuted : AppColors.neonRed,
                      ),
                    ),
                    child: Icon(
                      isDone ? Icons.refresh : Icons.play_arrow_rounded,
                      color: isDone ? AppColors.textMuted : Colors.black,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDone ? 'RETAKE' : 'START',
                    style: GoogleFonts.spaceMono(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isDone ? AppColors.textMuted : AppColors.neonRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceContainerHigh.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
