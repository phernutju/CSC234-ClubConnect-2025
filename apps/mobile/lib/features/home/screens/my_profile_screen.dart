import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/rating_model.dart';
import '../../../providers/rating_provider.dart';

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

/// Profile screen for the current user — reached via the "You" bottom-nav tab.
/// Shows "Edit Profile" outlined button; comments come from [RatingProvider].
/// TODO: filter by current user ID once auth is connected.
class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  // Hardcoded current username until auth is connected
  static const String _myUsername = 'Username';

  void _showViewAllSheet(BuildContext context, List<RatingModel> ratings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusL)),
      ),
      builder: (_) =>
          _ViewAllSheet(username: _myUsername, ratings: ratings),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider — filter ratings submitted for the current user
    final ratings = context
        .watch<RatingProvider>()
        .ratings
        .where((r) => r.ratedUsername == _myUsername)
        .toList();

    final avgRating = ratings.isEmpty
        ? AppSizes.defaultRating
        : ratings.map((r) => r.stars).reduce((a, b) => a + b) /
            ratings.length;

    return Scaffold(
      backgroundColor: AppColors.cardWhite,
      body: Column(
        children: [
          // ── Coral app bar ────────────────────────────────────────────────
          _ProfileAppBar(),

          // ── Scrollable profile content ───────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Gradient header band with avatar + three-dot menu
                _ProfileHeader(),

                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username + optional star rating + "Edit Profile" button
                      _UserInfoRow(avgRating: avgRating),
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

                      // Comments from RatingProvider — empty until rated
                      _CommentsSection(
                        ratings: ratings,
                        onViewAll: () =>
                            _showViewAllSheet(context, ratings),
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

/// Coral app bar — back arrow shown only when there is navigation history.
class _ProfileAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final canGoBack = context.canPop();
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: AppSizes.appBarHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: AppSizes.paddingM),
            if (canGoBack)
              GestureDetector(
                onTap: () => context.pop(),
                child:
                    const Icon(Icons.arrow_back, color: AppColors.cardWhite),
              )
            else
              const SizedBox(width: AppSizes.iconSize),
            Expanded(
              child: Center(
                child: Text(
                  'Username',
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontTitle,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cardWhite,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.iconSize + AppSizes.paddingM),
          ],
        ),
      ),
    );
  }
}

/// Salmon-to-peach gradient band with avatar circle + three-dot menu.
class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.profileHeaderHeight + AppSizes.avatarLarge / 2,
      child: Stack(
        children: [
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

/// Username + star icon + rating + outlined coral "Edit Profile" pill.
/// Shows [AppSizes.defaultRating] when no reviews exist; real average thereafter.
class _UserInfoRow extends StatelessWidget {
  final double avgRating;

  const _UserInfoRow({required this.avgRating});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Username',
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

        // Outlined coral pill: pencil icon + "Edit Profile"
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingM,
            vertical: AppSizes.paddingXS,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            border: Border.all(color: AppColors.primary),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit, color: AppColors.primary, size: 12),
              const SizedBox(width: 4),
              Text(
                AppStrings.profileEditButton,
                style: AppTextStyles.body(
                  fontSize: AppSizes.fontXS,
                  color: AppColors.primary,
                ),
              ),
            ],
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

/// Comments section — populated from [RatingProvider], empty until rated.
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

/// Draggable bottom sheet listing all ratings for the user.
class _ViewAllSheet extends StatelessWidget {
  final String username;
  final List<RatingModel> ratings;

  const _ViewAllSheet({
    required this.username,
    required this.ratings,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) {
        return Column(
          children: [
            // Drag handle bar
            Container(
              margin:
                  const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // "N reviews" header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingL,
                vertical: AppSizes.paddingXS,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${ratings.length} '
                  '${ratings.length == 1 ? AppStrings.rateReview : AppStrings.rateReviews}',
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontML,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),

            // All comment rows
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingL,
                ),
                children:
                    ratings.map((r) => _CommentRow(rating: r)).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
