import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/step_progress_bar.dart';
import '../widgets/primary_button.dart';

/// Step 3 of 4: user enters the 6-digit SMS code they received.
/// Sends OTP on mount; wires Verify and Resend to AppAuthProvider.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  Future<void> _onNext() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) return;
    final provider = context.read<AppAuthProvider>();
    await provider.verifyOtp(code);
    if (!mounted) return;
    if (provider.otpState == OtpState.verified) {
      context.push('/set-profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppAuthProvider>();
    final isLoading = provider.otpState == OtpState.verifying ||
        provider.otpState == OtpState.sendingOtp;
    final errorMsg = provider.otpState == OtpState.error ? provider.otpError : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        minimum: const EdgeInsets.only(top: 16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.paddingM),
              const StepProgressBar(currentStep: 3),
              const SizedBox(height: AppSizes.paddingL),
              _BackButton(),
              const SizedBox(height: AppSizes.paddingM),
              _OtpHeading(),
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
              if (errorMsg != null)
                Center(
                  child: Text(
                    errorMsg,
                    style: AppTextStyles.body(
                      fontSize: AppSizes.fontS,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (isLoading)
                const Center(child: CircularProgressIndicator()),
              const SizedBox(height: AppSizes.paddingS),
              _ResendRow(
                canResend: provider.canResend,
                onResend: () => provider.sendOtp(),
              ),
              const Spacer(),
              PrimaryButton(
                label: AppStrings.otpNext,
                onPressed: isLoading ? null : _onNext,
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
      child: const Icon(Icons.arrow_back, color: AppColors.textDark),
    );
  }
}

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
      children: List.generate(6, (i) {
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
  final bool canResend;
  final VoidCallback onResend;

  const _ResendRow({required this.canResend, required this.onResend});

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
            onTap: canResend ? onResend : null,
            child: Text(
              AppStrings.otpResend,
              style: AppTextStyles.body(
                fontSize: AppSizes.fontS,
                color: canResend ? AppColors.primary : AppColors.textGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}