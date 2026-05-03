import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_constants.dart';
import '../../auth/widgets/primary_button.dart';

/// "Host" screen for creating a new community.
class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _nameController  = TextEditingController();
  final _aboutController = TextEditingController();
  final _rulesController = TextEditingController();

  String? _selectedCategory;

  static const List<String> _categories = [
    'Cooking',
    'Cooking',
    'Cooking',
    'Cooking',
    'Badminton',
    'Cooking',
    'Cooking',
    'Cooking',
    'Cooking',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  void _onCreate() {
    // TODO: submit form to backend and navigate back
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardWhite,
      body: Column(
        children: [
          // ── Coral app bar ────────────────────────────────────────────────
          _CreateAppBar(),

          // ── Scrollable form ──────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
              children: [
                _CoverImagePicker(),
                const SizedBox(height: AppSizes.paddingL),

                _FormSectionLabel(label: AppStrings.createNameLabel),
                _FormTextField(
                  controller: _nameController,
                  hint: AppStrings.createNameHint,
                  maxLength: 50,
                ),
                const SizedBox(height: AppSizes.paddingM),

                _FormSectionLabel(label: AppStrings.createAboutLabel),
                _FormTextField(
                  controller: _aboutController,
                  hint: AppStrings.createAboutHint,
                  maxLength: 500,
                  maxLines: 3,
                ),
                const SizedBox(height: AppSizes.paddingM),

                _FormSectionLabel(label: AppStrings.createCategoryLabel),
                const SizedBox(height: AppSizes.paddingS),
                _CategoryChipSelector(
                  categories: _categories,
                  selected: _selectedCategory,
                  onSelected: (c) => setState(() => _selectedCategory = c),
                ),
                const SizedBox(height: AppSizes.paddingM),

                _FormSectionLabel(label: AppStrings.createRulesLabel),
                _RulesInput(controller: _rulesController),
                const SizedBox(height: AppSizes.paddingXL),

                PrimaryButton(
                  label: AppStrings.createButton,
                  onPressed: _onCreate,
                ),
                const SizedBox(height: AppSizes.paddingXL),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _CreateAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: AppSizes.paddingM,
        right: AppSizes.paddingM,
        bottom: AppSizes.paddingM,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back, color: AppColors.cardWhite),
          ),
          const SizedBox(width: AppSizes.paddingM),
          Text(
            AppStrings.createTitle,
            style: AppTextStyles.title(
              fontSize: AppSizes.fontL,
              fontWeight: FontWeight.w600,
              color: AppColors.cardWhite,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverImagePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: AppSizes.coverImageHeight,
          width: double.infinity,
          color: AppColors.inputFill,
          child: const SizedBox(),
        ),

        Positioned(
          bottom: AppSizes.paddingS,
          right: AppSizes.paddingS,
          child: Container(
            padding: const EdgeInsets.all(AppSizes.paddingS),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardWhite,
            ),
            child: const Icon(
              Icons.camera_alt,
              size: 18,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _FormSectionLabel extends StatelessWidget {
  final String label;

  const _FormSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingXS),
      child: Text(
        label,
        style: AppTextStyles.body(
          fontSize: AppSizes.fontM,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}

class _FormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final int maxLines;

  const _FormTextField({
    required this.controller,
    required this.hint,
    this.maxLength = 100,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      style: AppTextStyles.body(fontSize: AppSizes.fontM, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body(color: AppColors.textGray),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary),
        ),
        counterStyle: AppTextStyles.body(
          fontSize: AppSizes.fontXS,
          color: AppColors.textGray,
        ),
      ),
    );
  }
}

class _CategoryChipSelector extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _CategoryChipSelector({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.paddingS,
      runSpacing: AppSizes.paddingS,
      children: categories.map((cat) {
        final isActive = cat == selected;
        return GestureDetector(
          onTap: () => onSelected(cat),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingM,
              vertical: AppSizes.paddingS,
            ),
            decoration: BoxDecoration(
              color: isActive ? AppColors.chipSelected : AppColors.cardWhite,
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              border: Border.all(
                color: isActive ? AppColors.chipSelected : AppColors.chipBorder,
              ),
            ),
            child: Text(
              cat,
              style: AppTextStyles.body(
                fontSize: AppSizes.fontS,
                color: isActive ? AppColors.chipSelectedText : AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RulesInput extends StatelessWidget {
  final TextEditingController controller;

  const _RulesInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          style: AppTextStyles.body(fontSize: AppSizes.fontM, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: AppStrings.createRulesHint,
            hintStyle: AppTextStyles.body(color: AppColors.textGray),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.paddingS),

        GestureDetector(
          onTap: () {
            // TODO: add additional rule fields dynamically
          },
          child: Text(
            AppStrings.createAddRule,
            style: AppTextStyles.body(
              fontSize: AppSizes.fontS,
              color: AppColors.textGray,
            ),
          ),
        ),
      ],
    );
  }
}
