import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../models/community_model.dart';
import '../../../models/rule_model.dart';
import '../../../providers/community_provider.dart';
import '../../../providers/profile_provider.dart';

/// Shared screen for creating a new community (isEditMode = false)
/// and editing an existing one (isEditMode = true).
///
/// In edit mode, all fields are pre-filled from [existingCommunity],
/// the category chips are disabled, and the action button saves changes.
class CreateCommunityScreen extends StatefulWidget {
  final bool isEditMode;
  final CommunityModel? existingCommunity;

  const CreateCommunityScreen({
    super.key,
    this.isEditMode = false,
    this.existingCommunity,
  });

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _aboutController;
  late final List<TextEditingController> _rulesControllers;

  Uint8List? _coverImageBytes;
  String?    _selectedCategory;

  bool _submitted = false;

  // ── Computed error getters ─────────────────────────────────────────────────

  // Cover is only required when creating; in edit mode the existing cover is kept.
  String? get _coverError =>
      _submitted && !widget.isEditMode && _coverImageBytes == null
          ? AppStrings.createErrCover
          : null;

  String? get _nameError {
    if (!_submitted) return null;
    final v = _nameController.text.trim();
    return (v.isEmpty || v.length < AppSizes.createNameMinChars)
        ? AppStrings.createErrName
        : null;
  }

  String? get _aboutError {
    if (!_submitted) return null;
    final v = _aboutController.text.trim();
    return (v.isEmpty || v.length < AppSizes.createAboutMinChars)
        ? AppStrings.createErrAbout
        : null;
  }

  String? get _categoryError =>
      _submitted && _selectedCategory == null ? AppStrings.createErrCategory : null;

  String? get _rulesError {
    if (!_submitted) return null;
    final hasRule = _rulesControllers.any((c) => c.text.trim().isNotEmpty);
    return hasRule ? null : AppStrings.createErrRules;
  }

  bool get _isValid {
    final coverOk = widget.isEditMode || _coverImageBytes != null;
    return coverOk &&
        _nameController.text.trim().length >= AppSizes.createNameMinChars &&
        _aboutController.text.trim().length >= AppSizes.createAboutMinChars &&
        _selectedCategory != null &&
        _rulesControllers.any((c) => c.text.trim().isNotEmpty);
  }

  @override
  void initState() {
    super.initState();

    if (widget.isEditMode && widget.existingCommunity != null) {
      final c = widget.existingCommunity!;
      _nameController  = TextEditingController(text: c.name);
      _aboutController = TextEditingController(text: c.description);
      _coverImageBytes = c.coverImage;
      _selectedCategory = c.category;

      // Pre-fill one controller per existing rule (fall back to one empty field)
      final ruleTexts = c.rules.map((r) => r.title).toList();
      _rulesControllers = ruleTexts.isNotEmpty
          ? ruleTexts.map((t) => TextEditingController(text: t)).toList()
          : [TextEditingController()];
    } else {
      _nameController   = TextEditingController();
      _aboutController  = TextEditingController();
      _rulesControllers = [TextEditingController()];
    }

    // Rebuild on every keystroke so errors clear as soon as the field is filled
    _nameController.addListener(() => setState(() {}));
    _aboutController.addListener(() => setState(() {}));
    for (final ctrl in _rulesControllers) {
      ctrl.addListener(() => setState(() {}));
    }
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
      setState(() => _coverImageBytes = bytes);
    }
  }

  void _addRule() {
    final ctrl = TextEditingController()..addListener(() => setState(() {}));
    setState(() => _rulesControllers.add(ctrl));
  }

  List<RuleModel> get _buildRules => _rulesControllers
      .map((c) => c.text.trim())
      .where((r) => r.isNotEmpty)
      .map((text) => RuleModel(title: text))
      .toList();

  void _onCreate() {
    setState(() => _submitted = true);
    if (!_isValid) return;

    context.read<CommunityProvider>().addCommunity(CommunityModel(
      name: _nameController.text.trim(),
      description: _aboutController.text.trim(),
      category: _selectedCategory ?? '',
      coverImage: _coverImageBytes,
      rules: _buildRules,
      hostName: context.read<ProfileProvider>().username,
    ));

    context.go('/home');
  }

  void _onSave() {
    setState(() => _submitted = true);
    if (!_isValid) return;

    final original = widget.existingCommunity!;
    context.read<CommunityProvider>().updateCommunity(
      original.name,
      original.copyWith(
        name: _nameController.text.trim(),
        description: _aboutController.text.trim(),
        coverImage: _coverImageBytes ?? original.coverImage,
        rules: _buildRules,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.editSnackbar)),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEditMode;

    return Scaffold(
      backgroundColor: AppColors.createBackground,
      body: Column(
        children: [
          _CreateAppBar(
            title: isEdit ? AppStrings.editTitle : AppStrings.createTitle,
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _CoverImageSection(
                  imageBytes: _coverImageBytes,
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

                      if (_coverError != null) ...[
                        _ErrorText(_coverError!),
                        const SizedBox(height: AppSizes.paddingS),
                      ],

                      const _SectionLabel(label: AppStrings.createNameLabel),
                      _FormField(
                        controller: _nameController,
                        hint: AppStrings.createNameHint,
                        maxLength: 50,
                        errorText: _nameError,
                      ),
                      const SizedBox(height: AppSizes.paddingM),

                      const _SectionLabel(label: AppStrings.createAboutLabel),
                      _FormField(
                        controller: _aboutController,
                        hint: AppStrings.createAboutHint,
                        maxLength: 500,
                        maxLines: 4,
                        errorText: _aboutError,
                      ),
                      const SizedBox(height: AppSizes.paddingM),

                      const _SectionLabel(label: AppStrings.createCategoryLabel),
                      const SizedBox(height: AppSizes.paddingS),
                      _CategoryChips(
                        selected: _selectedCategory,
                        // Disabled in edit mode: category cannot be changed after creation
                        onSelected: isEdit
                            ? null
                            : (c) => setState(() => _selectedCategory = c),
                        errorText: _categoryError,
                      ),
                      const SizedBox(height: AppSizes.paddingM),

                      _RulesSection(
                        controllers: _rulesControllers,
                        onAddRule: _addRule,
                        errorText: _rulesError,
                      ),
                      const SizedBox(height: AppSizes.paddingXL),

                      _ActionButton(
                        onPressed: isEdit ? _onSave : _onCreate,
                        label: isEdit
                            ? AppStrings.editSaveButton
                            : AppStrings.createButton,
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

class _CreateAppBar extends StatelessWidget {
  final String title;
  const _CreateAppBar({required this.title});

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
                child: const Icon(Icons.arrow_back, color: AppColors.cardWhite),
              ),
            ),
            Text(
              title,
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

class _CoverImageSection extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onTap;

  const _CoverImageSection({required this.imageBytes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: AppSizes.coverImageHeight,
          width: double.infinity,
          child: imageBytes != null
              ? Image.memory(imageBytes!, fit: BoxFit.cover)
              : Container(color: AppColors.inputFill),
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
  final String? errorText;

  const _FormField({
    required this.controller,
    required this.hint,
    required this.maxLength,
    this.maxLines = 1,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
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
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          _ErrorText(errorText!),
        ],
      ],
    );
  }
}

// ── Category chips ────────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  final String? selected;

  /// Null when chips are disabled (edit mode — category cannot be changed).
  final ValueChanged<String>? onSelected;
  final String? errorText;

  const _CategoryChips({
    required this.selected,
    required this.onSelected,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSizes.paddingS,
          runSpacing: AppSizes.paddingS,
          children: AppStrings.createCategories.map((cat) {
            final isSelected = cat == selected;
            return GestureDetector(
              // null onTap disables interaction in edit mode
              onTap: onSelected != null ? () => onSelected!(cat) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                  vertical: AppSizes.paddingS,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.chipSelected : AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(64),
                  border: Border.all(
                    color: isSelected ? AppColors.chipSelected : AppColors.chipBorder,
                  ),
                ),
                child: Text(
                  cat,
                  style: AppTextStyles.poppins(
                    fontSize: AppSizes.fontSM,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.chipSelectedText
                        : AppColors.textDark,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          _ErrorText(errorText!),
        ],
      ],
    );
  }
}

// ── Rules section ─────────────────────────────────────────────────────────────

class _RulesSection extends StatefulWidget {
  final List<TextEditingController> controllers;
  final VoidCallback onAddRule;
  final String? errorText;

  const _RulesSection({
    required this.controllers,
    required this.onAddRule,
    this.errorText,
  });

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
            top: pos.dy - (AppSizes.tooltipCardHeight - box.size.height) / 2,
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
          final i    = entry.key;
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

        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          _ErrorText(widget.errorText!),
        ],
      ],
    );
  }
}

// ── Action button (Create / Save) ─────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const _ActionButton({required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: AppSizes.createButtonWidth,
        height: AppSizes.createButtonHeight,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.reportAccent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusXL),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.poppins(
              fontSize: AppSizes.fontTitle,
              fontWeight: FontWeight.w600,
              color: AppColors.cardWhite,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared error label ────────────────────────────────────────────────────────

class _ErrorText extends StatelessWidget {
  final String message;
  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: AppTextStyles.poppins(
        fontSize: AppSizes.fontXXS,
        color: AppColors.primary,
      ),
    );
  }
}
