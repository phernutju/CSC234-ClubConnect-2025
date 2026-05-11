import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:intl/intl.dart';
import 'package:csc234_clubconnect/models/category_model.dart';

enum EventStatus { upcoming, ongoing, ended }

class EventModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final String? imageUrl;
  final Timestamp createdAt;
  final String createdBy;
  final List<String> attendees;
  final List<CategoryModel> tags;
  final String roomId;
  final int? maxAttendees;
  final Timestamp startDate;
  final Timestamp endDate;
  final EventStatus status;
  final bool isPublished;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.attendees,
    required this.tags,
    required this.location,
    required this.roomId,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.imageUrl,
    this.maxAttendees,
    
    this.isPublished = false,
  });

  // ─── Derived Getters ───────────────────────────

  bool get isFull =>
      maxAttendees != null && attendees.length >= maxAttendees!;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  int get attendeeCount => attendees.length;

  bool isAttending(String userId) => attendees.contains(userId);

  String get formattedDateRange {
    final start = startDate.toDate();
    final end = endDate.toDate();
    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    final dayFmt = DateFormat('d MMMM yyyy');
    final timeFmt = DateFormat('hh:mm a');
    if (sameDay) {
      return '${dayFmt.format(start)}  ${timeFmt.format(start)} - ${timeFmt.format(end)}';
    }
    return '${dayFmt.format(start)} ${timeFmt.format(start)} - '
        '${dayFmt.format(end)} ${timeFmt.format(end)}';
  }

  TimeOfDay get startTime {
    final d = startDate.toDate();
    return TimeOfDay(hour: d.hour, minute: d.minute);
  }

  TimeOfDay get endTime {
    final d = endDate.toDate();
    return TimeOfDay(hour: d.hour, minute: d.minute);
  }

  // ─── Serialization ─────────────────────────────

  factory EventModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel.fromJson({...data, 'id': doc.id});
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] ?? Timestamp.now(),
      createdBy: json['createdBy'] ?? '',
      attendees: List<String>.from(json['attendees'] ?? []),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((t) => CategoryModel.fromMap(t))
              .toList() ??
          [],
      roomId: json['roomId'] ?? '',
      maxAttendees: json['maxAttendees'] as int?,
      startDate: json['startDate'] ?? Timestamp.now(),
      endDate: json['endDate'] ?? json['expiresAt'] ?? Timestamp.now(),
      status: EventStatus.values.firstWhere(
        (s) => s.toString() == json['status'],
        orElse: () => EventStatus.upcoming,
      ),
      location: json['location'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'createdBy': createdBy,
        'attendees': attendees,
        'tags': tags.map((tag) => tag.toJson()).toList(),
        'roomId': roomId,
        'maxAttendees': maxAttendees,
        'startDate': startDate,
        'endDate': endDate,
        'status': status.toString().split('.').last,
        'isPublished': isPublished,
      };

  Map<String, dynamic> toFirestore() {
    final map = toJson();
    map.remove('id');
    return map;
  }

  EventModel copyWith({
    List<String>? attendees,
    String? imageUrl,
    String? roomId,
    int? maxAttendees,
  }) {
    return EventModel(
      id: id,
      title: title,
      description: description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy,
      createdAt: createdAt,
      attendees: attendees ?? this.attendees,
      tags: tags,
      roomId: roomId ?? this.roomId,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      startDate: startDate,
      endDate: endDate,
      location: location,
      status: status,
    );
  }
}
