import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

/// Single notification row in the Inbox screen.
class NotificationItem extends StatelessWidget {
  final String title;
  final String body;
  final bool isRead;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationItem({
    super.key,
    required this.title,
    required this.body,
    this.isRead = true,
    this.onTap,
    this.onDismiss,
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
            Stack(
              children: [
                Container(
                  width: AppSizes.avatarSmall,
                  height: AppSizes.avatarSmall,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.avatarSalmon,
                  ),
                ),
                if (!isRead)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: AppSizes.paddingM),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: isRead
                          ? AppColors.notifBorder
                          : AppColors.primary,
                      width: 3,
                    ),
                  ),
                ),
                padding: const EdgeInsets.only(left: AppSizes.paddingS),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body(
                        fontSize: AppSizes.fontS,
                        color: AppColors.textDark,
                        fontWeight:
                            isRead ? FontWeight.normal : FontWeight.bold,
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
