import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
  DateTime? _filterDate;

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
    return count.isEmpty
        ? widget.communityName
        : '${widget.communityName} ($count)';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.cardWhite,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _filterDate = picked);
    }
  }

  List<EventModel> _filtered(List<EventModel> events) {
    if (_filterDate == null) return events;
    final d = _filterDate!;
    return events.where((e) {
      final start = e.startDate.toDate();
      final end = e.endDate.toDate();
      final dayStart = DateTime(d.year, d.month, d.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      return start.isBefore(dayEnd) && end.isAfter(dayStart);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<EventProvider>();
    final filtered = _filtered(ep.events);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _EventsAppBar(title: _title),
          _DateFilterBar(
            selectedDate: _filterDate,
            onPickDate: _pickDate,
            onClear: () => setState(() => _filterDate = null),
          ),
          Expanded(
            child: ep.isLoading && ep.events.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : filtered.isEmpty
                    ? const _EmptyState()
                    : _EventList(
                        events: filtered,
                        communityId: widget.communityId,
                        communityName: widget.communityName),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        onPressed: () =>
            context.push('/create-event', extra: widget.communityId),
        child: const Icon(Icons.add, color: AppColors.cardWhite),
      ),
    );
  }
}

// ── Date filter bar ───────────────────────────────────────────────────────────

class _DateFilterBar extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onPickDate;
  final VoidCallback onClear;

  const _DateFilterBar({
    required this.selectedDate,
    required this.onPickDate,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilter = selectedDate != null;
    return Container(
      color: AppColors.cardWhite,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onPickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasFilter
                        ? AppColors.primary
                        : AppColors.textGray.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  color: hasFilter
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.background,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: hasFilter ? AppColors.primary : AppColors.textGray,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasFilter
                          ? DateFormat('d MMMM yyyy').format(selectedDate!)
                          : 'Filter by date',
                      style: AppTextStyles.poppins(
                        fontSize: AppSizes.fontS,
                        color:
                            hasFilter ? AppColors.primary : AppColors.textGray,
                        fontWeight:
                            hasFilter ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hasFilter) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.textGray.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    size: 16, color: AppColors.textGray),
              ),
            ),
          ],
        ],
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
  final String communityName;

  const _EventList({
    required this.events,
    required this.communityId,
    required this.communityName,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.paddingM),
      itemBuilder: (context, index) => EventCard(
        event: events[index],
        communityId: communityId,
        communityName: communityName,
      ),
    );
  }
}
