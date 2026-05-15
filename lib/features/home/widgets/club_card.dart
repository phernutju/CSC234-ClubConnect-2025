import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import 'network_image_view.dart';

/// Card that represents a single community/club in any of the home tabs.
class ClubCard extends StatelessWidget {
  final String name;
  final String description;
  final String memberCount;
  final String? coverImageUrl;
  final VoidCallback? onTap;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ClubCard({
    super.key,
    required this.name,
    required this.description,
    required this.memberCount,
    this.coverImageUrl,
    this.onTap,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: AppColors.chatBackground,
          borderRadius: BorderRadius.circular(AppSizes.clubCardRadius),
          border: Border.all(
            color: AppColors.rateCardBorder,
            width: AppSizes.clubCardBorderWidth,
          ),
        ),
        child: Row(
          children: [
            _ClubThumbnail(coverImageUrl: coverImageUrl),

            const SizedBox(width: AppSizes.paddingM),

            Expanded(child: _ClubInfo(
              name: name,
              description: description,
              memberCount: memberCount,
              isOwner: isOwner,
              onEdit: onEdit,
              onDelete: onDelete,
            )),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _ClubThumbnail extends StatelessWidget {
  final String? coverImageUrl;
  const _ClubThumbnail({this.coverImageUrl});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusS),
      child: Container(
        width: AppSizes.clubThumbnailSize,
        height: AppSizes.clubThumbnailSize,
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
  final String memberCount;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ClubInfo({
    required this.name,
    required this.description,
    required this.memberCount,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
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
          style: AppTextStyles.poppins(
            fontSize: AppSizes.fontML,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        if (isOwner) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              GestureDetector(
                onTap: onEdit,
                child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
              ),
            ],
          ),
        ],
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
