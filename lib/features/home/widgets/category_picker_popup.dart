import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../models/category_model.dart';
import '../../../services/category_service.dart';
import 'interest_chip.dart';

/// Modal bottom sheet that fetches all categories from Firestore and lets
/// the user toggle interests. Each tap calls [onToggle] immediately so the
/// parent's state stays in sync without a separate "confirm" step.
class CategoryPickerPopup extends StatefulWidget {
  final Set<String> selectedInterests;

  /// Called with the category name each time the user taps a chip.
  /// Parent is responsible for add/remove logic in its own state.
  final void Function(String) onToggle;

  const CategoryPickerPopup({
    super.key,
    required this.selectedInterests,
    required this.onToggle,
  });

  @override
  State<CategoryPickerPopup> createState() => _CategoryPickerPopupState();
}

class _CategoryPickerPopupState extends State<CategoryPickerPopup> {
  // Local mirror of selected state so chip animations respond immediately
  // without waiting for the parent widget tree to rebuild.
  late Set<String> _localSelected;

  // Fetch categories once when the popup opens; reuse the same Future on rebuild.
  late final Future<List<CategoryModel>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _localSelected = Set<String>.from(widget.selectedInterests);
    // CategoryService maps each Firestore doc in the 'categories' collection
    // to a CategoryModel(id, name) — only docs with a non-empty 'name' field
    // are included.
    _categoriesFuture = CategoryService().getCategories();
  }

  void _toggle(String name) {
    setState(() {
      if (_localSelected.contains(name)) {
        _localSelected.remove(name);
      } else {
        _localSelected.add(name);
      }
    });
    // Propagate to parent immediately — parent calls setState to keep its
    // _selectedInterests and the 3-chip preview row in sync.
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
              child: FutureBuilder<List<CategoryModel>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // On Firestore error or empty collection, fall back to the
                  // hardcoded interest list so the user always sees options.
                  final List<String> names =
                      (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty)
                          ? AppStrings.interestOptions
                          : snapshot.data!.map((cat) => cat.name).toList();

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
