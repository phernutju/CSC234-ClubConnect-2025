import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/event_detail_args.dart';
import '../../../models/event_model.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/profile_provider.dart';
import '../widgets/event_card.dart';
import 'package:google_fonts/google_fonts.dart';

class EventsScreen extends StatefulWidget {
  final String communityId;
  final String communityName;
  final String memberCount;

  const EventsScreen({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.memberCount,
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadEvents(widget.communityId);
    });
  }

  @override
  void dispose() {
    context.read<EventProvider>().clearEvents();
    super.dispose();
  }

  String get _title {
    final count = widget.memberCount;
    return count.isEmpty ? widget.communityName : '${widget.communityName} ($count)';
  }

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<EventProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _EventsAppBar(title: _title),
          Expanded(
            child: ep.isLoading && ep.events.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : ep.events.isEmpty
                    ? const _EmptyState()
                    : _EventList(events: ep.events, communityId: widget.communityId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        onPressed: () => context.push('/create-event', extra: widget.communityId),
        child: const Icon(Icons.add, color: AppColors.cardWhite),
      ),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────

class _EventsAppBar extends StatelessWidget {
  final String title;
  const _EventsAppBar({required this.title});

  @override
  Widget build(BuildContext context) {
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
                title,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.poppins(
                  fontSize: AppSizes.fontL,
                  fontWeight: FontWeight.bold,
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

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_activity,
            size: 64,
            color: AppColors.textGray.withValues(alpha: 0.35),
          ),
          const SizedBox(height: AppSizes.paddingM),
          Text(
            AppStrings.eventsEmpty,
            style: AppTextStyles.poppins(
              fontWeight: FontWeight.w600,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Event list ────────────────────────────────────────────────────────────────

class _EventList extends StatelessWidget {
  final List<EventModel> events;
  final String communityId;

  const _EventList({required this.events, required this.communityId});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.paddingM),
      itemBuilder: (context, index) =>
          _EventCard(event: events[index], communityId: communityId, currentMembers: events[index].attendeeCount),
    );
  }
}

// ── Event card ────────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final EventModel event;
  final String communityId;
  final int currentMembers;

  const _EventCard({
    required this.event,
    required this.communityId,
    this.currentMembers = 0,
  });

  @override
  Widget build(BuildContext context) {
    final dateLine = event.formattedDateRange;

    return Container(
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
          _CoverImage(url: event.imageUrl?.isNotEmpty == true ? event.imageUrl! : ''),

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
                // Event name + member count on same line
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
                      '${event.attendeeCount}/${event.maxAttendees} members',
                      style: GoogleFonts.poppins(
                        fontSize: AppSizes.fontXS,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFFF6B4A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),

                // Host name
                if (event.createdBy.isNotEmpty)
                  FutureBuilder(
                    future: context.read<ProfileProvider>().fetchUserById(event.createdBy),
                    builder: (context, snapshot) {
                      final hostLabel = snapshot.hasData
                          ? snapshot.data!.displayName
                          : event.createdBy;

                      return Text(
                        'by $hostLabel',
                        style: GoogleFonts.poppins(
                          fontSize: AppSizes.fontXS,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF837A7A),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: AppSizes.paddingS),

                // Details link
                Row(
                  children: [
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push('/event-detail',
                          extra: EventDetailArgs(
                              event: event, communityId: communityId)),
                      child: Text(
                        'details →',
                        style: GoogleFonts.poppins(
                          fontSize: AppSizes.fontXS,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
        child: const Icon(Icons.image_outlined, color: AppColors.inputBorder, size: 40),
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
          child: const Icon(Icons.broken_image_outlined, color: AppColors.inputBorder, size: 40),
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

