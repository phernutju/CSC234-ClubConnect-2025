import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/category_model.dart';

class CategoryService {
  Future<List<CategoryModel>> getCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('categories')
        .get();
    debugPrint('CategoryService: got ${snapshot.docs.length} docs');
    for (final doc in snapshot.docs) {
      debugPrint('  doc ${doc.id}: ${doc.data()}');
    }
    return snapshot.docs
        .map((doc) => CategoryModel(
              id: doc.id,
              name: (doc.data()['name'] as String?) ?? '',
            ))
        .where((cat) => cat.name.isNotEmpty)
        .toList();
  }
}
