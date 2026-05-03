import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/app_constants.dart';

/// Reusable labeled text field for all auth screens.
/// Label renders in Inter w300 16px. Supports error text and input formatters.
class AuthTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final Color? borderColor;
  final Color? fillColor;
  final double? fieldBorderRadius;
  final Color? enabledBorderColor;
  final double? contentPaddingVertical;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;

  const AuthTextField({
    super.key,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.borderColor,
    this.fillColor,
    this.fieldBorderRadius,
    this.enabledBorderColor,
    this.contentPaddingVertical,
    this.controller,
    this.onChanged,
    this.errorText,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeBorder = borderColor ?? AppColors.primary;
    final Color effectiveFill = fillColor ?? AppColors.inputFill;
    final double radius = fieldBorderRadius ?? AppSizes.radiusPill;

    BorderSide enabledSide;
    if (errorText != null) {
      enabledSide = const BorderSide(color: Colors.red);
    } else if (enabledBorderColor != null) {
      enabledSide = BorderSide(color: enabledBorderColor!, width: 1);
    } else {
      enabledSide = BorderSide.none;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            inputFormatters: inputFormatters,
            style: AppTextStyles.body(
              fontSize: 14.0,
              fontWeight: FontWeight.w400,
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.body(color: AppColors.textGray),
              filled: true,
              fillColor: effectiveFill,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSizes.paddingM,
                vertical: contentPaddingVertical ?? AppSizes.paddingM,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: enabledSide,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: BorderSide(color: activeBorder, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
            ),
          ),
        ),

        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: AppTextStyles.body(
              fontSize: AppSizes.fontXS,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }
}
