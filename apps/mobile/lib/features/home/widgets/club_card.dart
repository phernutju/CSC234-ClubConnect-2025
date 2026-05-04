import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

/// Card that represents a single community/club in any of the home tabs.
class ClubCard extends StatelessWidget {
  final String name;
  final String description;
  final String memberCount;
  final Uint8List? coverImage;
  final VoidCallback? onTap;

  const ClubCard({
    super.key,
    required this.name,
    required this.description,
    required this.memberCount,
    this.coverImage,
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
          color: AppColors.chatBackground,
          borderRadius: BorderRadius.circular(AppSizes.clubCardRadius),
          border: Border.all(
            color: AppColors.rateCardBorder,
            width: AppSizes.clubCardBorderWidth,
          ),
        ),
        child: Row(
          children: [
            _ClubThumbnail(imageBytes: coverImage),

            const SizedBox(width: AppSizes.paddingM),

            Expanded(child: _ClubInfo(
              name: name,
              description: description,
              memberCount: memberCount,
            )),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _ClubThumbnail extends StatelessWidget {
  final Uint8List? imageBytes;
  const _ClubThumbnail({this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusS),
      child: Container(
        width: AppSizes.clubThumbnailSize,
        height: AppSizes.clubThumbnailSize,
        color: AppColors.inputFill,
        child: imageBytes != null
            ? Image.memory(imageBytes!, fit: BoxFit.cover)
            : null,
      ),
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
          style: AppTextStyles.poppins(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 2),

        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.poppins(
            fontSize: AppSizes.fontXXS,
            color: AppColors.commentBody,
          ).copyWith(height: 1.4),
        ),
        const SizedBox(height: 4),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              memberCount,
              style: AppTextStyles.poppins(
                fontSize: AppSizes.fontXXS,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
            Icon(
              Icons.arrow_forward,
              size: AppSizes.clubArrowSize,
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }
}
