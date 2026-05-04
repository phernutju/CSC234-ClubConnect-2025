import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

/// Single notification row: coral left border, salmon avatar, rich-text lines.
/// Followed by a hairline divider.
class NotificationItem extends StatelessWidget {
  final String senderName;
  final String communityName;

  /// The message snippet shown below the mention line (e.g. "@name message text").
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Salmon circle avatar
                Container(
                  width: AppSizes.avatarSmall,
                  height: AppSizes.avatarSmall,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.profileHeaderStart, // #FFB199
                  ),
                ),
                const SizedBox(width: AppSizes.paddingM),

                // Coral left-border content block
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: AppColors.notifBorder,
                          width: AppSizes.notifBorderWidth,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: AppSizes.paddingS),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // "[Name] mentioned you in [Community Name]"
                        RichText(
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
                              const TextSpan(text: AppStrings.notifMention),
                              TextSpan(
                                text: communityName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),

                        // "@name message snippet"
                        Text(
                          body,
                          style: AppTextStyles.body(
                            fontSize: AppSizes.fontXS,
                            color: AppColors.commentBody, // #837A7A
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Hairline divider below each item
        Container(
          height: AppSizes.inboxDividerWidth,
          color: AppColors.rateCardBorder, // #E8DFD8
        ),
      ],
    );
  }
}
