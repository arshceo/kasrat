import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/widgets/tactical_button.dart';
import 'package:kasrat_ai/features/dashboard/logic/dashboard_utils.dart';

class DashboardHeader extends StatelessWidget {
  final String rank;
  final String fullName;
  final bool isSubscriber;

  const DashboardHeader({
    super.key,
    required this.rank,
    required this.fullName,
    required this.isSubscriber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isSubscriber ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'SITREP: USTAD AI // BHARATACE CORP',
                style: GoogleFonts.spaceMono(
                  fontSize: 7,
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TacticalButton(
                soundType: TacticalSoundType.nav,
                onTap: () {
                  context.push(
                    AppRoutes.rankUnlocked,
                    extra: {
                      'rankName': rank,
                      'insigniaPath': DashboardUtils.getInsigniaPath(rank),
                      'isSilent': true,
                    },
                  );
                },
                child: Container(
                  width: 64,
                  height: 64,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh.withValues(alpha: 0.3),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      _buildCornerBrackets(),
                      Center(
                        child: Image.asset(
                          DashboardUtils.getInsigniaPath(rank),
                          width: 40,
                          height: 40,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rank.toUpperCase(),
                      style: GoogleFonts.orbitron(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.neonRed,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            fullName.toUpperCase(),
                            style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSubscriber 
                                  ? Colors.green.withValues(alpha: 0.15) 
                                  : Colors.white.withValues(alpha: 0.05),
                              border: Border.all(
                                  color: isSubscriber 
                                      ? Colors.green.withValues(alpha: 0.5) 
                                      : Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 3,
                                  backgroundColor: isSubscriber ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isSubscriber ? 'ACTIVE' : 'INACTIVE',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: isSubscriber ? Colors.green : AppColors.textMuted,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCornerBrackets() {
    return Stack(
      children: [
        Positioned(
          top: 2,
          left: 2,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white, width: 1),
                left: BorderSide(color: Colors.white, width: 1),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white, width: 1),
                right: BorderSide(color: Colors.white, width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
