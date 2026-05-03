import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_constants.dart';
import '../widgets/step_progress_bar.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

/// Step 2 of 4 in the registration flow.
/// Collects the user's phone number before sending an OTP SMS.
class VerifyPhoneScreen extends StatefulWidget {
  const VerifyPhoneScreen({super.key});

  @override
  State<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends State<VerifyPhoneScreen> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onNext() {
    // TODO: trigger SMS OTP for the entered phone number
    context.push('/otp');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.paddingM),

              // Step indicator: 2 of 4 filled
              const StepProgressBar(currentStep: 2),
              const SizedBox(height: AppSizes.paddingL),

              // Back arrow
              _BackButton(),
              const SizedBox(height: AppSizes.paddingM),

              // "Verify your" (black) + "Phone Number" (coral, italic)
              _VerifyHeading(),
              const SizedBox(height: AppSizes.paddingXL),

              // Phone number input — note the coral active border
              AuthTextField(
                label: AppStrings.verifyPhoneLabel,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                borderColor: AppColors.primary,
              ),
              const SizedBox(height: AppSizes.paddingS),

              // Helper text below the phone field
              Text(
                AppStrings.verifyHint,
                style: AppTextStyles.body(
                  fontSize: AppSizes.fontXS,
                  color: AppColors.textGray,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              // Next button pinned to the bottom
              PrimaryButton(
                label: AppStrings.verifyNext,
                onPressed: _onNext,
              ),
              const SizedBox(height: AppSizes.paddingXL),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: const Icon(
        Icons.arrow_back,
        color: AppColors.textDark,
        size: AppSizes.iconSize,
      ),
    );
  }
}

/// "Verify your" (bold black) with "Phone Number" (italic coral) on next line.
class _VerifyHeading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.verifyHeading,
          style: AppTextStyles.title(color: AppColors.textDark),
        ),
        Text(
          AppStrings.verifyHeadingAccent,
          style: AppTextStyles.title(
            fontStyle: FontStyle.italic,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
