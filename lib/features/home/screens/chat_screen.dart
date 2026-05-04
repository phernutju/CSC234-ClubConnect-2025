import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_constants.dart';
import '../../../models/profile_args.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_bar.dart';
import '../widgets/message_long_press_menu.dart';
import '../widgets/report_message_modal.dart';

/// Full-screen chat room for a single community conversation.
class ChatScreen extends StatefulWidget {
  final String communityName;

  /// Numeric member count shown in parentheses after the name.
  /// Empty string suppresses the parentheses.
  final String memberCount;

  const ChatScreen({
    super.key,
    required this.communityName,
    required this.memberCount,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  // TESTING ONLY - remove when DB connected
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'test_1',
      text: 'Hey! Anyone want to play badminton?',
      isSent: false,
      senderName: 'TestUser',
      time: '10:14',
    ),
    ChatMessage(
      id: 'test_2',
      text: "I'm in! Let's meet tomorrow",
      isSent: false,
      senderName: 'JohnDoe',
      time: '10:15',
    ),
  ];

  // When non-null, the user is in reply mode targeting this message
  ChatMessage? _replyingTo;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Current time formatted as "HH:mm" (used as the timestamp on new messages).
  String get _nowTime {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _sendTextMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isSent: true,
        senderName: 'Me',
        time: _nowTime,
        readCount: 'Read 0',
        replyToName: _replyingTo?.senderName,
        replyToText: _replyingTo?.text,
      ));
      _replyingTo = null;
    });

    _inputController.clear();
    _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chatBackground,
      body: Column(
        children: [
          // ── App bar ──────────────────────────────────────────────────────
          _ChatAppBar(
            communityName: widget.communityName,
            memberCount: widget.memberCount,
          ),

          // ── Message list ─────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSizes.paddingM),
              itemCount: _messages.length + 1, // +1 for the date separator
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
                  // Tapping a received message's avatar/name → other user profile
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

          // ── Input bar (+ reply preview when replying) ────────────────────
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
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

/// Coral app bar: back arrow, community name + member count, hamburger menu.
class _ChatAppBar extends StatelessWidget {
  final String communityName;
  final String memberCount;

  const _ChatAppBar({
    required this.communityName,
    required this.memberCount,
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

            const Icon(Icons.menu, color: AppColors.cardWhite),
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
