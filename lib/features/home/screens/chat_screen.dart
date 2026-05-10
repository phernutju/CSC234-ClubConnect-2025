import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/chat_args.dart';
import '../../../models/message_model.dart';
import '../../../models/profile_args.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/community_provider.dart';
import '../widgets/community_info_modal.dart';
import '../widgets/members_sheet.dart';
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
  bool _menuOpen = false;

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
      imageUrl: m.imageURL.isNotEmpty ? m.imageURL : null,
      isSent: isSent,
      senderName: senderName,
      senderId: m.senderId,
      time: _formatTime(m.timestamp),
      readCount: isSent ? 'Read ${m.seenBy.length}' : null,
      replyToName: m.replyToSenderName,
      replyToText: m.replyToText,
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _sendTextMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    final replySnapshot = _replyingTo;
    _inputController.clear();
    setState(() {
      _isSending = true;
      _replyingTo = null;
    });

    try {
      await context.read<CommunityProvider>().sendMessage(
            widget.communityId,
            text: text,
            replyToId: replySnapshot?.id,
            replyToSenderName: replySnapshot?.senderName,
            replyToText: replySnapshot?.text,
          );
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
      setState(() => _replyingTo = replySnapshot);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _sendImageMessage(Uint8List bytes) {
    _doSendImage(bytes);
  }

  Future<void> _doSendImage(Uint8List bytes) async {
    setState(() => _isSending = true);
    try {
      await context.read<CommunityProvider>().sendImageMessage(
            widget.communityId,
            bytes,
          );
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send image: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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
        reporterId: context.read<AppAuthProvider>().user?.uid ?? '',
        targetUserId: message.senderId,
        communityId: widget.communityId,
        messageId: message.id,
      ),
    );
  }

  void _onInfo() {
    setState(() => _menuOpen = false);
    final community = context.read<CommunityProvider>().activeCommunity;
    if (community == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.chatInfoSnackbar)),
      );
      return;
    }
    final currentUid = context.read<AppAuthProvider>().user?.uid ?? '';
    final isHost = community.createdBy == currentUid;
    if (isHost) {
      context.push('/edit-community', extra: community);
    } else {
      showDialog(
        context: context,
        barrierColor: Colors.black45,
        barrierDismissible: true,
        builder: (_) => CommunityInfoModal(community: community),
      );
    }
  }

  void _onMute() {
    setState(() => _menuOpen = false);
    final provider = context.read<CommunityProvider>();
    provider.toggleMute(widget.communityId);
    final nowMuted = provider.isMuted(widget.communityId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowMuted ? AppStrings.chatMutedSnackbar : AppStrings.chatUnmutedSnackbar,
        ),
      ),
    );
  }

  void _onLeave() {
    setState(() => _menuOpen = false);
    showDialog(
      context: context,
      builder: (ctx) => _LeaveDialog(
        onNo: () => Navigator.of(ctx).pop(),
        onYes: () async {
          Navigator.of(ctx).pop();
          await context.read<CommunityProvider>().leaveCommunity(widget.communityId);
          if (mounted) context.pop();
        },
      ),
    );
  }

  void _onShowMembers() {
    setState(() => _menuOpen = false);
    final cp = context.read<CommunityProvider>();
    final community = cp.communities.where((c) => c.id == widget.communityId).firstOrNull;
    final currentUid = context.read<AppAuthProvider>().user?.uid ?? '';
    showMembersBottomSheet(
      context,
      communityId: widget.communityId,
      communityName: widget.communityName,
      currentUid: currentUid,
      creatorId: community?.createdBy ?? '',
    );
  }

  void _onEvents() {
    setState(() => _menuOpen = false);
    final cp = context.read<CommunityProvider>();
    final memberCount = cp.members.isNotEmpty
        ? cp.members.length.toString()
        : widget.memberCount;
    context.push(
      '/events',
      extra: ChatArgs(
        communityId: widget.communityId,
        communityName: widget.communityName,
        memberCount: memberCount,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final cp = context.watch<CommunityProvider>();
    final currentUid = context.watch<AppAuthProvider>().user?.uid ?? '';
    final muted = cp.isMuted(widget.communityId);

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
      body: Stack(
        children: [
          // ── Main content column ──────────────────────────────────────────
          Column(
            children: [
              // ── App bar ──────────────────────────────────────────────────
              _ChatAppBar(
                communityName: widget.communityName,
                memberCount: memberDisplay,
                onMenuTap: () => setState(() => _menuOpen = !_menuOpen),
              ),

              // ── Error banner ────────────────────────────────────────────
              if (cp.error != null)
                _ErrorBanner(message: cp.error!),

              // ── Upload progress ─────────────────────────────────────────
              if (cp.isUploading || _isSending)
                const LinearProgressIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.inputFill,
                ),

              // ── Message list ────────────────────────────────────────────
              Expanded(
                child: _buildMessageList(uiMessages, cp),
              ),

              // ── Input bar ───────────────────────────────────────────────
              MessageInputBar(
                controller: _inputController,
                onSend: _sendTextMessage,
                onImagePicked: _sendImageMessage,
                replyToName: _replyingTo?.senderName,
                replyToText: _replyingTo?.text,
                onCancelReply: () => setState(() => _replyingTo = null),
              ),
            ],
          ),

          // ── Dismissal barrier (shown when menu is open) ──────────────────
          if (_menuOpen)
            Positioned(
              top: statusBarHeight + AppSizes.appBarHeight,
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () => setState(() => _menuOpen = false),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),

          // ── Drop-down menu bar ───────────────────────────────────────────
          if (_menuOpen)
            Positioned(
              top: statusBarHeight + AppSizes.appBarHeight,
              left: 0,
              right: 0,
              child: _ChatMenuBar(
                muted: muted,
                onInfo: _onInfo,
                onMute: _onMute,
                onLeave: _onLeave,
                onShowMembers: _onShowMembers,
                onEvents: _onEvents,
              ),
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

/// Coral drop-down menu bar with Info / Mute / Leave options.
class _ChatMenuBar extends StatelessWidget {
  final bool muted;
  final VoidCallback onInfo;
  final VoidCallback onMute;
  final VoidCallback onLeave;
  final VoidCallback onShowMembers;
  final VoidCallback onEvents;

  const _ChatMenuBar({
    required this.muted,
    required this.onInfo,
    required this.onMute,
    required this.onLeave,
    required this.onShowMembers,
    required this.onEvents,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Mute · Members · Leave
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MenuItem(
                icon: muted ? Icons.notifications_off : Icons.notifications_off_outlined,
                label: muted ? AppStrings.chatMenuUnmute : AppStrings.chatMenuMute,
                onTap: onMute,
              ),
              _MenuItem(
                icon: Icons.group_outlined,
                label: AppStrings.chatMenuMembers,
                onTap: onShowMembers,
              ),
              _MenuItem(
                icon: Icons.exit_to_app,
                label: AppStrings.chatMenuLeave,
                onTap: onLeave,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: Info · Events
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MenuItem(
                icon: Icons.description_outlined,
                label: AppStrings.chatMenuInfo,
                onTap: onInfo,
              ),
              _MenuItem(
                icon: Icons.local_activity,
                label: AppStrings.chatMenuEvents,
                onTap: onEvents,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One icon + label item inside the menu bar.
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.cardWhite, size: AppSizes.chatMenuIconSize),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.body(
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.bold,
              color: AppColors.cardWhite,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact leave-confirmation dialog.
class _LeaveDialog extends StatelessWidget {
  final VoidCallback onNo;
  final VoidCallback onYes;

  const _LeaveDialog({required this.onNo, required this.onYes});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSizes.rateModalRadius),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSizes.paddingL,
          AppSizes.paddingL,
          AppSizes.paddingL,
          AppSizes.paddingM,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.chatLeaveTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.poppins(
                fontSize: AppSizes.fontSM,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppSizes.paddingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DialogButton(label: AppStrings.chatLeaveNo, color: AppColors.commentBody, onTap: onNo),
                _DialogButton(label: AppStrings.chatLeaveYes, color: AppColors.primary, onTap: onYes),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared dialog button with InkWell highlight.
class _DialogButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DialogButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.dialogHighlight,
        highlightColor: AppColors.dialogHighlight,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingM,
            vertical: AppSizes.paddingS,
          ),
          child: Text(
            label,
            style: AppTextStyles.poppins(
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
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
