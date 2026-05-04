import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_constants.dart';
import '../../../models/review_model.dart';

// ── File-scoped helpers ────────────────────────────────────────────────────────

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return AppStrings.rateJustNow;
  if (diff.inMinutes < 60) return '${diff.inMinutes}${AppStrings.rateMinAgo}';
  return '${diff.inHours}${AppStrings.rateHrAgo}';
}

Widget _buildSmallStars(int starCount) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (index) {
      return Icon(
        index < starCount ? Icons.star : Icons.star_border,
        color: index < starCount ? AppColors.starColor : AppColors.reviewStarEmpty,
        size: AppSizes.reviewMiniStarSize,
      );
    }),
  );
}

// ── Main Modal Screen ──────────────────────────────────────────────────────────

class ViewAllReviewsModal extends StatelessWidget {
  final String username;
  final List<ReviewModel> reviews;

  const ViewAllReviewsModal({
    super.key,
    required this.username,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
      child: Container(
        width: AppSizes.rateModalWidth,
        height: AppSizes.reviewModalHeight,
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSizes.rateModalRadius),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: AppTextStyles.body(
                      fontSize: AppSizes.fontTitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingL),

                  _RatingSummaryCard(reviews: reviews),
                  const SizedBox(height: AppSizes.paddingL),

                  Expanded(
                    child: reviews.isEmpty
                        ? Center(
                            child: Text(
                              AppStrings.reviewNoReviews,
                              style: AppTextStyles.body(
                                fontSize: AppSizes.fontS,
                                color: AppColors.textGray,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: reviews.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppSizes.reviewItemSpacing),
                            itemBuilder: (context, index) {
                              return _ReviewItem(review: reviews[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),

            Positioned(
              top: AppSizes.paddingM,
              right: AppSizes.paddingM,
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: AppSizes.fontTitle,
                  height: AppSizes.fontTitle,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.cardWhite,
                    size: AppSizes.fontSM,
                  ),
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

class _RatingSummaryCard extends StatelessWidget {
  final List<ReviewModel> reviews;

  const _RatingSummaryCard({required this.reviews});

  @override
  Widget build(BuildContext context) {
    final total = reviews.length;
    final avgRating = total == 0
        ? 0.0
        : reviews.map((r) => r.score).reduce((a, b) => a + b) /
            total;

    return Container(
      width: AppSizes.rateUserCardWidth,
      height: AppSizes.reviewSummaryHeight,
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.rateStarFill,
        border: Border.all(color: AppColors.rateCardBorder, width: 1),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.reviewRatingLabel,
                  style: AppTextStyles.body(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  avgRating.toStringAsFixed(1),
                  style: AppTextStyles.body(
                    fontSize: AppSizes.ratingStarSize,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '$total ${AppStrings.rateReviews}',
                  style: AppTextStyles.poppins(
                    fontSize: AppSizes.fontXXS,
                    fontWeight: FontWeight.normal,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starLevel = 5 - index;
                final count = reviews
                    .where((r) => r.score == starLevel)
                    .length;
                final fraction = total == 0 ? 0.0 : count / total;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Row(
                    children: [
                      _buildSmallStars(starLevel),
                      const SizedBox(width: AppSizes.paddingS),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: AppSizes.reviewBarHeight,
                            backgroundColor: AppColors.rateCardBorder,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.reviewBarFilled,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final ReviewModel review;

  const _ReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    final stars = review.score;

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
          Row(
            children: [
              _buildSmallStars(stars),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '· ${_relativeTime(review.createdAt.toDate())} · from ${review.communityId}',
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontXXS,
                    fontWeight: FontWeight.w300,
                    color: AppColors.commentMeta,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              review.comment,
              style: AppTextStyles.body(
                fontSize: AppSizes.fontXXS,
                fontWeight: FontWeight.normal,
                color: AppColors.commentBody,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
