import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/services/auth_service.dart';

/// Screen B-03: VAULT — Escrow status, 28-day streak grid, financial accountability.
/// Design: Stitch "Vault Escrow" HTML — brutalist, zero rounding, #ff5540 accents.
class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await AuthService.getProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Grid background
          _buildGridBackground(),

          SafeArea(
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
                              _buildCollateralHero(),
                              const SizedBox(height: 20),
                              _buildStreakGrid(),
                              const SizedBox(height: 20),
                              _buildEscrowRules(),
                              const SizedBox(height: 20),
                              _buildRefundProgress(),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridBackground() {
    return Positioned.fill(
      child: CustomPaint(painter: _GridPainter()),
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
          const Icon(Icons.account_balance_wallet_outlined, color: AppColors.neonRed, size: 18),
          const SizedBox(width: 10),
          Text(
            'VAULT / ESCROW',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            color: AppColors.neonRed.withValues(alpha: 0.15),
            child: Text(
              'ACTIVE',
              style: GoogleFonts.orbitron(
                fontSize: 8,
                color: AppColors.neonRed,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollateralHero() {
    final amount = _profile?['collateral_amount'] ?? 0;
    final status = (_profile?['streak_status'] ?? 'unbroken').toString();
    final isUnbroken = status != 'broken';

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        border: Border(left: BorderSide(color: isUnbroken ? AppColors.neonRed : AppColors.danger, width: 6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isUnbroken ? Icons.lock_outline : Icons.lock_open_outlined,
                color: isUnbroken ? AppColors.neonRed : AppColors.danger,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'SECURED ASSETS',
                style: GoogleFonts.orbitron(
                  fontSize: 9,
                  color: AppColors.textMuted,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹$amount',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: isUnbroken ? AppColors.neonRed : AppColors.danger,
              height: 1.0,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                color: isUnbroken ? AppColors.neonRed : AppColors.danger,
              ),
              const SizedBox(width: 8),
              Text(
                'STATUS: ${status.toUpperCase()}',
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  color: isUnbroken ? AppColors.neonRed : AppColors.danger,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          if (isUnbroken) ...[
            const SizedBox(height: 16),
            Text(
              'Your collateral is held in escrow. Complete all 28 days to unlock a full refund.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStreakGrid() {
    final currentDay = (_profile?['current_day'] as int?) ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('28-DAY STREAK GRID'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: 28,
          itemBuilder: (context, index) {
            final day = index + 1;
            final isCompleted = day < currentDay;
            final isCurrent = day == currentDay;
            final isFuture = day > currentDay;

            Color bgColor;
            Color textColor;
            Color borderColor;

            if (isCompleted) {
              bgColor = AppColors.neonRed.withValues(alpha: 0.15);
              textColor = AppColors.neonRed;
              borderColor = AppColors.neonRed.withValues(alpha: 0.4);
            } else if (isCurrent) {
              bgColor = AppColors.neonRed;
              textColor = Colors.white;
              borderColor = AppColors.neonRed;
            } else {
              bgColor = AppColors.surfaceContainerHighest;
              textColor = AppColors.textMuted;
              borderColor = AppColors.outlineVariant;
            }

            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                border: Border.all(color: borderColor),
              ),
              alignment: Alignment.center,
              child: isFuture
                  ? Text(
                      '$day',
                      style: GoogleFonts.orbitron(fontSize: 9, color: textColor),
                    )
                  : isCompleted
                      ? Icon(Icons.check, color: textColor, size: 12)
                      : Text(
                          '$day',
                          style: GoogleFonts.orbitron(
                            fontSize: 9,
                            color: textColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _legendItem(AppColors.neonRed, 'COMPLETE'),
            const SizedBox(width: 16),
            _legendItem(AppColors.textMuted, 'UPCOMING'),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.orbitron(fontSize: 8, color: AppColors.textMuted, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildEscrowRules() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        border: Border(left: BorderSide(color: Color(0xFF2A2A2A), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('// ESCROW PROTOCOL'),
          const SizedBox(height: 16),
          _ruleRow(Icons.check_circle_outline, '28 DAYS COMPLETED → FULL COLLATERAL REFUND', AppColors.neonRed),
          _ruleRow(Icons.cancel_outlined, 'MISSED ALARM → COLLATERAL FORFEIT', AppColors.danger),
          _ruleRow(Icons.account_balance_outlined, 'COLLATERAL HELD VIA RAZORPAY UPI', AppColors.textSecondary),
          _ruleRow(Icons.schedule_outlined, 'REFUND PROCESSED WITHIN 48 HOURS', AppColors.textSecondary),
          _ruleRow(Icons.privacy_tip_outlined, 'NO PARTIAL REFUNDS. NO EXCEPTIONS.', AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _ruleRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                color: color,
                letterSpacing: 1,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundProgress() {
    final currentDay = (_profile?['current_day'] as int?) ?? 0;
    final progress = (currentDay / 28).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('// REFUND UNLOCK PROGRESS'),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(height: 12, color: AppColors.background),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(height: 12, color: AppColors.neonRed),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DAY $currentDay / 28',
                style: GoogleFonts.orbitron(fontSize: 10, color: AppColors.neonRed, letterSpacing: 2),
              ),
              Text(
                '${(progress * 100).toInt()}% COMPLETE',
                style: GoogleFonts.orbitron(fontSize: 10, color: AppColors.textMuted, letterSpacing: 2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.orbitron(
        fontSize: 9,
        color: AppColors.neonRed,
        letterSpacing: 3,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..strokeWidth = 0.5;

    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
