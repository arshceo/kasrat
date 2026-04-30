import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';

class ActiveMissionCalendar extends StatelessWidget {
  final int currentDay;
  final int totalDays;
  final DateTime? protocolStartDate;

  const ActiveMissionCalendar({
    super.key,
    required this.currentDay,
    required this.totalDays,
    this.protocolStartDate,
  });

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM').format(date).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'STREAK PROGRESS',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 2,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$currentDay',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -2,
                    height: 1.0,
                  ),
                ),
                Text(
                  '/$totalDays',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            const int crossAxisCount = 7;
            const double spacing = 4.0;
            final double itemWidth =
                (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
                crossAxisCount;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: List.generate(totalDays, (index) {
                final day = index + 1;
                final isCompleted = day < currentDay;
                final isCurrent = day == currentDay;

                String dateLabel = 'TBD';
                if (protocolStartDate != null) {
                  final targetDate = protocolStartDate!.add(
                    Duration(days: index),
                  );
                  dateLabel = _formatDate(targetDate);
                }

                final isRestDay = day % 7 == 0;

                Color bgColor = AppColors.surfaceContainerHighest;
                Color borderColor = AppColors.outlineVariant;
                Color textColor = AppColors.textMuted;

                if (isCurrent) {
                  bgColor = AppColors.neonRed;
                  borderColor = Colors.white;
                  textColor = Colors.white;
                } else if (isCompleted) {
                  bgColor = AppColors.neonRed.withValues(alpha: 0.2);
                  borderColor = AppColors.neonRed.withValues(alpha: 0.5);
                  textColor = AppColors.neonRed.withValues(alpha: 0.8);
                } else if (isRestDay) {
                  bgColor = Colors.black.withValues(alpha: 0.3);
                  borderColor = AppColors.surfaceContainerHigh;
                  textColor = AppColors.textMuted.withValues(alpha: 0.5);
                }

                return Container(
                  width: itemWidth,
                  height: itemWidth * 1.1,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(
                      color: borderColor,
                      width: isCurrent ? 1.5 : 0.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dateLabel,
                        style: GoogleFonts.spaceMono(
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          color: textColor.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '[ $day ]',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}
