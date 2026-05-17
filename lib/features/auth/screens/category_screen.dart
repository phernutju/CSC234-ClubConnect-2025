import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_constants.dart';
import '../../../services/category_service.dart';
import '../../home/widgets/interest_chip.dart';
import '../widgets/step_progress_bar.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/category_provider.dart';
import 'package:provider/provider.dart';

class CategoryScreen extends StatefulWidget {
  final String? displayName;

  const CategoryScreen({super.key, this.displayName});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final Set<String> _selected = {};
  late final Future<List<String>> _categoriesFuture =
      CategoryService().getApprovedCategories().map((list) => list.map((c) => c.name).toList()).first;

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
    context.push('/community-standards');
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
                child: FutureBuilder<List<String>>(
                  future: _categoriesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.paddingL),
                          child: Text(
                            'Could not load categories.\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body(color: AppColors.textGray),
                          ),
                        ),
                      );
                    }
                    final names = snapshot.data ?? [];
                    if (names.isEmpty) {
                      return Center(
                        child: Text(
                          'No categories found.\nCheck the "categories" collection and field name.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body(color: AppColors.textGray),
                        ),
                      );
                    }
                    return SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: names
                            .map((name) => InterestChip(
                                  label: name,
                                  selected: _selected.contains(name),
                                  onTap: () => _toggleCategory(name),
                                ))
                            .toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
