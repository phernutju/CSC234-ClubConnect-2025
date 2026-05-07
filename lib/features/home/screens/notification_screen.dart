import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/notification_model.dart';
import '../../../providers/community_provider.dart';
import '../widgets/notification_item.dart';

/// Inbox screen — groups notifications by recency and skips muted communities.
/// Shows empty state until backend data is connected.
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  // TESTING ONLY — replace with real data source when backend is connected.
  static const List<NotificationModel> _allNotifications = [];

  /// Returns a human-readable time-group label for a notification's timestamp.
  static String _groupLabel(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inHours < 1) return AppStrings.inboxRecent;
    if (diff.inHours < 24) return '${diff.inHours}${AppStrings.inboxHrsAgo}';
    return '${diff.inDays}${AppStrings.inboxDaysAgo}';
  }

  /// Groups [notifications] by their time label, preserving insertion order.
  static Map<String, List<NotificationModel>> _groupByTime(
      List<NotificationModel> notifications) {
    final grouped = <String, List<NotificationModel>>{};
    for (final n in notifications) {
      final label = _groupLabel(n.timestamp);
      grouped.putIfAbsent(label, () => []).add(n);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final mutedNames = context.watch<CommunityProvider>().mutedCommunityNames;

    // Filter out notifications from muted communities
    final visible = _allNotifications
        .where((n) => !mutedNames.contains(n.communityName))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.cardWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page title ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(
                top: AppSizes.paddingL,
                left: AppSizes.paddingL,
                right: AppSizes.paddingL,
              ),
              child: Text(
                AppStrings.inboxTitle,
                style: AppTextStyles.title(
                  fontSize: 32.0,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textDark,
                ),
              ),
            ),

            // Divider below title
            const SizedBox(height: AppSizes.paddingM),
            Container(
              height: AppSizes.inboxDividerWidth,
              color: AppColors.rateCardBorder, // #E8DFD8
            ),

            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: visible.isEmpty
                  ? const _EmptyState()
                  : _NotificationList(
                      grouped: _groupByTime(visible),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

/// Shown when there are no notifications.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppStrings.inboxEmpty,
        style: AppTextStyles.body(
          fontSize: AppSizes.fontSM,
          color: AppColors.fieldPlaceholder, // #BABABA
        ),
      ),
    );
  }
}

/// Scrollable list of grouped notifications.
class _NotificationList extends StatelessWidget {
  final Map<String, List<NotificationModel>> grouped;

  const _NotificationList({required this.grouped});

  @override
  Widget build(BuildContext context) {
    final sections = grouped.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(
        top: AppSizes.paddingM,
        left: AppSizes.paddingL,
        right: AppSizes.paddingL,
      ),
      itemCount: sections.length,
      itemBuilder: (_, i) {
        final label = sections[i].key;
        final items = sections[i].value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (i > 0) const SizedBox(height: AppSizes.paddingM),
            _SectionHeader(label: label),
            ...items.map(
              (n) => NotificationItem(
                senderName: n.senderName,
                communityName: n.communityName,
                body: n.messageSnippet,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Coral time-group header (e.g. "Recent", "2 hrs ago").
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
      child: Text(
        label,
        style: AppTextStyles.body(
          fontSize: AppSizes.fontS,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
