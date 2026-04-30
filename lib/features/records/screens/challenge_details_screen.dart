import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';

class ChallengeDetailsScreen extends StatelessWidget {
  const ChallengeDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopNav(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildDemoSection(context),
                    const SizedBox(height: 32),
                    _buildSchematicSection(),
                    const SizedBox(height: 32),
                    _buildTargetAcquisition(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Row(
          children: [
            const Icon(
              Icons.arrow_back_ios,
              color: AppColors.neonRed,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'PROTOCOLS // ABORT ANALYSIS',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.neonRed,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '01 // LOWER_BODY_STORM',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -2,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: AppColors.surfaceContainerHighest,
          child: Text(
            'CLASSIFICATION: S-TIER / DURATION: 45 MINS / FATIGUE RATIO: 8.9/10',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDemoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Action Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: Ink(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.neonRed, AppColors.bloodOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                alignment: Alignment.center,
                child: Text(
                  '[ INITIATE DEMO DAY ]',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'WARNING: Proceeding will log this as your Day 1 baseline test.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.neonRed,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Preview Image
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outlineVariant, width: 2),
            color: AppColors.surfaceContainerLow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/images/demo_day_preview.jpg',
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: AppColors.surfaceContainerHighest,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                color: AppColors.background,
                child: Text(
                  'PREVIEW OF DAY 1 COMBAT READY CONDITIONS.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSchematicSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neonRed, width: 2),
        color: AppColors.surfaceContainerLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Schematic Image with scan effect
          Stack(
            children: [
              Image.asset(
                'assets/images/schematic_lower_body.jpg',
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 250,
                  color: AppColors.surfaceContainerHighest,
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.neonRed.withValues(alpha: 0.1),
                        AppColors.neonRed.withValues(alpha: 0.3),
                      ],
                      stops: const [0.0, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: AppColors.neonRed.withValues(alpha: 0.1),
            child: Text(
              'BIOMECHANICAL SCAN CONFIRMED. TARGET: QUADRICEPS/GLUTES.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppColors.neonRed,
                letterSpacing: 1.5,
              ),
            ),
          ),

          // Data Readout
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildDataRow('FORCE PRODUCTION', 'MAX'),
                _buildDivider(),
                _buildDataRow('NEURAL FATIGUE', 'HIGH'),
                _buildDivider(),
                _buildDataRow('CALORIC BURN', '900+ KCAL'),
                _buildDivider(),
                _buildDataRow(
                  'RISK FACTOR',
                  'SEVERE',
                  valueColor: AppColors.neonRed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(
    String label,
    String value, {
    Color valueColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: valueColor,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: AppColors.outlineVariant.withValues(alpha: 0.5),
      height: 16,
      thickness: 1,
    );
  }

  Widget _buildTargetAcquisition() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TARGET ACQUISITION',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.neonRed,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'This protocol places maximum stress on the lower kinematic chain. Focus on explosive concentric phases and controlled eccentric lowering. Failure to maintain tension will result in structural breakdown.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        _buildListItems([
          'PRIMARY: Anterior Chain (Quads)',
          'SECONDARY: Posterior Chain (Glutes/Hams)',
          'MECHANICS: Compound / Explosive',
          'RECOVERY: 48HRS Minimum',
        ]),
      ],
    );
  }

  Widget _buildListItems(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6, right: 12),
                width: 4,
                height: 4,
                color: AppColors.neonRed,
              ),
              Expanded(
                child: Text(
                  item,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
