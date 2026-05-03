import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_constants.dart';

/// User profile screen accessed from the "You" bottom-nav item.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const List<Map<String, String>> _comments = [
    {'from': 'Badminton Thonburi', 'ago': '1 hr ago'},
    {'from': 'Badminton KMUTT',    'ago': '1 hr ago'},
    {'from': 'Valorant Thailand',  'ago': '1 hr ago'},
    {'from': 'Cafe Gurilii',       'ago': '1 hr ago'},
    {'from': 'Coding TIPs',        'ago': '1 hr ago'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardWhite,
      body: Column(
        children: [
          // ── Coral app bar ────────────────────────────────────────────────
          _ProfileAppBar(),

          // ── Scrollable profile content ───────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: const Icon(
                    Icons.more_horiz,
                    color: AppColors.textGray,
                  ),
                ),

                _UserHeader(),
                const SizedBox(height: AppSizes.paddingM),

                _AboutSection(),
                const SizedBox(height: AppSizes.paddingM),

                _InterestsSection(),
                const SizedBox(height: AppSizes.paddingM),

                _CommentsSection(comments: _comments),
                const SizedBox(height: AppSizes.paddingXL),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _ProfileAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: AppSizes.paddingM,
        right: AppSizes.paddingM,
        bottom: AppSizes.paddingM,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back, color: AppColors.cardWhite),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Username',
                style: AppTextStyles.title(
                  fontSize: AppSizes.fontL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cardWhite,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.iconSize),
        ],
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSizes.avatarLarge,
          height: AppSizes.avatarLarge,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.avatarSalmon,
          ),
        ),
        const SizedBox(height: AppSizes.paddingM),

        Row(
          children: [
            Text(
              'Username',
              style: AppTextStyles.title(
                fontSize: AppSizes.fontXL,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: AppSizes.paddingS),
            const Icon(Icons.star, color: AppColors.primary, size: 16),
            Text(
              ' 4.9',
              style: AppTextStyles.body(
                fontSize: AppSizes.fontM,
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingM,
                vertical: AppSizes.paddingXS + 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              ),
              child: Text(
                AppStrings.profileRateUser,
                style: AppTextStyles.body(
                  fontSize: AppSizes.fontXS,
                  color: AppColors.cardWhite,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.profileAbout,
          style: AppTextStyles.title(
            fontSize: AppSizes.fontL,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppSizes.paddingXS),
        Text(
          AppStrings.profileBio,
          style: AppTextStyles.body(
            fontSize: AppSizes.fontM,
            color: AppColors.textGray,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _InterestsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.profileInterests,
          style: AppTextStyles.title(
            fontSize: AppSizes.fontL,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppSizes.paddingS),
        Row(
          children: [
            _InterestChip(label: ''),
            const SizedBox(width: AppSizes.paddingS),
            _InterestChip(label: ''),
            const SizedBox(width: AppSizes.paddingS),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingM,
                vertical: AppSizes.paddingS,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: const Icon(
                Icons.add,
                size: 16,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;

  const _InterestChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Center(
        child: Text(
          label,
          style: AppTextStyles.body(
            fontSize: AppSizes.fontXS,
            color: AppColors.textGray,
          ),
        ),
      ),
    );
  }
}

class _CommentsSection extends StatelessWidget {
  final List<Map<String, String>> comments;

  const _CommentsSection({required this.comments});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.profileComments,
              style: AppTextStyles.title(
                fontSize: AppSizes.fontL,
                color: AppColors.textDark,
              ),
            ),
            Text(
              AppStrings.profileViewAll,
              style: AppTextStyles.body(
                fontSize: AppSizes.fontS,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.paddingS),

        ...comments.map((c) => _CommentRow(
              from: c['from']!,
              ago: c['ago']!,
            )),
      ],
    );
  }
}

class _CommentRow extends StatelessWidget {
  final String from;
  final String ago;

  const _CommentRow({required this.from, required this.ago});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
      padding: const EdgeInsets.only(left: AppSizes.paddingS),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$ago · from $from',
            style: AppTextStyles.body(
              fontSize: AppSizes.fontXS,
              color: AppColors.textGray,
            ),
          ),
          Text(
            'Lorem ipsum dolor sit amet, consectetuer adipiscing elit',
            style: AppTextStyles.body(
              fontSize: AppSizes.fontS,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
