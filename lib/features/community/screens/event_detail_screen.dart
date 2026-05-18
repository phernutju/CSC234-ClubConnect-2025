import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/event_chat_args.dart';
import '../../../models/event_model.dart';
import '../../../models/community_model.dart';
import '../../../providers/attendee_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/community_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/smart_bill_provider.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;
  final String communityId;

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.communityId,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  AttendeeProvider? _attendeeProvider;
  Future<CommunityModel?>? _communityFuture;

  static const _avatarColors = [
    Color(0xFFFFB347),
    Color(0xFF77DD77),
    Color(0xFF89CFF0),
    Color(0xFFCDA4DE),
    Color(0xFFFF6961),
    Color(0xFFFFD700),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _attendeeProvider = context.read<AttendeeProvider>();
      _attendeeProvider!.loadAttendees(widget.communityId, widget.event.id);
      await _attendeeProvider!
          .checkIsAttending(widget.communityId, widget.event.id);
      if (!mounted) return;
      context.read<SmartBillProvider>().loadBillByEvent(widget.communityId, widget.event.id);
      _communityFuture = context.read<CommunityProvider>().fetchCommunity(widget.communityId);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _attendeeProvider?.clearAttendees();
    super.dispose();
  }

  // ── Host check ──────────────────────────────────────────────────────────────

  bool get _isHost {
    final uid = context.read<AppAuthProvider>().user?.uid ?? '';
    return uid.isNotEmpty && widget.event.createdBy == uid;
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  Future<void> _onCreateBillTap() async {
    await context.push(
      '/create-bill',
      extra: {
        'communityId': widget.communityId,
        'eventId': widget.event.id,
        'eventName': widget.event.title,
      },
    );
  }

  void _goToChat() {
    final ap = context.read<AttendeeProvider>();
    context.push(
      '/event-chat',
      extra: EventChatArgs(
        event: widget.event,
        memberCount: '${ap.attendees.length}/${widget.event.maxAttendees}',
        communityId: widget.communityId,
      ),
    );
  }

  // ── Button tap ──────────────────────────────────────────────────────────────

  Future<void> _onButtonTap() async {
    if (_isHost) {
      _goToChat();
      return;
    }
    final ap = context.read<AttendeeProvider>();
    final communityId = widget.communityId;
    final eventId = widget.event.id;

    if (ap.isAttending) {
      final uid = context.read<AppAuthProvider>().user?.uid ?? '';
      final billMembers = context.read<SmartBillProvider>().bill?.members ?? [];
      if (billMembers.any((m) => m.uid == uid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "You can't leave this event because you're part of its Smart Bill."),
          ),
        );
        return;
      }
      await ap.leaveEvent(communityId, eventId);
      if (!mounted) return;
      if (ap.error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(ap.error!)));
      }
    } else {
      await ap.joinEvent(communityId, eventId);
      if (!mounted) return;
      if (ap.error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(ap.error!)));
      } else {
        _goToChat();
      }
    }
  }

  void _onEditTap() {
    context.push('/edit-event', extra: widget.event);
  }

  Future<void> _onDeleteTap() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await context.read<EventProvider>().deleteEvent(widget.communityId, widget.event.id);
    if (!mounted) return;
    context.pop();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AttendeeProvider>();
    context.watch<SmartBillProvider>();
    final dateStr = widget.event.formattedDateRange;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isHost = _isHost;
    final memberCount = ap.attendees.length;
    final memberNames = ap.attendees.map((a) => a.displayName).toList();

    String buttonLabel;
    if (isHost) {
      buttonLabel = 'Enter Chat';
    } else if (ap.isAttending) {
      buttonLabel = 'Leave';
    } else {
      buttonLabel = 'Join';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── App bar ───────────────────────────────────────────────────────
          _DetailAppBar(
            title: widget.event.title,
            memberCount: '$memberCount/${widget.event.maxAttendees}',
            isHost: _isHost,
            onEditTap: _onEditTap,
          ),

          // ── Scrollable content ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CoverImage(
                    url: widget.event.imageUrl?.isNotEmpty == true
                        ? widget.event.imageUrl!
                        : '',
                  ),

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

                        // Location / description row
                        if (widget.event.description.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _IconRow(
                              icon: Icons.location_on,
                              text: widget.event.location),
                        ],

                        // Event Detail section
                        if (widget.event.description.isNotEmpty) ...[
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
                            widget.event.description,
                            style: GoogleFonts.poppins(
                              fontSize: AppSizes.fontSM,
                              fontWeight: FontWeight.w300,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],

                        // ── Members section ──────────────────────────────────
                        const SizedBox(height: 25),
                        Text(
                          'Members ($memberCount/${widget.event.maxAttendees})',
                          style: GoogleFonts.poppins(
                            fontSize: AppSizes.fontSM,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        if (memberNames.isNotEmpty) ...[
                          const SizedBox(height: AppSizes.paddingS),
                          _MemberAvatarRow(
                            names: memberNames,
                            colors: _avatarColors,
                          ),
                        ],

                        // Bills card
                        const SizedBox(height: AppSizes.paddingM),
                        _BillsCard(
                          communityId:  widget.communityId,
                          eventId:      widget.event.id,
                          isHost:       isHost,
                          isAttending:  ap.isAttending,
                          onCreateBill: _onCreateBillTap,
                        ),

                        // Rules section
                        FutureBuilder<CommunityModel?>(
                          future: _communityFuture,
                          builder: (context, snapshot) {
                            final rules = snapshot.data?.rules ?? [];
                            if (rules.isEmpty) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: AppSizes.paddingM),
                                Text(
                                  'Rules',
                                  style: GoogleFonts.poppins(
                                    fontSize: AppSizes.fontSM,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: AppSizes.paddingXS),
                                ...rules.asMap().entries.map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '${e.key + 1}. ${e.value.text}',
                                      style: GoogleFonts.poppins(
                                        fontSize: AppSizes.fontSM,
                                        fontWeight: FontWeight.w300,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        SizedBox(height: AppSizes.paddingXL + bottomPad),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Action button ─────────────────────────────────────────────────
          if (ap.isLoading)
            const LinearProgressIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.inputFill,
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.paddingM,
              AppSizes.paddingS,
              AppSizes.paddingM,
              bottomPad > 0 ? bottomPad : AppSizes.paddingL,
            ),
            child: Column(
              children: [
                if (!isHost && ap.isAttending) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: ap.isLoading ? null : _goToChat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.inputBorder,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.paddingM),
                      ),
                      child: Text(
                        'Go to Chat',
                        style: GoogleFonts.poppins(
                          fontSize: AppSizes.fontML,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cardWhite,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingS),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: ap.isLoading ? null : _onButtonTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (!isHost && ap.isAttending)
                          ? AppColors.cardWhite
                          : AppColors.primary,
                      foregroundColor: (!isHost && ap.isAttending)
                          ? AppColors.primary
                          : AppColors.cardWhite,
                      disabledBackgroundColor: AppColors.inputBorder,
                      elevation: 0,
                      side: (!isHost && ap.isAttending)
                          ? const BorderSide(color: AppColors.primary)
                          : BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusPill),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.paddingM),
                    ),
                    child: Text(
                      buttonLabel,
                      style: GoogleFonts.poppins(
                        fontSize: AppSizes.fontML,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

// ── App bar ───────────────────────────────────────────────────────────────────

class _DetailAppBar extends StatelessWidget {
  final String title;
  final String memberCount;
  final bool isHost;
  final VoidCallback onEditTap;

  const _DetailAppBar({
    required this.title,
    required this.memberCount,
    required this.isHost,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle =
        memberCount.isEmpty ? title : '$title ($memberCount)';
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
              child:
                  const Icon(Icons.arrow_back, color: AppColors.cardWhite),
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
            if (isHost)
              IconButton(
                onPressed: onEditTap,
                icon: const Icon(Icons.edit_outlined, color: AppColors.cardWhite),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
        child: const Icon(Icons.image_outlined,
            color: AppColors.inputBorder, size: 48),
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
          child: const Icon(Icons.broken_image_outlined,
              color: AppColors.inputBorder, size: 48),
        ),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                height: AppSizes.coverImageHeight,
                color: AppColors.inputFill,
                child: const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2),
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
                label: visible[i].isNotEmpty
                    ? visible[i][0].toUpperCase()
                    : '?',
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
  final String       communityId;
  final String       eventId;
  final bool         isHost;
  final bool         isAttending;
  final VoidCallback onCreateBill;

  const _BillsCard({
    required this.communityId,
    required this.eventId,
    required this.isHost,
    required this.isAttending,
    required this.onCreateBill,
  });

  Future<void> _confirmAndDelete(BuildContext context, String billId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Bill?',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark)),
        content: Text('This cannot be undone.',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppColors.textGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Delete',
                style:
                    GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context
          .read<SmartBillProvider>()
          .deleteBill(communityId, eventId, billId);
    }
  }

  Widget _card({
    required BuildContext context,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: AppSizes.fontSM,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SmartBillProvider>();
    final bill     = provider.bill;
    final hasBill  = bill != null;

    // isHost + no bill: show Create Bill
    if (isHost && !hasBill) {
      return _card(
        context:  context,
        title:    'Create Bill',
        subtitle: 'Create & manage the bill for this event',
        onTap:    onCreateBill,
      );
    }

    // isHost + has bill: show Manage Bill with ⋮ menu
    if (isHost && hasBill) {
      return GestureDetector(
        onTap: () => context.push('/bill-summary', extra: {
          'communityId':       communityId,
          'eventId':           eventId,
          'billId':            bill.id,
          'isCurrentUserHost': true,
        }),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.only(
            left: AppSizes.paddingM,
            top: AppSizes.paddingM,
            bottom: AppSizes.paddingM,
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
                      'Manage Bill',
                      style: GoogleFonts.poppins(
                        fontSize: AppSizes.fontSM,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View and manage the bill summary',
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
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.primary,
                  size: 20,
                ),
                color: const Color(0xFFFFFCF8),
                padding: EdgeInsets.zero,
                onSelected: (value) async {
                  if (value == 'edit') {
                    context.push('/create-bill', extra: {
                      'communityId': communityId,
                      'eventId': eventId,
                      'eventName': bill.name,
                      'bill': bill,
                      'items': provider.items.toList(),
                      'isEdit': true,
                    });
                  } else if (value == 'delete') {
                    await _confirmAndDelete(context, bill.id);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(children: [
                      const Text('✏️'),
                      const SizedBox(width: 8),
                      Text('Edit Bill',
                          style: GoogleFonts.poppins(
                              fontSize: AppSizes.fontSM,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDark)),
                    ]),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(children: [
                      const Text('🗑️'),
                      const SizedBox(width: 8),
                      Text('Delete Bill',
                          style: GoogleFonts.poppins(
                              fontSize: AppSizes.fontSM,
                              fontWeight: FontWeight.w500,
                              color: Colors.red)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // non-host: hide if not attending (includes loading state where isAttending is false)
    if (!isAttending) return const SizedBox.shrink();

    // member + no bill: hide section
    if (!hasBill) return const SizedBox.shrink();

    // member + has bill but not listed in bill members: hide section
    final uid = context.read<AppAuthProvider>().user?.uid ?? '';
    if (!bill.members.any((m) => m.uid == uid)) return const SizedBox.shrink();

    // member + has bill: show View Bill → BillSummaryScreen (member view)
    return _card(
      context:  context,
      title:    'View Bill',
      subtitle: 'View the bill and pay your share',
      onTap: () => context.push('/bill-summary', extra: {
        'communityId':       communityId,
        'eventId':           eventId,
        'billId':            bill.id,
        'isCurrentUserHost': false,
      }),
    );
  }
}
