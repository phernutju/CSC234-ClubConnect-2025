import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

/// Coral bottom navigation bar with three items: Home, Notification, You.
///
/// [currentIndex] determines which icon/label is highlighted (full opacity).
/// [onTap] fires with the tapped item's index so the parent can call
/// context.go('/home'), context.go('/notification'), or context.go('/profile').
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.bottomNavHeight,
      color: AppColors.primary,
      child: Row(
        children: [
          // Home tab
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: AppStrings.navHome,
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),

          // Notification tab
          _NavItem(
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications,
            label: AppStrings.navNotification,
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),

          // Profile tab
          _NavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: AppStrings.navYou,
            isActive: currentIndex == 2,
            onTap: () => onTap(2),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widget ─────────────────────────────────────────────────────────────────

/// Single item in the bottom nav: icon + label, full opacity when active.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          // Active items are fully visible; inactive items are slightly dimmed
          opacity: isActive ? 1.0 : 0.65,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: AppColors.cardWhite,
                size: AppSizes.iconSize,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppSizes.fontXS,
                  color: AppColors.cardWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
