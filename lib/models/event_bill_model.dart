import 'package:cloud_firestore/cloud_firestore.dart';

enum BillStatus { pending, partial, settled }

// ─────────────────────────────────────────────
// Embedded inside each participant doc as an array of maps
// ─────────────────────────────────────────────
class BillItem {
  final String name;
  final double amount;

  const BillItem({
    required this.name,
    required this.amount,
  });

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      name: map['name'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
    };
  }

  BillItem copyWith({String? name, double? amount}) {
    return BillItem(
      name: name ?? this.name,
      amount: amount ?? this.amount,
    );
  }
}

// ─────────────────────────────────────────────
// bills/{billId}/participants/{participantId}
// ─────────────────────────────────────────────
class BillParticipantModel {
  final String userId;
  final String userName;
  final String userAvatar;
  final bool isPaid;
  final DateTime? paidAt;
  final List<BillItem> items;

  const BillParticipantModel({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    this.isPaid = false,
    this.paidAt,
    this.items = const [],
  });

  /// Sum of all item amounts for this participant
  double get totalOwed => items.fold(0.0, (acc, i) => acc + i.amount);

  factory BillParticipantModel.fromMap(Map<String, dynamic> map, String id) {
    final rawItems = map['items'] as List<dynamic>? ?? [];
    return BillParticipantModel(
      userId: map['userId'] ?? id,
      userName: map['userName'] ?? '',
      userAvatar: map['userAvatar'] ?? '',
      isPaid: map['isPaid'] ?? false,
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
      items: rawItems
          .map((e) => BillItem.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory BillParticipantModel.fromFirestore(DocumentSnapshot doc) {
    return BillParticipantModel.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'isPaid': isPaid,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'items': items.map((i) => i.toMap()).toList(),
    };
  }

  BillParticipantModel copyWith({
    String? userId,
    String? userName,
    String? userAvatar,
    bool? isPaid,
    DateTime? paidAt,
    List<BillItem>? items,
  }) {
    return BillParticipantModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      items: items ?? this.items,
    );
  }
}

// ─────────────────────────────────────────────
// bills/{billId}
// ─────────────────────────────────────────────
class EventBillModel {
  final String id;
  final String title;
  final String description;
  final String createdBy; // hostId only
  final String qrImageUrl;
  final double totalAmount;
  final BillStatus status;
  final DateTime createdAt;

  /// Loaded separately from the participants subcollection
  final List<BillParticipantModel> participants;

  const EventBillModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.qrImageUrl,
    required this.totalAmount,
    this.status = BillStatus.pending,
    required this.createdAt,
    this.participants = const [],
  });

  double get paidAmount => participants
      .where((p) => p.isPaid)
      .fold(0.0, (acc, p) => acc + p.totalOwed);

  double get remainingAmount => totalAmount - paidAmount;

  bool get isSettled => status == BillStatus.settled;

  /// Derive status from participants list when loaded
  BillStatus get derivedStatus {
    if (participants.isEmpty) return status;
    final paidCount = participants.where((p) => p.isPaid).length;
    if (paidCount == 0) return BillStatus.pending;
    if (paidCount == participants.length) return BillStatus.settled;
    return BillStatus.partial;
  }

  factory EventBillModel.fromMap(Map<String, dynamic> map, String id) {
    return EventBillModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdBy'] ?? '',
      qrImageUrl: map['qrImageUrl'] ?? '',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: BillStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BillStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory EventBillModel.fromFirestore(DocumentSnapshot doc) {
    return EventBillModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'qrImageUrl': qrImageUrl,
      'totalAmount': totalAmount,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  EventBillModel copyWith({
    String? id,
    String? title,
    String? description,
    String? createdBy,
    String? qrImageUrl,
    double? totalAmount,
    BillStatus? status,
    DateTime? createdAt,
    List<BillParticipantModel>? participants,
  }) {
    return EventBillModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      qrImageUrl: qrImageUrl ?? this.qrImageUrl,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      participants: participants ?? this.participants,
    );
  }
}