import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';

class DirectiveSection extends StatelessWidget {
  final bool isSubscriber;
  final String protocolTitle;
  final String workoutTime;
  final String directiveTitle;

  const DirectiveSection({
    super.key,
    required this.isSubscriber,
    required this.protocolTitle,
    required this.workoutTime,
    this.directiveTitle = "DAILY MISSION",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.neonRed, width: 6)),
      ),
      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            directiveTitle.toUpperCase(),
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.neonRed,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isSubscriber ? protocolTitle : 'FUEL PROTOCOL',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -2,
              height: 1.0,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.payments_outlined,
            'FOOD BUDGET: NOT SET YET',
            AppColors.neonRed,
          ),
          const SizedBox(height: 4),
          _buildInfoRow(
            Icons.access_time_rounded,
            'WORKOUT TIME: ${workoutTime == '24H' ? 'FLEXIBLE (24H)' : workoutTime}',
            Colors.white,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: AppColors.neonRed.withValues(alpha: 0.2),
            child: Text(
              'FORFEITURE ACTIVE: COMPLETE WORKOUT BEFORE DEADLINE OR LOSE DEPOSIT.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: AppColors.neonRed,
                letterSpacing: 1,
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
}
