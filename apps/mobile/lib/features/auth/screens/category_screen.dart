import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_constants.dart';
import '../widgets/step_progress_bar.dart';
import '../widgets/primary_button.dart';

/// Step 4 of 4: user picks up to 3 interest categories.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final Set<String> _selected = {};

  static const List<Map<String, String>> _categories = [
    {'emoji': '🏸', 'label': 'Badminton'},
    {'emoji': '🏃', 'label': 'Running'},
    {'emoji': '🥐', 'label': 'Baking'},
    {'emoji': '🧗', 'label': 'Climbing'},
    {'emoji': '🧘', 'label': 'Yoga'},
    {'emoji': '🚴', 'label': 'Cycling'},
    {'emoji': '⚽', 'label': 'Football'},
    {'emoji': '🔍', 'label': 'Home cooking'},
    {'emoji': '🍷', 'label': 'Wine'},
    {'emoji': '🥦', 'label': 'Vegan'},
    {'emoji': '💻', 'label': 'Coding'},
    {'emoji': '🚀', 'label': 'Startups'},
    {'emoji': '🔧', 'label': 'Hardware'},
    {'emoji': '✍️', 'label': 'Writing'},
    {'emoji': '🎨', 'label': 'Design'},
  ];

  void _toggleCategory(String label) {
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else if (_selected.length < 3) {
        _selected.add(label);
      }
    });
  }

  void _onGetStarted() {
    // TODO: save selected categories, then navigate to the main app
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.paddingM),

              // Step 4 of 4 — all segments filled
              const StepProgressBar(currentStep: 4),
              const SizedBox(height: AppSizes.paddingL),

              // Back arrow
              _BackButton(),
              const SizedBox(height: AppSizes.paddingM),

              // Page title
              Text(
                AppStrings.categoryHeading,
                style: AppTextStyles.title(color: AppColors.textDark),
              ),
              const SizedBox(height: AppSizes.paddingXS),

              // Subtitle
              Text(
                AppStrings.categorySubtitle,
                style: AppTextStyles.body(
                  fontSize: AppSizes.fontS,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),

              // Scrollable chip grid
              Expanded(
                child: _CategoryChipGrid(
                  categories: _categories,
                  selected: _selected,
                  onTap: _toggleCategory,
                ),
              ),

              const SizedBox(height: AppSizes.paddingM),

              // Get Started button
              PrimaryButton(
                label: AppStrings.categoryGetStarted,
                onPressed: _onGetStarted,
              ),
              const SizedBox(height: AppSizes.paddingXL),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: const Icon(Icons.arrow_back, color: AppColors.textDark),
    );
  }
}

class _CategoryChipGrid extends StatelessWidget {
  final List<Map<String, String>> categories;
  final Set<String> selected;
  final ValueChanged<String> onTap;

  const _CategoryChipGrid({
    required this.categories,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: AppSizes.paddingS,
        runSpacing: AppSizes.paddingS,
        children: categories.map((cat) {
          final label    = cat['label']!;
          final emoji    = cat['emoji']!;
          final isActive = selected.contains(label);
          return _CategoryChip(
            emoji: emoji,
            label: label,
            isSelected: isActive,
            onTap: () => onTap(label),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.chipSelected : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          border: Border.all(
            color: isSelected ? AppColors.chipSelected : AppColors.chipBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: AppTextStyles.body(fontSize: AppSizes.fontM)),
            const SizedBox(width: AppSizes.paddingXS),
            Text(
              label,
              style: AppTextStyles.body(
                fontSize: AppSizes.fontS,
                color: isSelected
                    ? AppColors.chipSelectedText
                    : AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: AppSizes.paddingXS),
              Text(
                '✓',
                style: AppTextStyles.body(
                  fontSize: AppSizes.fontS,
                  color: AppColors.chipSelectedText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
