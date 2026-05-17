import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/review_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../services/category_service.dart';
import '../widgets/interest_chip.dart';
import '../widgets/edit_profile_header.dart';
import '../widgets/category_picker_popup.dart';
import '../widgets/view_all_reviews_modal.dart';

// ── File-scoped helpers ─────────────────────────
String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return AppStrings.rateJustNow;
  if (diff.inMinutes < 60) return '${diff.inMinutes}${AppStrings.rateMinAgo}';
  return '${diff.inHours}${AppStrings.rateHrAgo}';
}

String _reviewBody(ReviewModel r) {
  if (r.comment.isNotEmpty) return r.comment;
  final stars = r.score.clamp(0, 5).toInt();
  return '${'★' * stars}${'☆' * (5 - stars)}';
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
  bool _isEditing = false;
  Uint8List? _avatarBytes;
  Uint8List? _coverBytes;
  Set<String> _selectedInterests = {};

  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _loadData() {
    final uid = context.read<AppAuthProvider>().user?.uid;
    if (uid == null) return;
    final pp = context.read<ProfileProvider>();
    pp.loadProfile(uid);
    pp.loadReviews(uid);
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _avatarBytes = bytes);
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return; 
    final bytes = await picked.readAsBytes();
    setState(() => _coverBytes = bytes);
    if (mounted) await context.read<ProfileProvider>().updateCover(bytes);
  }

  void _enterEditMode() {
    final profile = context.read<ProfileProvider>().profile;
    _usernameController.text = profile?.displayName ?? '';
    _bioController.text = profile?.bio ?? '';
    setState(() {
      _selectedInterests = Set<String>.from(profile?.interests ?? []);
      _isEditing = true;
    });
  }

  void _saveProfile() {
    final uid = context.read<AppAuthProvider>().user?.uid;
    if (uid == null) return;
    context.read<ProfileProvider>().updateProfile(
      uid,
      {
        'displayName': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'interests': _selectedInterests.toList(),
      },
      avatarBytes: _avatarBytes,
    );
    setState(() => _isEditing = false);
  }

  void _showViewAllModal(BuildContext context, List<ReviewModel> reviews) {
    final name = context.read<ProfileProvider>().profile?.displayName ?? '';
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => ViewAllReviewsModal(username: name, reviews: reviews),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProfileProvider>();
    final profile = pp.profile;
    final reviews = pp.reviewsResult?.reviews ?? [];
    final avgRating = pp.reviewsResult?.averageScore ?? AppSizes.defaultRating;
    final displayName = profile?.displayName ?? 'Username';
    if (pp.isLoading && profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.cardWhite,
      body: Column(
        children: [
          _ProfileAppBar(
            title: displayName,
            isEditing: _isEditing,
            onBackTap: () => setState(() => _isEditing = false),
            onLogout: () async {
              await context.read<AppAuthProvider>().signOut();
            },
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (_isEditing)
                  EditProfileHeader(
                    avatarBytes: _avatarBytes,
                    onAvatarTap: _pickAvatar,
                    coverBytes: _coverBytes,
                    onCoverTap: _pickCover,
                    photoUrl: profile?.photoURL,
                  )
                else
                  _ProfileHeader(
                    avatarBytes: _avatarBytes,
                    coverBytes: _coverBytes,
                    coverBannerUrl: pp.coverBannerUrl,
                    photoURL: profile?.photoURL,
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingL,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _UserInfoRow(
                        username: displayName,
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
                          profile?.bio ?? '',
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
                        _InterestsEditRow(
                          selectedInterests: _selectedInterests,
                          onToggle: (interest) => setState(() {
                            if (_selectedInterests.contains(interest)) {
                              _selectedInterests.remove(interest);
                            } else {
                              _selectedInterests.add(interest);
                            }
                          }),
                        )
                      else
                        _SelectedInterestsView(
                          selectedInterests: Set<String>.from(
                            profile?.interests ?? [],
                          ),
                        ),
                      const SizedBox(height: AppSizes.paddingL),

                      _CommentsSection(
                        reviews: reviews,
                        onViewAll: () => _showViewAllModal(context, reviews),
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

class _ProfileAppBar extends StatelessWidget {
  final String title;
  final bool isEditing;
  final VoidCallback? onBackTap;
  final Future<void> Function()? onLogout;

  const _ProfileAppBar({
    required this.title,
    this.isEditing = false,
    this.onBackTap,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: AppSizes.appBarHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: AppSizes.paddingM),
            if (isEditing)
              GestureDetector(
                onTap: onBackTap,
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: AppColors.cardWhite,
                  size: AppSizes.iconSize,
                ),
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
            if (onLogout != null)
              GestureDetector(
                onTap: onLogout,
                child: const Padding(
                  padding: EdgeInsets.only(right: AppSizes.paddingM),
                  child: Icon(Icons.logout, color: AppColors.cardWhite),
                ),
              )
            else
              const SizedBox(width: AppSizes.iconSize + AppSizes.paddingM),
          ],
        ),
      ),
    );
  }
}

/// Gradient header (or cover photo) with avatar. View mode only.
/// Shows [photoURL] as a network image when no local bytes are selected.
class _ProfileHeader extends StatelessWidget {
  final Uint8List? avatarBytes;
  final Uint8List? coverBytes;
  final String? coverBannerUrl;
  final String? photoURL;

  const _ProfileHeader({
    required this.avatarBytes,
    required this.coverBytes,
    this.coverBannerUrl,
    this.photoURL,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar =
        avatarBytes != null || (photoURL != null && photoURL!.isNotEmpty);

    return SizedBox(
      height: AppSizes.profileHeaderHeight + AppSizes.avatarLarge / 2,
      child: Stack(
        children: [
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
                  : (coverBannerUrl != null && coverBannerUrl!.isNotEmpty)
                      ? Image.network(
                          coverBannerUrl!,
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
              clipBehavior: hasAvatar ? Clip.antiAlias : Clip.none,
              child: avatarBytes != null
                  ? Image.memory(avatarBytes!, fit: BoxFit.cover)
                  : (photoURL != null && photoURL!.isNotEmpty)
                      ? Image.network(
                          photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        )
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}

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
                  vertical: AppSizes.paddingXS,
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.inputBorder),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
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

        if (!isEditing) ...[
          const SizedBox(width: AppSizes.paddingXS),
          const Icon(
            Icons.star,
            color: AppColors.starColor,
            size: AppSizes.starIconSize,
          ),
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
        ],

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
                style: AppTextStyles.body(
                  fontSize: 12,
                  color: AppColors.cardWhite,
                ),
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
                  // Invisible text to prevent jitter when button text changes
                ],
              ),
            ),
          ),
      ],
    );
  }
}

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
        contentPadding: const EdgeInsets.symmetric(
          vertical: AppSizes.paddingS,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

/// Edit-mode interests row: shows first 3 selected chips + a "+" button.
/// Tapping a chip deselects it; tapping "+" opens the full category popup.
class _InterestsEditRow extends StatefulWidget {
  final Set<String> selectedInterests;
  final void Function(String) onToggle;

  const _InterestsEditRow({
    required this.selectedInterests,
    required this.onToggle,
  });

  @override
  State<_InterestsEditRow> createState() => _InterestsEditRowState();
}

class _InterestsEditRowState extends State<_InterestsEditRow> {
  late final Future<List<String>> _categoriesFuture =
      CategoryService().getApprovedCategories().map((list) => list.map((c) => c.name).toList()).first ;

  void _openPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CategoryPickerPopup(
        selectedInterests: widget.selectedInterests,
        onToggle: widget.onToggle,
      ),
    );
  }

  // Selected first, then fill remaining slots from unselected. Always 3 real names.
  List<String> _buildPreview(List<String> all) {
    final selected =
        all.where((c) => widget.selectedInterests.contains(c)).toList();
    final unselected =
        all.where((c) => !widget.selectedInterests.contains(c)).toList();
    return [...selected, ...unselected].take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        final preview = _buildPreview(snapshot.data ?? []);
        return Wrap(
          spacing: AppSizes.paddingS,
          runSpacing: AppSizes.paddingS,
          children: [
            ...preview.map(
              (cat) => InterestChip(
                label: cat,
                selected: widget.selectedInterests.contains(cat),
                onTap: () => widget.onToggle(cat),
              ),
            ),
            GestureDetector(
              onTap: () => _openPopup(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                  vertical: AppSizes.paddingXS,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.interestChipRadius),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: const Icon(Icons.add, size: 14, color: AppColors.textDark),
              ),
            ),
          ],
        );
      },
    );
  }
}

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
              borderRadius: BorderRadius.circular(AppSizes.interestChipRadius),
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
            borderRadius: BorderRadius.circular(AppSizes.interestChipRadius),
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

/// Comments section — populated from [ProfileProvider], empty until rated.
/// Shows up to 5 entries; tapping "view all (N)" opens [ViewAllReviewsModal].
class _CommentsSection extends StatelessWidget {
  final List<ReviewModel> reviews;
  final VoidCallback onViewAll;

  const _CommentsSection({required this.reviews, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final preview = reviews.take(5).toList();

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
            if (reviews.isNotEmpty)
              GestureDetector(
                onTap: onViewAll,
                child: Text(
                  '${AppStrings.profileViewAll} (${reviews.length})',
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

        if (reviews.isEmpty)
          Text(
            AppStrings.rateNoComments,
            style: AppTextStyles.body(
              fontSize: AppSizes.fontS,
              color: AppColors.textGray,
            ),
          )
        else
          ...preview.map((r) => _CommentRow(review: r)),
      ],
    );
  }
}

class _CommentRow extends StatelessWidget {
  final ReviewModel review;

  const _CommentRow({required this.review});

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
            '${_relativeTime(review.createdAt.toDate())} · from ${review.communityId}',
            style: AppTextStyles.body(
              fontSize: AppSizes.fontXXS,
              fontWeight: FontWeight.w300,
              color: AppColors.commentMeta,
            ),
          ),
          Text(
            _reviewBody(review),
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