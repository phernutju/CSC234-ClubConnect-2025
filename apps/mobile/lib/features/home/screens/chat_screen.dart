import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_constants.dart';

/// Full-screen chat screen for a single community conversation.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Coral app bar ────────────────────────────────────────────────
          _ChatAppBar(),

          // ── Message list ─────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              children: [
                _DateSeparator(label: AppStrings.chatToday),
                const SizedBox(height: AppSizes.paddingM),

                _SentMessage(
                  text: 'Lorem ipsum dolor sit amet,',
                  time: '10:14',
                  readCount: 'Read 3',
                ),
                const SizedBox(height: AppSizes.paddingM),

                _ReceivedMessage(
                  senderName: 'Name1',
                  text: 'consectetuer adipiscing',
                  time: '10:14',
                ),
                const SizedBox(height: AppSizes.paddingM),

                _SentMessage(
                  text: 'elit. Aenean commodo ligula\neget dolor.',
                  time: '10:14',
                  readCount: 'Read 1',
                ),
                const SizedBox(height: AppSizes.paddingM),

                _ReceivedMessage(
                  senderName: 'Name',
                  text: 'Aenean massa',
                  time: '10:14',
                  replyingTo: 'Name1',
                ),
              ],
            ),
          ),

          // ── Message input bar ────────────────────────────────────────────
          _ChatInputBar(controller: _inputController),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _ChatAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: AppSizes.paddingM,
        right: AppSizes.paddingM,
        bottom: AppSizes.paddingM,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back, color: AppColors.cardWhite),
          ),
          const SizedBox(width: AppSizes.paddingM),

          Expanded(
            child: Text(
              'Community name (10)',
              style: AppTextStyles.title(
                fontSize: AppSizes.fontL,
                fontWeight: FontWeight.w600,
                color: AppColors.cardWhite,
              ),
            ),
          ),

          const Icon(Icons.menu, color: AppColors.cardWhite),
        ],
      ),
    );
  }
}

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

class _SentMessage extends StatelessWidget {
  final String text;
  final String time;
  final String readCount;

  const _SentMessage({
    required this.text,
    required this.time,
    required this.readCount,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$readCount  $time',
            style: AppTextStyles.body(
              fontSize: AppSizes.fontXS,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 4),

          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingM,
              vertical: AppSizes.paddingS,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 4),
              ],
            ),
            child: Text(
              text,
              style: AppTextStyles.body(
                fontSize: AppSizes.fontM,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceivedMessage extends StatelessWidget {
  final String senderName;
  final String text;
  final String time;
  final String? replyingTo;

  const _ReceivedMessage({
    required this.senderName,
    required this.text,
    required this.time,
    this.replyingTo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSizes.avatarSmall,
          height: AppSizes.avatarSmall,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.avatarSalmon,
          ),
        ),
        const SizedBox(width: AppSizes.paddingS),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              senderName,
              style: AppTextStyles.body(
                fontSize: AppSizes.fontS,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            if (replyingTo != null)
              Text(
                '↳ replying to $replyingTo',
                style: AppTextStyles.body(
                  fontSize: AppSizes.fontXS,
                  color: AppColors.textGray,
                ),
              ),
            const SizedBox(height: 4),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.55,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                    vertical: AppSizes.paddingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0A000000), blurRadius: 4),
                    ],
                  ),
                  child: Text(
                    text,
                    style: AppTextStyles.body(
                      fontSize: AppSizes.fontM,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  time,
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontXS,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;

  const _ChatInputBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        left: AppSizes.paddingM,
        right: AppSizes.paddingM,
        top: AppSizes.paddingS,
        bottom: MediaQuery.of(context).padding.bottom + AppSizes.paddingS,
      ),
      child: Row(
        children: [
          const Icon(Icons.add, color: AppColors.cardWhite, size: AppSizes.iconSize),
          const SizedBox(width: AppSizes.paddingS),

          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              ),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: AppStrings.chatInputHint,
                  hintStyle: AppTextStyles.body(color: AppColors.textGray),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                    vertical: 0,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.paddingS),

          const Icon(
            Icons.send,
            color: AppColors.cardWhite,
            size: AppSizes.iconSize,
          ),
        ],
      ),
    );
  }
}
