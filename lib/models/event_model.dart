import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csc234_clubconnect/models/category_model.dart';

enum EventStatus { upcoming, ongoing, ended }

class EventModel {
  final String id;
  final String title;
  final String description;   // user puts location info here naturally
  final String location;
  final String? imageUrl;     // optional cover photo
  final Timestamp createdAt;
  final String createdBy;
  final List<String> attendees;
  final List<CategoryModel> tags;
  final String roomId;        // links to Room (type: event) which has createdAt
  final int? maxAttendees;    // null = unlimited
  final Timestamp startDate;       // event start
  final Timestamp endDate;    // event end — Room uses this as expiresAt
  final EventStatus status;

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
    required this.status,
    required this.endDate,
    this.imageUrl,
    this.maxAttendees,
  });

  // ─── Derived Getters ───────────────────────────



  bool get isFull =>
      maxAttendees != null && attendees.length >= maxAttendees!;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  int get attendeeCount => attendees.length;

  bool isAttending(String userId) => attendees.contains(userId);

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
      tags: (json['tags'] as List<dynamic>?)?.map((t) => CategoryModel.fromMap(t)).toList() ?? [],
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
      createdAt: createdAt ?? this.createdAt,
      attendees: attendees ?? this.attendees,
      tags: tags,
      roomId: roomId ?? this.roomId,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      status: status ?? this.status,
    );
  }
}
