import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String communityId;
  final String title;
  final String hostName;
  final DateTime date;
  final String location;
  final String detail;
  final int memberLimit;
  final String coverImageUrl;
  final String createdById;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.communityId,
    required this.title,
    required this.hostName,
    required this.date,
    required this.location,
    required this.detail,
    required this.memberLimit,
    required this.coverImageUrl,
    required this.createdById,
    required this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json, String id) {
    return EventModel(
      id: id,
      communityId: json['communityId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      hostName: json['hostName'] as String? ?? '',
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: json['location'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      memberLimit: json['memberLimit'] as int? ?? 15,
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      createdById: json['createdById'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'communityId': communityId,
        'title': title,
        'hostName': hostName,
        'date': Timestamp.fromDate(date),
        'location': location,
        'detail': detail,
        'memberLimit': memberLimit,
        'coverImageUrl': coverImageUrl,
        'createdById': createdById,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
