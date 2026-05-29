import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import 'network_image_view.dart';

// ── Data model ────────────────────────────────────────────────────────────────

/// Holds all the data needed to render one chat message bubble.
class ChatMessage {
  final String id;
  final String text;

  /// Raw bytes of a locally-picked image (pre-upload). Non-null for optimistic display.
  final Uint8List? imageBytes;

  /// Download URL of an image stored in Firebase Storage.
  final String? imageUrl;

  final bool isSent;
  final String senderName;
  final String senderId;
  final String? senderPhotoUrl;
  final DateTime timestamp;
  final String time;
  final String? readCount;
  final String? replyToName;
  final String? replyToText;
  final bool isSystemMessage;
  final String type;
  final Map<String, String> mentionMap;

  const ChatMessage({
    required this.id,
    required this.text,
    this.imageBytes,
    this.imageUrl,
    required this.isSent,
    required this.senderName,
    required this.senderId,
    this.senderPhotoUrl,
    required this.timestamp,
    required this.time,
    this.readCount,
    this.replyToName,
    this.replyToText,
    this.isSystemMessage = false,
    this.type = '',
    this.mentionMap = const {},
  });
}

// ── Public widget ─────────────────────────────────────────────────────────────

/// Renders the correct bubble variant and fires [onLongPress] with the global
/// tap position so the caller can anchor showMenu() next to the bubble.
/// [onSenderTap] fires when the user taps the avatar or name of a received
/// message — typically navigates to the sender's profile.
/// [onMentionTap] fires with the UID when a highlighted @mention is tapped.
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final void Function(Offset globalPosition)? onLongPress;
  final VoidCallback? onSenderTap;
  final void Function(String uid)? onMentionTap;

  const MessageBubble({
    super.key,
    required this.message,
    this.onLongPress,
    this.onSenderTap,
    this.onMentionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystemMessage) {
      return _SystemPill(
          type: message.type,
          senderName: message.senderName,
          fallbackText: message.text);
    }
    return GestureDetector(
      onLongPressStart: onLongPress == null
          ? null
          : (details) => onLongPress!(details.globalPosition),
      child: message.isSent
          ? _SentBubble(message: message, onMentionTap: onMentionTap)
          : _ReceivedBubble(
              message: message,
              onSenderTap: onSenderTap,
              onMentionTap: onMentionTap,
            ),
    );
  }
}

// ── System message pill (centered, LINE-style) ────────────────────────────────

String _systemText(String type, String senderName) {
  switch (type) {
    case 'joined':
      return '$senderName joined the group';
    case 'left':
      return '$senderName left the group';
    case 'kicked':
      return '$senderName was removed from the group';
    default:
      return '';
  }
}

class _SystemPill extends StatelessWidget {
  final String type;
  final String senderName;
  final String fallbackText;

  const _SystemPill({
    required this.type,
    required this.senderName,
    required this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    final label = _systemText(type, senderName).isNotEmpty
        ? _systemText(type, senderName)
        : fallbackText;
    if (label.isEmpty) return const SizedBox.shrink();
    return Center(
      child: Container(
        margin:
            const EdgeInsets.symmetric(vertical: AppSizes.systemPillMarginV),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.systemPillPadH,
          vertical: AppSizes.systemPillPadV,
        ),
        decoration: BoxDecoration(
          color: AppColors.systemPillBg,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        ),
        child: Text(
          label,
          style: AppTextStyles.body(
            fontSize: AppSizes.fontXS,
            color: AppColors.systemPillText,
          ),
        ),
      ),
    );
  }
}

// ── Sent bubble (right-aligned) ───────────────────────────────────────────────

class _SentBubble extends StatelessWidget {
  final ChatMessage message;
  final void Function(String uid)? onMentionTap;
  const _SentBubble({required this.message, this.onMentionTap});

  // All corners 18, bottom-right 4 → tail pointing toward the sender
  static final _shape = BorderRadius.only(
    topLeft: Radius.circular(AppSizes.radiusBubble),
    topRight: Radius.circular(AppSizes.radiusBubble),
    bottomLeft: Radius.circular(AppSizes.radiusBubble),
    bottomRight: Radius.circular(AppSizes.radiusBubbleTail),
  );

  @override
  Widget build(BuildContext context) {
    final isImage = message.imageBytes != null || message.imageUrl != null;
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
            child: _BubbleBody(message: message, onMentionTap: onMentionTap),
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
  final void Function(String uid)? onMentionTap;

  const _ReceivedBubble({
    required this.message,
    this.onSenderTap,
    this.onMentionTap,
  });

  // All corners 18, bottom-left 4 → tail pointing toward the receiver
  static final _shape = BorderRadius.only(
    topLeft: Radius.circular(AppSizes.radiusBubbleTail),
    topRight: Radius.circular(AppSizes.radiusBubble),
    bottomLeft: Radius.circular(AppSizes.radiusBubble),
    bottomRight: Radius.circular(AppSizes.radiusBubble),
  );

  @override
  Widget build(BuildContext context) {
    final isImage = message.imageBytes != null || message.imageUrl != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tappable avatar → other user profile
        GestureDetector(
          onTap: onSenderTap,
          child: _AvatarCircle(
            photoUrl: message.senderPhotoUrl,
            size: AppSizes.avatarSmall,
          ),
        ),
        const SizedBox(width: AppSizes.paddingS),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tappable sender name → other user profile
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
                  child: _BubbleBody(
                    message: message,
                    onMentionTap: onMentionTap,
                  ),
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

// ── Avatar circle (photo or salmon fallback) ──────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  final String? photoUrl;
  final double size;
  const _AvatarCircle({this.photoUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.avatarSalmon,
        ),
      );
    }
    return ClipOval(
      child: NetworkImageView(
        url: photoUrl,
        width: size,
        height: size,
      ),
    );
  }
}

// ── Bubble body (reply strip + text/image) ────────────────────────────────────

/// Renders the optional reply strip followed by the message content.
class _BubbleBody extends StatelessWidget {
  final ChatMessage message;
  final void Function(String uid)? onMentionTap;

  const _BubbleBody({required this.message, this.onMentionTap});

  bool get _hasImage => message.imageBytes != null || message.imageUrl != null;

  Widget _imageContent(BuildContext context) {
    if (message.imageBytes != null) {
      return _ImageContent(bytes: message.imageBytes!, context: context);
    }
    return _NetworkImageContent(url: message.imageUrl!, context: context);
  }

  /// Parses [text] for @mention patterns and returns a RichText with
  /// known @names highlighted in blue with a tap recognizer.
  Widget _buildText(String text, Color baseColor) {
    if (message.mentionMap.isEmpty) {
      return Text(text,
          style:
              AppTextStyles.body(fontSize: AppSizes.fontM, color: baseColor));
    }

    final spans = <TextSpan>[];
    final regex = RegExp(r'@(\w+)');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      final name = match.group(1)!;
      final uid = message.mentionMap[name];
      if (uid != null && onMentionTap != null) {
        final recognizer = TapGestureRecognizer()
          ..onTap = () => onMentionTap!(uid);
        spans.add(TextSpan(
          text: '@$name',
          style: const TextStyle(
              color: Color(0xFF2196F3), fontWeight: FontWeight.bold),
          recognizer: recognizer,
        ));
      } else {
        spans.add(TextSpan(text: '@$name'));
      }
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: AppTextStyles.body(fontSize: AppSizes.fontM, color: baseColor),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasImage && message.replyToName == null) {
      return _imageContent(context);
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
        if (_hasImage)
          _imageContent(context)
        else
          _buildText(message.text, AppColors.textDark),
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

// ── Network image content ─────────────────────────────────────────────────────

/// Displays an image from Firebase Storage via URL.
class _NetworkImageContent extends StatelessWidget {
  final String url;
  final BuildContext context;
  const _NetworkImageContent({required this.url, required this.context});

  @override
  Widget build(BuildContext ctx) {
    final targetWidth = MediaQuery.sizeOf(ctx).width * 0.6;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: AppSizes.chatImageMaxHeight),
      child: NetworkImageView(
        url: url,
        width: targetWidth,
        height: AppSizes.chatImageMaxHeight,
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
