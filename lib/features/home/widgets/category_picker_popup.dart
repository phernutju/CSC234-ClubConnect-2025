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
  late Set<String> _localSelected;
  late final Future<List<String>> _categoriesFuture;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _localSelected = Set<String>.from(widget.selectedInterests);
    _categoriesFuture = CategoryService()
        .getApprovedCategories()
        .map((list) => list.map((c) => c.name).toList())
        .first;
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggle(String name) {
    if (!_localSelected.contains(name) &&
        _localSelected.length >= 10 &&
        !widget.singleSelect) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can select up to 10 interests')),
      );
      return;
    }
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

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingL,
                AppSizes.paddingM,
                AppSizes.paddingL,
                AppSizes.paddingXS,
              ),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: AppSizes.paddingM),
                    const Icon(Icons.search,
                        color: AppColors.textGray, size: 18),
                    const SizedBox(width: AppSizes.paddingS),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search categories…',
                          hintStyle: AppTextStyles.body(
                            color: AppColors.textGray,
                            fontSize: AppSizes.fontM,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: AppTextStyles.body(fontSize: AppSizes.fontM),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () => _searchController.clear(),
                        child: const Padding(
                          padding: EdgeInsets.only(right: AppSizes.paddingS),
                          child: Icon(Icons.close,
                              color: AppColors.textGray, size: 16),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Category chips — built from Firestore data
            Expanded(
              child: FutureBuilder<List<String>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
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
                  final allNames = snapshot.data ?? [];
                  if (allNames.isEmpty) {
                    return Center(
                      child: Text(
                        'No categories found in Firestore.',
                        style: AppTextStyles.body(color: AppColors.textGray),
                      ),
                    );
                  }
                  final names = _searchQuery.isEmpty
                      ? allNames
                      : allNames
                          .where((n) => n.toLowerCase().contains(_searchQuery))
                          .toList();
                  if (names.isEmpty) {
                    return Center(
                      child: Text(
                        'No categories match "$_searchQuery".',
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
