import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

/// Tappable interest chip for the Edit Profile interests grid.
/// Selected state: black background, white text, leading checkmark.
/// Unselected state: outlined border, dark text.
class InterestChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const InterestChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingXS,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.chipSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.interestChipRadius),
          border: Border.all(
            color: selected ? AppColors.chipSelected : AppColors.inputBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(
                Icons.check,
                size: 12,
                color: AppColors.chipSelectedText,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.poppins(
                fontSize: AppSizes.fontSM,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.chipSelectedText : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
