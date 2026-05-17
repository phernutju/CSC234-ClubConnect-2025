import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadPublishedEvents();
    });
  }

  @override
  void dispose() {
    context.read<EventProvider>().clearPublishedEvents();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<EventProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _AppBar(),
          Expanded(
            child: ep.publishedEvents.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSizes.paddingM),
                    itemCount: ep.publishedEvents.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.paddingM),
                    itemBuilder: (_, i) => EventCard(
                      event: ep.publishedEvents[i],
                      communityId: ep.publishedEvents[i].communityId,
                    ),
                  ),
          ),
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
