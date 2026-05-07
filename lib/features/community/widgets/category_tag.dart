import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

/// Colored square card shown in the "Discover" tab.
/// Each card represents a broad category (e.g., Badminton, Coding, Games)
/// and shows a smiley-face emoji as a playful mascot.
class CategoryTag extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const CategoryTag({
    super.key,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppSizes.categoryCardSize,
        height: AppSizes.categoryCardSize,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        child: Stack(
          children: [
            // Category label at top-left
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingS),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: AppSizes.fontS,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),

            // Smiley-face mascot at bottom-right
            const Positioned(
              bottom: AppSizes.paddingS,
              right: AppSizes.paddingS,
              child: Text(
                '🙂',
                style: TextStyle(fontSize: AppSizes.fontXL),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
