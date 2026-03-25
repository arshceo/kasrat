import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Determine the current index based on the route location
    final String location = GoRouterState.of(context).matchedLocation;
    int currentIndex = _calculateSelectedIndex(location);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      // Minimalist BottomNavBar
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.15),
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
              route: AppRoutes.dashboard,
            ),
            _buildNavItem(
              context,
              index: 1,
              currentIndex: currentIndex,
              icon: 'receipt_long',
              label: 'RECORDS',
              route: AppRoutes.records,
            ),
            _buildNavItem(
              context,
              index: 2,
              currentIndex: currentIndex,
              icon: 'account_balance_wallet',
              label: 'VAULT',
              route: AppRoutes.vault,
              filledIcon: true,
            ),
            _buildNavItem(
              context,
              index: 3,
              currentIndex: currentIndex,
              icon: 'settings_accessibility',
              label: 'PROFILE',
              route: AppRoutes.profile,
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
    required String route,
    bool filledIcon = false,
  }) {
    final bool isActive = index == currentIndex;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          splashColor: Colors.transparent,
          highlightColor: AppColors.surfaceContainerHigh,
          child: Container(
            color: isActive ? AppColors.neonRed : Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  // We simulate Material Symbols logic here (filled variation requires specific font/weight setup in normal apps, 
                  // but we'll use IconData mapping or typical icons as close to what's requested)
                  _getIconData(icon),
                  color: isActive ? Colors.black : Colors.white.withValues(alpha: 0.6),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: isActive ? Colors.black : Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'target':
        return Icons.radar; // closest match
      case 'receipt_long':
        return Icons.receipt_long;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'settings_accessibility':
        return Icons.accessibility_new;
      default:
        return Icons.circle;
    }
  }

  int _calculateSelectedIndex(String location) {
    if (location.startsWith(AppRoutes.dashboard)) return 0;
    if (location.startsWith(AppRoutes.records)) return 1;
    if (location.startsWith(AppRoutes.vault)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0; // default to dashboard
  }
}
