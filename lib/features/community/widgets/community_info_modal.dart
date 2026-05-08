import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_constants.dart';
import '../../../models/community_model.dart';
import '../../../models/profile_args.dart';

/// First step of the join flow.
/// Shows community cover, name, member count, host card, and description.
/// "Next" closes this modal and fires [onNext] so the caller can open the
/// rules modal from its own context (preventing two modals from stacking).
class CommunityInfoModal extends StatelessWidget {
  final CommunityModel community;

  /// When non-null, a "Next" button is shown that pops this modal and fires the callback.
  /// Pass null to show the modal as view-only (no Next button — close via X only).
  final VoidCallback? onNext;

  const CommunityInfoModal({
    super.key,
    required this.community,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.rateModalRadius)),
      ),
      clipBehavior: Clip.hardEdge,
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      child: SizedBox(
        width: AppSizes.communityModalWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover image with X button overlay ────────────────────────
            Stack(
              children: [
                _CoverArea(imageUrl: community.coverImageURL.isEmpty ? null : community.coverImageURL),
                Positioned(
                  top: AppSizes.paddingS,
                  right: AppSizes.paddingS,
                  child: _CloseButton(
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),

            // ── White scrollable content area ─────────────────────────────
            Container(
              color: AppColors.cardWhite,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSizes.communityInfoContentPad,
                  AppSizes.communityInfoContentPad,
                  AppSizes.communityInfoContentPad,
                  AppSizes.communityInfoBottomPad,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Community name
                    Text(
                      community.communityName,
                      style: AppTextStyles.poppins(
                        fontSize: AppSizes.fontTitle,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // "[N] members" — N is bold, "members" is regular
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${community.memberCount}',
                            style: AppTextStyles.poppins(
                              fontSize: AppSizes.fontXII,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          TextSpan(
                            text: ' ${AppStrings.communityMembersLabel}',
                            style: AppTextStyles.poppins(
                              fontSize: AppSizes.fontXII,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.communityInfoSectionGap),

                    // Host info card
                    _HostCard(
                      community: community,
                      onViewProfile: () {
                        Navigator.of(context).pop();
                        context.push(
                          '/other-profile',
                          extra: ProfileArgs(
                            userId: community.createdById,
                            username: '',
                            communityName: community.communityName,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSizes.communityInfoSectionGap),

                    // Description
                    Text(
                      community.description,
                      style: AppTextStyles.poppins(
                        fontSize: AppSizes.fontXII,
                        color: AppColors.commentBody,
                      ),
                    ),
                    const SizedBox(height: AppSizes.communityInfoSectionGap),

                    // Next button — only shown in join flow (onNext != null)
                    if (onNext != null)
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            onNext!();
                          },
                          child: Container(
                            width: AppSizes.modalActionButtonWidth,
                            height: AppSizes.modalActionButtonHeight,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              AppStrings.communityInfoNext,
                              style: AppTextStyles.poppins(
                                fontSize: AppSizes.fontTitle,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cardWhite,
                              ),
                            ),
                          ),
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

// ── Sub-widgets ────────────────────────────────────────────────────────────────

/// Grey placeholder or community cover photo (H167).
class _CoverArea extends StatelessWidget {
  final String? imageUrl;
  const _CoverArea({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.communityInfoCoverHeight,
      width: double.infinity,
      child: imageUrl != null
          ? Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.inputFill))
          : Container(color: AppColors.inputFill),
    );
  }
}

/// Host info card: avatar circle, name, star rating, rating score, view profile link.
class _HostCard extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback onViewProfile;

  const _HostCard({required this.community, required this.onViewProfile});

  @override
  Widget build(BuildContext context) {
    final filledStars = 0;

    return Container(
      width: double.infinity,
      height: AppSizes.hostCardHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.createBackground,
        borderRadius: BorderRadius.circular(AppSizes.rateModalRadius),
        border: Border.all(color: AppColors.rateCardBorder),
      ),
      child: Row(
        children: [
          // Avatar placeholder circle
          Container(
            width: AppSizes.hostAvatarSize,
            height: AppSizes.hostAvatarSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.profileHeaderStart,
            ),
          ),
          const SizedBox(width: AppSizes.paddingS),

          // Host name, stars + rating, view profile
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '',
                  style: AppTextStyles.poppins(
                    fontSize: AppSizes.fontXII,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        Icons.star,
                        size: AppSizes.hostStarSize,
                        color: i < filledStars
                            ? AppColors.primary
                            : AppColors.reviewStarEmpty,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '0.0',
                      style: AppTextStyles.poppins(
                        fontSize: AppSizes.fontXXS,
                        color: AppColors.hostRatingColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: onViewProfile,
                  child: Text(
                    AppStrings.communityInfoViewProfile,
                    style: AppTextStyles.poppins(
                      fontSize: AppSizes.fontXXS,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// White circle with × — dismisses the modal.
class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppSizes.rateCloseButtonSize,
        height: AppSizes.rateCloseButtonSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.cardWhite,
        ),
        child: const Icon(Icons.close, size: 16, color: AppColors.textDark),
      ),
    );
  }
}
