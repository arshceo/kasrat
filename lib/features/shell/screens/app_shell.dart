import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/widgets/tactical_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasrat_ai/features/dashboard/providers/dashboard_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _isLoading = true;
  bool _isPaid = false;
  bool _isOnboardingComplete = false;
  int _baselineSquats = -1;
  int _baselinePushups = -1;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        final onboardingComplete = response?['onboarding_complete'] ?? false;

        if (!onboardingComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go(AppRoutes.exerciseSelection);
          });
          return; 
        }

        setState(() {
          _isPaid = response?['is_paid'] ?? false;
          _isOnboardingComplete = onboardingComplete;
          _baselineSquats = response?['baseline_squats'] ?? -1;
          _baselinePushups = response?['baseline_pushups'] ?? -1;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _showExitPrompt(DashboardState state) async {
    String title = 'EXIT MISSION?';
    String message = 'MISSION PROGRESS WILL BE SUSPENDED.';
    String primaryActionLabel = 'EXIT';
    bool isHardPrompt = false;

    if (state.isSubscriber && state.protocolTitle != 'NO ACTIVE MISSION') {
      if (!state.isWorkoutDoneToday) {
        title = 'DISCIPLINE REQUIRED';
        message = 'FINISH YOUR DAILY WORKOUT FIRST. DISCIPLINE IS NON-NEGOTIABLE.';
        primaryActionLabel = 'STAY & FINISH';
        isHardPrompt = true;
      }
    } else if (state.pendingCode != null) {
      title = 'AUTH PENDING';
      message = 'DEPLOYMENT AUTHENTICATION PENDING. COMPLETE AUTH ON THE WEBSITE TO START YOUR MISSION.';
      primaryActionLabel = 'CONTINUE AUTH';
      isHardPrompt = true;
    } else if (state.protocolTitle == 'NO ACTIVE MISSION') {
      title = 'NO ACTIVE MISSION';
      message = 'NO ACTIVE MISSION. JOIN A CHALLENGE TO COMMENCE OPERATIONS.';
      primaryActionLabel = 'JOIN CHALLENGE';
      isHardPrompt = true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.neonRed, width: 2),
        ),
        title: Text(
          title,
          style: GoogleFonts.orbitron(
            color: AppColors.neonRed,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 18,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          if (isHardPrompt)
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'FORCE EXIT',
                style: GoogleFonts.orbitron(color: Colors.white30, fontSize: 10),
              ),
            )
          else
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'CANCEL',
                style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 12),
              ),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonRed,
              foregroundColor: Colors.white,
              shape: const BeveledRectangleBorder(),
            ),
            onPressed: () {
              if (primaryActionLabel == 'JOIN CHALLENGE') {
                Navigator.of(context).pop(false);
                widget.navigationShell.goBranch(1);
              } else if (primaryActionLabel == 'CONTINUE AUTH') {
                Navigator.of(context).pop(false);
              } else if (primaryActionLabel == 'STAY & FINISH') {
                Navigator.of(context).pop(false);
              } else {
                Navigator.of(context).pop(true);
              }
            },
            child: Text(
              primaryActionLabel,
              style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.neonRed),
        ),
      );
    }

    final int currentIndex = widget.navigationShell.currentIndex;
    final state = ref.watch(dashboardProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _showExitPrompt(state);
        if (shouldPop && mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: widget.navigationShell,
      // Minimalist BottomNavBar
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: AppColors.outlineVariant.withOpacity(0.15)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildNavItem(
              context,
              index: 0,
              currentIndex: currentIndex,
              icon: 'target',
              label: 'COMMAND',
            ),
            _buildNavItem(
              context,
              index: 1,
              currentIndex: currentIndex,
              icon: 'armory',
              label: 'CHALLENGE',
            ),
            _buildNavItem(
              context,
              index: 2,
              currentIndex: currentIndex,
              icon: 'leaderboard',
              label: 'WARZONE',
            ),
            _buildNavItem(
              context,
              index: 3,
              currentIndex: currentIndex,
              icon: 'settings_accessibility',
              label: 'PROFILE',
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required int currentIndex,
    required String icon,
    required String label,
  }) {
    final bool isActive = index == currentIndex;

    return Expanded(
      child: TacticalButton(
        soundType: TacticalSoundType.mouseClick,
        onTap: () => _onNavigationAction(index),
        child: Container(
          color: isActive ? AppColors.neonRed : Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconData(icon),
                color: isActive ? Colors.black : Colors.white.withOpacity(0.6),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: isActive
                      ? Colors.black
                      : Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNavigationAction(int index) {
    debugPrint('AppShell: Navigation to index $index triggered');
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'target':
        return Icons.radar;
      case 'armory':
        return Icons.fitness_center;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'settings_accessibility':
        return Icons.accessibility_new;
      case 'leaderboard':
        return Icons.workspace_premium;
      default:
        return Icons.circle;
    }
  }
}
