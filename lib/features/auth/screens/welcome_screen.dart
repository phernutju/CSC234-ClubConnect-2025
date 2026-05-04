import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_constants.dart';
import '../widgets/liquid_card.dart';
import '../widgets/primary_button.dart';

/// Entry point of the app.
/// Shows the mascot illustration area (placeholder) and two action buttons.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Illustration area (mascot characters placeholder) ────────────
          Expanded(
            flex: 5,
            child: _IllustrationPlaceholder(),
          ),

          // ── Glass liquid card: tagline + buttons ─────────────────────────
          LiquidCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Drop-in !" heading
                Text(
                  AppStrings.welcomeHeading,
                  style: AppTextStyles.title(
                    fontSize: AppSizes.fontDisplay,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingXS),

                // Italic coral tagline
                Text(
                  AppStrings.welcomeTagline,
                  style: AppTextStyles.title(
                    fontSize: AppSizes.fontXL,
                    fontStyle: FontStyle.italic,
                    color: AppColors.primary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingXL),

                // Login button
                PrimaryButton(
                  label: AppStrings.welcomeLogin,
                  onPressed: () => context.push('/login'),
                ),
                const SizedBox(height: AppSizes.paddingM),

                // "No Account? Sign Up" text link
                Center(child: _SignUpLink()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _IllustrationPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: double.infinity);
  }
}

class _SignUpLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.welcomeNoAccount,
          style: AppTextStyles.body(
            fontSize: AppSizes.fontM,
            color: AppColors.textDark,
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/signup'),
          child: Text(
            AppStrings.welcomeSignUp,
            style: AppTextStyles.body(
              fontSize: AppSizes.fontM,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
