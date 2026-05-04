import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

/// Displays a row of 4 horizontal segments showing how far along
/// the registration flow the user is (e.g., step 2 of 4).
///
/// Active segments are dark; inactive segments are light gray.
class StepProgressBar extends StatelessWidget {
  /// Number of steps that are filled/active (1–4)
  final int currentStep;

  /// Total number of steps in the flow
  final int totalSteps;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        // Determine whether this segment is before or at the current step
        final bool isActive = index < currentStep;
        return Expanded(
          child: Container(
            height: AppSizes.stepBarHeight,
            // Add a small gap between segments except for the last one
            margin: EdgeInsets.only(
              right: index < totalSteps - 1 ? AppSizes.paddingXS : 0,
            ),
            decoration: BoxDecoration(
              color: isActive ? AppColors.stepActive : AppColors.stepInactive,
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            ),
          ),
        );
      }),
    );
  }
}
