import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/event_chat_args.dart';
import '../../../models/event_model.dart';
import '../../../providers/auth_provider.dart';

// ── Join status ───────────────────────────────────────────────────────────────

enum _JoinStatus { none, pending, accepted }

class _JoinRequest {
  final String userId;
  final String username;
  const _JoinRequest({required this.userId, required this.username});
}

// ── Screen ────────────────────────────────────────────────────────────────────

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  _JoinStatus _joinStatus = _JoinStatus.none;
  int _currentMembers = 0;

  /// Pending join requests — populated locally; backend will sync later.
  final List<_JoinRequest> _pendingRequests = [];

  /// Accepted member display names — populated locally; backend will sync later.
  final List<String> _memberNames = [];

  static const _avatarColors = [
    Color(0xFFFFB347),
    Color(0xFF77DD77),
    Color(0xFF89CFF0),
    Color(0xFFCDA4DE),
    Color(0xFFFF6961),
    Color(0xFFFFD700),
  ];

  // ── Host check ──────────────────────────────────────────────────────────────

  bool get _isHost {
    final uid = context.read<AppAuthProvider>().user?.uid ?? '';
    return uid.isNotEmpty && widget.event.createdById == uid;
  }

  // ── Button ──────────────────────────────────────────────────────────────────

  String get _buttonLabel {
    if (_isHost) return 'Enter Chat';
    switch (_joinStatus) {
      case _JoinStatus.none:     return 'Join';
      case _JoinStatus.pending:  return 'Cancel';
      case _JoinStatus.accepted: return 'Enter Chat';
    }
  }

  void _onButtonTap() {
    if (_isHost) {
      _goToChat();
      return;
    }
    switch (_joinStatus) {
      case _JoinStatus.none:
        final uid = context.read<AppAuthProvider>().user?.uid ?? '';
        setState(() {
          _joinStatus = _JoinStatus.pending;
          _pendingRequests.add(_JoinRequest(userId: uid, username: 'You'));
        });
        break;
      case _JoinStatus.pending:
        final uid = context.read<AppAuthProvider>().user?.uid ?? '';
        setState(() {
          _pendingRequests.removeWhere((r) => r.userId == uid);
          _joinStatus = _JoinStatus.none;
        });
        break;
      case _JoinStatus.accepted:
        _goToChat();
        break;
    }
  }

  void _goToChat() {
    context.push(
      '/event-chat',
      extra: EventChatArgs(
        event: widget.event,
        memberCount: '$_currentMembers/${widget.event.memberLimit}',
      ),
    );
  }

  // ── Host actions ─────────────────────────────────────────────────────────────

  void _acceptRequest(_JoinRequest req) {
    final currentUid = context.read<AppAuthProvider>().user?.uid ?? '';
    setState(() {
      _pendingRequests.remove(req);
      _memberNames.add(req.username);
      _currentMembers++;
      // Same-device demo: if current user's request is accepted, update status.
      if (req.userId == currentUid) _joinStatus = _JoinStatus.accepted;
    });
  }

  void _rejectRequest(_JoinRequest req) {
    setState(() => _pendingRequests.remove(req));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMMM yyyy  hh:mm a').format(widget.event.date);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isHost = _isHost;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── App bar ─────────────────────────────────────────────────────────
          _DetailAppBar(
            title: widget.event.title,
            memberCount: '$_currentMembers/${widget.event.memberLimit}',
          ),

          // ── Scrollable content ───────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CoverImage(url: widget.event.coverImageUrl),

                  Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event name
                        Text(
                          widget.event.title,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingS),

                        // Date row
                        _IconRow(icon: Icons.calendar_month, text: dateStr),

                        // Location row
                        if (widget.event.location.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _IconRow(icon: Icons.location_on, text: widget.event.location),
                        ],

                        // Event Detail section
                        if (widget.event.detail.isNotEmpty) ...[
                          const SizedBox(height: AppSizes.paddingM),
                          Text(
                            'Event Detail',
                            style: GoogleFonts.poppins(
                              fontSize: AppSizes.fontSM,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: AppSizes.paddingXS),
                          Text(
                            widget.event.detail,
                            style: GoogleFonts.poppins(
                              fontSize: AppSizes.fontSM,
                              fontWeight: FontWeight.w300,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],

                        // ── Members section ──────────────────────────────────
                        const SizedBox(height: 25),

                        if (isHost) ...[
                          // Host: pending requests
                          if (_pendingRequests.isNotEmpty) ...[
                            Text(
                              'Pending Requests (${_pendingRequests.length})',
                              style: GoogleFonts.poppins(
                                fontSize: AppSizes.fontSM,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: AppSizes.paddingS),
                            ..._pendingRequests.map((req) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
                              child: _PendingRequestTile(
                                request: req,
                                onAccept: () => _acceptRequest(req),
                                onReject: () => _rejectRequest(req),
                              ),
                            )),
                            const SizedBox(height: AppSizes.paddingS),
                          ],

                          // Host: members list
                          Text(
                            'Members ($_currentMembers/${widget.event.memberLimit})',
                            style: GoogleFonts.poppins(
                              fontSize: AppSizes.fontSM,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          if (_memberNames.isNotEmpty) ...[
                            const SizedBox(height: AppSizes.paddingS),
                            _MemberAvatarRow(
                              names: _memberNames,
                              colors: _avatarColors,
                            ),
                          ],
                        ] else ...[
                          // Non-host: member count + avatar row
                          Text(
                            'Members ($_currentMembers/${widget.event.memberLimit})',
                            style: GoogleFonts.poppins(
                              fontSize: AppSizes.fontSM,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          if (_memberNames.isNotEmpty) ...[
                            const SizedBox(height: AppSizes.paddingS),
                            _MemberAvatarRow(
                              names: _memberNames,
                              colors: _avatarColors,
                            ),
                          ],
                        ],

                        // Event's bills card
                        const SizedBox(height: AppSizes.paddingM),
                        const _BillsCard(),

                        SizedBox(height: AppSizes.paddingXL + bottomPad),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Action button ────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.paddingM,
              AppSizes.paddingS,
              AppSizes.paddingM,
              bottomPad > 0 ? bottomPad : AppSizes.paddingL,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onButtonTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
                ),
                child: Text(
                  _buttonLabel,
                  style: GoogleFonts.poppins(
                    fontSize: AppSizes.fontML,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cardWhite,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pending request tile ──────────────────────────────────────────────────────

class _PendingRequestTile extends StatelessWidget {
  final _JoinRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _PendingRequestTile({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar circle
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFFFB347),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            request.username.isNotEmpty
                ? request.username[0].toUpperCase()
                : '?',
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.w600,
              color: AppColors.cardWhite,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.paddingS),

        // Username
        Expanded(
          child: Text(
            request.username,
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ),

        // Accept button (✓)
        GestureDetector(
          onTap: onAccept,
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: AppColors.cardWhite, size: 16),
          ),
        ),
        const SizedBox(width: AppSizes.paddingXS),

        // Reject button (✗)
        GestureDetector(
          onTap: onReject,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close, color: AppColors.textDark, size: 16),
          ),
        ),
      ],
    );
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────

class _DetailAppBar extends StatelessWidget {
  final String title;
  final String memberCount;

  const _DetailAppBar({required this.title, required this.memberCount});

  @override
  Widget build(BuildContext context) {
    final displayTitle = memberCount.isEmpty ? title : '$title ($memberCount)';
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: AppSizes.paddingM,
        right: AppSizes.paddingM,
      ),
      child: SizedBox(
        height: AppSizes.appBarHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: const Icon(Icons.arrow_back, color: AppColors.cardWhite),
            ),
            const SizedBox(width: AppSizes.paddingM),
            Expanded(
              child: Text(
                displayTitle,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: AppSizes.fontL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cardWhite,
                ),
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
        height: AppSizes.coverImageHeight,
        width: double.infinity,
        color: AppColors.inputFill,
        child: const Icon(Icons.image_outlined, color: AppColors.inputBorder, size: 48),
      );
    }
    return SizedBox(
      height: AppSizes.coverImageHeight,
      width: double.infinity,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: AppSizes.coverImageHeight,
          color: AppColors.inputFill,
          child: const Icon(Icons.broken_image_outlined, color: AppColors.inputBorder, size: 48),
        ),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                height: AppSizes.coverImageHeight,
                color: AppColors.inputFill,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                ),
              ),
      ),
    );
  }
}

// ── Icon + text row ───────────────────────────────────────────────────────────

class _IconRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IconRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 26, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.w300,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Member avatar row ─────────────────────────────────────────────────────────

class _MemberAvatarRow extends StatelessWidget {
  final List<String> names;
  final List<Color> colors;

  static const int _maxVisible = 4;
  static const double _size = 32;
  static const double _overlap = 10;

  const _MemberAvatarRow({required this.names, required this.colors});

  @override
  Widget build(BuildContext context) {
    final visible = names.take(_maxVisible).toList();
    final overflow = names.length - _maxVisible;
    final slotCount = visible.length + (overflow > 0 ? 1 : 0);

    return SizedBox(
      height: _size,
      width: slotCount * (_size - _overlap) + _overlap,
      child: Stack(
        children: [
          for (int i = 0; i < visible.length; i++)
            Positioned(
              left: i * (_size - _overlap),
              child: _AvatarCircle(
                label: visible[i].isNotEmpty ? visible[i][0].toUpperCase() : '?',
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
      width: _MemberAvatarRow._size,
      height: _MemberAvatarRow._size,
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

// ── Event's bills card ────────────────────────────────────────────────────────

class _BillsCard extends StatelessWidget {
  const _BillsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingM,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: const Color(0xFFE8DFD8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Event's bills",
                  style: GoogleFonts.poppins(
                    fontSize: AppSizes.fontSM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'view bill summary that each need to pay',
                  style: GoogleFonts.poppins(
                    fontSize: AppSizes.fontXXS,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFFF6B4A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.paddingS),
          Text(
            '→',
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontL,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
