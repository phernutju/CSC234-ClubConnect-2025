import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

/// Card that represents a single community/club in any of the home tabs.
class ClubCard extends StatelessWidget {
  final String name;
  final String description;
  final String memberCount;
  final VoidCallback? onTap;

  const ClubCard({
    super.key,
    required this.name,
    required this.description,
    required this.memberCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _ClubThumbnail(),

            const SizedBox(width: AppSizes.paddingM),

            Expanded(child: _ClubInfo(
              name: name,
              description: description,
              memberCount: memberCount,
            )),

            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _ClubThumbnail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.cardThumbnailSize,
      height: AppSizes.cardThumbnailSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
        color: AppColors.inputFill,
      ),
      child: const SizedBox(),
    );
  }
}

class _ClubInfo extends StatelessWidget {
  final String name;
  final String description;
  final String memberCount;

  const _ClubInfo({
    required this.name,
    required this.description,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.title(
            fontSize: AppSizes.fontM,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 2),

        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body(
            fontSize: AppSizes.fontXS,
            color: AppColors.textGray,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),

        Text(
          memberCount,
          style: AppTextStyles.body(
            fontSize: AppSizes.fontXS,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
