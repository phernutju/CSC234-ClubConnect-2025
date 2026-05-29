import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/member_model.dart';
import '../../../providers/community_provider.dart';

void showMembersModal(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black45,
    barrierDismissible: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<CommunityProvider>(),
      child: const _MembersModal(),
    ),
  );
}

class _MembersModal extends StatefulWidget {
  const _MembersModal();

  @override
  State<_MembersModal> createState() => _MembersModalState();
}

class _MembersModalState extends State<_MembersModal> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cp = context.read<CommunityProvider>();
      for (final m in cp.members) {
        cp.fetchDisplayName(m.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CommunityProvider>();
    final members = cp.members;

    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.all(Radius.circular(AppSizes.rateModalRadius)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 460),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSizes.rateModalRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingM,
                AppSizes.paddingM,
                AppSizes.paddingS,
                AppSizes.paddingS,
              ),
              child: Row(
                children: [
                  Text(
                    AppStrings.chatMenuMembers,
                    style: AppTextStyles.poppins(
                      fontSize: AppSizes.fontSM,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingS),
                  Text(
                    '${members.length}',
                    style: AppTextStyles.poppins(
                      fontSize: AppSizes.fontSM,
                      color: AppColors.textGray,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: AppSizes.rateCloseButtonSize,
                      height: AppSizes.rateCloseButtonSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.inputFill,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),

            // ── Member list ───────────────────────────────────────────────
            Flexible(
              child: members.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingL),
                      child: Text(
                        AppStrings.membersEmpty,
                        style: AppTextStyles.body(color: AppColors.textGray),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.paddingS,
                      ),
                      itemCount: members.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: AppSizes.paddingM +
                            AppSizes.memberAvatarSize +
                            AppSizes.paddingS,
                        color: AppColors.divider,
                      ),
                      itemBuilder: (context, i) => _MemberTile(
                        member: members[i],
                        displayName: cp.displayNameOf(members[i].userId),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final MemberModel member;
  final String displayName;

  const _MemberTile({
    required this.member,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final name = displayName.isNotEmpty ? displayName : '…';
    final initial =
        (displayName.isNotEmpty) ? displayName[0].toUpperCase() : '?';
    final isAdmin = member.role == 'admin';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: AppSizes.memberAvatarSize,
            height: AppSizes.memberAvatarSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.profileHeaderStart,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppTextStyles.poppins(
                fontSize: AppSizes.fontSM,
                fontWeight: FontWeight.bold,
                color: AppColors.cardWhite,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.paddingS),

          // Display name
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(
                fontSize: AppSizes.fontSM,
                color: AppColors.textDark,
              ),
            ),
          ),

          // Admin badge
          if (isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingS,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              ),
              child: Text(
                AppStrings.memberRoleAdmin,
                style: AppTextStyles.poppins(
                  fontSize: AppSizes.fontXXS,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
