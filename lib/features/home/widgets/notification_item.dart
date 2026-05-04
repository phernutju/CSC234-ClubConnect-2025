import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

/// Single notification row in the Inbox screen.
class NotificationItem extends StatelessWidget {
  final String senderName;
  final String communityName;
  final String body;
  final VoidCallback? onTap;

  const NotificationItem({
    super.key,
    required this.senderName,
    required this.communityName,
    required this.body,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppSizes.avatarSmall,
              height: AppSizes.avatarSmall,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.avatarSalmon,
              ),
            ),

            const SizedBox(width: AppSizes.paddingM),

            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: AppColors.notifBorder,
                      width: 3,
                    ),
                  ),
                ),
                padding: const EdgeInsets.only(left: AppSizes.paddingS),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.body(
                          fontSize: AppSizes.fontS,
                          color: AppColors.textDark,
                        ),
                        children: [
                          TextSpan(text: senderName),
                          const TextSpan(text: AppStrings.notifMention),
                          TextSpan(
                            text: communityName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),

                    Text(
                      body,
                      style: AppTextStyles.body(
                        fontSize: AppSizes.fontXS,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
