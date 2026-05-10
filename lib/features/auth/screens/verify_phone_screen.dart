import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../widgets/step_progress_bar.dart';
import '../widgets/primary_button.dart';
import '../../../providers/auth_provider.dart'; 
class VerifyPhoneScreen extends StatefulWidget {
  const VerifyPhoneScreen({super.key});

  @override
  State<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends State<VerifyPhoneScreen> {
  final _phoneController = TextEditingController();
  String? _phoneError;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onNext() {
    final provider = context.read<AppAuthProvider>();
    provider.setPhoneNumber(_phoneController.text);
    provider.sendOtp(); // unawaited — provider state drives OTP screen
    context.push('/otp');
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
              const StepProgressBar(currentStep: 2),
              const SizedBox(height: AppSizes.paddingL),

              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(Icons.arrow_back, color: AppColors.textDark, size: AppSizes.iconSize),
              ),
              const SizedBox(height: AppSizes.paddingM),

              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${AppStrings.verifyHeading}\n',
                      style: AppTextStyles.title(
                        fontSize: 36.0,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textDark,
                      ),
                    ),
                    TextSpan(
                      text: AppStrings.verifyHeadingAccent,
                      style: AppTextStyles.title(
                        fontSize: 36.0,
                        fontWeight: FontWeight.w400,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.paddingXL),

              Text(
                AppStrings.verifyPhoneLabel,
                style: AppTextStyles.body(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: AppSizes.paddingS),

              SizedBox(
                height: AppSizes.inputHeight,
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTextStyles.body(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textDark,
                  ),
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: Colors.red, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingM,
                      vertical: AppSizes.paddingM,
                    ),
                  ),
                ),
              ),

              if (_phoneError != null) ...[
                const SizedBox(height: 4),
                Text(
                  _phoneError!,
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontXS,
                    color: Colors.red,
                  ),
                ),
              ],

              const SizedBox(height: AppSizes.paddingS),

              Text(
                AppStrings.verifyHint,
                style: AppTextStyles.body(
                  fontSize: AppSizes.fontXS,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textGray,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: AppSizes.paddingXL),

              PrimaryButton(label: AppStrings.verifyNext, onPressed: _onNext),
            ],
          ),
        ),
      ),
    );
  }
}