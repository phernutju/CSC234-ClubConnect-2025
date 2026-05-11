import 'package:cloud_firestore/cloud_firestore.dart';

class EventBill {
  final String billId;
  final String name;
  final String hostId;
  final String hostName;
  final String hostPromptPayQrUrl;
  final List<BillMember> members;
  final double totalAmount;
  final BillStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventBill({
    required this.billId,
    required this.name,
    required this.hostId,
    required this.hostName,
    required this.hostPromptPayQrUrl,
    required this.members,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventBill.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EventBill(
      billId: doc.id,
      name: d['name'] ?? '',
      hostId: d['hostId'] ?? '',
      hostName: d['hostName'] ?? '',
      hostPromptPayQrUrl: d['hostPromptPayQrUrl'] ?? '',
      members: (d['members'] as List? ?? [])
          .map((m) => BillMember.fromMap(m))
          .toList(),
      totalAmount: (d['totalAmount'] ?? 0).toDouble(),
      status: BillStatus.values.firstWhere(
        (e) => e.name == d['status'], orElse: () => BillStatus.draft),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'hostId': hostId,
    'hostName': hostName,
    'hostPromptPayQrUrl': hostPromptPayQrUrl,
    'memberIds': members.map((m) => m.uid).toList(),
    'members': members.map((m) => m.toMap()).toList(),
    'totalAmount': totalAmount,
    'status': status.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}

enum BillStatus { draft, published, settled }

class BillMember {
  final String uid;
  final String displayName;

  const BillMember({required this.uid, required this.displayName});

  factory BillMember.fromMap(Map<String, dynamic> m) =>
      BillMember(uid: m['uid'] ?? '', displayName: m['displayName'] ?? '');

  Map<String, dynamic> toMap() => {'uid': uid, 'displayName': displayName};
}