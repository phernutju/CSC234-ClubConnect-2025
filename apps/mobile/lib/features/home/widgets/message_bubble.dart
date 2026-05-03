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
  /// Uses Uint8List (not File path) so it works on Flutter Web.
  final Uint8List? imageBytes;

  final bool isSent;       // true = current user's message (right side)
  final String senderName;
  final String time;       // displayed as "HH:mm"
  final String? readCount; // e.g. "Read 3" — only used for sent messages
  final String? replyToName; // sender name being replied to
  final String? replyToText; // text snippet of the message being replied to

  const ChatMessage({
    required this.id,
    required this.text,
    this.imageBytes,
    required this.isSent,
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
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final void Function(Offset globalPosition)? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: onLongPress == null
          ? null
          : (details) => onLongPress!(details.globalPosition),
      child: message.isSent
          ? _SentBubble(message: message)
          : _ReceivedBubble(message: message),
    );
  }
}

// ── Sent bubble (right-aligned) ───────────────────────────────────────────────

class _SentBubble extends StatelessWidget {
  final ChatMessage message;
  const _SentBubble({required this.message});

  // All corners 18, bottom-right 4 → tail pointing toward the sender
  static final _shape = BorderRadius.only(
    topLeft:     Radius.circular(AppSizes.radiusBubble),
    topRight:    Radius.circular(AppSizes.radiusBubble),
    bottomLeft:  Radius.circular(AppSizes.radiusBubble),
    bottomRight: Radius.circular(AppSizes.radiusBubbleTail),
  );

  @override
  Widget build(BuildContext context) {
    final isImage = message.imageBytes != null;
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // "Read N" + timestamp — Poppins Light coral, to the LEFT of the bubble
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

          // Bubble — clipBehavior clips the image to the bubble's border radius
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.65,
            ),
            // No padding for image-only messages so the image fills edge-to-edge
            padding: isImage && message.replyToName == null
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                    vertical: AppSizes.paddingS,
                  ),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.sentBubble,
              borderRadius: _shape,
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 4),
              ],
            ),
            child: _BubbleBody(message: message),
          ),
        ],
      ),
    );
  }
}

// ── Received bubble (left-aligned, with avatar) ───────────────────────────────

class _ReceivedBubble extends StatelessWidget {
  final ChatMessage message;
  const _ReceivedBubble({required this.message});

  // All corners 18, bottom-left 4 → tail pointing toward the receiver
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
        // Salmon avatar circle
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
            // Sender name — Inter Bold
            Text(
              message.senderName,
              style: AppTextStyles.body(
                fontSize: AppSizes.fontS,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Bubble
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

                // Timestamp — Poppins Light, coral
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

/// Renders the optional reply strip followed by the message content.
class _BubbleBody extends StatelessWidget {
  final ChatMessage message;
  const _BubbleBody({required this.message});

  @override
  Widget build(BuildContext context) {
    // Image-only (no reply) → image fills the bubble with no padding wrapper
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
              color: AppColors.textDark,
            ),
          ),
      ],
    );
  }
}

// ── Image content ─────────────────────────────────────────────────────────────

/// Displays image bytes using Image.memory() — works on Flutter Web and mobile.
/// Falls back to a grey placeholder if the bytes can't be decoded.
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
        // Show a grey placeholder if the bytes can't be decoded
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

/// 3 px coral left border + "↳ replying to Name" + optional quoted snippet.
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
          // "↳ replying to " Inter Light  +  "Name" Inter Bold
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
