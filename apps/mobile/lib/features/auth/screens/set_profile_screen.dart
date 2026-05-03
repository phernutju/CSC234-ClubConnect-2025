import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_constants.dart';
import '../widgets/step_progress_bar.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

/// Step 3 of 4: user sets a display name and an optional bio.
/// A tappable avatar circle lets them upload a profile photo.
class SetProfileScreen extends StatefulWidget {
  const SetProfileScreen({super.key});

  @override
  State<SetProfileScreen> createState() => _SetProfileScreenState();
}

class _SetProfileScreenState extends State<SetProfileScreen> {
  final _displayNameController = TextEditingController();
  final _aboutMeController     = TextEditingController();

  @override
  void dispose() {
    _displayNameController.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }

  void _onNext() {
    context.push('/category');
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

              // Step 3 of 4
              const StepProgressBar(currentStep: 3),
              const SizedBox(height: AppSizes.paddingL),

              // Back arrow
              _BackButton(),
              const SizedBox(height: AppSizes.paddingM),

              // "Complete " (black) + "Profile !" (italic coral)
              _ProfileHeading(),
              const SizedBox(height: AppSizes.paddingXL),

              // Avatar picker
              Center(child: _AvatarPicker()),
              const SizedBox(height: AppSizes.paddingXL),

              // Display name field
              AuthTextField(
                label: AppStrings.setProfileDisplayName,
                controller: _displayNameController,
              ),
              const SizedBox(height: AppSizes.paddingM),

              // Bio field (optional)
              AuthTextField(
                label: AppStrings.setProfileAboutMe,
                controller: _aboutMeController,
              ),

              const Spacer(),

              // Next button
              PrimaryButton(
                label: AppStrings.setProfileNext,
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
      child: const Icon(Icons.arrow_back, color: AppColors.textDark),
    );
  }
}

/// "Complete " (black bold) + "Profile !" (italic coral Instrument Serif).
class _ProfileHeading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: AppStrings.setProfileHeading,
            style: AppTextStyles.title(color: AppColors.textDark),
          ),
          TextSpan(
            text: AppStrings.setProfileHeadingAccent,
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

/// Salmon-colored circle placeholder with a camera-badge overlay.
class _AvatarPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.avatarLarge,
      height: AppSizes.avatarLarge,
      child: Stack(
        children: [
          Container(
            width: AppSizes.avatarLarge,
            height: AppSizes.avatarLarge,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.avatarSalmon,
            ),
            child: const SizedBox(),
          ),

          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(AppSizes.paddingXS + 2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textDark,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: AppColors.cardWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
