import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_constants.dart';
import '../widgets/step_progress_bar.dart';
import '../widgets/primary_button.dart';

/// Step 3 of 4: user enters the 4-digit SMS code they received.
/// Automatically moves focus to the next digit box when a digit is typed.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _onNext() {
    // TODO: verify OTP with backend
    context.push('/set-profile');
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

              // Step indicator: 3 of 4 filled
              const StepProgressBar(currentStep: 3),
              const SizedBox(height: AppSizes.paddingL),

              // Back arrow
              _BackButton(),
              const SizedBox(height: AppSizes.paddingM),

              // "Enter " (black) + "OTP" (italic coral)
              _OtpHeading(),
              const SizedBox(height: AppSizes.paddingS),

              // Subtitle explanation
              Text(
                AppStrings.otpSubtitle,
                style: AppTextStyles.body(
                  fontSize: AppSizes.fontS,
                  color: AppColors.textGray,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSizes.paddingXL),

              // Row of 4 digit input boxes
              _OtpBoxRow(
                controllers: _controllers,
                focusNodes: _focusNodes,
                onChanged: _onDigitChanged,
              ),
              const SizedBox(height: AppSizes.paddingM),

              // "Didn't receive code? Resend now"
              _ResendRow(),

              const Spacer(),

              // Next button
              PrimaryButton(label: AppStrings.otpNext, onPressed: _onNext),
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
      child: const Icon(Icons.arrow_back, color: AppColors.textDark),
    );
  }
}

/// "Enter " in bold black + "OTP" in italic coral side-by-side.
class _OtpHeading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: AppStrings.otpHeading,
            style: AppTextStyles.title(color: AppColors.textDark),
          ),
          TextSpan(
            text: AppStrings.otpHeadingAccent,
            style: AppTextStyles.title(
              fontStyle: FontStyle.italic,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Four square digit input boxes in a horizontal row.
class _OtpBoxRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(String value, int index) onChanged;

  const _OtpBoxRow({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS),
          child: SizedBox(
            width: AppSizes.otpBoxSize,
            height: AppSizes.otpBoxSize,
            child: TextField(
              controller: controllers[i],
              focusNode: focusNodes[i],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              onChanged: (v) => onChanged(v, i),
              style: AppTextStyles.body(
                fontSize: AppSizes.fontXL,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: false,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// "Didn't receive code?" + tappable "Resend now" in coral.
class _ResendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.otpNoCode,
            style: AppTextStyles.body(
              fontSize: AppSizes.fontS,
              color: AppColors.textGray,
            ),
          ),
          GestureDetector(
            onTap: () {
              // TODO: trigger resend OTP
            },
            child: Text(
              AppStrings.otpResend,
              style: AppTextStyles.body(
                fontSize: AppSizes.fontS,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
