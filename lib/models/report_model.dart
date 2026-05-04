import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String reportId;
  final String reporterId;
  final String targetId;
  final String reason;
  final DateTime timestamp;

  const ReportModel({
    required this.reportId,
    required this.reporterId,
    required this.targetId,
    required this.reason,
    required this.timestamp,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) => ReportModel(
        reportId: json['reportId'] as String,
        reporterId: json['reporterId'] as String,
        targetId: json['targetId'] as String,
        reason: json['reason'] as String,
        timestamp: (json['timestamp'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toJson() => {
        'reportId': reportId,
        'reporterId': reporterId,
        'targetId': targetId,
        'reason': reason,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}