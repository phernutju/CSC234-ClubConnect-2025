import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../models/rating_model.dart';

// ── File-scoped helper ────────────────────────────────────────────────────────

/// Returns "just now", "N min ago", or "N hr ago" relative to [time].
String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return AppStrings.rateJustNow;
  if (diff.inMinutes < 60) return '${diff.inMinutes}${AppStrings.rateMinAgo}';
  return '${diff.inHours}${AppStrings.rateHrAgo}';
}

// ── Public entry point ────────────────────────────────────────────────────────

/// Full-screen overlay dialog showing all submitted reviews for [username].
/// Open via:
///   showDialog(context: context, barrierColor: Colors.black45,
///              builder: (_) => ViewAllReviewsModal(...))
class ViewAllReviewsModal extends StatelessWidget {
  /// The profile owner's display name — shown as the modal title.
  final String username;

  /// All ratings submitted for this user (filtered by caller).
  final List<RatingModel> ratings;

  const ViewAllReviewsModal({
    super.key,
    required this.username,
    required this.ratings,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardWhite,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.rateModalRadius),
      ),
      child: SizedBox(
        width: AppSizes.rateModalWidth,
        height: AppSizes.reviewModalHeight,
        child: Stack(
          children: [
            // ── Scrollable modal body ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username as title
                  Text(
                    username,
                    style: AppTextStyles.body(
                      fontSize: AppSizes.fontTitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingM),

                  // Rating summary card
                  _RatingSummaryCard(ratings: ratings),
                  const SizedBox(height: AppSizes.paddingM),

                  // Scrollable review list (Expanded fills remaining height)
                  Expanded(
                    child: ratings.isEmpty
                        ? Center(
                            child: Text(
                              AppStrings.reviewNoReviews,
                              style: AppTextStyles.body(
                                fontSize: AppSizes.fontM,
                                color: AppColors.textGray,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: ratings.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSizes.reviewItemSpacing),
                            itemBuilder: (_, i) =>
                                _ReviewItem(rating: ratings[i]),
                          ),
                  ),
                ],
              ),
            ),

            // ── X close button (top-right corner) ─────────────────────────
            Positioned(
              top: AppSizes.paddingS,
              right: AppSizes.paddingS,
              child: _CloseButton(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

/// Summary card: average score on the left, per-star bars on the right.
class _RatingSummaryCard extends StatelessWidget {
  final List<RatingModel> ratings;

  const _RatingSummaryCard({required this.ratings});

  @override
  Widget build(BuildContext context) {
    final total = ratings.length;

    // Use default rating when no reviews exist
    final avg = total == 0
        ? AppSizes.defaultRating
        : ratings.map((r) => r.stars).reduce((a, b) => a + b) / total;

    // Count how many reviews have each star level (index 0 = 5 stars, index 4 = 1 star)
    final counts = List.generate(5, (i) {
      final level = 5 - i;
      return ratings.where((r) => r.stars == level).length;
    });

    return Container(
      width: AppSizes.rateUserCardWidth,
      height: AppSizes.reviewSummaryHeight,
      decoration: BoxDecoration(
        color: AppColors.rateStarFill,
        borderRadius: BorderRadius.circular(AppSizes.rateStarBoxRadius),
        border: Border.all(color: AppColors.rateCardBorder),
      ),
      padding: const EdgeInsets.all(AppSizes.paddingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: "Rating" label + big average number + review count
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.reviewRatingLabel,
                style: AppTextStyles.body(
                  fontSize: AppSizes.fontS,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                avg.toStringAsFixed(1),
                style: AppTextStyles.body(
                  fontSize: AppSizes.fontDisplay,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '$total ${total == 1 ? AppStrings.rateReview : AppStrings.rateReviews}',
                style: AppTextStyles.poppins(
                  fontSize: AppSizes.fontXXS,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSizes.paddingM),

          // Right: one distribution row per star level (5→1)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                final level = 5 - i;
                final fraction =
                    total == 0 ? 0.0 : counts[i] / total;
                return _StarDistributionRow(
                  level: level,
                  fraction: fraction,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// One row in the distribution: [level] filled stars + empty stars + progress bar.
class _StarDistributionRow extends StatelessWidget {
  final int level; // 1–5
  final double fraction; // 0.0–1.0

  const _StarDistributionRow({
    required this.level,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Star icons: first [level] filled, rest empty
        ...List.generate(5, (i) => Icon(
              i < level ? Icons.star : Icons.star_border,
              size: AppSizes.reviewMiniStarSize,
              color: i < level
                  ? AppColors.starColor
                  : AppColors.reviewStarEmpty,
            )),
        const SizedBox(width: AppSizes.paddingXS),

        // Proportional progress bar
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: AppColors.rateCardBorder,
              color: AppColors.reviewBarFilled,
              minHeight: AppSizes.reviewBarHeight,
            ),
          ),
        ),
      ],
    );
  }
}

/// One review item: coral left border, star row + meta text, optional comment.
class _ReviewItem extends StatelessWidget {
  final RatingModel rating;

  const _ReviewItem({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Top line: mini stars + " · time · from community"
          Row(
            children: [
              ...List.generate(5, (i) => Icon(
                    i < rating.stars ? Icons.star : Icons.star_border,
                    size: AppSizes.reviewMiniStarSize,
                    color: i < rating.stars
                        ? AppColors.starColor
                        : AppColors.reviewStarEmpty,
                  )),
              Expanded(
                child: Text(
                  ' · ${_relativeTime(rating.submittedAt)} · from ${rating.communityName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontXXS,
                    fontWeight: FontWeight.w300,
                    color: AppColors.commentMeta,
                  ),
                ),
              ),
            ],
          ),

          // Comment body — omitted when the user left no text
          if (rating.comment.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              rating.comment,
              style: AppTextStyles.body(
                fontSize: AppSizes.fontXXS,
                color: AppColors.commentBody,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Coral circle X button — closes the dialog.
class _CloseButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: AppSizes.rateCloseButtonSize,
        height: AppSizes.rateCloseButtonSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
        ),
        child: const Icon(
          Icons.close,
          color: AppColors.cardWhite,
          size: 16,
        ),
      ),
    );
  }
}
