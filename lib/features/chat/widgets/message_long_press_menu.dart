import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/app_constants.dart';
import 'message_bubble.dart';

enum _MenuAction { copy, reply, report, delete }

/// Shows a small compact popup menu (~94 × 77 px) anchored to [tapPosition].
/// Flutter's showMenu() auto-dismisses when the user taps outside — no barrier
/// overlay needed and no background dimming.
void showMessageMenu(
  BuildContext context, {
  required ChatMessage message,
  required Offset tapPosition,
  required VoidCallback onReply,
  required VoidCallback onReport,
  VoidCallback? onDelete,
}) {
  final screenSize = MediaQuery.sizeOf(context);

  // Anchor the popup's top-left corner at the tap point; Flutter flips it
  // automatically if it would overflow a screen edge.
  final position = RelativeRect.fromLTRB(
    tapPosition.dx,
    tapPosition.dy,
    screenSize.width - tapPosition.dx,
    screenSize.height - tapPosition.dy,
  );

  showMenu<_MenuAction>(
    context: context,
    position: position,
    color: AppColors.cardWhite,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusS),
    ),
    constraints: const BoxConstraints(
      minWidth: AppSizes.popupMenuWidth,
      maxWidth: AppSizes.popupMenuWidth,
    ),
    items: [
      // Copy
      PopupMenuItem<_MenuAction>(
        value: _MenuAction.copy,
        height: AppSizes.popupMenuItemHeight,
        padding: EdgeInsets.zero,
        child: const _MenuRow(
          icon: Icons.copy_outlined,
          label: AppStrings.chatCopy,
          color: AppColors.textDark,
        ),
      ),

      // Reply
      PopupMenuItem<_MenuAction>(
        value: _MenuAction.reply,
        height: AppSizes.popupMenuItemHeight,
        padding: EdgeInsets.zero,
        child: const _MenuRow(
          icon: Icons.reply_outlined,
          label: AppStrings.chatReply,
          color: AppColors.textDark,
        ),
      ),

      // Report — coral accent
      PopupMenuItem<_MenuAction>(
        value: _MenuAction.report,
        height: AppSizes.popupMenuItemHeight,
        padding: EdgeInsets.zero,
        child: const _MenuRow(
          icon: Icons.flag_outlined,
          label: AppStrings.chatReport,
          color: AppColors.reportAccent,
        ),
      ),

      // Delete — only shown to the message sender
      if (message.isSent && onDelete != null)
        PopupMenuItem<_MenuAction>(
          value: _MenuAction.delete,
          height: AppSizes.popupMenuItemHeight,
          padding: EdgeInsets.zero,
          child: const _MenuRow(
            icon: Icons.delete_outline,
            label: AppStrings.chatDelete,
            color: AppColors.alertRed,
          ),
        ),
    ],
  ).then((action) {
    if (action == null) return;
    switch (action) {
      case _MenuAction.copy:
        Clipboard.setData(ClipboardData(text: message.text));
      case _MenuAction.reply:
        onReply();
      case _MenuAction.report:
        onReport();
      case _MenuAction.delete:
        onDelete?.call();
    }
  });
}

// ── Single action row ─────────────────────────────────────────────────────────

/// Icon + label at Inter Medium 12 px, minimal padding to keep the popup compact.
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingS,
        vertical: AppSizes.paddingXS,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: AppSizes.popupMenuIconSize),
          const SizedBox(width: AppSizes.paddingXS),
          Text(
            label,
            style: AppTextStyles.body(
              fontSize: AppSizes.popupMenuFontSize,
              fontWeight: FontWeight.w500, // Inter Medium
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}