import 'package:cloud_firestore/cloud_firestore.dart';

enum SmartBillStatus { draft, published, settled }

/// Lightweight member reference stored inside a bill document.
class SmartBillMember {
  final String uid;
  final String name;
  final String avatarUrl;

  const SmartBillMember({
    required this.uid,
    required this.name,
    this.avatarUrl = '',
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory SmartBillMember.fromMap(Map<String, dynamic> m) => SmartBillMember(
        uid: m['uid']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        avatarUrl: m['avatarUrl']?.toString() ?? '',
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'avatarUrl': avatarUrl,
      };
}

/// bills/{billId}
class SmartBillModel {
  final String id;
  final String eventId;
  final String name;
  final String hostId;
  final String hostPromptPayQrUrl;
  final List<SmartBillMember> members;
  final double totalAmount;
  final SmartBillStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SmartBillModel({
    required this.id,
    this.eventId = '',
    required this.name,
    required this.hostId,
    this.hostPromptPayQrUrl = '',
    this.members = const [],
    this.totalAmount = 0,
    this.status = SmartBillStatus.draft,
    required this.createdAt,
    this.updatedAt,
  });

  factory SmartBillModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SmartBillModel(
      id: doc.id,
      eventId: d['eventId']?.toString() ?? '',
      name: d['name']?.toString() ?? '',
      hostId: d['hostId']?.toString() ?? '',
      hostPromptPayQrUrl: d['hostPromptPayQrUrl']?.toString() ?? '',
      members: (d['members'] as List<dynamic>? ?? [])
          .map((e) => SmartBillMember.fromMap(e as Map<String, dynamic>))
          .toList(),
      totalAmount: (d['totalAmount'] as num?)?.toDouble() ?? 0,
      status: SmartBillStatus.values.firstWhere(
        (s) => s.name == d['status'],
        orElse: () => SmartBillStatus.draft,
      ),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'eventId': eventId,
        'name': name,
        'hostId': hostId,
        'hostPromptPayQrUrl': hostPromptPayQrUrl,
        'members': members.map((m) => m.toMap()).toList(),
        'totalAmount': totalAmount,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  SmartBillModel copyWith({
    String? id,
    String? eventId,
    String? name,
    String? hostId,
    String? hostPromptPayQrUrl,
    List<SmartBillMember>? members,
    double? totalAmount,
    SmartBillStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      SmartBillModel(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        name: name ?? this.name,
        hostId: hostId ?? this.hostId,
        hostPromptPayQrUrl: hostPromptPayQrUrl ?? this.hostPromptPayQrUrl,
        members: members ?? this.members,
        totalAmount: totalAmount ?? this.totalAmount,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// bills/{billId}/items/{itemId}
class SmartBillItemModel {
  final String id;
  final String name;
  final double price;
  final List<String> payerIds;

  const SmartBillItemModel({
    required this.id,
    required this.name,
    required this.price,
    this.payerIds = const [],
  });

  int get payerCount => payerIds.isEmpty ? 1 : payerIds.length;
  double get pricePerPayer =>
      payerIds.isEmpty ? price : price / payerIds.length;

  factory SmartBillItemModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SmartBillItemModel(
      id: doc.id,
      name: d['name']?.toString() ?? '',
      price: (d['price'] as num?)?.toDouble() ?? 0,
      payerIds: List<String>.from(d['payerIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'price': price,
        'payerIds': payerIds,
        'payerCount': payerCount,
        'pricePerPayer': pricePerPayer,
      };

  SmartBillItemModel copyWith({
    String? id,
    String? name,
    double? price,
    List<String>? payerIds,
  }) =>
      SmartBillItemModel(
        id: id ?? this.id,
        name: name ?? this.name,
        price: price ?? this.price,
        payerIds: payerIds ?? this.payerIds,
      );
}


/// Embedded inside SmartPaymentModel.aiVerification
class AiVerificationResult {
  final double detectedAmount;
  final double expectedAmount;
  final bool recipientMatch;
  final String result; // 'match' | 'mismatch'
  final String reason;

  const AiVerificationResult({
    required this.detectedAmount,
    required this.expectedAmount,
    required this.recipientMatch,
    required this.result,
    this.reason = '',
  });

  bool get isMatch => result == 'match';

  factory AiVerificationResult.fromMap(Map<String, dynamic> m) =>
      AiVerificationResult(
        detectedAmount: (m['detectedAmount'] as num?)?.toDouble() ?? 0,
        expectedAmount: (m['expectedAmount'] as num?)?.toDouble() ?? 0,
        recipientMatch: (m['recipientMatch'] as bool?) ?? false,
        result: m['result']?.toString() ?? 'mismatch',
        reason: m['reason']?.toString() ?? '',
      );

  Map<String, dynamic> toMap() => {
        'detectedAmount': detectedAmount,
        'expectedAmount': expectedAmount,
        'recipientMatch': recipientMatch,
        'result': result,
        'reason': reason,
      };
}

/// bills/{billId}/payments/{userId}
class SmartPaymentModel {
  final String id;
  final String userId;
  final double amountDue;
  final String? receiptUrl;
  final String status; // 'pending' | 'verifying' | 'verified' | 'rejected'
  final AiVerificationResult? aiVerification;

  const SmartPaymentModel({
    required this.id,
    required this.userId,
    required this.amountDue,
    this.receiptUrl,
    this.status = 'pending',
    this.aiVerification,
  });

  factory SmartPaymentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SmartPaymentModel(
      id: doc.id,
      userId: d['userId']?.toString() ?? '',
      amountDue: (d['amountDue'] as num?)?.toDouble() ?? 0,
      receiptUrl: d['receiptUrl'] as String?,
      status: d['status']?.toString() ?? 'pending',
      aiVerification: d['aiVerification'] != null
          ? AiVerificationResult.fromMap(
              d['aiVerification'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'amountDue': amountDue,
        if (receiptUrl != null) 'receiptUrl': receiptUrl,
        'status': status,
        if (aiVerification != null)
          'aiVerification': aiVerification!.toMap(),
      };

  SmartPaymentModel copyWith({
    String? id,
    String? userId,
    double? amountDue,
    String? receiptUrl,
    String? status,
    AiVerificationResult? aiVerification,
  }) =>
      SmartPaymentModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        amountDue: amountDue ?? this.amountDue,
        receiptUrl: receiptUrl ?? this.receiptUrl,
        status: status ?? this.status,
        aiVerification: aiVerification ?? this.aiVerification,
      );
}
