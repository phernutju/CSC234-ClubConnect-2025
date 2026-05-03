import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_constants.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/liquid_card.dart';

/// Sign-up screen: email, password, confirm-password fields.
/// Heading uses a mix of black regular text and italic coral accent.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onNext() {
    // TODO: validate form fields before proceeding
    context.push('/verify-phone');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Illustration area (mascot characters placeholder) ────────────
          Expanded(
            flex: 4,
            child: const SizedBox(width: double.infinity),
          ),

          // ── Glass liquid card: form fields ───────────────────────────────
          LiquidCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Create your account" — mixed style heading
                _SignupHeading(),
                const SizedBox(height: AppSizes.paddingL),

                // Email
                AuthTextField(
                  label: AppStrings.signupEmail,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSizes.paddingM),

                // Password
                AuthTextField(
                  label: AppStrings.signupPassword,
                  controller: _passwordController,
                  obscureText: true,
                ),
                const SizedBox(height: AppSizes.paddingM),

                // Confirm password
                AuthTextField(
                  label: AppStrings.signupConfirm,
                  controller: _confirmController,
                  obscureText: true,
                ),
                const SizedBox(height: AppSizes.paddingXL),

                // Next button
                PrimaryButton(
                  label: AppStrings.signupNext,
                  onPressed: _onNext,
                ),
                const SizedBox(height: AppSizes.paddingM),

                // Google sign-in option
                GoogleSignInButton(onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

/// "Create your " (black) + "account" (italic coral) heading.
class _SignupHeading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: AppStrings.signupHeading,
            style: AppTextStyles.title(color: AppColors.textDark),
          ),
          TextSpan(
            text: AppStrings.signupHeadingAccent,
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
