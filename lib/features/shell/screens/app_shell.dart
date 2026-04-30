import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kasrat_ai/core/constants/app_constants.dart';
import 'package:kasrat_ai/core/widgets/tactical_button.dart';

class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
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
          return; // Keep loading true so we don't flash dashboard
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: widget.navigationShell,
      // Minimalist BottomNavBar
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(
              color: AppColors.outlineVariant.withOpacity(0.15),
            ),
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
              label: 'ARMORY',
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
              icon: 'receipt_long',
              label: 'RECORDS',
            ),
            _buildNavItem(
              context,
              index: 4,
              currentIndex: currentIndex,
              icon: 'settings_accessibility',
              label: 'PROFILE',
            ),
          ],
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
                color: isActive
                    ? Colors.black
                    : Colors.white.withOpacity(0.6),
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
