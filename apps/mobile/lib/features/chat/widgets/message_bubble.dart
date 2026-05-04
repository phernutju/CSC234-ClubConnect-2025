import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

// ── Data model ────────────────────────────────────────────────────────────────

/// Holds all the data needed to render one chat message bubble.
class ChatMessage {
  final String id;
  final String text;

  /// Raw bytes of an image picked from the gallery.
  /// Non-null means this is an image message.
  final Uint8List? imageBytes;

  final bool isSent;        // true = current user's message (right side)
  final bool isFlagged;     // true = content was flagged by moderation
  final String senderName;
  final String time;        // displayed as "HH:mm"
  final String? readCount;  // e.g. "Read 3" — only used for sent messages
  final String? replyToName;
  final String? replyToText;

  const ChatMessage({
    required this.id,
    required this.text,
    this.imageBytes,
    required this.isSent,
    this.isFlagged = false,
    required this.senderName,
    required this.time,
    this.readCount,
    this.replyToName,
    this.replyToText,
  });
}

// ── Public widget ─────────────────────────────────────────────────────────────

/// Renders the correct bubble variant and fires [onLongPress] with the global
/// tap position so the caller can anchor showMenu() next to the bubble.
/// [onSenderTap] fires when the user taps the avatar or name of a received
/// message — typically navigates to the sender's profile.
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final void Function(Offset globalPosition)? onLongPress;
  final VoidCallback? onSenderTap;

  const MessageBubble({
    super.key,
    required this.message,
    this.onLongPress,
    this.onSenderTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: onLongPress == null
          ? null
          : (details) => onLongPress!(details.globalPosition),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          message.isSent
              ? _SentBubble(message: message)
              : _ReceivedBubble(message: message, onSenderTap: onSenderTap),
          if (message.isSent && message.isFlagged) ...[
            const SizedBox(height: 6),
            const Center(child: _WarningBox()),
          ],
        ],
      ),
    );
  }
}

// ── Sent bubble (right-aligned) ───────────────────────────────────────────────

class _SentBubble extends StatelessWidget {
  final ChatMessage message;

  const _SentBubble({required this.message});

  static final _shape = BorderRadius.only(
    topLeft:     Radius.circular(AppSizes.radiusBubble),
    topRight:    Radius.circular(AppSizes.radiusBubble),
    bottomLeft:  Radius.circular(AppSizes.radiusBubble),
    bottomRight: Radius.circular(AppSizes.radiusBubbleTail),
  );

  @override
  Widget build(BuildContext context) {
    final isImage    = message.imageBytes != null;
    final isFlagged  = message.isFlagged;

    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // "Read N" + timestamp to the left of the bubble
              if (message.readCount != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.readCount!,
                      style: AppTextStyles.poppins(
                        fontSize: AppSizes.fontXS,
                        fontWeight: FontWeight.w300,
                        color: AppColors.reportAccent,
                      ),
                    ),
                    Text(
                      message.time,
                      style: AppTextStyles.poppins(
                        fontSize: AppSizes.fontXS,
                        fontWeight: FontWeight.w300,
                        color: AppColors.reportAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
              ],

              // Bubble — red/pink when flagged, default colour otherwise
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.65,
                ),
                padding: isImage && message.replyToName == null
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingM,
                        vertical: AppSizes.paddingS,
                      ),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: isFlagged ? AppColors.flaggedBubble : AppColors.sentBubble,
                  borderRadius: _shape,
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 4),
                  ],
                ),
                child: _BubbleBody(
                  message: message,
                  textColor: isFlagged ? AppColors.cardWhite : null,
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }
}

// ── Received bubble (left-aligned, with avatar) ───────────────────────────────

class _ReceivedBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onSenderTap;

  const _ReceivedBubble({required this.message, this.onSenderTap});

  static final _shape = BorderRadius.only(
    topLeft:     Radius.circular(AppSizes.radiusBubbleTail),
    topRight:    Radius.circular(AppSizes.radiusBubble),
    bottomLeft:  Radius.circular(AppSizes.radiusBubble),
    bottomRight: Radius.circular(AppSizes.radiusBubble),
  );

  @override
  Widget build(BuildContext context) {
    final isImage = message.imageBytes != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onSenderTap,
          child: Container(
            width: AppSizes.avatarSmall,
            height: AppSizes.avatarSmall,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.avatarSalmon,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.paddingS),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onSenderTap,
              child: Text(
                message.senderName,
                style: AppTextStyles.body(
                  fontSize: AppSizes.fontS,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 4),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.55,
                  ),
                  padding: isImage && message.replyToName == null
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingM,
                          vertical: AppSizes.paddingS,
                        ),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: _shape,
                    boxShadow: const [
                      BoxShadow(color: Color(0x0A000000), blurRadius: 4),
                    ],
                  ),
                  child: _BubbleBody(message: message),
                ),
                const SizedBox(width: 4),

                Text(
                  message.time,
                  style: AppTextStyles.poppins(
                    fontSize: AppSizes.fontXS,
                    fontWeight: FontWeight.w300,
                    color: AppColors.reportAccent,
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

// ── Bubble body (reply strip + text/image) ────────────────────────────────────

class _BubbleBody extends StatelessWidget {
  final ChatMessage message;

  /// Override text color (used for flagged messages where text is white).
  final Color? textColor;

  const _BubbleBody({required this.message, this.textColor});

  @override
  Widget build(BuildContext context) {
    if (message.imageBytes != null && message.replyToName == null) {
      return _ImageContent(bytes: message.imageBytes!, context: context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.replyToName != null) ...[
          _ReplyStrip(
            name: message.replyToName!,
            snippet: message.replyToText,
          ),
          const SizedBox(height: 6),
        ],
        if (message.imageBytes != null)
          _ImageContent(bytes: message.imageBytes!, context: context)
        else
          Text(
            message.text,
            style: AppTextStyles.body(
              fontSize: AppSizes.fontM,
              color: textColor ?? AppColors.textDark,
            ),
          ),
      ],
    );
  }
}

// ── Warning box (shown below a flagged sent message) ──────────────────────────

class _WarningBox extends StatelessWidget {
  const _WarningBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.warningBoxWidth,
      constraints: const BoxConstraints(minHeight: AppSizes.warningBoxHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningBoxBg.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppSizes.warningBoxRadius),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: AppTextStyles.body(
            fontSize: AppSizes.fontXXS,
            fontWeight: FontWeight.w300,
            color: AppColors.primary,
          ),
          children: [
            TextSpan(text: AppStrings.warningText),
            TextSpan(
              text: AppStrings.warningReviewRules,
              style: AppTextStyles.body(
                fontSize: AppSizes.fontXXS,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ).copyWith(decoration: TextDecoration.underline),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Image content ─────────────────────────────────────────────────────────────

class _ImageContent extends StatelessWidget {
  final Uint8List bytes;
  final BuildContext context;
  const _ImageContent({required this.bytes, required this.context});

  @override
  Widget build(BuildContext ctx) {
    final targetWidth = MediaQuery.sizeOf(ctx).width * 0.6;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: AppSizes.chatImageMaxHeight),
      child: Image.memory(
        bytes,
        width: targetWidth,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: targetWidth,
          height: AppSizes.chatImageMaxHeight,
          color: AppColors.inputFill,
          child: const Icon(
            Icons.broken_image_outlined,
            color: AppColors.textGray,
            size: 40,
          ),
        ),
      ),
    );
  }
}

// ── Reply strip (inside bubble, above text) ───────────────────────────────────

class _ReplyStrip extends StatelessWidget {
  final String name;
  final String? snippet;

  const _ReplyStrip({required this.name, this.snippet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: AppSizes.paddingS,
        top: AppSizes.paddingXS,
        bottom: AppSizes.paddingXS,
      ),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.reportAccent, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '↳ replying to ',
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontXS,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textGray,
                  ),
                ),
                TextSpan(
                  text: name,
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontXS,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),

          if (snippet != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                snippet!,
                style: AppTextStyles.body(
                  fontSize: AppSizes.fontXS,
                  color: AppColors.textGray,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
