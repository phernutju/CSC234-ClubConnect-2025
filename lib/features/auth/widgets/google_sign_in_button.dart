import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

/// Circular Google sign-in icon shown below the Next button on
/// the Login and Sign-up screens.
///
/// The "G" logo is replicated with Flutter's built-in text styling
/// since we don't bundle a custom SVG asset here.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const GoogleSignInButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.inputBorder, width: 1.5),
            color: AppColors.cardWhite,
          ),
          // Multicolor "G" text that approximates the Google logo
          child: const Center(
            child: Text(
              'G',
              style: TextStyle(
                fontSize: AppSizes.fontL,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4285F4), // Google blue
              ),
            ),
          ),
        ),
      ),
    );
  }
}
