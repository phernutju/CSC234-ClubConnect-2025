import 'package:cloud_firestore/cloud_firestore.dart';

class ContextMessage {
  final String name;
  final String message;
  final String time;
  final bool isReported;

  const ContextMessage({
    required this.name,
    required this.message,
    required this.time,
    required this.isReported,
  });
}

enum ReportStatus { pending, reviewed, resolved, dismissed }
enum ReportReason { hateSpeech, scam, harassment, threat, other }
enum ReportTargetType { message, post, user }
enum ReportSource { user, aiDetected, userAiDetected }

class ReportModel {
  final String reportId;
  final String reporterId;      // who submitted the report
  final String targetUserId;    // who got reported
  final String communityId;     // which chatroom/community
  final String messageId;       // reported message id
  final String messageText;     // snapshot of reported message text
  final ReportReason reason;
  final ReportTargetType targetType;
  final ReportSource source;
  final ReportStatus status;
  final String? description;    // optional note from reporter
  final String? reviewedBy;     // admin uid who handled it
  final DateTime? reviewedAt;   // when admin acted on it
  final DateTime createdAt;

  const ReportModel({
    required this.reportId,
    required this.reporterId,
    required this.targetUserId,
    required this.communityId,
    required this.messageId,
    required this.messageText,
    required this.reason,
    required this.targetType,
    required this.source,
    required this.status,
    this.description,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      reportId: map['reportId'] ?? '',
      reporterId: map['reporterId'] ?? '',
      targetUserId: map['targetUserId'] ?? '',
      communityId: map['communityId'] ?? '',
      messageId: map['messageId'] ?? '',
      messageText: map['messageText'] ?? '',
      reason: ReportReason.values.firstWhere(
        (e) => e.name == map['reason'],
        orElse: () => ReportReason.other,
      ),
      targetType: ReportTargetType.values.firstWhere(
        (e) => e.name == map['targetType'],
        orElse: () => ReportTargetType.message,
      ),
      source: ReportSource.values.firstWhere(
        (e) => e.name == (map['source'] as String).replaceAll('|', '_'),
        orElse: () => ReportSource.user,
      ),
      status: ReportStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReportStatus.pending,
      ),
      description: map['description'],
      reviewedBy: map['reviewedBy'],
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'reporterId': reporterId,
      'targetUserId': targetUserId,
      'communityId': communityId,
      'messageId': messageId,
      'messageText': messageText,
      'reason': reason.name,
      'targetType': targetType.name,
      'source': source.name,
      'status': status.name,
      'description': description,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt,
      'createdAt': createdAt,
    };
  }

  ReportModel copyWith({
    ReportStatus? status,
    String? reviewedBy,
    DateTime? reviewedAt,
  }) {
    return ReportModel(
      reportId: reportId,
      reporterId: reporterId,
      targetUserId: targetUserId,
      communityId: communityId,
      messageId: messageId,
      messageText: messageText,
      reason: reason,
      targetType: targetType,
      source: source,
      status: status ?? this.status,
      description: description,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt,
    );
  }
}
