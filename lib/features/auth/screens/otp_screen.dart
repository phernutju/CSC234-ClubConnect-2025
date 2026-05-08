import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_constants.dart';
import '../widgets/step_progress_bar.dart';
import '../widgets/primary_button.dart';

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
        minimum: const EdgeInsets.only(top: 16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              const StepProgressBar(currentStep: 3),
              const SizedBox(height: AppSizes.paddingL),

              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(Icons.arrow_back, color: AppColors.textDark),
              ),
              const SizedBox(height: AppSizes.paddingM),

              // "Enter " (black) + "OTP" (italic coral)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: AppStrings.otpHeading,
                      style: AppTextStyles.title(
                        fontSize: 36.0,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textDark,
                      ),
                    ),
                    TextSpan(
                      text: AppStrings.otpHeadingAccent,
                      style: AppTextStyles.title(
                        fontSize: 36.0,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.paddingS),

              Text(
                AppStrings.otpSubtitle,
                style: AppTextStyles.body(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textGray,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSizes.paddingXL),

              _OtpBoxRow(
                controllers: _controllers,
                focusNodes: _focusNodes,
                onChanged: _onDigitChanged,
              ),
              const SizedBox(height: AppSizes.paddingM),

              _ResendRow(),
              const SizedBox(height: AppSizes.paddingXL),

              PrimaryButton(label: AppStrings.otpNext, onPressed: _onNext),
              const SizedBox(height: AppSizes.paddingXL),
            ],
          ),
        ),
      ),
    );
  }
}

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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) => onChanged(v, i),
              style: AppTextStyles.body(
                fontSize: AppSizes.fontXL,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              decoration: const InputDecoration(
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFFDDDDDD), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFFFF6B4A), width: 2),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

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
              fontSize: AppSizes.fontXS,
              fontWeight: FontWeight.w400,
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
                fontSize: AppSizes.fontXS,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}