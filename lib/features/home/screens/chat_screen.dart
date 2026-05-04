import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/community_model.dart';
import '../../../models/profile_args.dart';
import '../../../providers/community_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../services/message_service.dart';
import '../widgets/community_info_modal.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_bar.dart';
import '../widgets/message_long_press_menu.dart';
import '../widgets/report_message_modal.dart';

/// Full-screen chat room for a single community conversation.
class ChatScreen extends StatefulWidget {
  final String communityName;
  final String communityId;
  final String communityRules;

  /// Numeric member count shown in parentheses after the name.
  /// Empty string suppresses the parentheses.
  final String memberCount;

  const ChatScreen({
    super.key,
    required this.communityName,
    required this.communityId,
    this.communityRules = '',
    required this.memberCount,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  bool _menuOpen = false;
  bool _isBanned = false;
  DateTime? _banUntil;
  bool _showFlaggedBanner = false;
  List<ChatMessage> _messages = [];

  ChatMessage? _replyingTo;

  @override
  void initState() {
    super.initState();
    _loadBanStatus();
    _listenMessages();
  }

  void _loadBanStatus() async {
    final uid = MessageService.currentUid;
    if (uid == null) return;
    final status = await MessageService.getBanStatus(uid);
    if (mounted) setState(() {
      _isBanned = status.isBanned;
      _banUntil = status.bannedUntil;
    });
  }

  void _listenMessages() {
    MessageService.messagesStream(widget.communityId).listen((msgs) {
      if (!mounted) return;
      final uid = MessageService.currentUid;
      setState(() {
        _messages = msgs.map((m) => ChatMessage(
          id: m.id,
          text: m.text,
          isSent: m.senderId == uid,
          senderName: m.senderName,
          time: _formatTime(m.timestamp),
          isFlagged: m.flagged,
          replyToName: m.replyToName,
          replyToText: m.replyToText,
        )).toList();
      });
      _scrollToBottom();
    });
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Current time formatted as "HH:mm".
  String get _nowTime {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _sendTextMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    setState(() => _showFlaggedBanner = false);

    final result = await MessageService.sendMessage(
      communityId: widget.communityId,
      text: text,
      communityRules: widget.communityRules,
      replyToName: _replyingTo?.senderName,
      replyToText: _replyingTo?.text,
    );

    setState(() => _replyingTo = null);

    switch (result.status) {
      case SendStatus.flagged:
      case SendStatus.banned:
        setState(() {
          _showFlaggedBanner = true;
          if (result.newBan || result.status == SendStatus.banned) {
            _isBanned = true;
            _banUntil = result.banUntil;
          }
        });
      case SendStatus.error:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.errorMessage ?? 'Failed to send')),
          );
        }
      case SendStatus.success:
        break;
    }
  }

  void _sendImageMessage(Uint8List bytes) {
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '',
        imageBytes: bytes,
        isSent: true,
        senderName: 'Me',
        time: _nowTime,
        readCount: 'Read 0',
      ));
    });
    _scrollToBottom();
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

  // ── Menu actions ────────────────────────────────────────────────────────────

  void _onInfo() {
    setState(() => _menuOpen = false);

    final communityProvider = context.read<CommunityProvider>();
    final username = context.read<ProfileProvider>().username;

    // Look up the community the chat belongs to
    final matches = communityProvider.communities
        .where((c) => c.name == widget.communityName);
    final CommunityModel? community =
        matches.isEmpty ? null : matches.first;

    if (community == null) {
      // Community not found (e.g., fresh session state) — no action
      return;
    }

    final isHost = username == community.hostName;

    if (isHost) {
      // Host → open Edit Community page
      context.push('/edit-community', extra: community);
    } else {
      // Member → show Community Info modal (view-only: onNext closes the modal)
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
    provider.toggleMute(widget.communityName);
    final nowMuted = provider.isMuted(widget.communityName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowMuted
              ? AppStrings.chatMutedSnackbar
              : AppStrings.chatUnmutedSnackbar,
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
        onYes: () {
          Navigator.of(ctx).pop();
          context.read<CommunityProvider>().leaveCommunity(widget.communityName);
          context.go('/home');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final muted = context.watch<CommunityProvider>().isMuted(widget.communityName);

    return Scaffold(
      backgroundColor: AppColors.chatBackground,
      body: Stack(
        children: [
          // ── Main content column ────────────────────────────────────────
          Column(
            children: [
              _ChatAppBar(
                communityName: widget.communityName,
                memberCount: widget.memberCount,
                onMenuTap: () => setState(() => _menuOpen = !_menuOpen),
              ),

              // ── Message list ───────────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  itemCount: _messages.length + 1, // +1 for date separator
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSizes.paddingM),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const _DateSeparator(label: AppStrings.chatToday);
                    }
                    final message = _messages[index - 1];
                    return MessageBubble(
                      message: message,
                      onLongPress: (pos) => _onLongPressMessage(message, pos),
                      onSenderTap: message.isSent
                          ? null
                          : () => context.push(
                                '/other-profile',
                                extra: ProfileArgs(
                                  username: message.senderName,
                                  communityName: widget.communityName,
                                ),
                              ),
                    );
                  },
                ),
              ),

              // ── Flagged banner ─────────────────────────────────────────
              if (_showFlaggedBanner)
                _FlaggedBanner(
                  onReviewRules: () => showDialog(
                    context: context,
                    builder: (_) => CommunityInfoModal(
                      community: CommunityModel(
                        name: widget.communityName,
                        description: '',
                        category: '',
                      ),
                    ),
                  ),
                ),

              // ── Ban banner ─────────────────────────────────────────────
              if (_isBanned && _banUntil != null)
                _BanBanner(banUntil: _banUntil!),

              // ── Input bar ──────────────────────────────────────────────
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

          // ── Dismissal barrier (shown when menu is open) ────────────────
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

          // ── Drop-down menu bar ─────────────────────────────────────────
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
              ),
            ),
        ],
      ),
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

/// Coral drop-down menu bar with Info / Mute / Leave options.
class _ChatMenuBar extends StatelessWidget {
  final bool muted;
  final VoidCallback onInfo;
  final VoidCallback onMute;
  final VoidCallback onLeave;

  const _ChatMenuBar({
    required this.muted,
    required this.onInfo,
    required this.onMute,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: AppSizes.chatMenuHeight,
      color: AppColors.primary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _MenuItem(
            icon: Icons.description_outlined,
            label: AppStrings.chatMenuInfo,
            onTap: onInfo,
          ),
          _MenuItem(
            // Filled icon = muted (active); outlined = not muted
            icon: muted ? Icons.notifications_off : Icons.notifications_off_outlined,
            label: muted ? AppStrings.chatMenuUnmute : AppStrings.chatMenuMute,
            onTap: onMute,
          ),
          _MenuItem(
            icon: Icons.exit_to_app,
            label: AppStrings.chatMenuLeave,
            onTap: onLeave,
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
          Icon(
            icon,
            color: AppColors.cardWhite,
            size: AppSizes.chatMenuIconSize,
          ),
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

/// Compact leave-confirmation dialog: white card, shadow, 16px radius.
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
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
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
                _DialogButton(
                  label: AppStrings.chatLeaveNo,
                  color: AppColors.commentBody,
                  onTap: onNo,
                ),
                _DialogButton(
                  label: AppStrings.chatLeaveYes,
                  color: AppColors.primary,
                  onTap: onYes,
                ),
              ],
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

/// Gray banner shown when Gemini flags a message as inappropriate.
class _FlaggedBanner extends StatelessWidget {
  final VoidCallback onReviewRules;
  const _FlaggedBanner({required this.onReviewRules});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.commentBody,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingXS,
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: AppTextStyles.body(
            fontSize: AppSizes.fontXXS,
            color: AppColors.textGray,
          ),
          children: [
            const TextSpan(
              text: 'Message failed to send. This content goes against\nour community standards. Repeated offenses will result in a ban.\n',
            ),
            WidgetSpan(
              child: GestureDetector(
                onTap: onReviewRules,
                child: Text(
                  'Review rules',
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontXXS,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sticky bar shown above the input bar when the user is temporarily banned.
/// Displays how long the restriction lasts; disables the input bar.
class _BanBanner extends StatelessWidget {
  final DateTime banUntil;

  const _BanBanner({required this.banUntil});

  String get _formattedDate {
    final d = banUntil;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    final mm = d.minute.toString().padLeft(2, '0');
    final ss = d.second.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year} $hour12:$mm:$ss $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: AppSizes.banBannerHeight),
      decoration: BoxDecoration(
        color: AppColors.banBannerBg,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingXS,
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: AppTextStyles.body(
            fontSize: AppSizes.fontXXS,
            fontWeight: FontWeight.w300,
            color: AppColors.textDark,
          ),
          children: [
            TextSpan(text: AppStrings.banText),
            TextSpan(
              text: _formattedDate,
              style: AppTextStyles.body(
                fontSize: AppSizes.fontXXS,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared dialog button: text with InkWell orange-circle highlight on tap.
class _DialogButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

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
