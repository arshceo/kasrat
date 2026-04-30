import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/widgets/tactical_button.dart';
import 'package:kasrat_ai/core/audio/fauj_audio_engine.dart';

class DietPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> dietPlan;

  const DietPreviewScreen({super.key, required this.dietPlan});

  @override
  State<DietPreviewScreen> createState() => _DietPreviewScreenState();
}

class _DietPreviewScreenState extends State<DietPreviewScreen> {
  bool _isCommitting = false;

  void _commitPlan() async {
    FaujAudioEngine().playTap();
    setState(() => _isCommitting = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        // 1. Deactivate any existing plans
        await supabase
            .from('diet_plans')
            .update({'is_active': false})
            .eq('user_id', user.id)
            .eq('is_active', true);

        // 2. Commit the new tactical protocol
        await supabase.from('diet_plans').insert({
          'user_id': user.id,
          'plan_json': widget.dietPlan,
          'is_active': true,
        });

        if (mounted) {
          setState(() => _isCommitting = false);
          // Return to Dashboard - Shell will handle visibility of new protocol
          context.go(AppRoutes.dashboard);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'DIET PLAN SAVED.',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCommitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'COMMIT FAILED: $e',
              style: GoogleFonts.orbitron(color: Colors.white, fontSize: 10),
            ),
            backgroundColor: AppColors.neonRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final meals = (widget.dietPlan['meals'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'DIET PLAN PREVIEW',
          style: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.neonRed.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.dietPlan['plan_name'] ?? 'DIET PLAN',
                          style: GoogleFonts.orbitron(
                            color: AppColors.neonRed,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'TARGET: ${widget.dietPlan['daily_calories_target']} kcal | ${widget.dietPlan['daily_protein_target_g']}g PROTEIN',
                          style: GoogleFonts.spaceMono(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...meals.map((meal) => _buildMealRow(meal)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: TacticalButton(
              onTap: _isCommitting ? () {} : _commitPlan,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                color: AppColors.neonRed,
                child: Center(
                  child: _isCommitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'START THIS DIET PLAN',
                          style: GoogleFonts.orbitron(
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
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

  Widget _buildMealRow(dynamic meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Text(
            meal['time'] ?? '00:00',
            style: GoogleFonts.spaceMono(
              color: AppColors.neonRed,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal['name'] ?? 'MEAL',
                  style: GoogleFonts.rajdhani(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${meal['calories']} kcal | ${meal['protein_g']}g P',
                  style: GoogleFonts.spaceMono(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
