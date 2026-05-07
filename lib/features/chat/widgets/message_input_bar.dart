import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants/app_constants.dart';

/// Bottom input bar: "+" image button, pill text field, and send button.
///
/// When [replyToName] is non-null, a reply preview strip is shown above the
/// coral bar so the user knows what message they are replying to.
class MessageInputBar extends StatefulWidget {
  final TextEditingController controller;

  /// Called when the user taps the send button with non-empty text.
  final VoidCallback onSend;

  /// Called with the raw bytes after the user picks an image.
  final void Function(Uint8List bytes) onImagePicked;

  /// Set when the user is replying to a message; shows the preview strip.
  final String? replyToName;
  final String? replyToText;

  /// Called when the user taps the ✕ on the reply preview strip.
  final VoidCallback? onCancelReply;

  /// When false, the text field and action buttons are disabled (e.g., user is banned).
  final bool enabled;

  const MessageInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onImagePicked,
    this.replyToName,
    this.replyToText,
    this.onCancelReply,
    this.enabled = true,
  });

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      widget.onImagePicked(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show placeholder when field is empty and not focused
    final showHint = !_focusNode.hasFocus && widget.controller.text.isEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reply preview strip — only visible when replying
        if (widget.replyToName != null)
          _ReplyPreviewBar(
            name: widget.replyToName!,
            text: widget.replyToText ?? '',
            onCancel: widget.onCancelReply ?? () {},
          ),

        // Main coral input row
        Container(
          color: AppColors.primary,
          padding: EdgeInsets.only(
            left: AppSizes.paddingM,
            right: AppSizes.paddingM,
            top: AppSizes.paddingS,
            bottom: MediaQuery.of(context).padding.bottom + AppSizes.paddingS,
          ),
          child: Row(
            children: [
              // "+" opens the system image gallery
              GestureDetector(
                onTap: widget.enabled ? _pickImage : null,
                child: Icon(
                  Icons.add,
                  color: widget.enabled
                      ? AppColors.cardWhite
                      : AppColors.cardWhite.withOpacity(0.4),
                  size: AppSizes.iconSize,
                ),
              ),
              const SizedBox(width: AppSizes.paddingS),

              // Pill-shaped text field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: showHint ? AppStrings.chatInputHint : null,
                      hintStyle: AppTextStyles.poppins(
                        fontSize: AppSizes.fontSM,
                        fontWeight: FontWeight.w300,
                        color: AppColors.fieldPlaceholder,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.paddingS),

              // Send button
              GestureDetector(
                onTap: widget.enabled ? widget.onSend : null,
                child: Icon(
                  Icons.send,
                  color: widget.enabled
                      ? AppColors.cardWhite
                      : AppColors.cardWhite.withOpacity(0.4),
                  size: AppSizes.iconSize,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Reply preview strip ───────────────────────────────────────────────────────

/// Shown above the input row while reply mode is active.
/// Displays the name and a snippet of the message being replied to.
class _ReplyPreviewBar extends StatelessWidget {
  final String name;
  final String text;
  final VoidCallback onCancel;

  const _ReplyPreviewBar({
    required this.name,
    required this.text,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // Slightly darker coral so the strip is visually distinct from the bar
    return Container(
      color: const Color(0xFFD06A4E),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingXS,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // "↳ replying to Name"
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '↳ replying to ',
                        style: AppTextStyles.body(
                          fontSize: AppSizes.fontXS,
                          fontWeight: FontWeight.w300,
                          color: AppColors.cardWhite,
                        ),
                      ),
                      TextSpan(
                        text: name,
                        style: AppTextStyles.body(
                          fontSize: AppSizes.fontXS,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cardWhite,
                        ),
                      ),
                    ],
                  ),
                ),
                // Quoted snippet
                Text(
                  text,
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontXS,
                    color: const Color(0xCCFFFFFF),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Cancel reply
          GestureDetector(
            onTap: onCancel,
            child: const Icon(
              Icons.close,
              color: AppColors.cardWhite,
              size: AppSizes.iconSize,
            ),
          ),
        ],
      ),
    );
  }
}
