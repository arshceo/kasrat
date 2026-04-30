import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The Reveal (Blurred outline)
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Simulated blurred background data
                      Opacity(
                        opacity: 0.3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 12,
                              width: 200,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 8,
                              width: 150,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: 40,
                                  width: 40,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  height: 40,
                                  width: 40,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.lock,
                        size: 64,
                        color: AppColors.textPrimary.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // The Hook
                Text(
                  'Assessment Complete. Your custom 28-day roadmap is ready. But we do not train tourists. Put skin in the game.',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 40),

                // The Bet Breakdown
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF111111),
                    border: Border(
                      left: BorderSide(color: AppColors.neonRed, width: 4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMathRow(
                        '1',
                        'Deposit ₹${CommercialConstants.collateralAmount.toInt()} today.',
                      ),
                      const SizedBox(height: 16),
                      _buildMathRow(
                        '2',
                        'Survive all 28 days without quitting.',
                      ),
                      const SizedBox(height: 16),
                      _buildMathRow(
                        '3',
                        'Get your ₹${CommercialConstants.collateralAmount.toInt()} back.',
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Stake Amount',
                            style: GoogleFonts.spaceMono(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '₹${CommercialConstants.collateralAmount.toInt()}',
                            style: GoogleFonts.spaceMono(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.neonRed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // The Action
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    context.push(
                      AppRoutes.deploymentAuth,
                      extra: {
                        'protocolId': 'baseline',
                        'protocolTitle': 'INITIAL ENROLLMENT',
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonRed,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                    '[ LOCK IN MY ₹${CommercialConstants.collateralAmount.toInt()} STAKE ]',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMathRow(String step, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$step.',
          style: GoogleFonts.spaceMono(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.neonRed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
