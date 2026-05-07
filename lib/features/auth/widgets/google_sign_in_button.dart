import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

/// Circular Google sign-in button below the Next button on Login and Sign-up screens.
/// Shows the Google 'G' in Google blue as a fallback logo (flutter_svg not available).
/// Shows a loading spinner when [isLoading] is true.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: isLoading ? null : onPressed,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
            color: Colors.white,
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : Image.asset(
                    'assets/images/google_icon.png',
                    width: 24,
                    height: 24,
                  ),
          ),
        ),
      ),
    );
  }
}
