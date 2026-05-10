import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/event_model.dart';
import '../../../models/profile_args.dart';
import '../../../providers/auth_provider.dart';
import '../../home/widgets/message_bubble.dart';
import '../../home/widgets/message_input_bar.dart';
import '../../home/widgets/message_long_press_menu.dart';
import '../../home/widgets/report_message_modal.dart';

class EventChatScreen extends StatefulWidget {
  final EventModel event;
  final String memberCount;

  const EventChatScreen({
    super.key,
    required this.event,
    required this.memberCount,
  });

  @override
  State<EventChatScreen> createState() => _EventChatScreenState();
}

class _EventChatScreenState extends State<EventChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  ChatMessage? _replyingTo;
  bool _isSending = false;
  bool _muted = false;
  bool _menuOpen = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String get _title => widget.memberCount.isEmpty
      ? widget.event.title
      : '${widget.event.title} (${widget.memberCount})';

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  bool get _isHost {
    final uid = context.read<AppAuthProvider>().user?.uid ?? '';
    return uid.isNotEmpty && widget.event.createdById == uid;
  }

  // ── Send ──────────────────────────────────────────────────────────────────────

  void _sendText() {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    final replySnapshot = _replyingTo;
    _inputController.clear();
    setState(() {
      _isSending = true;
      _replyingTo = null;
    });

    final uid = context.read<AppAuthProvider>().user?.uid ?? '';
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isSent: true,
        senderName: 'You',
        senderId: uid,
        time: _formatTime(DateTime.now()),
        readCount: 'Read 0',
        replyToName: replySnapshot?.senderName,
        replyToText: replySnapshot?.text,
      ));
      _isSending = false;
    });
    _scrollToBottom();
  }

  void _sendImage(Uint8List bytes) {
    final uid = context.read<AppAuthProvider>().user?.uid ?? '';
    setState(() {
      _isSending = true;
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '',
        imageBytes: bytes,
        isSent: true,
        senderName: 'You',
        senderId: uid,
        time: _formatTime(DateTime.now()),
        readCount: 'Read 0',
      ));
      _isSending = false;
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

  // ── Long press ────────────────────────────────────────────────────────────────

  void _onLongPressMessage(ChatMessage message, Offset tapPosition) {
    showMessageMenu(
      context,
      message: message,
      tapPosition: tapPosition,
      onReply: () => setState(() => _replyingTo = message),
      onReport: () => showReportModal(
        context,
        reportedUsername: message.senderName,
        communityName: widget.event.title,
        messageSnippet: message.text,
      ),
    );
  }

  // ── Menu actions ──────────────────────────────────────────────────────────────

  void _onMute() {
    setState(() {
      _muted = !_muted;
      _menuOpen = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_muted
          ? AppStrings.chatMutedSnackbar
          : AppStrings.chatUnmutedSnackbar),
    ));
  }

  void _onInfo() {
    setState(() => _menuOpen = false);
    if (_isHost) {
      context.push('/edit-event', extra: widget.event);
    } else {
      showDialog(
        context: context,
        barrierColor: Colors.black45,
        barrierDismissible: true,
        builder: (_) => _EventInfoDialog(event: widget.event),
      );
    }
  }

  void _onBills() {
    setState(() => _menuOpen = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bills feature coming soon')),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.chatBackground,
      body: Stack(
        children: [
          Column(
            children: [
              _EventChatAppBar(
                title: _title,
                onMenuTap: () => setState(() => _menuOpen = !_menuOpen),
              ),
              if (_isSending)
                const LinearProgressIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.inputFill,
                ),
              Expanded(child: _buildMessageList()),
              MessageInputBar(
                controller: _inputController,
                onSend: _sendText,
                onImagePicked: _sendImage,
                replyToName: _replyingTo?.senderName,
                replyToText: _replyingTo?.text,
                onCancelReply: () => setState(() => _replyingTo = null),
              ),
            ],
          ),

          // Dismissal barrier
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

          // Drop-down menu
          if (_menuOpen)
            Positioned(
              top: statusBarHeight + AppSizes.appBarHeight,
              left: 0,
              right: 0,
              child: _EventMenuBar(
                muted: _muted,
                onMute: _onMute,
                onInfo: _onInfo,
                onBills: _onBills,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
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
      itemCount: _messages.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.paddingM),
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
                      userId: message.senderId,
                      username: message.senderName,
                      communityName: widget.event.title,
                    ),
                  ),
        );
      },
    );
  }
}

// ── App bar ────────────────────────────────────────────────────────────────────

class _EventChatAppBar extends StatelessWidget {
  final String title;
  final VoidCallback onMenuTap;

  const _EventChatAppBar({required this.title, required this.onMenuTap});

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

// ── Date separator ─────────────────────────────────────────────────────────────

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

// ── Drop-down menu bar ─────────────────────────────────────────────────────────

class _EventMenuBar extends StatelessWidget {
  final bool muted;
  final VoidCallback onMute;
  final VoidCallback onInfo;
  final VoidCallback onBills;

  const _EventMenuBar({
    required this.muted,
    required this.onMute,
    required this.onInfo,
    required this.onBills,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _MenuItem(
            icon: muted
                ? Icons.notifications_off
                : Icons.notifications_off_outlined,
            label: muted ? AppStrings.chatMenuUnmute : AppStrings.chatMenuMute,
            onTap: onMute,
          ),
          _MenuItem(
            icon: Icons.description_outlined,
            label: AppStrings.chatMenuInfo,
            onTap: onInfo,
          ),
          _MenuItem(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Bills',
            onTap: onBills,
          ),
        ],
      ),
    );
  }
}

// ── Menu item ──────────────────────────────────────────────────────────────────

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

// ── Event info dialog ──────────────────────────────────────────────────────────

class _EventInfoDialog extends StatelessWidget {
  final EventModel event;
  const _EventInfoDialog({required this.event});

  @override
  Widget build(BuildContext context) {
    final dateStr = event.formattedDateRange;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.coverImageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusM),
                ),
                child: Image.network(
                  event.coverImageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: GoogleFonts.poppins(
                      fontSize: AppSizes.fontML,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (event.hostName.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'by ${event.hostName}',
                      style: GoogleFonts.poppins(
                        fontSize: AppSizes.fontXS,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF837A7A),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSizes.paddingM),
                  _InfoRow(icon: Icons.calendar_month, text: dateStr),
                  if (event.location.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.paddingXS),
                    _InfoRow(icon: Icons.location_on, text: event.location),
                  ],
                  if (event.detail.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.paddingM),
                    Text(
                      event.detail,
                      style: GoogleFonts.poppins(
                        fontSize: AppSizes.fontXS,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSizes.paddingM),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(
                        'Close',
                        style: GoogleFonts.poppins(
                          fontSize: AppSizes.fontSM,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: AppSizes.fontXS,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
