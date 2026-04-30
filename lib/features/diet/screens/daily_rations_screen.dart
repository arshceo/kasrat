import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/widgets/tactical_button.dart';
import 'package:kasrat_ai/features/ai/services/gemini_service.dart';

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

  int _extraCalories = 0;
  final TextEditingController _extraCalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDiet();
  }

  @override
  void dispose() {
    _extraCalController.dispose();
    super.dispose();
  }

  Future<void> _loadDiet() async {
    final plan = await GeminiService.getActiveDietPlan();
    if (mounted) {
      setState(() {
        _dietPlan = plan;
        _isLoading = false;
      });
    }
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
          SnackBar(
            content: Text('Failed to generate diet: $e'),
            backgroundColor: AppColors.danger,
          ),
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
        title: Text(
          'DIET PLAN',
          style: GoogleFonts.orbitron(
            fontSize: 14,
            color: AppColors.neonRed,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.neonRed),
            )
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
            Icon(
              Icons.restaurant_outlined,
              color: AppColors.textMuted.withValues(alpha: 0.3),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'NO RATIONS ASSIGNED',
              style: GoogleFonts.orbitron(
                fontSize: 12,
                color: AppColors.textMuted,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate your AI-customized diet plan based on your budget and region.',
              style: GoogleFonts.rajdhani(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateDiet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonRed,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                _isGenerating ? 'GENERATING...' : 'GENERATE RATIONS',
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietView() {
    final planJson = _dietPlan!['plan_json'] as Map<String, dynamic>? ?? {};

    if (planJson.containsKey('manifest')) {
      return _buildManifestView(planJson['manifest']);
    }

    // Try to get meals from top-level or from first day
    List<dynamic> meals = [];
    String costStr = '—';
    Map<String, dynamic>? today;

    if (planJson.containsKey('meals')) {
      meals = planJson['meals'] as List<dynamic>;
      costStr = '${planJson['daily_cost_inr'] ?? '—'}';
      today = planJson; // For flat structure, top level has the tips/meta
    } else {
      final days = (planJson['days'] as List<dynamic>?) ?? [];
      today = days.isNotEmpty ? days[0] as Map<String, dynamic> : null;
      if (today == null) return _buildNoPlan();
      meals = (today['meals'] as List<dynamic>?) ?? [];
      costStr = '${today['daily_cost_inr'] ?? '—'}';
    }

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
              border: Border.all(
                color: AppColors.neonRed.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planJson['plan_name'] ?? 'USTAD RATIONS',
                      style: GoogleFonts.rajdhani(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neonRed,
                      ),
                    ),
                    Text(
                      '${planJson['daily_calories_target'] ?? 2200} kcal • ${planJson['daily_protein_target_g'] ?? 80}g protein',
                      style: GoogleFonts.orbitron(
                        fontSize: 8,
                        color: AppColors.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹$costStr',
                  style: GoogleFonts.rajdhani(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Extra calories tracking
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceGlass,
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL CONSUMED',
                      style: GoogleFonts.rajdhani(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_calculateConsumed(meals) + _extraCalories} / ${planJson['daily_calories_target'] ?? 2200} kcal',
                      style: GoogleFonts.orbitron(
                        fontSize: 12,
                        color: AppColors.neonRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _extraCalController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.spaceMono(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          hintText: 'ADD EXTRA KCAL...',
                          hintStyle: GoogleFonts.spaceMono(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF111111),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: AppColors.outlineVariant,
                            ),
                            borderRadius: BorderRadius.zero,
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.neonRed),
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_extraCalController.text.isNotEmpty) {
                          setState(() {
                            _extraCalories +=
                                int.tryParse(_extraCalController.text) ?? 0;
                            _extraCalController.clear();
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonRed,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        'ADD',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
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
                    color: isChecked
                        ? AppColors.success.withValues(alpha: 0.05)
                        : AppColors.surfaceGlass,
                    border: Border.all(
                      color: isChecked
                          ? AppColors.success.withValues(alpha: 0.3)
                          : AppColors.textMuted.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isChecked
                                ? AppColors.success
                                : AppColors.textMuted,
                            width: 1.5,
                          ),
                          color: isChecked
                              ? AppColors.success.withValues(alpha: 0.1)
                              : Colors.transparent,
                        ),
                        child: isChecked
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: AppColors.success,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  m['time'] ?? '',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 9,
                                    color: AppColors.textMuted,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  '${m['calories'] ?? 0} kcal • ${m['protein_g'] ?? 0}g',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 8,
                                    color: AppColors.textMuted,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              m['name'] ?? '',
                              style: GoogleFonts.rajdhani(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isChecked
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                                decoration: isChecked
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            if (m['items'] != null)
                              Text(
                                (m['items'] as List).join(' • '),
                                style: GoogleFonts.rajdhani(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
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
          }),

          // Tip
          if (today['tip'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.neonRed.withValues(alpha: 0.05),
                border: Border.all(
                  color: AppColors.neonRed.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Text('💡', style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      today['tip'],
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildManifestView(String manifest) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border.all(
                color: AppColors.neonRed.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.description,
                      color: AppColors.neonRed,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TACTICAL PROTOCOL',
                      style: GoogleFonts.orbitron(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.neonRed,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.outlineVariant, height: 24),
                Text(
                  manifest,
                  style: GoogleFonts.spaceMono(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TacticalButton(
            soundType: TacticalSoundType.nav,
            onTap: () => context.go(AppRoutes.dashboard),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.neonRed),
              ),
              child: Center(
                child: Text(
                  'DISMISS TO DASHBOARD',
                  style: GoogleFonts.orbitron(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.neonRed,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateConsumed(List<dynamic> meals) {
    int consumed = 0;
    for (var meal in meals) {
      final m = meal as Map<String, dynamic>;
      final id = '${m['time']}_${m['name']}';
      if (_checkedMeals.contains(id)) {
        consumed += (m['calories'] as num?)?.toInt() ?? 0;
      }
    }
    return consumed;
  }
}
