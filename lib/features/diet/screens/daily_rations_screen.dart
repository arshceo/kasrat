import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../ai/services/gemini_service.dart';

/// Daily Rations screen — AI-generated diet checklist.
class DailyRationsScreen extends StatefulWidget {
  const DailyRationsScreen({super.key});

  @override
  State<DailyRationsScreen> createState() => _DailyRationsScreenState();
}

class _DailyRationsScreenState extends State<DailyRationsScreen> {
  Map<String, dynamic>? _dietPlan;
  bool _isLoading = true;
  bool _isGenerating = false;
  final Set<String> _checkedMeals = {};

  @override
  void initState() {
    super.initState();
    _loadDiet();
  }

  Future<void> _loadDiet() async {
    final plan = await GeminiService.getActiveDietPlan();
    if (mounted) setState(() { _dietPlan = plan; _isLoading = false; });
  }

  Future<void> _generateDiet() async {
    setState(() => _isGenerating = true);
    try {
      await GeminiService.generateDietPlan(
        budgetTier: 'budget',
        language: 'en',
        region: 'north_india',
      );
      await _loadDiet();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate diet: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
    if (mounted) setState(() => _isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('DAILY RATIONS', style: GoogleFonts.orbitron(fontSize: 14, color: AppColors.neonRed, letterSpacing: 3)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.neonRed))
          : _dietPlan == null
              ? _buildNoPlan()
              : _buildDietView(),
    );
  }

  Widget _buildNoPlan() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_outlined, color: AppColors.textMuted.withValues(alpha: 0.3), size: 64),
            const SizedBox(height: 16),
            Text('NO RATIONS ASSIGNED', style: GoogleFonts.orbitron(fontSize: 12, color: AppColors.textMuted, letterSpacing: 3)),
            const SizedBox(height: 8),
            Text(
              'Generate your AI-customized diet plan based on your budget and region.',
              style: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateDiet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonRed,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: Text(
                _isGenerating ? 'GENERATING...' : 'GENERATE RATIONS',
                style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietView() {
    final planJson = _dietPlan!['plan_json'] as Map<String, dynamic>? ?? {};
    final days = (planJson['days'] as List<dynamic>?) ?? [];
    final today = days.isNotEmpty ? days[0] as Map<String, dynamic> : null;

    if (today == null) return _buildNoPlan();

    final meals = (today['meals'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Plan header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceGlass,
              border: Border.all(color: AppColors.neonRed.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(planJson['plan_name'] ?? 'USTAD RATIONS', style: GoogleFonts.rajdhani(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.neonRed)),
                    Text('${planJson['daily_calories_target'] ?? 2200} kcal • ${planJson['daily_protein_target_g'] ?? 80}g protein',
                        style: GoogleFonts.orbitron(fontSize: 8, color: AppColors.textMuted, letterSpacing: 1)),
                  ],
                ),
                Text('₹${today['daily_cost_inr'] ?? '—'}',
                    style: GoogleFonts.rajdhani(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.success)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Meals
          ...meals.map((meal) {
            final m = meal as Map<String, dynamic>;
            final id = '${m['time']}_${m['name']}';
            final isChecked = _checkedMeals.contains(id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() {
                  isChecked ? _checkedMeals.remove(id) : _checkedMeals.add(id);
                }),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isChecked ? AppColors.success.withValues(alpha: 0.05) : AppColors.surfaceGlass,
                    border: Border.all(
                      color: isChecked ? AppColors.success.withValues(alpha: 0.3) : AppColors.textMuted.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22, height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: isChecked ? AppColors.success : AppColors.textMuted, width: 1.5),
                          color: isChecked ? AppColors.success.withValues(alpha: 0.1) : Colors.transparent,
                        ),
                        child: isChecked ? const Icon(Icons.check, size: 14, color: AppColors.success) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(m['time'] ?? '', style: GoogleFonts.orbitron(fontSize: 9, color: AppColors.textMuted, letterSpacing: 1)),
                                Text('${m['calories'] ?? 0} kcal • ${m['protein_g'] ?? 0}g',
                                    style: GoogleFonts.orbitron(fontSize: 8, color: AppColors.textMuted, letterSpacing: 1)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              m['name'] ?? '',
                              style: GoogleFonts.rajdhani(
                                fontSize: 16, fontWeight: FontWeight.w600,
                                color: isChecked ? AppColors.textMuted : AppColors.textPrimary,
                                decoration: isChecked ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if (m['items'] != null)
                              Text(
                                (m['items'] as List).join(' • '),
                                style: GoogleFonts.rajdhani(fontSize: 12, color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Tip
          if (today['tip'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.neonRed.withValues(alpha: 0.05),
                border: Border.all(color: AppColors.neonRed.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Text('💡', style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(today['tip'], style: GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textSecondary, height: 1.3)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
