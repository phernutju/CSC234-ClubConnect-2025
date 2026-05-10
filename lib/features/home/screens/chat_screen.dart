import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/message_model.dart';
import '../../../models/profile_args.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/community_provider.dart';
import '../../../services/message_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_bar.dart';
import '../widgets/message_long_press_menu.dart';
import '../widgets/report_message_modal.dart';

class ChatScreen extends StatefulWidget {
  final String communityId;
  final String communityName;

  /// Fallback member count shown before the member stream loads.
  final String memberCount;

  const ChatScreen({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.memberCount,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  ChatMessage? _replyingTo;
  bool _isSending = false;
  bool _isInitializing = true;
  bool _isBanned = false;
  DateTime? _banUntil;

  // Track which sender UIDs have already had a name fetch triggered.
  final Set<String> _fetchedUids = {};

  // Stored so dispose() can call clearActiveCommunity() safely.
  CommunityProvider? _provider;

  // Track last-known message count to auto-scroll on new messages.
  int _lastMessageCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider ??= context.read<CommunityProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final cp = context.read<CommunityProvider>();
      _provider = cp;
      if (widget.communityId.isEmpty) {
        setState(() => _isInitializing = false);
        return;
      }
      final community = await cp.fetchCommunity(widget.communityId);
      if (!mounted) return;
      if (community != null) cp.setActiveCommunity(community);

      final uid = context.read<AppAuthProvider>().user?.uid;
      if (uid != null) {
        final banStatus = await MessageService.getBanStatus(uid);
        if (mounted) {
          setState(() {
            _isBanned = banStatus.isBanned;
            _banUntil = banStatus.bannedUntil;
          });
        }
      }

      setState(() => _isInitializing = false);
    });
  }

  @override
  void dispose() {
    _provider?.clearActiveCommunity();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  ChatMessage _toUIMessage(
    MessageModel m,
    String currentUid,
    CommunityProvider cp,
  ) {
    final isSent = m.senderId == currentUid;
    final cachedName = cp.displayNameOf(m.senderId);
    final senderName = isSent
        ? 'You'
        : cachedName.isNotEmpty
            ? cachedName
            : '…';
    return ChatMessage(
      id: m.id,
      text: m.text,
      isSent: isSent,
      senderName: senderName,
      senderId: m.senderId,
      time: _formatTime(m.timestamp),
      readCount: isSent ? 'Read ${m.seenBy.length}' : null,
      replyToName: _replyingTo?.id == m.id ? _replyingTo?.senderName : null,
      replyToText: _replyingTo?.id == m.id ? _replyingTo?.text : null,
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _sendTextMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending || _isBanned) return;

    final replySnapshot = _replyingTo;
    _inputController.clear();
    setState(() {
      _isSending = true;
      _replyingTo = null;
    });

    try {
      final cp = context.read<CommunityProvider>();
      final rules = cp.activeCommunity?.rules
              .map((r) => '- ${r.text}')
              .join('\n') ??
          '';

      final result = await MessageService.sendMessage(
        communityId: widget.communityId,
        text: text,
        communityRules: rules,
      );

      if (!mounted) return;

      switch (result.status) {
        case SendStatus.success:
          _scrollToBottom();

        case SendStatus.flagged:
          setState(() => _replyingTo = replySnapshot);
          if (result.newBan) {
            setState(() {
              _isBanned = true;
              _banUntil = result.banUntil;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'ข้อความไม่เหมาะสม — คุณถูกระงับการส่งข้อความเป็นเวลา 24 ชั่วโมง'),
                backgroundColor: AppColors.alertRed,
                duration: Duration(seconds: 4),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ข้อความมีเนื้อหาไม่เหมาะสม ไม่สามารถส่งได้'),
                backgroundColor: AppColors.alertRed,
              ),
            );
          }

        case SendStatus.banned:
          setState(() {
            _replyingTo = replySnapshot;
            _isBanned = true;
            _banUntil = result.banUntil;
          });

        case SendStatus.error:
          setState(() => _replyingTo = replySnapshot);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.errorMessage ?? 'ส่งข้อความไม่สำเร็จ')),
          );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ส่งข้อความไม่สำเร็จ: $e')),
      );
      setState(() => _replyingTo = replySnapshot);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // Image upload requires StorageService (not yet implemented).
  void _sendImageMessage(Uint8List bytes) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image upload coming soon')),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onLongPressMessage(ChatMessage message, Offset tapPosition) {
    showMessageMenu(
      context,
      message: message,
      tapPosition: tapPosition,
      onReply: () => setState(() => _replyingTo = message),
      onReport: () => showReportModal(
        context,
        reportedUsername: message.senderName,
        communityName: widget.communityName,
        messageSnippet: message.text,
      ),
    );
  }

  void _showMenu() {
    final cp = context.read<CommunityProvider>();
    final isMuted = cp.mutedCommunityNames.contains(widget.communityId);

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusL)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(AppStrings.chatMenuInfo, style: AppTextStyles.body()),
              onTap: () {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.chatInfoSnackbar)),
                );
              },
            ),
            ListTile(
              leading: Icon(
                isMuted ? Icons.notifications : Icons.notifications_off_outlined,
              ),
              title: Text(
                isMuted ? AppStrings.chatMenuUnmute : AppStrings.chatMenuMute,
                style: AppTextStyles.body(),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                context.read<CommunityProvider>().toggleMute(widget.communityId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isMuted
                        ? AppStrings.chatUnmutedSnackbar
                        : AppStrings.chatMutedSnackbar),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: AppColors.alertRed),
              title: Text(
                AppStrings.chatMenuLeave,
                style: AppTextStyles.body(color: AppColors.alertRed),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _confirmLeave();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLeave() {
    showDialog<void>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(
          AppStrings.chatLeaveTitle,
          style: AppTextStyles.body(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text(AppStrings.chatLeaveNo, style: AppTextStyles.body()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dlgCtx);
              await context
                  .read<CommunityProvider>()
                  .leaveCommunity(widget.communityId);
              if (mounted) context.pop();
            },
            child: Text(
              AppStrings.chatLeaveYes,
              style: AppTextStyles.body(color: AppColors.alertRed),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CommunityProvider>();
    final currentUid = context.watch<AppAuthProvider>().user?.uid ?? '';

    // Trigger display-name fetches for any sender we haven't requested yet.
    for (final m in cp.messages) {
      if (m.senderId != currentUid && _fetchedUids.add(m.senderId)) {
        cp.fetchDisplayName(m.senderId);
      }
    }

    // Auto-scroll when a new message arrives.
    if (cp.messages.length != _lastMessageCount) {
      _lastMessageCount = cp.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    final uiMessages = cp.messages
        .map((m) => _toUIMessage(m, currentUid, cp))
        .toList();

    final memberDisplay = cp.members.isNotEmpty
        ? cp.members.length.toString()
        : widget.memberCount;

    return Scaffold(
      backgroundColor: AppColors.chatBackground,
      body: Column(
        children: [
          // ── App bar ────────────────────────────────────────────────────────
          _ChatAppBar(
            communityName: widget.communityName,
            memberCount: memberDisplay,
            onMenuTap: _showMenu,
          ),

          // ── Error banner ──────────────────────────────────────────────────
          if (cp.error != null)
            _ErrorBanner(message: cp.error!),

          // ── Ban banner ────────────────────────────────────────────────────
          if (_isBanned)
            _BanBanner(banUntil: _banUntil),

          // ── Message list ──────────────────────────────────────────────────
          Expanded(
            child: _buildMessageList(uiMessages, cp),
          ),

          // ── Input bar ─────────────────────────────────────────────────────
          MessageInputBar(
            controller: _inputController,
            onSend: _sendTextMessage,
            onImagePicked: _sendImageMessage,
            replyToName: _replyingTo?.senderName,
            replyToText: _replyingTo?.text,
            onCancelReply: () => setState(() => _replyingTo = null),
            enabled: !_isBanned,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> uiMessages, CommunityProvider cp) {
    if (_isInitializing || (cp.isLoading && cp.messages.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (cp.messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet. Say hello! 👋',
          style: AppTextStyles.body(color: AppColors.textGray),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSizes.paddingM),
      itemCount: uiMessages.length + 1, // +1 for the date separator
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.paddingM),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _DateSeparator(label: AppStrings.chatToday);
        }
        final message = uiMessages[index - 1];
        return MessageBubble(
          message: message,
          onLongPress: (pos) => _onLongPressMessage(message, pos),
          onSenderTap: message.isSent
              ? null
              : () => context.push(
                    '/other-profile',
                    extra: ProfileArgs(
                      userId: message.senderId,
                      username: message.senderName,
                      communityName: widget.communityName,
                    ),
                  ),
        );
      },
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

/// Coral app bar: back arrow, community name + member count, hamburger menu.
class _ChatAppBar extends StatelessWidget {
  final String communityName;
  final String memberCount;
  final VoidCallback onMenuTap;

  const _ChatAppBar({
    required this.communityName,
    required this.memberCount,
    required this.onMenuTap,
  });

  String get _title =>
      memberCount.isEmpty ? communityName : '$communityName ($memberCount)';

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
                _title,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(
                  fontSize: AppSizes.fontL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cardWhite,
                ),
              ),
            ),
            GestureDetector(
              onTap: onMenuTap,
              child: const Icon(Icons.menu, color: AppColors.cardWhite),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centered date label (e.g. "Today") between message groups.
class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: AppTextStyles.body(
          fontSize: AppSizes.fontXS,
          color: AppColors.textGray,
        ),
      ),
    );
  }
}

/// Thin red banner shown when the provider reports an error.
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.alertRed.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      child: Text(
        message,
        style: AppTextStyles.body(
          fontSize: AppSizes.fontXS,
          color: AppColors.alertRed,
        ),
      ),
    );
  }
}

/// Red banner shown when the current user is banned from sending messages.
class _BanBanner extends StatelessWidget {
  final DateTime? banUntil;
  const _BanBanner({this.banUntil});

  String get _label {
    if (banUntil == null) return 'คุณถูกระงับการส่งข้อความชั่วคราว';
    final dt = banUntil!;
    final date =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return 'คุณถูกระงับการส่งข้อความ — ระงับถึง $date เวลา $time น.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.alertRed,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      child: Row(
        children: [
          const Icon(Icons.block, color: AppColors.cardWhite, size: 14),
          const SizedBox(width: AppSizes.paddingS),
          Expanded(
            child: Text(
              _label,
              style: AppTextStyles.body(
                fontSize: AppSizes.fontXS,
                color: AppColors.cardWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
