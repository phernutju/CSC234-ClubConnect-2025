import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_constants.dart';
import '../../../models/event_detail_args.dart';
import '../../../models/event_model.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

/// Shared event card used in the community events page and the global Events tab/screen.
class EventCard extends StatelessWidget {
  final EventModel event;
  final String communityId;

  /// Member display names — populated from backend later; defaults to empty.
  final List<String> memberNames;

  /// Current RSVP / joined count — defaults to 0.
  final int currentMembers;

  const EventCard({
    super.key,
    required this.event,
    this.communityId = '',
    this.memberNames = const [],
    this.currentMembers = 0,
  });

  static const _avatarColors = [
    Color(0xFFFFB347),
    Color(0xFF77DD77),
    Color(0xFF89CFF0),
    Color(0xFFCDA4DE),
    Color(0xFFFF6961),
    Color(0xFFFFD700),
  ];

  @override
  Widget build(BuildContext context) {
    final dateLine = event.formattedDateRange;
    final hostName = context.read<AppAuthProvider>().user?.displayName ?? '';
    return GestureDetector(
      onTap: () => context.push('/event-detail', extra: EventDetailArgs(event: event, communityId: communityId)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: const Color(0xFFE8DFD8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingM,
                AppSizes.paddingS,
                AppSizes.paddingM,
                AppSizes.paddingS,
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateLine,
                    style: GoogleFonts.poppins(
                      fontSize: AppSizes.fontXS,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Cover image ──────────────────────────────────────────────────
            _CoverImage(url: event.imageUrl ?? ''),

            // ── Body ─────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingM,
                AppSizes.paddingS,
                AppSizes.paddingM,
                AppSizes.paddingS,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: AppSizes.fontML,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingS),
                      Text(
                        '$currentMembers/${event.maxAttendees} members',
                        style: GoogleFonts.poppins(
                          fontSize: AppSizes.fontXS,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFFF6B4A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (hostName.isNotEmpty)
                    Text(
                      'by ${hostName}',
                      style: GoogleFonts.poppins(
                        fontSize: AppSizes.fontXS,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF837A7A),
                      ),
                    ),
                  const SizedBox(height: AppSizes.paddingS),
                  Row(
                    children: [
                      if (memberNames.isNotEmpty)
                        _MemberAvatars(
                            names: memberNames, colors: _avatarColors),
                      if (memberNames.isNotEmpty)
                        const SizedBox(width: AppSizes.paddingS),
                      const Spacer(),
                      Text(
                        'details →',
                        style: GoogleFonts.poppins(
                          fontSize: AppSizes.fontXS,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cover image ───────────────────────────────────────────────────────────────

class _CoverImage extends StatelessWidget {
  final String url;
  const _CoverImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        height: 130,
        width: double.infinity,
        color: AppColors.inputFill,
        child: const Icon(Icons.image_outlined,
            color: AppColors.inputBorder, size: 40),
      );
    }
    return SizedBox(
      height: 130,
      width: double.infinity,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 130,
          color: AppColors.inputFill,
          child: const Icon(Icons.broken_image_outlined,
              color: AppColors.inputBorder, size: 40),
        ),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                height: 130,
                color: AppColors.inputFill,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Member avatar row ─────────────────────────────────────────────────────────

class _MemberAvatars extends StatelessWidget {
  final List<String> names;
  final List<Color> colors;

  static const int _maxVisible = 4;
  static const double _size = 26;
  static const double _overlap = 8;

  const _MemberAvatars({required this.names, required this.colors});

  @override
  Widget build(BuildContext context) {
    final visible = names.take(_maxVisible).toList();
    final overflow = names.length - _maxVisible;

    return SizedBox(
      height: _size,
      width: visible.length * (_size - _overlap) +
          _size +
          (overflow > 0 ? (_size - _overlap) : 0),
      child: Stack(
        children: [
          for (int i = 0; i < visible.length; i++)
            Positioned(
              left: i * (_size - _overlap),
              child: _AvatarCircle(
                label:
                    visible[i].isNotEmpty ? visible[i][0].toUpperCase() : '?',
                color: colors[i % colors.length],
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: visible.length * (_size - _overlap),
              child: _AvatarCircle(
                label: '+$overflow',
                color: AppColors.inputFill,
                textColor: AppColors.textGray,
                fontSize: AppSizes.fontXXS,
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final double fontSize;

  const _AvatarCircle({
    required this.label,
    required this.color,
    this.textColor = AppColors.cardWhite,
    this.fontSize = AppSizes.fontXS,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _MemberAvatars._size,
      height: _MemberAvatars._size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cardWhite, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
