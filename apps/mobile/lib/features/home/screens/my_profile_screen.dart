import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/rating_model.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/rating_provider.dart';
import '../widgets/interest_chip.dart';
import '../widgets/edit_profile_header.dart';
import '../widgets/view_all_reviews_modal.dart';

// ── File-scoped helpers ────────────────────────────────────────────────────────

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return AppStrings.rateJustNow;
  if (diff.inMinutes < 60) return '${diff.inMinutes}${AppStrings.rateMinAgo}';
  return '${diff.inHours}${AppStrings.rateHrAgo}';
}

String _ratingBody(RatingModel r) {
  if (r.comment.isNotEmpty) return r.comment;
  return '${'★' * r.stars}${'☆' * (5 - r.stars)}';
}

// ── Screen ─────────────────────────────────────────────────────────────────────

/// Profile screen for the current user — reached via the "You" bottom-nav tab.
/// Toggles between view mode and edit mode via the "Edit Profile" / "Save" button.
class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  // Only edit-mode transient state lives here; all persisted data is in ProfileProvider.
  bool _isEditing = false;
  Set<String> _editInterests = {}; // working copy while editing

  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// Pick avatar and persist immediately via provider (no Save required).
  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) context.read<ProfileProvider>().updateAvatar(bytes);
  }

  /// Pick cover photo and persist immediately via provider (no Save required).
  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) context.read<ProfileProvider>().updateCover(bytes);
  }

  void _enterEditMode() {
    final profile = context.read<ProfileProvider>();
    _usernameController.text = profile.username;
    _bioController.text = profile.bio;
    setState(() {
      _editInterests = Set.from(profile.selectedInterests);
      _isEditing = true;
    });
  }

  void _saveProfile() {
    final newName = _usernameController.text.trim();
    context.read<ProfileProvider>().saveProfile(
      username: newName.isEmpty ? 'Username' : newName,
      bio: _bioController.text.trim(),
      interests: _editInterests,
    );
    setState(() => _isEditing = false);
  }

  void _showViewAllModal(BuildContext context, List<RatingModel> ratings) {
    final username = context.read<ProfileProvider>().username;
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => ViewAllReviewsModal(
        username: username,
        ratings: ratings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final ratings = context
        .watch<RatingProvider>()
        .ratings
        .where((r) => r.ratedUsername == profile.username)
        .toList();

    final avgRating = ratings.isEmpty
        ? AppSizes.defaultRating
        : ratings.map((r) => r.stars).reduce((a, b) => a + b) / ratings.length;

    return Scaffold(
      backgroundColor: AppColors.cardWhite,
      body: Column(
        children: [
          _ProfileAppBar(title: profile.username),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Gradient/cover header — edit mode adds camera overlays
                if (_isEditing)
                  EditProfileHeader(
                    avatarBytes: profile.avatarBytes,
                    onAvatarTap: _pickAvatar,
                    coverBytes: profile.coverBytes,
                    onCoverTap: _pickCover,
                  )
                else
                  _ProfileHeader(
                    avatarBytes: profile.avatarBytes,
                    coverBytes: profile.coverBytes,
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _UserInfoRow(
                        username: profile.username,
                        avgRating: avgRating,
                        isEditing: _isEditing,
                        usernameController: _usernameController,
                        onEditTap: _enterEditMode,
                        onSaveTap: _saveProfile,
                      ),
                      const SizedBox(height: AppSizes.paddingL),

                      const _SectionLabel(AppStrings.profileAbout),
                      const SizedBox(height: AppSizes.paddingXS),
                      if (_isEditing)
                        _BioField(controller: _bioController)
                      else
                        Text(
                          profile.bio,
                          style: AppTextStyles.poppins(
                            fontSize: AppSizes.fontSM,
                            fontWeight: FontWeight.w300,
                            color: AppColors.commentBody,
                          ),
                        ),
                      const SizedBox(height: AppSizes.paddingL),

                      const _SectionLabel(AppStrings.profileInterests),
                      const SizedBox(height: AppSizes.paddingS),
                      if (_isEditing)
                        _InterestsGrid(
                          selectedInterests: _editInterests,
                          onToggle: (interest) => setState(() {
                            if (_editInterests.contains(interest)) {
                              _editInterests.remove(interest);
                            } else {
                              _editInterests.add(interest);
                            }
                          }),
                        )
                      else
                        _SelectedInterestsView(
                            selectedInterests: profile.selectedInterests),
                      const SizedBox(height: AppSizes.paddingL),

                      _CommentsSection(
                        ratings: ratings,
                        onViewAll: () => _showViewAllModal(context, ratings),
                      ),
                      const SizedBox(height: AppSizes.paddingXL),
                    ],
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

// ── Sub-widgets ────────────────────────────────────────────────────────────────

/// Coral app bar — back arrow shown only when there is navigation history.
class _ProfileAppBar extends StatelessWidget {
  final String title;

  const _ProfileAppBar({required this.title});

  @override
  Widget build(BuildContext context) {
    final canGoBack = context.canPop();
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: AppSizes.appBarHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: AppSizes.paddingM),
            if (canGoBack)
              GestureDetector(
                onTap: () => context.pop(),
                child:
                    const Icon(Icons.arrow_back, color: AppColors.cardWhite),
              )
            else
              const SizedBox(width: AppSizes.iconSize),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontTitle,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cardWhite,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.iconSize + AppSizes.paddingM),
          ],
        ),
      ),
    );
  }
}

/// Salmon-to-peach gradient band (or cover photo) with avatar circle.
/// View mode only — no camera overlays.
class _ProfileHeader extends StatelessWidget {
  final Uint8List? avatarBytes;
  final Uint8List? coverBytes;

  const _ProfileHeader({
    required this.avatarBytes,
    required this.coverBytes,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.profileHeaderHeight + AppSizes.avatarLarge / 2,
      child: Stack(
        children: [
          // Cover area — photo if selected, gradient otherwise
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: AppSizes.profileHeaderHeight,
              child: coverBytes != null
                  ? Image.memory(
                      coverBytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.profileHeaderStart,
                            AppColors.profileHeaderEnd,
                            AppColors.profileHeaderEnd,
                          ],
                          stops: [0.0, 0.44, 0.9],
                        ),
                      ),
                    ),
            ),
          ),

          // Avatar circle
          Positioned(
            left: AppSizes.paddingL,
            bottom: 0,
            child: Container(
              width: AppSizes.avatarLarge,
              height: AppSizes.avatarLarge,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.avatarSalmon,
                border: Border.all(color: AppColors.cardWhite, width: 3),
              ),
              clipBehavior: avatarBytes != null ? Clip.antiAlias : Clip.none,
              child: avatarBytes != null
                  ? Image.memory(avatarBytes!, fit: BoxFit.cover)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Username + star rating + Edit Profile / Save button.
/// In view mode: static text + outlined coral "Edit Profile" pill pushed to the right.
/// In edit mode: username TextField (Expanded) + star rating + green "Save" pill.
class _UserInfoRow extends StatelessWidget {
  final String username;
  final double avgRating;
  final bool isEditing;
  final TextEditingController usernameController;
  final VoidCallback onEditTap;
  final VoidCallback onSaveTap;

  const _UserInfoRow({
    required this.username,
    required this.avgRating,
    required this.isEditing,
    required this.usernameController,
    required this.onEditTap,
    required this.onSaveTap,
  });

  @override
  Widget build(BuildContext context) {
    // Flat Row: username · star · rating · [8px] · button, all left-aligned.
    // Flexible on username truncates long names without pushing the button off screen.
    // In edit mode, Expanded on the TextField bounds it to the remaining row width.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isEditing)
          Expanded(
            child: TextField(
              controller: usernameController,
              style: AppTextStyles.body(
                fontSize: AppSizes.fontTitle,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingS,
                  vertical: AppSizes.paddingXS,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          )
        else
          Flexible(
            child: Text(
              username,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: AppTextStyles.body(
                fontSize: AppSizes.fontTitle,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),

        const SizedBox(width: AppSizes.paddingXS),
        const Icon(Icons.star, color: AppColors.starColor, size: AppSizes.starIconSize),
        const SizedBox(width: 2),
        Text(
          avgRating.toStringAsFixed(1),
          style: AppTextStyles.body(
            fontSize: AppSizes.fontTitle,
            fontWeight: FontWeight.normal,
            color: AppColors.textDark,
          ),
        ),

        const SizedBox(width: AppSizes.paddingS),

        if (isEditing)
          GestureDetector(
            onTap: onSaveTap,
            child: Container(
              width: AppSizes.saveButtonWidth,
              height: AppSizes.saveButtonHeight,
              decoration: BoxDecoration(
                color: AppColors.saveButtonColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              ),
              alignment: Alignment.center,
              child: Text(
                AppStrings.profileSaveButton,
                style: AppTextStyles.body(fontSize: 12, color: AppColors.cardWhite),
              ),
            ),
          )
        else
          GestureDetector(
            onTap: onEditTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingM,
                vertical: AppSizes.paddingXS,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit, color: AppColors.primary, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    AppStrings.profileEditButton,
                    style: AppTextStyles.body(
                      fontSize: AppSizes.fontXS,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Section header label — Inter Light 16.
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.body(
        fontSize: AppSizes.fontML,
        fontWeight: FontWeight.w300,
        color: AppColors.textDark,
      ),
    );
  }
}

/// Multi-line bio text field shown in edit mode.
class _BioField extends StatelessWidget {
  final TextEditingController controller;

  const _BioField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      style: AppTextStyles.poppins(
        fontSize: AppSizes.fontSM,
        fontWeight: FontWeight.w300,
        color: AppColors.textDark,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.all(AppSizes.paddingS),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

/// Wrap of all 30 interest chips shown in edit mode.
class _InterestsGrid extends StatelessWidget {
  final Set<String> selectedInterests;
  final void Function(String) onToggle;

  const _InterestsGrid({
    required this.selectedInterests,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.paddingS,
      runSpacing: AppSizes.paddingS,
      children: AppStrings.interestOptions.map((interest) {
        return InterestChip(
          label: interest,
          selected: selectedInterests.contains(interest),
          onTap: () => onToggle(interest),
        );
      }).toList(),
    );
  }
}

/// View mode interests: shows selected chips as outlined pills.
/// Falls back to placeholder chips when nothing is selected yet.
class _SelectedInterestsView extends StatelessWidget {
  final Set<String> selectedInterests;

  const _SelectedInterestsView({required this.selectedInterests});

  @override
  Widget build(BuildContext context) {
    if (selectedInterests.isEmpty) {
      return Row(
        children: [
          const _PlaceholderChip(),
          const SizedBox(width: AppSizes.paddingS),
          const _PlaceholderChip(),
          const SizedBox(width: AppSizes.paddingS),
          Container(
            width: AppSizes.interestChipHeight,
            height: AppSizes.interestChipHeight,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(AppSizes.interestChipRadius),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: const Icon(Icons.add, size: 16, color: AppColors.textDark),
          ),
        ],
      );
    }

    return Wrap(
      spacing: AppSizes.paddingS,
      runSpacing: AppSizes.paddingS,
      children: selectedInterests.map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingM,
            vertical: AppSizes.paddingXS,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(AppSizes.interestChipRadius),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Text(
            interest,
            style: AppTextStyles.poppins(
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Empty rounded chip placeholder (view mode, no interests selected yet).
class _PlaceholderChip extends StatelessWidget {
  const _PlaceholderChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.interestChipWidth,
      height: AppSizes.interestChipHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.interestChipRadius),
        border: Border.all(color: AppColors.inputBorder),
      ),
    );
  }
}

/// Comments section — populated from [RatingProvider], empty until rated.
/// Shows up to 5 entries; tapping "view all (N)" opens [ViewAllReviewsModal].
class _CommentsSection extends StatelessWidget {
  final List<RatingModel> ratings;
  final VoidCallback onViewAll;

  const _CommentsSection({
    required this.ratings,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final preview = ratings.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.profileComments,
              style: AppTextStyles.body(
                fontSize: AppSizes.fontML,
                fontWeight: FontWeight.w300,
                color: AppColors.textDark,
              ),
            ),
            if (ratings.isNotEmpty)
              GestureDetector(
                onTap: onViewAll,
                child: Text(
                  '${AppStrings.profileViewAll} (${ratings.length})',
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontXXS,
                    fontWeight: FontWeight.w300,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.paddingS),

        if (ratings.isEmpty)
          Text(
            AppStrings.rateNoComments,
            style: AppTextStyles.body(
              fontSize: AppSizes.fontS,
              color: AppColors.textGray,
            ),
          )
        else
          ...preview.map((r) => _CommentRow(rating: r)),
      ],
    );
  }
}

/// One comment row built from a [RatingModel].
class _CommentRow extends StatelessWidget {
  final RatingModel rating;

  const _CommentRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
      padding: const EdgeInsets.only(left: AppSizes.paddingS),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppColors.primary,
            width: AppSizes.commentBorderWidth,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_relativeTime(rating.submittedAt)} · from ${rating.communityName}',
            style: AppTextStyles.body(
              fontSize: AppSizes.fontXXS,
              fontWeight: FontWeight.w300,
              color: AppColors.commentMeta,
            ),
          ),
          Text(
            _ratingBody(rating),
            style: AppTextStyles.body(
              fontSize: AppSizes.fontXXS,
              color: AppColors.commentBody,
            ),
          ),
        ],
      ),
    );
  }
}
