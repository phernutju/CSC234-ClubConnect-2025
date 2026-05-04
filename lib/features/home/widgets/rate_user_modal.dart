import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/profile_provider.dart';

/// Shows the rate-user modal centered over a dimmed overlay.
/// Call via:
///   showDialog(context: context, barrierColor: Colors.black45,
///              builder: (_) => RateUserModal(username: ..., communityName: ...))
class RateUserModal extends StatefulWidget {
  /// Name of the user being rated.
  final String username;

  /// Community the rater encountered this user in.
  final String communityName;

  const RateUserModal({
    super.key,
    required this.username,
    required this.communityName,
  });

  @override
  State<RateUserModal> createState() => _RateUserModalState();
}

class _RateUserModalState extends State<RateUserModal> {
  /// 0 = nothing selected yet, 1-5 = filled stars
  int _stars = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Saves the rating to [ProfileProvider] and closes the modal.
  void _onPost() {
    if (_stars == 0) return;
    context.read<ProfileProvider>().createReview(
      widget.username, // targetUserId
      communityId: 'dummy', // TODO: pass actual communityId
      score: _stars.toString(),
      comment: _commentController.text,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardWhite,
      // Remove default horizontal inset so our fixed width takes effect
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.rateModalRadius),
      ),
      child: SizedBox(
        width: AppSizes.rateModalWidth,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Modal content ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingM,
                AppSizes.paddingM + AppSizes.paddingXS,
                AppSizes.paddingM,
                AppSizes.paddingM,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ModalTitle(),
                  const SizedBox(height: AppSizes.paddingXS),
                  _ModalSubtitle(),
                  const SizedBox(height: AppSizes.paddingS + 2),
                  _UserInfoCard(
                    username: widget.username,
                    communityName: widget.communityName,
                  ),
                  const SizedBox(height: AppSizes.paddingS + 2),
                  _StarRow(
                    selected: _stars,
                    onSelect: (n) => setState(() => _stars = n),
                  ),
                  const SizedBox(height: AppSizes.paddingS + 2),
                  _CommentField(controller: _commentController),
                  const SizedBox(height: AppSizes.paddingM),
                  _PostButton(onTap: _onPost),
                ],
              ),
            ),

            // ── X close button (top-right corner) ──────────────────────────
            Positioned(
              top: AppSizes.paddingS,
              right: AppSizes.paddingS,
              child: _CloseButton(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

/// "What in [coral italic]Your mind?" title line.
class _ModalTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${AppStrings.rateModalTitle1} ',
            style: AppTextStyles.title(
              fontSize: AppSizes.fontTitle,
              fontWeight: FontWeight.normal,
              color: AppColors.textDark,
            ),
          ),
          TextSpan(
            text: AppStrings.rateModalTitle2,
            style: AppTextStyles.title(
              fontSize: AppSizes.fontTitle,
              fontWeight: FontWeight.normal,
              fontStyle: FontStyle.italic,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Your rating is anonymous." subtitle.
class _ModalSubtitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.rateModalAnonymous,
      style: AppTextStyles.body(
        fontSize: AppSizes.fontXXS,
        color: AppColors.commentBody,
      ),
    );
  }
}

/// Bordered card showing the avatar, username, and "from [community]".
class _UserInfoCard extends StatelessWidget {
  final String username;
  final String communityName;

  const _UserInfoCard({required this.username, required this.communityName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.rateUserCardWidth,
      height: AppSizes.rateUserCardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.rateStarBoxRadius),
        border: Border.all(color: AppColors.rateCardBorder),
      ),
      padding: const EdgeInsets.all(AppSizes.paddingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile avatar placeholder
          Container(
            width: AppSizes.rateUserAvatarSize,
            height: AppSizes.rateUserAvatarSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.profileHeaderStart,
            ),
          ),
          const SizedBox(width: AppSizes.paddingM),

          // Expanded prevents the text column from overflowing the card width
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontS,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingXS),
                Text(
                  'from $communityName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontS,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Row of 5 tappable star boxes. [selected] is 0 (none) to 5 (all filled).
class _StarRow extends StatelessWidget {
  final int selected;
  final void Function(int stars) onSelect;

  const _StarRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.rateUserCardWidth,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (i) {
          final filled = i < selected;
          return GestureDetector(
            onTap: () => onSelect(i + 1),
            child: Container(
              width: AppSizes.rateStarBoxSize,
              height: AppSizes.rateStarBoxSize,
              decoration: BoxDecoration(
                color: AppColors.rateStarFill,
                borderRadius: BorderRadius.circular(AppSizes.rateStarBoxRadius),
                border: Border.all(
                  color: AppColors.starColor,
                  width: AppSizes.fieldBorderWidth,
                ),
              ),
              child: Icon(
                Icons.star,
                size: AppSizes.rateStarIconSize,
                color: filled ? AppColors.starColor : AppColors.rateStarEmpty,
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// "Comments (optional)" label + single-line text input.
class _CommentField extends StatelessWidget {
  final TextEditingController controller;

  const _CommentField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.rateUserCardWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${AppStrings.profileComments} ',
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontML,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textDark,
                  ),
                ),
                TextSpan(
                  text: AppStrings.rateCommentOptional,
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontXXS,
                    fontWeight: FontWeight.w300,
                    color: AppColors.commentBody,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.paddingXS),

          // Single-line input
          SizedBox(
            height: AppSizes.rateCommentFieldHeight,
            child: TextField(
              controller: controller,
              maxLines: 1,
              style: AppTextStyles.poppins(
                fontSize: AppSizes.fontSM,
                fontWeight: FontWeight.w300,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                hintText: AppStrings.rateCommentHint,
                hintStyle: AppTextStyles.poppins(
                  fontSize: AppSizes.fontSM,
                  fontWeight: FontWeight.w300,
                  color: AppColors.fieldPlaceholder,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingS,
                  vertical: AppSizes.paddingS,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSizes.rateStarBoxRadius),
                  borderSide: const BorderSide(
                    color: AppColors.rateCardBorder,
                    width: AppSizes.fieldBorderWidth,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSizes.rateStarBoxRadius),
                  borderSide: const BorderSide(
                    color: AppColors.rateCardBorder,
                    width: AppSizes.fieldBorderWidth,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Coral pill "Post" button.
class _PostButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PostButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppSizes.ratePostButtonWidth,
        height: AppSizes.ratePostButtonHeight,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        ),
        alignment: Alignment.center,
        child: Text(
          AppStrings.ratePost,
          style: AppTextStyles.poppins(
            fontSize: AppSizes.fontTitle,
            fontWeight: FontWeight.w600,
            color: AppColors.cardWhite,
          ),
        ),
      ),
    );
  }
}

/// Coral circle X button — closes the dialog.
class _CloseButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: AppSizes.rateCloseButtonSize,
        height: AppSizes.rateCloseButtonSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
        ),
        child: const Icon(
          Icons.close,
          color: AppColors.cardWhite,
          size: 16,
        ),
      ),
    );
  }
}
