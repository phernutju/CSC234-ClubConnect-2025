import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:intl/intl.dart';

class EventModel {
  final String id;
  final String communityId;
  final String title;
  final String hostName;
  final DateTime startDate;
  final DateTime endDate;
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
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.detail,
    required this.memberLimit,
    required this.coverImageUrl,
    required this.createdById,
    required this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json, String id) {
    // Fall back to legacy 'date' field for documents created before this update.
    final legacyDate = (json['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    return EventModel(
      id: id,
      communityId: json['communityId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      hostName: json['hostName'] as String? ?? '',
      startDate: (json['startDate'] as Timestamp?)?.toDate() ?? legacyDate,
      endDate: (json['endDate'] as Timestamp?)?.toDate() ?? legacyDate,
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
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        // Keep 'date' = startDate so the orderBy('date') query in EventService keeps working.
        'date': Timestamp.fromDate(startDate),
        'location': location,
        'detail': detail,
        'memberLimit': memberLimit,
        'coverImageUrl': coverImageUrl,
        'createdById': createdById,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// Smart date-range label.
  /// Same day  → 'DD Month YYYY  HH:MM AM/PM - HH:MM AM/PM'
  /// Diff days → 'DD Month YYYY HH:MM AM/PM - DD Month YYYY HH:MM AM/PM'
  String get formattedDateRange {
    final sameDay = startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day;
    final dayFmt = DateFormat('d MMMM yyyy');
    final timeFmt = DateFormat('hh:mm a');
    if (sameDay) {
      return '${dayFmt.format(startDate)}  ${timeFmt.format(startDate)} - ${timeFmt.format(endDate)}';
    }
    return '${dayFmt.format(startDate)} ${timeFmt.format(startDate)} - '
        '${dayFmt.format(endDate)} ${timeFmt.format(endDate)}';
  }

  TimeOfDay get startTime => TimeOfDay(hour: startDate.hour, minute: startDate.minute);
  TimeOfDay get endTime   => TimeOfDay(hour: endDate.hour,   minute: endDate.minute);
}
