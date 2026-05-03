import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_constants.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/liquid_card.dart';

/// Login screen: email + password fields, Next button, Google sign-in.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onNext() {
    // TODO: validate credentials; route to verify-phone on success
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
                // Screen title
                Text(
                  AppStrings.loginTitle,
                  style: AppTextStyles.title(color: AppColors.textDark),
                ),
                const SizedBox(height: AppSizes.paddingL),

                // Email field
                AuthTextField(
                  label: AppStrings.loginEmail,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSizes.paddingM),

                // Password field
                AuthTextField(
                  label: AppStrings.loginPassword,
                  controller: _passwordController,
                  obscureText: true,
                ),
                const SizedBox(height: AppSizes.paddingXL),

                // Next button
                PrimaryButton(
                  label: AppStrings.loginNext,
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
