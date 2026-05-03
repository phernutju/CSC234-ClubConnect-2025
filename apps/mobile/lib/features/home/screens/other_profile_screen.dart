import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/rating_model.dart';
import '../../../providers/rating_provider.dart';
import '../widgets/rate_user_modal.dart';
import '../widgets/view_all_reviews_modal.dart';

// ── File-scoped helpers ────────────────────────────────────────────────────────

/// Returns "just now", "N min ago", or "N hr ago" relative to [time].
String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return AppStrings.rateJustNow;
  if (diff.inMinutes < 60) return '${diff.inMinutes}${AppStrings.rateMinAgo}';
  return '${diff.inHours}${AppStrings.rateHrAgo}';
}

/// Comment body: the typed comment if non-empty, otherwise a filled/empty star string.
String _ratingBody(RatingModel r) {
  if (r.comment.isNotEmpty) return r.comment;
  return '${'★' * r.stars}${'☆' * (5 - r.stars)}';
}

// ── Screen ─────────────────────────────────────────────────────────────────────

/// Profile screen shown when viewing another user — shows "Rate this user" button.
/// Receives [username] and [communityName] from [ProfileArgs] via GoRouter extra.
class OtherProfileScreen extends StatelessWidget {
  final String username;
  final String communityName;

  const OtherProfileScreen({
    super.key,
    required this.username,
    required this.communityName,
  });

  void _showRateModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => RateUserModal(
        username: username,
        communityName: communityName,
      ),
    );
  }

  void _showViewAllModal(BuildContext context, List<RatingModel> ratings) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => ViewAllReviewsModal(
        username: username,
        ratings: ratings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider so the screen rebuilds when a new rating is submitted
    final ratings = context
        .watch<RatingProvider>()
        .ratings
        .where((r) => r.ratedUsername == username)
        .toList();

    final avgRating = ratings.isEmpty
        ? AppSizes.defaultRating
        : ratings.map((r) => r.stars).reduce((a, b) => a + b) /
            ratings.length;

    return Scaffold(
      backgroundColor: AppColors.cardWhite,
      body: Column(
        children: [
          // ── Coral app bar with back arrow ────────────────────────────────
          _ProfileAppBar(title: username),

          // ── Scrollable profile content ───────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Gradient header band with avatar + three-dot menu
                const _ProfileHeader(),

                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username + optional star rating + "Rate this user" button
                      _UserInfoRow(
                        username: username,
                        avgRating: avgRating,
                        onRateTap: () => _showRateModal(context),
                      ),
                      const SizedBox(height: AppSizes.paddingL),

                      const _SectionLabel(AppStrings.profileAbout),
                      const SizedBox(height: AppSizes.paddingXS),
                      Text(
                        AppStrings.profileBio,
                        style: AppTextStyles.poppins(
                          fontSize: AppSizes.fontSM,
                          fontWeight: FontWeight.w300,
                          color: AppColors.commentBody,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingL),

                      const _SectionLabel(AppStrings.profileInterests),
                      const SizedBox(height: AppSizes.paddingS),
                      const _InterestsRow(),
                      const SizedBox(height: AppSizes.paddingL),

                      // Comments from RatingProvider — empty until someone rates
                      _CommentsSection(
                        ratings: ratings,
                        onViewAll: () =>
                            _showViewAllModal(context, ratings),
                      ),
                      const SizedBox(height: AppSizes.paddingXL),
                    ],
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

// ── Sub-widgets ────────────────────────────────────────────────────────────────

/// Coral app bar with back arrow + centered title text.
class _ProfileAppBar extends StatelessWidget {
  final String title;

  const _ProfileAppBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: AppSizes.appBarHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: AppSizes.paddingM),
            GestureDetector(
              onTap: () => context.pop(),
              child: const Icon(Icons.arrow_back, color: AppColors.cardWhite),
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontTitle,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cardWhite,
                  ),
                ),
              ),
            ),
            // Balances the back arrow so the title stays centered
            const SizedBox(width: AppSizes.iconSize + AppSizes.paddingM),
          ],
        ),
      ),
    );
  }
}

/// Salmon-to-peach gradient band with avatar circle + three-dot menu.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.profileHeaderHeight + AppSizes.avatarLarge / 2,
      child: Stack(
        children: [
          // Gradient band
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: AppSizes.profileHeaderHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.profileHeaderStart,
                    AppColors.profileHeaderEnd,
                    AppColors.profileHeaderEnd,
                  ],
                  stops: [0.0, 0.44, 0.9],
                ),
              ),
            ),
          ),

          // Three-dot menu (top-right of gradient area)
          Positioned(
            top: AppSizes.paddingM,
            right: AppSizes.paddingM,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardWhite,
              ),
              child: const Icon(
                Icons.more_horiz,
                color: AppColors.textGray,
                size: AppSizes.iconSize,
              ),
            ),
          ),

          // Large avatar overlapping the gradient-white boundary
          Positioned(
            left: AppSizes.paddingL,
            bottom: 0,
            child: Container(
              width: AppSizes.avatarLarge,
              height: AppSizes.avatarLarge,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.avatarSalmon,
                border: Border.all(color: AppColors.cardWhite, width: 3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Username + star icon + rating + filled coral "Rate this user" pill.
/// Shows [AppSizes.defaultRating] when no reviews exist; real average thereafter.
class _UserInfoRow extends StatelessWidget {
  final String username;
  final double avgRating;
  final VoidCallback onRateTap;

  const _UserInfoRow({
    required this.username,
    required this.avgRating,
    required this.onRateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          username,
          style: AppTextStyles.body(
            fontSize: AppSizes.fontTitle,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(width: AppSizes.paddingXS),
        const Icon(
          Icons.star,
          color: AppColors.starColor,
          size: AppSizes.starIconSize,
        ),
        const SizedBox(width: 2),
        Text(
          avgRating.toStringAsFixed(1),
          style: AppTextStyles.body(
            fontSize: AppSizes.fontTitle,
            fontWeight: FontWeight.normal,
            color: AppColors.textDark,
          ),
        ),

        const Spacer(),

        // Filled coral pill: star icon + "Rate this user"
        GestureDetector(
          onTap: onRateTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingM,
              vertical: AppSizes.paddingXS,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star,
                  color: AppColors.cardWhite,
                  size: AppSizes.starIconSize,
                ),
                const SizedBox(width: 4),
                Text(
                  AppStrings.profileRateUser,
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontXS,
                    color: AppColors.cardWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Section header label — Inter Light 16.
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.body(
        fontSize: AppSizes.fontML,
        fontWeight: FontWeight.w300,
        color: AppColors.textDark,
      ),
    );
  }
}

/// Two empty interest chips + an "add" chip.
class _InterestsRow extends StatelessWidget {
  const _InterestsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _InterestChip(),
        const SizedBox(width: AppSizes.paddingS),
        const _InterestChip(),
        const SizedBox(width: AppSizes.paddingS),
        Container(
          width: AppSizes.interestChipHeight,
          height: AppSizes.interestChipHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.interestChipRadius),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: const Icon(Icons.add, size: 16, color: AppColors.textDark),
        ),
      ],
    );
  }
}

/// Empty rounded chip (W108 × H35, radius 64).
class _InterestChip extends StatelessWidget {
  const _InterestChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.interestChipWidth,
      height: AppSizes.interestChipHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.interestChipRadius),
        border: Border.all(color: AppColors.inputBorder),
      ),
    );
  }
}

/// Comments section — populated from [RatingProvider], empty until first rating.
/// Shows up to 5 entries; tapping "view all (N)" opens [_ViewAllSheet].
class _CommentsSection extends StatelessWidget {
  final List<RatingModel> ratings;
  final VoidCallback onViewAll;

  const _CommentsSection({
    required this.ratings,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final preview = ratings.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: "Comments" left, "view all (N)" right (hidden when empty)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.profileComments,
              style: AppTextStyles.body(
                fontSize: AppSizes.fontML,
                fontWeight: FontWeight.w300,
                color: AppColors.textDark,
              ),
            ),
            if (ratings.isNotEmpty)
              GestureDetector(
                onTap: onViewAll,
                child: Text(
                  '${AppStrings.profileViewAll} (${ratings.length})',
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontXXS,
                    fontWeight: FontWeight.w300,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.paddingS),

        // Empty state or list of comment rows
        if (ratings.isEmpty)
          Text(
            AppStrings.rateNoComments,
            style: AppTextStyles.body(
              fontSize: AppSizes.fontS,
              color: AppColors.textGray,
            ),
          )
        else
          ...preview.map((r) => _CommentRow(rating: r)),
      ],
    );
  }
}

/// One comment row built from a [RatingModel].
/// Meta line: "N min ago · from [Community]"
/// Body line: comment text, or filled/empty star string if no comment.
class _CommentRow extends StatelessWidget {
  final RatingModel rating;

  const _CommentRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
      padding: const EdgeInsets.only(left: AppSizes.paddingS),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppColors.primary,
            width: AppSizes.commentBorderWidth,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_relativeTime(rating.submittedAt)} · from ${rating.communityName}',
            style: AppTextStyles.body(
              fontSize: AppSizes.fontXXS,
              fontWeight: FontWeight.w300,
              color: AppColors.commentMeta,
            ),
          ),
          Text(
            _ratingBody(rating),
            style: AppTextStyles.body(
              fontSize: AppSizes.fontXXS,
              color: AppColors.commentBody,
            ),
          ),
        ],
      ),
    );
  }
}

