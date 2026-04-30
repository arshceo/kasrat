import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';

/// Onboarding Step 1 (Post-Login):
/// Show all available exercises. User picks those they can do 2+ reps of.
class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({super.key});

  @override
  State<ExerciseSelectionScreen> createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  bool _isSaving = false;

  // Master list of exercises with metadata
  static const List<Map<String, dynamic>> _allExercises = [
    {
      'id': 'squats',
      'name': 'SQUATS',
      'desc': 'Knees bend, hips drop below parallel',
      'icon': Icons.accessibility_new,
      'muscle': 'LEGS + CORE',
    },
    {
      'id': 'pushups',
      'name': 'PUSH-UPS',
      'desc': 'Chest to floor, full lockout up',
      'icon': Icons.fitness_center,
      'muscle': 'CHEST + ARMS',
    },
    {
      'id': 'lunges',
      'name': 'LUNGES',
      'desc': 'One leg forward, knee almost touches floor',
      'icon': Icons.directions_run,
      'muscle': 'LEGS + GLUTES',
    },
    {
      'id': 'jumping_jacks',
      'name': 'JUMPING JACKS',
      'desc': 'Arms over head, feet wide, continuous',
      'icon': Icons.sports,
      'muscle': 'FULL BODY',
    },
    {
      'id': 'plank',
      'name': 'PLANK HOLD',
      'desc': 'Flat spine, hold for at least 10 seconds',
      'icon': Icons.horizontal_rule,
      'muscle': 'CORE',
    },

    {
      'id': 'mountain_climbers',
      'name': 'MOUNTAIN CLIMBERS',
      'desc': 'Plank position, drive knees alternately',
      'icon': Icons.trending_up,
      'muscle': 'CORE + LEGS',
    },
    {
      'id': 'high_knees',
      'name': 'HIGH KNEES',
      'desc': 'Run in place, knees above waist',
      'icon': Icons.speed,
      'muscle': 'LEGS + CARDIO',
    },
  ];

  final Set<String> _selected = {};

  void _toggle(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isSaving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('profiles').update({
          'capable_exercises': _selected.toList(),
        }).eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Failed to save exercises: $e');
    }
    if (mounted) {
      // Go to baseline test — always test pushups + squats regardless of selection
      context.go(AppRoutes.baselineTest);
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
            child: CustomPaint(painter: _BrutalistGridPainter()),
          ),

          // Side urgency bar
          Positioned(
            left: 0, top: 0, bottom: 0, width: 6,
            child: Container(color: AppColors.neonRed),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Expanded(child: _buildExerciseGrid()),
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
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1),
        ),
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
                'STEP 1 OF 2 · ABILITY CHECK',
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
            'WHAT CAN\nYOU DO?',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 0.9,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AppColors.neonRed, width: 3)),
            ),
            child: Text(
              'Select every exercise you can perform at least 2 reps of. Be honest. The AI will calibrate your plan to this.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _allExercises.length,
      itemBuilder: (context, i) {
        final ex = _allExercises[i];
        final bool isSelected = _selected.contains(ex['id'] as String);
        return _ExerciseCard(
          name: ex['name'] as String,
          desc: ex['desc'] as String,
          muscle: ex['muscle'] as String,
          icon: ex['icon'] as IconData,
          isSelected: isSelected,
          onTap: () => _toggle(ex['id'] as String),
        );
      },
    );
  }

  Widget _buildFooter() {
    final count = _selected.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Color(0xFF1E1E1E))),
      ),
      child: Column(
        children: [
          if (count > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '$count EXERCISE${count > 1 ? 'S' : ''} SELECTED',
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  color: AppColors.neonRed,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAndContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: count > 0 ? AppColors.neonRed : AppColors.surfaceContainerHighest,
                foregroundColor: count > 0 ? Colors.black : AppColors.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 22),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          count > 0 ? 'CONFIRM ABILITIES →' : 'SELECT AT LEAST ONE',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
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
}

class _ExerciseCard extends StatelessWidget {
  final String name;
  final String desc;
  final String muscle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.name,
    required this.desc,
    required this.muscle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neonRed.withValues(alpha: 0.08) : AppColors.surfaceContainerLow,
          border: Border.all(
            color: isSelected ? AppColors.neonRed : AppColors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.neonRed : AppColors.textMuted,
                  size: 22,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.neonRed : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.neonRed : AppColors.outline,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.black, size: 14)
                      : null,
                ),
              ],
            ),
            const Spacer(),
            Text(
              name,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              muscle,
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                color: isSelected ? AppColors.neonRed : AppColors.textMuted,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrutalistGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceContainerHigh.withValues(alpha: 0.25)
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
