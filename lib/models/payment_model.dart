import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String paymentId;
  final String billId;
  final String userId;
  final String displayName;
  final double amountDue;
  final String? receiptUrl;
  final PaymentStatus status;
  final AiVerification aiVerification;
  final DateTime? submittedAt;
  final DateTime updatedAt;

  const Payment({
    required this.paymentId,
    required this.billId,
    required this.userId,
    required this.displayName,
    required this.amountDue,
    this.receiptUrl,
    required this.status,
    required this.aiVerification,
    this.submittedAt,
    required this.updatedAt,
  });

  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Payment(
      paymentId: doc.id,
      billId: d['billId'] ?? '',
      userId: d['userId'] ?? '',
      displayName: d['displayName'] ?? '',
      amountDue: (d['amountDue'] ?? 0).toDouble(),
      receiptUrl: d['receiptUrl'],
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == d['status'], orElse: () => PaymentStatus.pending),
      aiVerification: AiVerification.fromMap(d['aiVerification'] ?? {}),
      submittedAt: d['submittedAt'] != null
          ? (d['submittedAt'] as Timestamp).toDate() : null,
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'billId': billId,
    'userId': userId,
    'displayName': displayName,
    'amountDue': amountDue,
    'receiptUrl': receiptUrl,
    'status': status.name,
    'aiVerification': aiVerification.toMap(),
    'submittedAt': submittedAt != null
        ? Timestamp.fromDate(submittedAt!) : null,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

enum PaymentStatus { pending, verifying, verified, rejected }

class AiVerification {
  final double? detectedAmount;
  final double expectedAmount;
  final bool? recipientMatch;
  final String? result;   // "match" | "mismatch" | null
  final DateTime? verifiedAt;

  const AiVerification({
    this.detectedAmount,
    required this.expectedAmount,
    this.recipientMatch,
    this.result,
    this.verifiedAt,
  });

  factory AiVerification.fromMap(Map<String, dynamic> m) => AiVerification(
    detectedAmount: m['detectedAmount']?.toDouble(),
    expectedAmount: (m['expectedAmount'] ?? 0).toDouble(),
    recipientMatch: m['recipientMatch'],
    result: m['result'],
    verifiedAt: m['verifiedAt'] != null
        ? (m['verifiedAt'] as Timestamp).toDate() : null,
  );

  Map<String, dynamic> toMap() => {
    'detectedAmount': detectedAmount,
    'expectedAmount': expectedAmount,
    'recipientMatch': recipientMatch,
    'result': result,
    'verifiedAt': verifiedAt != null
        ? Timestamp.fromDate(verifiedAt!) : null,
  };
}