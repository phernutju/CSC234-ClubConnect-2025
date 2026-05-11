import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../services/category_service.dart';
import 'interest_chip.dart';

/// Modal bottom sheet that fetches all categories from Firestore and lets
/// the user toggle interests. Each tap calls [onToggle] immediately so the
/// parent's state stays in sync without a separate "confirm" step.
class CategoryPickerPopup extends StatefulWidget {
  final Set<String> selectedInterests;
  final void Function(String) onToggle;

  /// When true, selecting a chip deselects any previously selected chip.
  final bool singleSelect;

  const CategoryPickerPopup({
    super.key,
    required this.selectedInterests,
    required this.onToggle,
    this.singleSelect = false,
  });

  @override
  State<CategoryPickerPopup> createState() => _CategoryPickerPopupState();
}

class _CategoryPickerPopupState extends State<CategoryPickerPopup> {
  // Local mirror of selected state so chip animations respond immediately
  // without waiting for the parent widget tree to rebuild.
  late Set<String> _localSelected;

  late final Future<List<String>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _localSelected = Set<String>.from(widget.selectedInterests);
    _categoriesFuture = CategoryService().getApprovedCategories().map((list) => list.map((c) => c.name).toList()).first;
  }

  void _toggle(String name) {
    setState(() {
      if (_localSelected.contains(name)) {
        _localSelected.remove(name);
      } else {
        if (widget.singleSelect) _localSelected.clear();
        _localSelected.add(name);
      }
    });
    widget.onToggle(name);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingL,
                vertical: AppSizes.paddingXS,
              ),
              child: Row(
                children: [
                  Text(
                    AppStrings.profileInterests,
                    style: AppTextStyles.poppins(
                      fontSize: AppSizes.fontML,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppColors.textGray),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.divider),

            // Category chips — built from Firestore data
            Expanded(
              child: FutureBuilder<List<String>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
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
                        'No categories found in Firestore.',
                        style: AppTextStyles.body(color: AppColors.textGray),
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSizes.paddingL),
                    child: Wrap(
                      spacing: AppSizes.paddingS,
                      runSpacing: AppSizes.paddingS,
                      children: names
                          .map(
                            (name) => InterestChip(
                              label: name,
                              selected: _localSelected.contains(name),
                              onTap: () => _toggle(name),
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
