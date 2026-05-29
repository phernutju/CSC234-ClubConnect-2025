import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_constants.dart';
import '../../../models/event_detail_args.dart';
import '../../../models/event_model.dart';
import 'package:provider/provider.dart';
import '../../../providers/profile_provider.dart';

/// Shared event card used in the community events page and the global Events tab.
class EventCard extends StatefulWidget {
  final EventModel event;

  /// Community ID used for navigation and (when [communityName] is empty) for
  /// fetching the community name. Defaults to [event.communityId] when blank.
  final String communityId;

  /// Community display name shown below the event title. When empty the card
  /// fetches it automatically from Firestore using [communityId].
  final String communityName;

  static const _avatarColors = [
    Color(0xFFFFB347),
    Color(0xFF77DD77),
    Color(0xFF89CFF0),
    Color(0xFFCDA4DE),
    Color(0xFFFF6961),
    Color(0xFFFFD700),
  ];

  const EventCard({
    super.key,
    required this.event,
    this.communityId = '',
    this.communityName = '',
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  late final Future<List<String>> _memberNamesFuture;
  late final Future<String?> _communityNameFuture;
  late final Future<String> _hostNameFuture;

  String get _effectiveCommunityId => widget.communityId.isNotEmpty
      ? widget.communityId
      : widget.event.communityId;

  @override
  void initState() {
    super.initState();
    final pp = context.read<ProfileProvider>();

    // Host display name
    _hostNameFuture = _safeFetchDisplayName(pp, widget.event.createdBy);

    // First 4 attendee display names
    final ids = widget.event.attendees.take(4).toList();
    _memberNamesFuture = ids.isEmpty
        ? Future.value([])
        : Future.wait(ids.map((id) => _safeFetchDisplayName(pp, id)));

    // Community name: use provided value or fetch from Firestore
    if (widget.communityName.isNotEmpty) {
      _communityNameFuture = Future.value(widget.communityName);
    } else if (_effectiveCommunityId.isNotEmpty) {
      _communityNameFuture = _safeFetchCommunityName(pp, _effectiveCommunityId);
    } else {
      _communityNameFuture = Future.value(null);
    }
  }

  Future<String> _safeFetchDisplayName(ProfileProvider pp, String id) async {
    if (id.isEmpty) return '';
    try {
      final u = await pp.fetchUserById(id);
      return u.displayName;
    } catch (_) {
      return '';
    }
  }

  Future<String?> _safeFetchCommunityName(ProfileProvider pp, String id) async {
    try {
      return await pp.fetchCommunityName(id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLine = widget.event.formattedDateRange;
    final isClosed = widget.event.status == EventStatus.closed;
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isJoined =
        currentUid.isNotEmpty && widget.event.isAttending(currentUid);

    return GestureDetector(
      onTap: isClosed
          ? null
          : () => context.push(
                '/event-detail',
                extra: EventDetailArgs(
                    event: widget.event, communityId: _effectiveCommunityId),
              ),
      child: Opacity(
        opacity: isClosed ? 0.5 : 1.0,
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
                      decoration: BoxDecoration(
                        color: isClosed ? Colors.grey : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateLine,
                      style: GoogleFonts.poppins(
                        fontSize: AppSizes.fontXS,
                        fontWeight: FontWeight.w500,
                        color: isClosed ? Colors.grey : AppColors.primary,
                      ),
                    ),
                    if (isClosed) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          'Closed',
                          style: GoogleFonts.poppins(
                            fontSize: AppSizes.fontXXS,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Cover image ──────────────────────────────────────────────────
              _CoverImage(url: widget.event.imageUrl ?? ''),

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
                    // Event title + joined badge + member count
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.event.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: AppSizes.fontML,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              if (isJoined) ...[
                                const SizedBox(width: AppSizes.paddingXS),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.paddingS,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(
                                        AppSizes.interestChipRadius),
                                  ),
                                  child: Text(
                                    'Joined',
                                    style: GoogleFonts.poppins(
                                      fontSize: AppSizes.fontXXS,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.cardWhite,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingS),
                        Text(
                          '${widget.event.attendeeCount}/${widget.event.maxAttendees} members',
                          style: GoogleFonts.poppins(
                            fontSize: AppSizes.fontXS,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFFF6B4A),
                          ),
                        ),
                      ],
                    ),

                    // Community name
                    FutureBuilder<String?>(
                      future: _communityNameFuture,
                      builder: (context, snap) {
                        final name = snap.data;
                        if (name == null || name.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'from $name',
                            style: GoogleFonts.poppins(
                              fontSize: AppSizes.fontXS,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF9E9E9E),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 2),

                    // Host name
                    FutureBuilder<String>(
                      future: _hostNameFuture,
                      builder: (context, snap) {
                        final name = snap.data ?? '';
                        if (name.isEmpty) return const SizedBox.shrink();
                        return Text(
                          'Created by $name',
                          style: GoogleFonts.poppins(
                            fontSize: AppSizes.fontXS,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF837A7A),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppSizes.paddingS),

                    // Member avatars + details link
                    Row(
                      children: [
                        FutureBuilder<List<String>>(
                          future: _memberNamesFuture,
                          builder: (context, snap) {
                            final names = (snap.data ?? [])
                                .where((n) => n.isNotEmpty)
                                .toList();
                            if (names.isEmpty) return const SizedBox.shrink();
                            return _MemberAvatars(
                              names: names,
                              totalCount: widget.event.attendeeCount,
                              colors: EventCard._avatarColors,
                            );
                          },
                        ),
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

  /// Total attendee count — used to compute the +N overflow chip correctly
  /// when [names] contains fewer entries than the actual total.
  final int totalCount;

  static const int _maxVisible = 4;
  static const double _size = 26;
  static const double _overlap = 8;

  const _MemberAvatars({
    required this.names,
    required this.colors,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final visible = names.take(_maxVisible).toList();
    final overflow = totalCount - visible.length;

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
