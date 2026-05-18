import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/chat_args.dart';
import '../../../models/notification_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/community_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/profile_provider.dart';
import '../widgets/notification_item.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String? _watchedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId =
        context.read<AppAuthProvider>().user?.uid;
    if (userId != null && userId != _watchedUserId) {
      _watchedUserId = userId;
      context.read<NotificationProvider>().watchNotifications(userId);
    }
  }

  static String _groupLabel(Timestamp ts) {
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inHours < 1) return AppStrings.inboxRecent;
    if (diff.inHours < 24) return '${diff.inHours}${AppStrings.inboxHrsAgo}';
    return '${diff.inDays}${AppStrings.inboxDaysAgo}';
  }

  static Map<String, List<NotificationModel>> _groupByTime(
      List<NotificationModel> notifications) {
    final grouped = <String, List<NotificationModel>>{};
    for (final n in notifications) {
      grouped.putIfAbsent(_groupLabel(n.createdAt), () => []).add(n);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final mutedIds = context.watch<CommunityProvider>().mutedCommunityNames;
    final userId = context.read<AppAuthProvider>().user?.uid ?? '';

    final visible = notifProvider.notifications
        .where((n) => !mutedIds.contains(n.communityId))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.cardWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: AppSizes.paddingL,
                left: AppSizes.paddingL,
                right: AppSizes.paddingL,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.inboxTitle,
                    style: AppTextStyles.title(
                      fontSize: 32.0,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (notifProvider.unreadCount > 0)
                    TextButton(
                      onPressed: () =>
                          notifProvider.markAllAsRead(userId),
                      child: Text(
                        'Mark all read',
                        style: AppTextStyles.body(
                          fontSize: AppSizes.fontXS,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingM),
            Container(
              height: AppSizes.inboxDividerWidth,
              color: AppColors.rateCardBorder,
            ),

            Expanded(
              child: notifProvider.isLoading && visible.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : visible.isEmpty
                      ? const _EmptyState()
                      : _NotificationList(
                          grouped: _groupByTime(visible),
                          userId: userId,
                        ),
            ),
          ],
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
      child: Text(
        AppStrings.inboxEmpty,
        style: AppTextStyles.body(
          fontSize: AppSizes.fontSM,
          color: AppColors.fieldPlaceholder,
        ),
      ),
    );
  }
}

class _NotificationList extends StatefulWidget {
  final Map<String, List<NotificationModel>> grouped;
  final String userId;

  const _NotificationList({required this.grouped, required this.userId});

  @override
  State<_NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<_NotificationList> {
  final Map<String, String> _photoCache = {};
  final Set<String> _fetching = {};

  @override
  void didUpdateWidget(_NotificationList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fetchMissingPhotos();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchMissingPhotos());
  }

  void _fetchMissingPhotos() {
    final pp = context.read<ProfileProvider>();
    final allNotifs = widget.grouped.values.expand((l) => l);
    for (final n in allNotifs) {
      final uid = n.mentionedBy;
      if (uid.isEmpty || _photoCache.containsKey(uid) || _fetching.contains(uid)) continue;
      _fetching.add(uid);
      pp.fetchUserById(uid).then((user) {
        if (mounted) {
          setState(() {
            _photoCache[uid] = user.photoURL;
            _fetching.remove(uid);
          });
        }
      }).catchError((_) { _fetching.remove(uid); });
    }
  }

  VoidCallback? _buildOnTap(BuildContext context, NotificationModel n) {
    final isNavigable = n.type == 'reply' || n.type == 'mention';

    if (!isNavigable) {
      // Preserve existing behavior for other notification types
      // (rating, join, restriction, etc.): tap marks as read only.
      if (n.isRead) return null;
      return () => context
          .read<NotificationProvider>()
          .markAsRead(widget.userId, n.id);
    }

    return () async {
      final notifProvider = context.read<NotificationProvider>();
      final communityProvider = context.read<CommunityProvider>();

      if (!n.isRead) {
        notifProvider.markAsRead(widget.userId, n.id);
      }

      final targetCommunityId =
          (n.chatRoomId != null && n.chatRoomId!.isNotEmpty)
              ? n.chatRoomId!
              : n.communityId;
      if (targetCommunityId.isEmpty) return;

      final community =
          await communityProvider.fetchCommunity(targetCommunityId);
      if (!context.mounted) return;
      if (community == null) return;

      context.push(
        '/chat',
        extra: ChatArgs(
          communityId: community.id,
          communityName: community.communityName,
          memberCount: community.memberCount.toString(),
          targetMessageId: n.messageId,
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    final sections = widget.grouped.entries.toList();

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
                title: n.title,
                body: n.description,
                isRead: n.isRead,
                photoUrl: _photoCache[n.mentionedBy] ?? '',
                onTap: _buildOnTap(context, n),
              ),
            ),
          ],
        );
      },
    );
  }
}

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
