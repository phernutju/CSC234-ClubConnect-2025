import 'package:csc234_clubconnect/providers/community_provider.dart';
import 'package:csc234_clubconnect/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/review_model.dart';
import '../widgets/rate_user_modal.dart';
import '../widgets/view_all_reviews_modal.dart';
import '../widgets/report_user_modal.dart';
import '../widgets/network_image_view.dart';

// ── File-scoped helpers ────────────────────────────────────────────────────────

/// Returns "just now", "N min ago", or "N hr ago" relative to [time].
String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return AppStrings.rateJustNow;
  if (diff.inMinutes < 60) return '${diff.inMinutes}${AppStrings.rateMinAgo}';
  return '${diff.inHours}${AppStrings.rateHrAgo}';
}

/// Comment body: the typed comment if non-empty, otherwise a filled/empty star string.
String _reviewBody(ReviewModel r) {
  if (r.comment.isNotEmpty) return r.comment;
  final stars = r.score.clamp(0, 5).toInt();
  return '${'★' * stars}${'☆' * (5 - stars)}';
}

// ── Screen ─────────────────────────────────────────────────────────────────────

/// Profile screen shown when viewing another user — shows "Rate this user" button.
/// Receives [username] and [communityName] from [ProfileArgs] via GoRouter extra.
class OtherProfileScreen extends StatefulWidget {
  final String username;
  final String communityName;
  final String userId;
  final String communityId;

  const OtherProfileScreen({
    super.key,
    required this.username,
    required this.communityName,
    required this.userId,
    required this.communityId,
  });

  @override
  State<OtherProfileScreen> createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends State<OtherProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    context.read<ProfileProvider>().loadViewedProfile(widget.userId);
  }

  void _showRateModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => RateUserModal(
        username: widget.username,
        communityName: widget.communityName,
        userId: widget.userId,
        communityId: widget.communityId,
      ),
    );
  }

  void _showViewAllModal(BuildContext context, List<ReviewModel> ratings) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => ViewAllReviewsModal(
        username: widget.username,
        reviews: ratings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProfileProvider>();
    final profile = pp.viewedProfile;
    final ratings = pp.viewedReviewsResult?.reviews ?? [];
    final avgRating =
        pp.viewedReviewsResult?.averageScore ?? AppSizes.defaultRating;

    if (pp.isLoading && profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cardWhite,
      body: Column(
        children: [
          _ProfileAppBar(title: widget.username),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _ProfileHeader(
                  username: widget.username,
                  communityName: widget.communityName,
                  userId: widget.userId,
                  photoURL: profile?.photoURL,
                  coverBannerUrl: profile?.coverBannerUrl,
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _UserInfoRow(
                        username: widget.username,
                        avgRating: avgRating,
                        onRateTap: () => _showRateModal(context),
                      ),
                      const SizedBox(height: AppSizes.paddingL),
                      const _SectionLabel(AppStrings.profileAbout),
                      const SizedBox(height: AppSizes.paddingXS),
                      Text(
                        profile?.bio ?? '',
                        style: AppTextStyles.poppins(
                          fontSize: AppSizes.fontSM,
                          fontWeight: FontWeight.w300,
                          color: AppColors.commentBody,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingL),
                      const _SectionLabel(AppStrings.profileInterests),
                      const SizedBox(height: AppSizes.paddingS),
                      _InterestsView(interests: profile?.interests ?? []),
                      const SizedBox(height: AppSizes.paddingL),
                      _CommentsSection(
                        ratings: ratings,
                        onViewAll: () => _showViewAllModal(context, ratings),
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
  final String username;
  final String communityName;
  final String userId;
  final String? photoURL;
  final String? coverBannerUrl;

  const _ProfileHeader({
    required this.username,
    required this.communityName,
    required this.userId,
    this.photoURL,
    this.coverBannerUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.profileHeaderHeight + AppSizes.avatarLarge / 2,
      child: Stack(
        children: [
          // Banner photo or gradient fallback
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: AppSizes.profileHeaderHeight,
              child: (coverBannerUrl != null && coverBannerUrl!.isNotEmpty)
                  ? Image.network(
                      coverBannerUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : Container(
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
          ),

          // Three-dot menu (top-right of gradient area)
          Positioned(
            top: AppSizes.paddingM,
            right: AppSizes.paddingM,
            child: PopupMenuButton<String>(
              offset: const Offset(0, 40),
              color: AppColors.cardWhite,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              constraints: const BoxConstraints(
                minWidth: 79,
                maxWidth: 79,
              ),
              onSelected: (value) {
                if (value == 'report') {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black45,
                    builder: (_) => ReportUserModal(
                      username: username,
                      communityName: communityName,
                      userId: userId,
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'report',
                  height: 29,
                  padding: EdgeInsets.zero,
                  child: SizedBox(
                    width: 79,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          color: AppColors.alertRed,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Report',
                          style: AppTextStyles.body(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.alertRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
              clipBehavior: (photoURL != null && photoURL!.isNotEmpty)
                  ? Clip.antiAlias
                  : Clip.none,
              child: NetworkImageView(url: photoURL),
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

/// Displays real interests from the loaded profile as labelled chips.
/// Falls back to two placeholder chips when interests are empty.
class _InterestsView extends StatelessWidget {
  final List<String> interests;

  const _InterestsView({required this.interests});

  @override
  Widget build(BuildContext context) {
    if (interests.isEmpty) {
      return Row(
        children: [
          _PlaceholderChip(),
          const SizedBox(width: AppSizes.paddingS),
          _PlaceholderChip(),
        ],
      );
    }
    return Wrap(
      spacing: AppSizes.paddingS,
      runSpacing: AppSizes.paddingS,
      children: interests.map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingM,
            vertical: AppSizes.paddingXS,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.interestChipRadius),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Text(
            interest,
            style: AppTextStyles.poppins(
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PlaceholderChip extends StatelessWidget {
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
  final List<ReviewModel> ratings;
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

class _CommentRow extends StatefulWidget {
  final ReviewModel rating;

  const _CommentRow({required this.rating});

  @override
  State<_CommentRow> createState() => _CommentRowState();
}

class _CommentRowState extends State<_CommentRow> {
  late Future<String> _communityNameFuture;

  @override
  void initState() {
    super.initState();
    _communityNameFuture = context
        .read<CommunityProvider>()
        .resolveCommunityName(widget.rating.communityId);
  }

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
          FutureBuilder<String>(
            future: _communityNameFuture,
            builder: (context, snapshot) {
              final name = snapshot.data ?? widget.rating.communityId;
              return Text(
                '${_relativeTime(widget.rating.createdAt.toDate())} · from $name',
                style: AppTextStyles.body(
                  fontSize: AppSizes.fontXXS,
                  fontWeight: FontWeight.w300,
                  color: AppColors.commentMeta,
                ),
              );
            },
          ),
          Text(
            _reviewBody(widget.rating),
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
