import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/audio/fauj_audio_engine.dart';

class DailyRationsCard extends StatelessWidget {
  final Map<String, dynamic> dietPlan;
  final List<bool> rationsChecked;
  final Function(int, bool) onToggle;
  final dynamic dailyCalories;

  const DailyRationsCard({
    super.key,
    required this.dietPlan,
    required this.rationsChecked,
    required this.onToggle,
    this.dailyCalories,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> meals = dietPlan['meals'] ?? [];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surfaceContainerHigh,
            child: Row(
              children: [
                const Icon(Icons.restaurant_menu,
                    color: AppColors.neonRed, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'DAILY RATIONS',
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${dailyCalories ?? '-'} KCAL',
                      style: GoogleFonts.spaceMono(
                        fontSize: 8,
                        color: AppColors.neonRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PHASE: OPS',
                      style: GoogleFonts.spaceMono(
                        fontSize: 8,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: meals.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: Colors.white12),
            itemBuilder: (context, index) {
              final meal = meals[index];
              final isChecked = rationsChecked.length > index
                  ? rationsChecked[index]
                  : false;

              // Extract meal name with multiple fallbacks
              final String mealName = (meal['meal'] ??
                      meal['name'] ??
                      meal['meal_name'] ??
                      meal['item'] ??
                      'UNNAMED MEAL')
                  .toString()
                  .toUpperCase();

              // Combine items and notes for the description
              String description = "";
              if (meal['items'] is List) {
                description = (meal['items'] as List).join(", ");
              } else if (meal['description'] != null) {
                description = meal['description'].toString();
              }
              
              if (meal['notes'] != null && meal['notes'].toString().isNotEmpty) {
                description += description.isEmpty ? meal['notes'].toString() : "\n${meal['notes']}";
              }

              return CheckboxListTile(
                value: isChecked,
                onChanged: (val) {
                  FaujAudioEngine().playMouseClick();
                  onToggle(index, val ?? false);
                },
                title: Text(
                  mealName,
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isChecked
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: description.isNotEmpty 
                  ? Text(
                      description,
                      style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        color: isChecked
                            ? AppColors.textMuted
                            : AppColors.textSecondary,
                        height: 1.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
                activeColor: AppColors.neonRed,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              );
            },
          ),
        ],
      ),
    );
  }
}
