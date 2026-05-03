import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

/// Horizontal tab row for the Home screen: Discover | My club | Trending.
///
/// The active tab label is coral with an underline indicator.
/// Inactive tabs are gray with no indicator.
class HomeTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const HomeTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  static const List<String> _labels = [
    AppStrings.tabDiscover,
    AppStrings.tabMyClub,
    AppStrings.tabTrending,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length, (i) {
        return _TabItem(
          label: _labels[i],
          isActive: selectedIndex == i,
          onTap: () => onTabChanged(i),
        );
      }),
    );
  }
}

// ── Sub-widget ─────────────────────────────────────────────────────────────────

/// Single tab item with active/inactive styling.
class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: AppSizes.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tab label text
            Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.fontM,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.primary : AppColors.textGray,
              ),
            ),
            const SizedBox(height: 4),

            // Underline indicator — only visible on the active tab
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isActive ? 20 : 0,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
