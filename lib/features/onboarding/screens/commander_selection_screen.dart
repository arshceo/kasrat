import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import '../../auth/services/auth_service.dart';

/// W-01: Commander Selection — pick your Ustad persona.
class CommanderSelectionScreen extends StatefulWidget {
  const CommanderSelectionScreen({super.key});

  @override
  State<CommanderSelectionScreen> createState() =>
      _CommanderSelectionScreenState();
}

class _CommanderSelectionScreenState extends State<CommanderSelectionScreen> {
  String? _selectedCommander;

  final _commanders = [
    _Commander(
      'drill_sergeant',
      'The Haryanvi Drill Sergeant',
      'BRUTAL',
      '"Pain is temporary. Pride is permanent. Do another set or go home to your mother."',
      'LEVEL: EXTREME',
      'HARYANA_77',
      AppColors.danger,
      'https://lh3.googleusercontent.com/aida-public/AB6AXuA7-T5oKU1U2Et9NjTa5zARBK-I_5MuRfYJNNzTQ8GNJsEySE9WRahWadNZPvcU3StxY4_n5UUyUplJJ2g-teh2OeCCkGVUAw_4nQoeTtQx9I-DSQs2BO7_OB1axv4CPDHgY-J9a7vPwrNM_EwSKkgiCKgiqRNKkOpm7RrdgypY9zC7NxDOI5tjeapaaClPDFzE4dUkZDw0B0DQUYgU6vttCTHHDorkIANg0kKDPoU-EBXFVoUVhiMc7osh-V0V1hRQYxXH6_52i48',
    ),
    _Commander(
      'hardcore_punjabi',
      'The Hardcore Punjabi',
      'HUMILIATING',
      '"You call that a squat? My grandmother moves more weight than you while drinking tea."',
      'RECOMMENDED',
      'PUNJAB_01',
      AppColors.neonRed,
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCPHlx6htEIbe3vsCAfaDc8rOzl2bReY73LV1KJTCrU845-6s4B-NcFYHxQGW1paRfHv-Lp4Mnl3NXInB7ZZK75BOP-7u6CFCLZNwSiNR0iR2XI-hgzb8vrKuaPREB-s_xncWFAFZTlujJuMy0Adycrg1726dnWdymiVfAvhwBFarUGQX3D6XT2r5sjOm_TappBRWS6R7FfRrMn0bkPzAckpLMvjQEeOrcV-hU04bbCBbb3mc9Ym2FW3GTKM5p0oZvtA50FifzsbJU',
    ),
    _Commander(
      'disappointed_parent',
      'Special Forces English',
      'CLINICAL',
      '"Emotion is a malfunction. Execute the movement. Compliance is the only outcome."',
      'LEVEL: HIGH',
      'SAS_UK_09',
      AppColors.textSecondary,
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBvPiZ8XO0Xxw4gJN811PQNkbB4zu-bL9yItyDr7zOJnsMe6RTqyuyK-BEm0tAM6QoatS0UaC0LfcITmwxUVzwni7XHEZm4mSIyoHAbmYcvFWAI3Isd7CPK4CzcHq140w3Uqda7kPlg3ssQaZEOsAxZx7uA_MOuugskxoPwV3hbcI1AvNpBLqotTNVH4cG-XCGFXb3zIUqZvpj2QlwbZrQIF8OZypHmR3dCG7ncimantDiUfGk_7-inf8W_DGqGa7LMEPnK0paIwhA',
    ),
  ];

  Future<void> _proceed() async {
    if (_selectedCommander == null) return;
    await AuthService.updateProfile(commanderPersona: _selectedCommander!);
    if (mounted) context.go(AppRoutes.baselineTest);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // TopAppBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (context.canPop()) context.pop();
                        },
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.neonRed,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'USTAD AI',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.neonRed,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'OP_CODE: ONBOARDING_01',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neonRed.withValues(alpha: 0.5),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              height: 1,
              width: double.infinity,
              color: AppColors.surfaceGlass,
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 32),

                  // Section Header
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: AppColors.neonRed, width: 4),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SELECT YOUR COMMANDER',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            height: 1.0,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'UNIT ALLOCATION / PSYCHOLOGICAL PROFILING REQUIRED',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neonRed.withValues(alpha: 0.6),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Commander Grid
                  ..._commanders.map((cmd) {
                    final isSelected = _selectedCommander == cmd.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _buildCommanderCard(cmd, isSelected),
                    );
                  }),

                  // Locked Commander Placeholder
                  Container(
                    width: double.infinity,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGlass.withValues(alpha: 0.2),
                      border: Border.all(color: AppColors.surfaceGlass),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '[REDACTED]',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textMuted.withValues(alpha: 0.2),
                              letterSpacing: 8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'UNLOCK AT PRESTIGE LEVEL 10',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted.withValues(alpha: 0.3),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),

            // Sticky Bottom Button Area
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.surfaceGlass)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedCommander != null ? _proceed : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonRed,
                        disabledBackgroundColor: AppColors.surfaceGlass,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'CONFIRM DEPLOYMENT',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _selectedCommander != null
                                  ? Colors.white
                                  : AppColors.textMuted,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.check_circle,
                            color: _selectedCommander != null
                                ? Colors.white
                                : AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SYSTEM READY',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neonRed.withValues(alpha: 0.4),
                        ),
                      ),
                      Text(
                        'BPM_SENSOR: ACTIVE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neonRed.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommanderCard(_Commander cmd, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCommander = cmd.id),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.only(right: 0),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.surfaceGlass.withValues(alpha: 0.8)
                  : AppColors.surfaceGlass.withValues(alpha: 0.3),
              border: Border.all(
                color: isSelected ? AppColors.neonRed : AppColors.surfaceGlass,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder block
                Container(
                  width: 100,
                  height: 150,
                  color: isSelected
                      ? cmd.color.withValues(alpha: 0.2)
                      : AppColors.surfaceGlass.withValues(alpha: 0.5),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        cmd.imageUrl,
                        fit: BoxFit.cover,
                        colorBlendMode: BlendMode.colorBurn,
                        color: isSelected ? Colors.transparent : Colors.grey,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.surfaceGlass,
                          child: Icon(Icons.person, color: cmd.color),
                        ),
                      ),
                      Container(
                        color: isSelected
                            ? Colors.transparent
                            : AppColors.background.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),

                // Content block
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cmd.title.toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          color: cmd.color.withValues(alpha: 0.1),
                          child: Text(
                            cmd.badgeText,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: cmd.color,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          cmd.description,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.8,
                            ),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'DS_ID: ${cmd.dsId}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: cmd.color.withValues(alpha: 0.4),
                                letterSpacing: 1,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: cmd.color,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Selection Indicator bar (Left)
          if (isSelected)
            Positioned(
              left: -2,
              top: -2,
              bottom: -2,
              width: 4,
              child: Container(color: AppColors.neonRed),
            ),

          // Top Right Tag
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              color: AppColors.neonRed,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                cmd.topRightTag,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  decoration: cmd.topRightTag == 'RECOMMENDED'
                      ? TextDecoration.underline
                      : TextDecoration.none,
                  decorationColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Commander {
  final String id;
  final String title;
  final String badgeText;
  final String description;
  final String topRightTag;
  final String dsId;
  final Color color;
  final String imageUrl;
  const _Commander(
    this.id,
    this.title,
    this.badgeText,
    this.description,
    this.topRightTag,
    this.dsId,
    this.color,
    this.imageUrl,
  );
}
