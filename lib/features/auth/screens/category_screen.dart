import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/profile_provider.dart';
import '../widgets/step_progress_bar.dart';

class CategoryScreen extends StatefulWidget {
  final String? displayName;

  const CategoryScreen({super.key, this.displayName});

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
    {'emoji': '🍳', 'label': 'Home cooking'},
    {'emoji': '🍷', 'label': 'Wine'},
    {'emoji': '🌿', 'label': 'Vegan'},
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
      } else {
        _selected.add(label);
      }
    });
  }

  void _onGetStarted() {
    // Format as "label emoji" to match AppStrings.interestOptions keys
    final interests = _selected.map((label) {
      final cat = _categories.firstWhere(
        (c) => c['label'] == label,
        orElse: () => {'emoji': '', 'label': label},
      );
      final emoji = cat['emoji']!;
      return emoji.isEmpty ? label : '$label $emoji';
    }).toSet();

    context.read<ProfileProvider>().saveInterests(interests);
    context.go('/home', extra: {'displayName': widget.displayName ?? ''});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _onGetStarted,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B4A),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              AppStrings.categoryGetStarted,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        minimum: const EdgeInsets.only(top: 16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              const StepProgressBar(currentStep: 4),
              const SizedBox(height: AppSizes.paddingL),

              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(Icons.arrow_back, color: AppColors.textDark),
              ),
              const SizedBox(height: AppSizes.paddingM),

              Text(
                AppStrings.categoryHeading,
                style: AppTextStyles.title(
                  fontSize: 36.0,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: AppSizes.paddingXS),

              Text(
                AppStrings.categorySubtitle,
                style: AppTextStyles.body(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),

              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final label    = cat['label']!;
                      final emoji    = cat['emoji']!;
                      final isActive = _selected.contains(label);
                      return _CategoryChip(
                        emoji: emoji,
                        label: label,
                        isSelected: isActive,
                        onTap: () => _toggleCategory(label),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF000000) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFFDDDDDD), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: GoogleFonts.roboto(fontSize: 15)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Text(
                '✓',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
