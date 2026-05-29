import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import 'network_image_view.dart';

/// Card that represents a single community/club in any of the home tabs.
class ClubCard extends StatelessWidget {
  final String name;
  final String description;
  final String category;
  final String memberCount;
  final String? coverImageUrl;
  final bool hasUnread;
  final VoidCallback? onTap;

  const ClubCard({
    super.key,
    required this.name,
    required this.description,
    required this.category,
    required this.memberCount,
    this.coverImageUrl,
    this.hasUnread = false,
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                _ClubThumbnail(coverImageUrl: coverImageUrl),
                if (hasUnread)
                  const Positioned(
                    top: -4,
                    right: -4,
                    child: _GlowDot(),
                  ),
              ],
            ),
            const SizedBox(width: AppSizes.paddingM),
            Expanded(
                child: _ClubInfo(
              name: name,
              description: description,
              category: category,
              memberCount: memberCount,
            )),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

/// Animated pulsing dot shown when the club has unread messages.
class _GlowDot extends StatefulWidget {
  const _GlowDot();

  @override
  State<_GlowDot> createState() => _GlowDotState();
}

class _GlowDotState extends State<_GlowDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: _pulse.value * 0.75),
              blurRadius: 8 * _pulse.value,
              spreadRadius: 2 * _pulse.value,
            ),
          ],
        ),
      ),
    );
  }
}

/// Filled coral pill badge — inline category tag shown next to community name.
class _CategoryBadge extends StatelessWidget {
  final String label;
  const _CategoryBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSizes.interestChipRadius),
      ),
      child: Text(
        label,
        style: AppTextStyles.poppins(
          fontSize: AppSizes.fontXXS,
          fontWeight: FontWeight.w600,
          color: AppColors.cardWhite,
        ),
      ),
    );
  }
}

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
  final String category;
  final String memberCount;

  const _ClubInfo({
    required this.name,
    required this.description,
    required this.category,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.poppins(
                  fontSize: AppSizes.fontML,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            if (category.isNotEmpty) ...[
              const SizedBox(width: 6),
              _CategoryBadge(label: category),
            ],
          ],
        ),
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
