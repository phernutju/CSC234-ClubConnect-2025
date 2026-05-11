import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

/// Single notification row: salmon avatar, coral left-border content block,
/// and a hairline divider at the bottom.
///
/// Displays one of two formats depending on which fields are supplied:
/// - If [senderName] is provided: "[senderName] mentioned you in [communityName]"
/// - Otherwise: [title] (plain text)
/// Either way, [body] is shown as a smaller subtitle below.
class NotificationItem extends StatelessWidget {
  final String title;
  final String senderName;
  final String communityName;

  /// The message snippet shown below the mention line (e.g. "@name message text").
  final String body;
  final bool isRead;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationItem({
    super.key,
    required this.title,
    required this.body,
    this.senderName = '',
    this.communityName = '',
    this.isRead = true,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with unread dot
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

                // Coral left-border content block
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: isRead
                              ? AppColors.notifBorder
                              : AppColors.primary,
                          width: AppSizes.notifBorderWidth,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: AppSizes.paddingS),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header line
                        senderName.isNotEmpty
                            ? RichText(
                                text: TextSpan(
                                  style: AppTextStyles.body(
                                    fontSize: AppSizes.fontSM,
                                    color: AppColors.textDark,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: senderName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const TextSpan(
                                        text: AppStrings.notifMention),
                                    TextSpan(
                                      text: communityName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
                            : Text(
                                title,
                                style: AppTextStyles.body(
                                  fontSize: AppSizes.fontSM,
                                  color: AppColors.textDark,
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),

                        const SizedBox(height: 2),

                        // Body / snippet
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

          // Hairline divider below each item
          Container(
            height: AppSizes.inboxDividerWidth,
            color: AppColors.rateCardBorder,
          ),
        ],
      ),
    );
  }
}
