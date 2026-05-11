import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/community_model.dart';
import '../../../models/rule_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/community_provider.dart';
import '../../../services/storage_service.dart';

class EditCommunityScreen extends StatefulWidget {
  final CommunityModel community;

  const EditCommunityScreen({super.key, required this.community});

  @override
  State<EditCommunityScreen> createState() => _EditCommunityScreenState();
}

class _EditCommunityScreenState extends State<EditCommunityScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _aboutController;
  late final List<TextEditingController> _rulesControllers;

  Uint8List? _newCoverBytes;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.community.communityName);
    _aboutController =
        TextEditingController(text: widget.community.description);
    _rulesControllers = widget.community.rules.isEmpty
        ? [TextEditingController()]
        : widget.community.rules
            .map((r) => TextEditingController(text: r.text))
            .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    for (final c in _rulesControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _newCoverBytes = bytes);
    }
  }

  void _addRule() {
    setState(() => _rulesControllers.add(TextEditingController()));
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final rules = _rulesControllers
        .asMap()
        .entries
        .map((entry) => RuleModel(
              id: 'rule_${entry.key + 1}',
              text: entry.value.text.trim(),
              severity: 'medium',
            ))
        .where((r) => r.text.isNotEmpty)
        .toList();

    final data = <String, dynamic>{
      'communityName': name,
      'description': _aboutController.text.trim(),
      'rules': rules.map((r) => r.toJson()).toList(),
    };

    try {
      if (_newCoverBytes != null) {
        final url = await StorageService()
            .uploadCommunityImage(_newCoverBytes!, widget.community.id);
        data['coverImageURL'] = url;
      }

      if (!mounted) return;
      await context.read<CommunityProvider>().editCommunity(
            widget.community.id,
            data,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.editSnackbar)),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    }
  }

  /// Shows a confirmation dialog; deletes the community only if the user
  /// confirms. On success, navigates back to home.
  Future<void> _onDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => _DeleteConfirmDialog(
        communityName: widget.community.communityName,
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<CommunityProvider>().deleteCommunity(widget.community.id);
      if (!mounted) return;
      // Community no longer exists — return to home.
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.createBackground,
      body: Column(
        children: [
          _EditAppBar(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _EditCoverImageSection(
                  newBytes: _newCoverBytes,
                  existingUrl: widget.community.coverImageURL,
                  onTap: _pickCoverImage,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingL,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSizes.paddingM),
                      const _SectionLabel(label: AppStrings.createNameLabel),
                      _FormField(
                        controller: _nameController,
                        hint: AppStrings.createNameHint,
                        maxLength: 50,
                      ),
                      const SizedBox(height: AppSizes.paddingM),
                      const _SectionLabel(label: AppStrings.createAboutLabel),
                      _FormField(
                        controller: _aboutController,
                        hint: AppStrings.createAboutHint,
                        maxLength: 500,
                        maxLines: 4,
                      ),
                      const SizedBox(height: AppSizes.paddingM),
                      const _SectionLabel(
                          label: AppStrings.createCategoryLabel),
                      const SizedBox(height: AppSizes.paddingS),
                      _ReadOnlyCategoryChips(
                          categories: widget.community.category),
                      const SizedBox(height: AppSizes.paddingM),
                      _RulesSection(
                        controllers: _rulesControllers,
                        onAddRule: _addRule,
                      ),
                      const SizedBox(height: AppSizes.paddingXL),
                      Consumer<CommunityProvider>(
                        builder: (context, cp, _) {
                          final isHost = context.watch<AppAuthProvider>().user?.uid ==
                              widget.community.createdById;
                          return Row(
                            children: [
                              if (isHost) ...[
                                Expanded(
                                  child: _DeleteCommunityButton(
                                    onPressed: cp.isLoading ? null : _onDelete,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.paddingM),
                              ],
                              Expanded(
                                child: _SaveButton(
                                  onPressed: cp.isLoading ? null : _onSave,
                                  isLoading: cp.isLoading,
                                ),
                              ),
                            ],
                          );
                        },
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

// ── App bar ───────────────────────────────────────────────────────────────────

class _EditAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: AppSizes.paddingM,
        right: AppSizes.paddingM,
      ),
      child: SizedBox(
        height: AppSizes.appBarHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => context.pop(),
                child:
                    const Icon(Icons.arrow_back, color: AppColors.cardWhite),
              ),
            ),
            Text(
              AppStrings.editTitle,
              style: AppTextStyles.poppins(
                fontSize: AppSizes.fontTitle,
                fontWeight: FontWeight.w500,
                color: AppColors.cardWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cover image picker ────────────────────────────────────────────────────────

class _EditCoverImageSection extends StatelessWidget {
  final Uint8List? newBytes;
  final String existingUrl;
  final VoidCallback onTap;

  const _EditCoverImageSection({
    required this.newBytes,
    required this.existingUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageChild;
    if (newBytes != null) {
      imageChild = Image.memory(newBytes!, fit: BoxFit.cover);
    } else if (existingUrl.isNotEmpty) {
      imageChild = Image.network(
        existingUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: AppColors.inputFill),
      );
    } else {
      imageChild = Container(color: AppColors.inputFill);
    }

    return Stack(
      children: [
        SizedBox(
          height: AppSizes.coverImageHeight,
          width: double.infinity,
          child: imageChild,
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.coverShadowEdge,
                  Colors.transparent,
                  AppColors.coverShadowEdge,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: AppSizes.paddingS,
          right: AppSizes.paddingS,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardWhite,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 18,
                color: AppColors.textDark,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Form helpers ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.poppins(
        fontSize: AppSizes.fontML,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final int maxLines;

  const _FormField({
    required this.controller,
    required this.hint,
    required this.maxLength,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
          Text(
            '$currentLength/${maxLength ?? this.maxLength}',
            style: AppTextStyles.poppins(
              fontSize: AppSizes.fontXS,
              color: AppColors.textGray,
            ),
          ),
      style: AppTextStyles.poppins(
        fontSize: AppSizes.fontM,
        color: AppColors.textDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.poppins(
          fontSize: AppSizes.fontM,
          color: AppColors.fieldPlaceholder,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.fieldPlaceholder,
            width: AppSizes.fieldBorderWidth,
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.primary,
            width: AppSizes.fieldBorderWidth,
          ),
        ),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.fieldPlaceholder,
            width: AppSizes.fieldBorderWidth,
          ),
        ),
      ),
    );
  }
}

// ── Read-only category chips ──────────────────────────────────────────────────

class _ReadOnlyCategoryChips extends StatelessWidget {
  final List<String> categories;

  const _ReadOnlyCategoryChips({required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Text(
        'No category',
        style: AppTextStyles.poppins(
          fontSize: AppSizes.fontSM,
          color: AppColors.textGray,
        ),
      );
    }
    return Wrap(
      spacing: AppSizes.paddingS,
      runSpacing: AppSizes.paddingS,
      children: categories
          .map((cat) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                  vertical: AppSizes.paddingS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.chipSelected,
                  borderRadius: BorderRadius.circular(64),
                ),
                child: Text(
                  cat,
                  style: AppTextStyles.poppins(
                    fontSize: AppSizes.fontSM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.chipSelectedText,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ── Rules section ─────────────────────────────────────────────────────────────

class _RulesSection extends StatefulWidget {
  final List<TextEditingController> controllers;
  final VoidCallback onAddRule;

  const _RulesSection({required this.controllers, required this.onAddRule});

  @override
  State<_RulesSection> createState() => _RulesSectionState();
}

class _RulesSectionState extends State<_RulesSection> {
  final _iconKey = GlobalKey();
  OverlayEntry? _tooltipEntry;

  void _toggleTooltip() {
    if (_tooltipEntry != null) {
      _dismissTooltip();
      return;
    }
    final box = _iconKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);

    _tooltipEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _dismissTooltip,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: pos.dx + box.size.width + 6,
            top: pos.dy -
                (AppSizes.tooltipCardHeight - box.size.height) / 2,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: AppSizes.tooltipCardWidth,
                height: AppSizes.tooltipCardHeight,
                padding: const EdgeInsets.all(AppSizes.tooltipPadding),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  AppStrings.createRuleTooltip,
                  style: AppTextStyles.poppins(
                    fontSize: AppSizes.fontXS,
                    color: AppColors.reportAccent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_tooltipEntry!);
  }

  void _dismissTooltip() {
    _tooltipEntry?.remove();
    _tooltipEntry = null;
  }

  @override
  void dispose() {
    _dismissTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionLabel(label: AppStrings.createRulesLabel),
            const SizedBox(width: AppSizes.paddingXS),
            GestureDetector(
              key: _iconKey,
              onTap: _toggleTooltip,
              child: Icon(
                Icons.error_outline,
                size: AppSizes.tooltipIconSize,
                color: AppColors.reportAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.paddingS),
        ...widget.controllers.asMap().entries.map((entry) {
          final i = entry.key;
          final ctrl = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
            child: TextField(
              controller: ctrl,
              style: AppTextStyles.poppins(
                fontSize: AppSizes.fontM,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                hintText: '${i + 1}. ${AppStrings.createRulesHint}',
                hintStyle: AppTextStyles.poppins(
                  fontSize: AppSizes.fontM,
                  color: AppColors.fieldPlaceholder,
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.fieldPlaceholder,
                    width: AppSizes.fieldBorderWidth,
                  ),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: AppSizes.fieldBorderWidth,
                  ),
                ),
                border: const UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.fieldPlaceholder,
                    width: AppSizes.fieldBorderWidth,
                  ),
                ),
              ),
            ),
          );
        }),
        GestureDetector(
          onTap: widget.onAddRule,
          child: Text(
            AppStrings.createAddRule,
            style: AppTextStyles.poppins(
              fontSize: AppSizes.fontS,
              color: AppColors.textGray,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Save button ───────────────────────────────────────────────────────────────

class _DeleteCommunityButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _DeleteCommunityButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.createButtonHeight,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.cardWhite,
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusXL),
          ),
        ),
        child: Text(
          AppStrings.deleteCommunityButton,
          style: AppTextStyles.poppins(
            fontSize: AppSizes.fontTitle,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// Confirmation dialog shown before permanently deleting a community.
/// Returns [true] when the user taps "Delete", [false] / null on cancel.
class _DeleteConfirmDialog extends StatelessWidget {
  final String communityName;
  const _DeleteConfirmDialog({required this.communityName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSizes.rateModalRadius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSizes.paddingL,
          AppSizes.paddingL,
          AppSizes.paddingL,
          AppSizes.paddingM,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.deleteCommunityTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.poppins(
                fontSize: AppSizes.fontSM,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppSizes.paddingXS),
            Text(
              'This action is permanent. All chat history and member data for "$communityName" will be gone.',
              textAlign: TextAlign.center,
              style: AppTextStyles.poppins(
                fontSize: AppSizes.fontXS,
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: AppSizes.paddingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DialogButton(
                  label: AppStrings.deleteCommunityCancel,
                  color: AppColors.commentBody,
                  onTap: () => Navigator.of(context).pop(false),
                ),
                _DialogButton(
                  label: AppStrings.deleteCommunityConfirm,
                  color: AppColors.alertRed,
                  onTap: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable text button used inside dialogs.
class _DialogButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.dialogHighlight,
        highlightColor: AppColors.dialogHighlight,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingM,
            vertical: AppSizes.paddingS,
          ),
          child: Text(
            label,
            style: AppTextStyles.poppins(
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _SaveButton({required this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.createButtonHeight,
      width: double.infinity,
      child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.reportAccent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusXL),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.cardWhite,
                  ),
                )
              : Text(
                  AppStrings.editSaveButton,
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
