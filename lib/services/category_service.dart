import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _col = 'categories';

  Stream<List<CategoryModel>> getApprovedCategories() {
    return _db
        .collection(_col)
        .where('isApproved', isEqualTo: true)
        .orderBy('usageCount', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CategoryModel.fromDoc).toList());
  }

  Future<List<CategoryModel>> getDefaultCategories() async {
    print("Fetching default categories...");
    final snap = await _db
        .collection(_col)
        .where('isDefault', isEqualTo: true)
        .get();
    return snap.docs.map(CategoryModel.fromDoc).toList();
  }

  Future<void> createUserCategory(String name, String createdBy) async {
    await _db.collection(_col).add({
      'name': name,
      'slug': CategoryModel.toSlug(name),
      'createdBy': createdBy,
      'isDefault': false,
      'isApproved': false,
      'usageCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> incrementUsageCount(String categoryId) async {
    await _db.collection(_col).doc(categoryId).update({
      'usageCount': FieldValue.increment(1),
    });
  }
}
