import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryService {
  Future<List<String>> getCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('categories')
        .get();

    // ignore: avoid_print
    print('CategoryService: ${snapshot.docs.length} docs fetched');
    for (final doc in snapshot.docs) {
      // ignore: avoid_print
      print('  ${doc.id}: ${doc.data()}');
    }

    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          // try name → title → label in order
          return (data['name'] ?? data['title'] ?? data['label']) as String?;
        })
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toList();
  }
}
