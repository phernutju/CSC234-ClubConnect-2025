import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

/// Frosted-glass card that "floats" over the cream background on auth screens.
///
/// ClipRRect clips the blur region to rounded top corners. BackdropFilter blurs
/// the background behind the card. The semi-transparent white container with a
/// white border completes the liquid glass look.
class LiquidCard extends StatelessWidget {
  final Widget child;
  final double horizontalPadding;

  const LiquidCard({
    super.key,
    required this.child,
    this.horizontalPadding = AppSizes.paddingL,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSizes.radiusXL),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppSizes.glassBlurSigma,
          sigmaY: AppSizes.glassBlurSigma,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            border: Border.all(color: AppColors.glassBorder),
          ),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSizes.paddingXL,
            horizontalPadding,
            AppSizes.paddingXXL,
          ),
          child: child,
        ),
      ),
    );
  }
}
