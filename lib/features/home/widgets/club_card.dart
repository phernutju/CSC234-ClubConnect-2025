import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import 'network_image_view.dart';

/// Card that represents a single community/club in any of the home tabs.
class ClubCard extends StatelessWidget {
  final String name;
  final String description;
  final String category;
  final String memberCount;
  final String? coverImageUrl;
  final VoidCallback? onTap;

  const ClubCard({
    super.key,
    required this.name,
    required this.description,
    required this.category,
    required this.memberCount,
    this.coverImageUrl,
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
            _ClubThumbnail(coverImageUrl: coverImageUrl),

            const SizedBox(width: AppSizes.paddingM),

            Expanded(child: _ClubInfo(
              name: name,
              description: description,
              category: category,
              memberCount: memberCount,
            )),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

/// Filled coral pill badge — inline category tag shown next to community name.
class _CategoryBadge extends StatelessWidget {
  final String label;
  const _CategoryBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSizes.interestChipRadius),
      ),
      child: Text(
        label,
        style: AppTextStyles.poppins(
          fontSize: AppSizes.fontXXS,
          fontWeight: FontWeight.w600,
          color: AppColors.cardWhite,
        ),
      ),
    );
  }
}

class _ClubThumbnail extends StatelessWidget {
  final String? coverImageUrl;
  const _ClubThumbnail({this.coverImageUrl});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusS),
      child: Container(
        width: AppSizes.cardThumbnailSize,
        height: AppSizes.cardThumbnailSize,
        color: AppColors.inputFill,
        child: NetworkImageView(
          url: coverImageUrl,
          width: AppSizes.cardThumbnailSize,
          height: AppSizes.cardThumbnailSize,
        ),
      ),
    );
  }
}

class _ClubInfo extends StatelessWidget {
  final String name;
  final String description;
  final String category;
  final String memberCount;

  const _ClubInfo({
    required this.name,
    required this.description,
    required this.category,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.poppins(
                  fontSize: AppSizes.fontML,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            if (category.isNotEmpty) ...[
              const SizedBox(width: 6),
              _CategoryBadge(label: category),
            ],
          ],
        ),
        const SizedBox(height: 2),

        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.poppins(
            fontSize: AppSizes.fontS,
            color: AppColors.textGray,
          ).copyWith(height: 1.4),
        ),
        const SizedBox(height: 4),

        Row(
          children: [
            Expanded(
              child: Text(
                memberCount,
                style: AppTextStyles.poppins(
                  fontSize: AppSizes.fontXS,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }
}
