import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/services/auth_service.dart';

/// Screen B-04: DISCIPLINE PROFILE — Account, permissions, re-calibrate, logout.
/// Design: Stitch "Discipline Profile" HTML — brutalist, zero rounding.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService.getProfile();
    if (mounted) setState(() { _profile = profile; _isLoading = false; });
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceContainerHighest,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(width: 4, height: 4, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Text(
                    'ABORT DIRECTIVE?',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                color: const Color(0xFF2A2A2A),
              ),
              const SizedBox(height: 16),
              Text(
                'Initiating logout will suspend your 28-day protocol. Your commander will be disappointed. Any uncommitted streak progress will be lost.',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: const Color(0xFF2A2A2A),
                        alignment: Alignment.center,
                        child: Text(
                          'STAND DOWN',
                          style: GoogleFonts.orbitron(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: AppColors.danger,
                        alignment: Alignment.center,
                        child: Text(
                          'CONFIRM LOGOUT',
                          style: GoogleFonts.orbitron(
                            fontSize: 9,
                            color: Colors.white,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldLogout == true && mounted) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go(AppRoutes.bouncerLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final commander = (_profile?['commander_persona'] ?? 'DRILL_SGT').toString().toUpperCase();
    final currentDay = (_profile?['current_day'] as int?) ?? 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.neonRed))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildOperativeCard(user, commander, currentDay),
                          const SizedBox(height: 20),
                          _buildProtocolStatus(currentDay),
                          const SizedBox(height: 20),
                          _buildActionSection(context),
                          const SizedBox(height: 12),
                          _buildSettingsSection(),
                          const SizedBox(height: 20),
                          _buildTerminateButton(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          const Icon(Icons.settings_accessibility_outlined, color: AppColors.neonRed, size: 18),
          const SizedBox(width: 10),
          Text(
            'DISCIPLINE PROFILE',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperativeCard(dynamic user, String commander, int currentDay) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(left: BorderSide(color: AppColors.neonRed, width: 4)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            color: AppColors.neonRed.withValues(alpha: 0.1),
            alignment: Alignment.center,
            child: const Icon(Icons.person_outline, color: AppColors.neonRed, size: 28),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.email ?? 'UNKNOWN_OPERATIVE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'USTAD: $commander',
                  style: GoogleFonts.orbitron(
                    fontSize: 8,
                    color: AppColors.neonRed,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          // Day badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: AppColors.neonRed,
            child: Column(
              children: [
                Text(
                  'DAY',
                  style: GoogleFonts.orbitron(fontSize: 7, color: Colors.white, letterSpacing: 1),
                ),
                Text(
                  '$currentDay',
                  style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolStatus(int currentDay) {
    final progress = (currentDay / 28).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF1A1A1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// 28-DAY PROTOCOL STATUS',
            style: GoogleFonts.orbitron(fontSize: 9, color: AppColors.neonRed, letterSpacing: 3),
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(height: 8, color: const Color(0xFF2A2A2A)),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(height: 8, color: AppColors.neonRed),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DAY $currentDay OF 28',
                style: GoogleFonts.orbitron(fontSize: 9, color: AppColors.textPrimary, letterSpacing: 2),
              ),
              Text(
                '${(progress * 100).toInt()}% COMPLETE',
                style: GoogleFonts.orbitron(fontSize: 9, color: AppColors.neonRed, letterSpacing: 2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '// OPERATOR ACTIONS',
          style: GoogleFonts.orbitron(fontSize: 9, color: AppColors.textMuted, letterSpacing: 3),
        ),
        const SizedBox(height: 12),

        // RE-CALIBRATE button — primary monolith
        GestureDetector(
          onTap: () => context.push(AppRoutes.calibrationSetup),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.neonRed.withValues(alpha: 0.08),
              border: const Border(
                left: BorderSide(color: AppColors.neonRed, width: 4),
                top: BorderSide(color: Color(0xFF2A2A2A)),
                right: BorderSide(color: Color(0xFF2A2A2A)),
                bottom: BorderSide(color: Color(0xFF2A2A2A)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.sensors, color: AppColors.neonRed, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RE-CALIBRATE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'Re-run physical assessment to update baseline',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.neonRed, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Change commander button
        GestureDetector(
          onTap: () => context.push(AppRoutes.commanderSelection),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              border: Border(
                left: BorderSide(color: Color(0xFF2A2A2A), width: 4),
                top: BorderSide(color: Color(0xFF2A2A2A)),
                right: BorderSide(color: Color(0xFF2A2A2A)),
                bottom: BorderSide(color: Color(0xFF2A2A2A)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.military_tech_outlined, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHANGE COMMANDER',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'Switch your Ustad persona',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '// SYSTEM SETTINGS',
          style: GoogleFonts.orbitron(fontSize: 9, color: AppColors.textMuted, letterSpacing: 3),
        ),
        const SizedBox(height: 12),
        _settingsRow(Icons.notifications_active_outlined, 'ALARM PROTOCOLS', 'Configure wake-up drill times'),
        const SizedBox(height: 8),
        _settingsRow(Icons.security_outlined, 'ACCOUNT SECURITY', 'Password & authentication'),
        const SizedBox(height: 8),
        _settingsRow(Icons.language_outlined, 'LANGUAGE', 'Urdu / Hindi / English'),
      ],
    );
  }

  Widget _settingsRow(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1A1A1A),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
        ],
      ),
    );
  }

  Widget _buildTerminateButton() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.06),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.power_settings_new, color: AppColors.danger, size: 16),
            const SizedBox(width: 10),
            Text(
              'TERMINATE SESSION',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.danger,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
