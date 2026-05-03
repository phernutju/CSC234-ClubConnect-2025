import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../widgets/notification_item.dart';

/// Inbox screen — groups notifications by time (Recent / 2 days ago).
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  static const List<Map<String, String>> _recentNotifs = [
    {'name': 'Name', 'community': 'Community'},
    {'name': 'Name', 'community': 'Community'},
    {'name': 'Name', 'community': 'Community'},
  ];

  static const List<Map<String, String>> _olderNotifs = [
    {'name': 'Name', 'community': 'Community'},
    {'name': 'Name', 'community': 'Community'},
    {'name': 'Name', 'community': 'Community'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.paddingL),

              // "Inbox" page title
              Text(
                AppStrings.inboxTitle,
                style: AppTextStyles.title(color: AppColors.textDark),
              ),
              const SizedBox(height: AppSizes.paddingM),

              Expanded(
                child: ListView(
                  children: [
                    _SectionHeader(label: AppStrings.inboxRecent),
                    ..._recentNotifs.map(
                      (n) => NotificationItem(
                        senderName: n['name']!,
                        communityName: n['community']!,
                        body: AppStrings.notifBody,
                      ),
                    ),

                    const SizedBox(height: AppSizes.paddingM),

                    _SectionHeader(label: AppStrings.inboxOld),
                    ..._olderNotifs.map(
                      (n) => NotificationItem(
                        senderName: n['name']!,
                        communityName: n['community']!,
                        body: AppStrings.notifBody,
                      ),
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

// ── Sub-widget ─────────────────────────────────────────────────────────────────

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
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
