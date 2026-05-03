import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

/// Full-width pill-shaped button used as the primary action on every screen.
///
/// Defaults to the app's coral primary color with white text.
/// Pass [backgroundColor] and [textColor] to override for special cases.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = AppColors.primary,
    this.textColor = AppColors.cardWhite,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.body(
            fontSize: AppSizes.fontL,
            fontWeight: FontWeight.w600,
            color: AppColors.cardWhite,
          ),
        ),
      ),
    );
  }
}
