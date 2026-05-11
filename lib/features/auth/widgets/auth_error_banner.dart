import 'package:flutter/material.dart';

/// Post-submit error banner shown above the form.
/// [message] is the human-readable error copy.
/// [onClose] is called when the user taps ×.
/// [action] is an optional trailing widget (e.g. a "Log in" link).
class AuthErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;
  final Widget? action;

  const AuthErrorBanner({
    super.key,
    required this.message,
    required this.onClose,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFC62828),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 4),
                  action!,
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClose,
            child: const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.close, size: 16, color: Color(0xFFC62828)),
            ),
          ),
        ],
      ),
    );
  }
}
