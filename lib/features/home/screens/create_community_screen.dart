import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/community_provider.dart';
import '../../../models/rule_model.dart';
import '../widgets/category_picker_popup.dart';
import '../widgets/interest_chip.dart';

/// "Host" screen — create a new community.
class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _nameController  = TextEditingController();
  final _aboutController = TextEditingController();
  final List<TextEditingController> _rulesControllers = [TextEditingController()];

  Uint8List? _coverImageBytes;
  String? _selectedCategory;

  String? _nameError;
  String? _aboutError;
  String? _categoryError;
  String? _rulesError;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_clearNameError);
    _aboutController.addListener(_clearAboutError);
    _rulesControllers.first.addListener(_clearRulesError);
  }

  void _clearNameError() {
    if (_nameError != null && _nameController.text.trim().isNotEmpty) {
      setState(() => _nameError = null);
    }
  }

  void _clearAboutError() {
    if (_aboutError != null && _aboutController.text.trim().isNotEmpty) {
      setState(() => _aboutError = null);
    }
  }

  void _clearRulesError() {
    if (_rulesError != null &&
        _rulesControllers.any((c) => c.text.trim().isNotEmpty)) {
      setState(() => _rulesError = null);
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
    final ctrl = TextEditingController();
    ctrl.addListener(_clearRulesError);
    setState(() => _rulesControllers.add(ctrl));
  }

  Future<void> _onCreate() async {
    final name  = _nameController.text.trim();
    final about = _aboutController.text.trim();
    final hasRule = _rulesControllers.any((c) => c.text.trim().isNotEmpty);

    setState(() {
      _nameError     = name.isEmpty     ? 'Please enter a community name'          : null;
      _aboutError    = about.isEmpty    ? 'Please tell us about your community'    : null;
      _categoryError = _selectedCategory == null ? 'Please select a category'     : null;
      _rulesError    = !hasRule         ? 'Please add at least one community rule' : null;
    });

    if (_nameError != null || _aboutError != null ||
        _categoryError != null || _rulesError != null) { return; }

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

    await context.read<CommunityProvider>().addCommunity(
          communityName: name,
          description: about,
          category: _selectedCategory != null ? [_selectedCategory!] : [],
          coverImageBytes: _coverImageBytes,
          rules: rules,
        );

    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.createBackground,
      body: Column(
        children: [
          _CreateAppBar(),

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
                      _CategoryEditRow(
                        selected: _selectedCategory,
                        onToggle: (cat) => setState(() {
                          _selectedCategory = _selectedCategory == cat ? null : cat;
                          if (_selectedCategory != null) _categoryError = null;
                        }),
                        errorText: _categoryError,
                      ),
                      const SizedBox(height: AppSizes.paddingM),

                      _RulesSection(
                        controllers: _rulesControllers,
                        onAddRule: _addRule,
                        errorText: _rulesError,
                      ),
                      const SizedBox(height: AppSizes.paddingXL),

                      Consumer<CommunityProvider>(
                        builder: (context, cp, child) => _CreateButton(
                          onPressed: cp.isLoading ? null : _onCreate,
                          isLoading: cp.isLoading,
                        ),
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
              AppStrings.createTitle,
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

        // Inner-shadow vignette: dark top/bottom edges, transparent centre
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
        errorText: errorText,
        errorStyle: AppTextStyles.poppins(
          fontSize: AppSizes.fontXS,
          color: Colors.red,
        ),
      ),
    );
  }
}

// ── Category row (single chip preview + popup) ────────────────────────────────

class _CategoryEditRow extends StatelessWidget {
  final String? selected;
  final void Function(String) onToggle;
  final String? errorText;

  const _CategoryEditRow({
    required this.selected,
    required this.onToggle,
    this.errorText,
  });

  void _openPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CategoryPickerPopup(
        selectedInterests: selected != null ? {selected!} : {},
        onToggle: onToggle,
        singleSelect: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSizes.paddingS,
          runSpacing: AppSizes.paddingS,
          children: [
            if (selected != null)
              InterestChip(
                label: selected!,
                selected: true,
                onTap: () => onToggle(selected!),
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
                  border: Border.all(color: AppColors.chipBorder),
                ),
                child: const Icon(Icons.add, size: 14, color: AppColors.textDark),
              ),
            ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: AppTextStyles.poppins(
              fontSize: AppSizes.fontXS,
              color: Colors.red,
            ),
          ),
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
          final i   = entry.key;
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
          Text(
            widget.errorText!,
            style: AppTextStyles.poppins(
              fontSize: AppSizes.fontXS,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Create button ─────────────────────────────────────────────────────────────

class _CreateButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  const _CreateButton({required this.onPressed, this.isLoading = false});

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
                  AppStrings.createButton,
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