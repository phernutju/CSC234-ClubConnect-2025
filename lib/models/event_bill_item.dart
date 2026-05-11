import 'package:cloud_firestore/cloud_firestore.dart';

class BillItem {
  final String itemId;
  final String name;
  final double price;
  final List<String> payerIds;
  final int payerCount;
  final double pricePerPayer;

  const BillItem({
    required this.itemId,
    required this.name,
    required this.price,
    required this.payerIds,
    required this.payerCount,
    required this.pricePerPayer,
  });

  factory BillItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BillItem(
      itemId: doc.id,
      name: d['name'] ?? '',
      price: (d['price'] ?? 0).toDouble(),
      payerIds: List<String>.from(d['payerIds'] ?? []),
      payerCount: d['payerCount'] ?? 0,
      pricePerPayer: (d['pricePerPayer'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'price': price,
    'payerIds': payerIds,
    'payerCount': payerCount,
    'pricePerPayer': pricePerPayer,
    'createdAt': FieldValue.serverTimestamp(),
  };
}