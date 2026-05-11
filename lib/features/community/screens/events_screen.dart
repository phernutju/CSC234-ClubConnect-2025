import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/event_model.dart';
import '../../../providers/event_provider.dart';
import '../widgets/event_card.dart';

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
                    : _EventList(events: ep.events),
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

  const _EventList({required this.events});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.paddingM),
      itemBuilder: (context, index) => EventCard(event: events[index]),
    );
  }
}
