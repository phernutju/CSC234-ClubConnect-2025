import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/rating_model.dart';
import '../../../providers/community_provider.dart';

// ── File-scoped helpers ────────────────────────────────────────────────────────

/// Returns "just now", "N min ago", or "N hr ago" relative to [time].
String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return AppStrings.rateJustNow;
  if (diff.inMinutes < 60) return '${diff.inMinutes}${AppStrings.rateMinAgo}';
  return '${diff.inHours}${AppStrings.rateHrAgo}';
}

/// Renders a row of 5 stars based on the [starCount] (W11 H11).
Widget _buildSmallStars(int starCount) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (index) {
      return Icon(
        index < starCount ? Icons.star : Icons.star_border,
        color:
            index < starCount ? AppColors.starColor : AppColors.reviewStarEmpty,
        size: AppSizes.reviewMiniStarSize,
      );
    }),
  );
}

// ── Main Modal Screen ──────────────────────────────────────────────────────────

class ViewAllReviewsModal extends StatelessWidget {
  final String username;
  final List<RatingModel> ratings;

  const ViewAllReviewsModal({
    super.key,
    required this.username,
    required this.ratings,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
      child: Container(
        width: AppSizes.rateModalWidth, // 296
        height: AppSizes.reviewModalHeight, // 575
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
                  // Title
                  Text(
                    username,
                    style: AppTextStyles.body(
                      fontSize: AppSizes.fontTitle, // 24
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingL),

                  // Rating Summary Card
                  _RatingSummaryCard(ratings: ratings),
                  const SizedBox(height: AppSizes.paddingL),

                  // Review List
                  Expanded(
                    child: ratings.isEmpty
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
                            itemCount: ratings.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(
                                    height: AppSizes.reviewItemSpacing),
                            itemBuilder: (context, index) {
                              return _ReviewItem(rating: ratings[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),

            // Close Button (Coral circle top-right)
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
  final List<RatingModel> ratings;

  const _RatingSummaryCard({required this.ratings});

  @override
  Widget build(BuildContext context) {
    final total = ratings.length;
    final avgRating = total == 0
        ? 0.0
        : ratings.map((r) => r.stars).reduce((a, b) => a + b) / total;

    return Container(
      width: AppSizes.rateUserCardWidth, // 266
      height: AppSizes.reviewSummaryHeight, // 125
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.rateStarFill, // #FFF6EE
        border:
            Border.all(color: AppColors.rateCardBorder, width: 1), // #E8DFD8
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Row(
        children: [
          // Left Side: Rating Avg & Count
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
                    fontWeight: FontWeight.w300, // Inter Light
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  avgRating.toStringAsFixed(1),
                  style: AppTextStyles.body(
                    fontSize: AppSizes.ratingStarSize, // 32
                    fontWeight: FontWeight.w800, // Inter ExtraBold
                    color: AppColors.primary, // #FF6B4A
                  ),
                ),
                Text(
                  '$total ${AppStrings.rateReviews}',
                  style: AppTextStyles.poppins(
                    fontSize: AppSizes.fontXXS, // 10
                    fontWeight: FontWeight.normal,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),

          // Right Side: 5 Progress Bars
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starLevel = 5 - index;
                final count = ratings.where((r) => r.stars == starLevel).length;
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
                            minHeight: AppSizes.reviewBarHeight, // 4
                            backgroundColor:
                                AppColors.rateCardBorder, // #E8DFD8
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.reviewBarFilled, // #8CD9A7
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

class _ReviewItem extends StatefulWidget {
  final RatingModel rating;

  const _ReviewItem({required this.rating});

  @override
  State<_ReviewItem> createState() => _ReviewItemState();
}

class _ReviewItemState extends State<_ReviewItem> {
  late Future<String> _communityNameFuture;

  @override
  void initState() {
    super.initState();
    _communityNameFuture = context
        .read<CommunityProvider>()
        .resolveCommunityName(widget.rating.communityName);
  }

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
          Row(
            children: [
              _buildSmallStars(widget.rating.stars),
              const SizedBox(width: 4),
              Expanded(
                child: FutureBuilder<String>(
                  future: _communityNameFuture,
                  builder: (context, snapshot) {
                    final name = snapshot.data ?? widget.rating.communityName;
                    return Text(
                      '· ${_relativeTime(widget.rating.submittedAt)} · from $name',
                      style: AppTextStyles.body(
                        fontSize: AppSizes.fontXXS,
                        fontWeight: FontWeight.w300,
                        color: AppColors.commentMeta,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
            ],
          ),
          if (widget.rating.comment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.rating.comment,
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
