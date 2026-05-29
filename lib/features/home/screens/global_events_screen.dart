import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/event_model.dart';
import '../../../providers/event_provider.dart';
import '../../community/widgets/event_card.dart';

/// Standalone Events page (bottom nav tab 2).
/// Shows all published events across every community.
class GlobalEventsScreen extends StatefulWidget {
  const GlobalEventsScreen({super.key});

  @override
  State<GlobalEventsScreen> createState() => _GlobalEventsScreenState();
}

class _GlobalEventsScreenState extends State<GlobalEventsScreen> {
  DateTime? _filterDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadPublishedEvents();
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    context.read<EventProvider>().loadPublishedEvents();
  }

  @override
  void dispose() {
    context.read<EventProvider>().clearPublishedEvents();
    super.dispose();
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
    if (picked != null && mounted) setState(() => _filterDate = picked);
  }

  List<EventModel> _filtered(List<EventModel> events) {
    if (_filterDate == null) return events;
    final d = _filterDate!;
    final dayStart = DateTime(d.year, d.month, d.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return events.where((e) {
      final start = e.startDate.toDate();
      final end = e.endDate.toDate();
      return start.isBefore(dayEnd) && end.isAfter(dayStart);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<EventProvider>();
    final filtered = _filtered(ep.publishedEvents);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _AppBar(),
          _DateFilterBar(
            selectedDate: _filterDate,
            onPickDate: _pickDate,
            onClear: () => setState(() => _filterDate = null),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSizes.paddingM),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.paddingM),
                    itemBuilder: (_, i) => EventCard(
                      event: filtered[i],
                      communityId: filtered[i].communityId,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

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
                    Icon(Icons.calendar_today,
                        size: 18,
                        color:
                            hasFilter ? AppColors.primary : AppColors.textGray),
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

class _AppBar extends StatelessWidget {
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
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            AppStrings.tabEvents,
            style: AppTextStyles.poppins(
              fontSize: AppSizes.fontL,
              fontWeight: FontWeight.bold,
              color: AppColors.cardWhite,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: AppColors.textGray.withValues(alpha: 0.35),
          ),
          const SizedBox(height: AppSizes.paddingM),
          Text(
            'No published events yet',
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
