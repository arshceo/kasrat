import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/widgets/tactical_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class PreMissionSection extends StatelessWidget {
  final bool hasCompletedBaseline;
  final bool hasCompletedMetrics;
  final String protocolTitle;
  final String? pendingCode;
  final VoidCallback onDeploy;

  const PreMissionSection({
    super.key,
    required this.hasCompletedBaseline,
    required this.hasCompletedMetrics,
    required this.protocolTitle,
    required this.onDeploy,
    this.pendingCode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hasCompletedBaseline) ...[
          _buildPrompt(
            context,
            icon: Icons.fitness_center_rounded,
            title: 'STRENGTH ASSESSMENT REQUIRED',
            subtitle: 'Complete your baseline assessment to finalize your profile.',
            buttonLabel: 'START STRENGTH TEST',
            onTap: () => context.push(AppRoutes.baselineTest),
          ),
        ] else if (!hasCompletedMetrics) ...[
          _buildPrompt(
            context,
            icon: Icons.monitor_heart_outlined,
            title: 'WEIGHT & HEIGHT MISSING',
            subtitle: 'Update your metrics for accurate fuel calculations.',
            buttonLabel: 'UPDATE METRICS',
            onTap: () => context.push(AppRoutes.userMetrics),
          ),
        ] else if (protocolTitle != 'NO ACTIVE MISSION' && protocolTitle.isNotEmpty) ...[
          _buildPrompt(
            context,
            icon: Icons.shield_outlined,
            title: 'DEPLOYMENT PENDING',
            subtitle: 'MISSION: $protocolTitle\nSTATUS: AWAITING AUTHORIZATION',
            buttonLabel: pendingCode != null ? 'GO TO WEBSITE' : 'FINALIZE DEPLOYMENT',
            onTap: () async {
              if (pendingCode != null) {
                final url = Uri.parse('https://ustad.ai');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              } else {
                onDeploy();
              }
            },
            pendingCode: pendingCode,
            secondaryButtonLabel: 'EXPLORE OTHER CHALLENGES',
            onSecondaryTap: () => StatefulNavigationShell.of(context).goBranch(1),
          ),
        ] else ...[
          _buildPrompt(
            context,
            icon: Icons.military_tech_outlined,
            title: 'MISSION DEPLOYMENT REQUIRED',
            subtitle: 'Finalize your enrollment to activate your workout protocol.',
            buttonLabel: 'EXPLORE CHALLENGES',
            onTap: onDeploy,
          ),
        ],
      ],
    );
  }

  Widget _buildPrompt(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
    String? pendingCode,
    String? secondaryButtonLabel,
    VoidCallback? onSecondaryTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(
          color: AppColors.neonRed.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.neonRed, size: 28),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          if (pendingCode != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: pendingCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CODE COPIED TO CLIPBOARD')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: AppColors.neonRed.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pendingCode,
                      style: GoogleFonts.spaceMono(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.neonRed,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.copy, size: 18, color: AppColors.neonRed),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'TAP TO COPY AUTH CODE',
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: TacticalButton(
              onTap: onTap,
              soundType: TacticalSoundType.nav,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: AppColors.neonRed),
                alignment: Alignment.center,
                child: Text(
                  buttonLabel,
                  style: GoogleFonts.orbitron(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
          if (secondaryButtonLabel != null && onSecondaryTap != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TacticalButton(
                onTap: onSecondaryTap,
                soundType: TacticalSoundType.nav,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.outline),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    secondaryButtonLabel,
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
