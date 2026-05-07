import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_constants.dart';
import '../widgets/step_progress_bar.dart';
import '../widgets/primary_button.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/category_provider.dart';
import 'package:provider/provider.dart';

/// Step 4 of 4: user picks up to 3 interest categories.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final Set<String> _selected = {};

  void _toggleCategory(String label) {
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else if (_selected.length < 3) {
        _selected.add(label);
      }
    });
  }

  Future<void> _onGetStarted() async {
    final tags = _selected.toList();
    final provider = context.read<AppAuthProvider>();
    provider.setInterests(tags);
    await provider.signUp();
    if (!mounted) return;
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
                child: Consumer<CategoryProvider>(
                  builder: (context, catProvider, _) {
                    if (catProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    print(catProvider.error);
                    if (catProvider.error != null) {
                      return Center(
                        child: Text(
                          'Failed to load categories',
                          style: AppTextStyles.body(color: AppColors.textGray),
                        ),
                      );
                    }
                    return _CategoryChipGrid(
                      categories: catProvider.approvedCategories
                          .map((c) => c.name)
                          .toList(),
                      selected: _selected,
                      onTap: _toggleCategory,
                    );
                  },
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
  final List<String> categories;
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
        children: categories.map((label) {
          return _CategoryChip(
            label: label,
            isSelected: selected.contains(label),
            onTap: () => onTap(label),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
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
