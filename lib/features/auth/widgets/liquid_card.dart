import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

/// Solid card that sits at the bottom of auth screens over the background image.
/// Rounded top corners of 30px to match Figma design.
class LiquidCard extends StatelessWidget {
  final Widget child;
  final double horizontalPadding;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const LiquidCard({
    super.key,
    required this.child,
    this.horizontalPadding = AppSizes.paddingL,
    this.color,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(30),
      ),
      child: Container(
        width: double.infinity,
        color: color ?? AppColors.cardWhite,
        padding: padding ??
            EdgeInsets.fromLTRB(
              horizontalPadding,
              AppSizes.paddingXL,
              horizontalPadding,
              AppSizes.paddingXXL,
            ),
        child: child,
      ),
    );
  }
}