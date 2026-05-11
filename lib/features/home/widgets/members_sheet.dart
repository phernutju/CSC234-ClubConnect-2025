import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/member_model.dart';
import '../../../models/profile_args.dart';
import '../../../providers/community_provider.dart';

// Cycles through warm avatar tones so each member gets a distinct color
const List<Color> _kAvatarPalette = [
  Color(0xFFFFB199), // salmon
  Color(0xFFADD8E6), // soft blue
  Color(0xFFBBADD8), // lavender
  Color(0xFF8DD1A4), // mint
  Color(0xFFF7C59F), // peach
];

void showMembersBottomSheet(
  BuildContext context, {
  required String communityId,
  required String communityName,
  required String currentUid,
  required String creatorId,
  void Function(String)? onSystemMessage,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<CommunityProvider>(),
      child: _MembersSheet(
        communityId: communityId,
        communityName: communityName,
        currentUid: currentUid,
        creatorId: creatorId,
        onSystemMessage: onSystemMessage,
      ),
    ),
  );
}

// ── Sheet widget ──────────────────────────────────────────────────────────────

class _MembersSheet extends StatefulWidget {
  final String communityId;
  final String communityName;
  final String currentUid;
  final String creatorId;
  final void Function(String)? onSystemMessage;

  const _MembersSheet({
    required this.communityId,
    required this.communityName,
    required this.currentUid,
    required this.creatorId,
    this.onSystemMessage,
  });

  @override
  State<_MembersSheet> createState() => _MembersSheetState();
}

class _MembersSheetState extends State<_MembersSheet> {
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

  // Kick confirmation → provider call → toast
  Future<void> _confirmKick(String userId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _KickConfirmDialog(
        displayName: displayName,
        onCancel: () => Navigator.of(ctx).pop(false),
        onConfirm: () => Navigator.of(ctx).pop(true),
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<CommunityProvider>().kickMember(
          widget.communityId,
          userId,
        );

    if (mounted) {
      widget.onSystemMessage?.call('$displayName was removed from the group');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$displayName ${AppStrings.memberKickedToast}'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  // Close sheet → slide-in navigation to other-profile
  void _openProfile(MemberModel member, String displayName) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push('/other-profile', extra: ProfileArgs(
      userId: member.userId,
      username: displayName.isNotEmpty ? displayName : 'User',
      communityName: widget.communityName,
      communityId: widget.communityId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CommunityProvider>();
    final members = cp.members;

    final myRole = members
        .where((m) => m.userId == widget.currentUid)
        .map((m) => m.role)
        .fold<String>('user', (_, r) => r);
    final canKick = myRole == 'creator' || myRole == 'admin';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.memberLightBg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.memberSheetRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: AppSizes.paddingS),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.memberSheetHandle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingM,
              AppSizes.paddingM,
              AppSizes.paddingM,
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
                // Orange pill count badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                  child: Text(
                    '${members.length}',
                    style: AppTextStyles.poppins(
                      fontSize: AppSizes.fontXII,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cardWhite,
                    ),
                  ),
                ),
                const Spacer(),
                // X close button — rounded square
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: AppSizes.memberCloseBtnSize,
                    height: AppSizes.memberCloseBtnSize,
                    decoration: BoxDecoration(
                      color: AppColors.memberCloseBtnBg,
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    alignment: Alignment.center,
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

          // ── Member list ────────────────────────────────────────────────────
          Flexible(
            child: members.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingL),
                    child: Text(
                      AppStrings.membersEmpty,
                      style: AppTextStyles.body(
                        color: AppColors.memberRoleText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding:
                        const EdgeInsets.only(bottom: AppSizes.paddingL),
                    itemCount: members.length,
                    itemBuilder: (ctx, i) {
                      final member = members[i];
                      final name = cp.displayNameOf(member.userId);
                      final isAdmin = member.role == 'admin' ||
                          member.role == 'creator';
                      // Kick button shown only on non-admin members
                      // (admin rows have no kick button per spec)
                      final showKick = canKick &&
                          member.userId != widget.currentUid &&
                          !isAdmin;
                      return _MemberTile(
                        member: member,
                        displayName: name,
                        isAdmin: isAdmin,
                        showKickButton: showKick,
                        avatarColor:
                            _kAvatarPalette[i % _kAvatarPalette.length],
                        onKick: () => _confirmKick(
                          member.userId,
                          name.isNotEmpty ? name : 'This member',
                        ),
                        onTap: () => _openProfile(member, name),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Member tile ───────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  final MemberModel member;
  final String displayName;
  final bool isAdmin;
  final bool showKickButton;
  final Color avatarColor;
  final VoidCallback onKick;
  final VoidCallback onTap;

  const _MemberTile({
    required this.member,
    required this.displayName,
    required this.isAdmin,
    required this.showKickButton,
    required this.avatarColor,
    required this.onKick,
    required this.onTap,
  });

  String get _roleName {
    switch (member.role) {
      case 'creator':
        return AppStrings.memberRoleCreator;
      case 'admin':
        return AppStrings.memberRoleAdmin;
      default:
        return AppStrings.memberRoleMember;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = displayName.isNotEmpty ? displayName : '…';
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    // The row is split into two siblings so their tap areas never conflict:
    //   • Expanded GestureDetector — avatar + name + role → navigate to profile
    //   • Kick button GestureDetector — completely separate area → open modal
    return Container(
      decoration: BoxDecoration(
        color: isAdmin ? AppColors.memberAdminRowBg : AppColors.cardWhite,
        border: const Border(
          bottom: BorderSide(color: AppColors.memberRowDivider, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tappable profile area
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppSizes.paddingM,
                  top: AppSizes.paddingS + 2,
                  bottom: AppSizes.paddingS + 2,
                  right: showKickButton
                      ? AppSizes.paddingS
                      : AppSizes.paddingM,
                ),
                child: Row(
                  children: [
                    // Avatar + online dot (bottom-left)
                    Stack(
                      children: [
                        Container(
                          width: AppSizes.memberAvatarSize,
                          height: AppSizes.memberAvatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: avatarColor,
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
                        Positioned(
                          bottom: 1,
                          left: 1,
                          child: Container(
                            width: AppSizes.memberOnlineDotSize,
                            height: AppSizes.memberOnlineDotSize,
                            decoration: BoxDecoration(
                              color: AppColors.onlineDot,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isAdmin
                                    ? AppColors.memberAdminRowBg
                                    : AppColors.cardWhite,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSizes.paddingM),

                    // Name + role
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.body(
                                    fontSize: AppSizes.fontSM,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              if (isAdmin) ...[
                                const SizedBox(width: AppSizes.paddingXS),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusPill,
                                    ),
                                  ),
                                  child: Text(
                                    AppStrings.memberRoleAdmin,
                                    style: AppTextStyles.poppins(
                                      fontSize: AppSizes.fontXXS,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.cardWhite,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _roleName,
                            style: AppTextStyles.body(
                              fontSize: AppSizes.fontXXS,
                              color: AppColors.memberRoleText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Kick button — separate hit-test area (non-admin rows only)
          if (showKickButton)
            Padding(
              padding: const EdgeInsets.only(right: AppSizes.paddingM),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onKick,
                child: Container(
                  width: AppSizes.memberKickBtnSize,
                  height: AppSizes.memberKickBtnSize,
                  decoration: BoxDecoration(
                    color: AppColors.memberKickBtnBg,
                    borderRadius:
                        BorderRadius.circular(AppSizes.memberKickBtnRadius),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.person_remove_outlined,
                    color: AppColors.kickButton,
                    size: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Kick confirmation dialog ───────────────────────────────────────────────────

class _KickConfirmDialog extends StatelessWidget {
  final String displayName;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _KickConfirmDialog({
    required this.displayName,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusL)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Content ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingL,
                28,
                AppSizes.paddingL,
                AppSizes.paddingL,
              ),
              child: Column(
                children: [
                  // Soft pink circle — decorative, no icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.kickModalCircle,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingM),
                  Text(
                    AppStrings.kickConfirmTitle,
                    style: AppTextStyles.poppins(
                      fontSize: AppSizes.fontSM,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingS),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTextStyles.body(
                        fontSize: AppSizes.fontXII,
                        color: const Color(0xFFAAAAAA),
                      ),
                      children: [
                        const TextSpan(text: 'Remove '),
                        TextSpan(
                          text: displayName,
                          style: AppTextStyles.body(
                            fontSize: AppSizes.fontXII,
                            fontWeight: FontWeight.w600,
                            color: AppColors.kickModalNameGray,
                          ),
                        ),
                        const TextSpan(
                          text: " from this group? They won't be able to"
                              ' rejoin unless invited.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Horizontal divider ──────────────────────────────────────────
            const Divider(
                height: 1, thickness: 0.5, color: AppColors.divider),

            // ── Button row ──────────────────────────────────────────────────
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onCancel,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          AppStrings.kickConfirmNo,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.poppins(
                            fontSize: AppSizes.fontSM,
                            fontWeight: FontWeight.w500,
                            color: AppColors.kickModalNo,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(width: 0.5, color: AppColors.divider),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onConfirm,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          AppStrings.kickConfirmYes,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.poppins(
                            fontSize: AppSizes.fontSM,
                            fontWeight: FontWeight.w500,
                            color: AppColors.kickModalYes,
                          ),
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