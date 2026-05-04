import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

/// Reusable text field for all auth screens.
///
/// Renders a label above the input and a rounded, lightly-filled input box.
/// Pass [obscureText] = true for password fields.
/// Pass [borderColor] to override the default border (e.g., primary orange on
/// the Verify Phone screen).
class AuthTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final Color? borderColor;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const AuthTextField({
    super.key,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.borderColor,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeBorder = borderColor ?? AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body(
            fontSize: AppSizes.fontS,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppSizes.paddingS),

        SizedBox(
          height: AppSizes.inputHeight,
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: AppTextStyles.body(
              fontSize: AppSizes.fontM,
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.body(color: AppColors.textGray),
              filled: true,
              fillColor: AppColors.inputFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingM,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                borderSide: BorderSide(color: activeBorder, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
