import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _service;

  List<CategoryModel> _approvedCategories = [];
  bool isLoading = false;
  String? error;
  StreamSubscription<List<CategoryModel>>? _subscription;

  CategoryProvider({CategoryService? service})
      : _service = service ?? CategoryService() {
    _listenToApproved();
  }

  List<CategoryModel> get approvedCategories =>
      List.unmodifiable(_approvedCategories);

  void _listenToApproved() {
    isLoading = true;
    _subscription = _service.getApprovedCategories().listen(
      (categories) {
        _approvedCategories = categories;
        isLoading = false;
        error = null;
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<List<CategoryModel>> getDefaultCategories() =>
      _service.getDefaultCategories();

  Future<void> createUserCategory(String name, String createdBy) =>
      _service.createUserCategory(name, createdBy);

  Future<void> incrementUsageCount(String categoryId) =>
      _service.incrementUsageCount(categoryId);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
