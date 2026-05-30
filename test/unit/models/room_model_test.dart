import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:csc234_clubconnect/models/community_model.dart';

void main() {
  group('RoomModel.isExpired', () {
    test('community room never expires', () {
      final room = RoomModel(
        id: 'r1',
        name: 'Test Room',
        createdBy: 'uid1',
        tags: [],
        rules: [],
        type: RoomType.community,
        createdAt: Timestamp.fromDate(DateTime(2024, 1, 1)),
      );
      expect(room.isExpired, isFalse);
    });

    test('event room with past expiry is expired', () {
      final room = RoomModel(
        id: 'r2',
        name: 'Event Room',
        createdBy: 'uid1',
        tags: [],
        rules: [],
        type: RoomType.event,
        createdAt: Timestamp.fromDate(DateTime(2024, 1, 1)),
        expiresAt: Timestamp.fromDate(DateTime(2020, 1, 1)),
      );
      expect(room.isExpired, isTrue);
    });

    test('event room with future expiry is not expired', () {
      final room = RoomModel(
        id: 'r3',
        name: 'Event Room',
        createdBy: 'uid1',
        tags: [],
        rules: [],
        type: RoomType.event,
        createdAt: Timestamp.fromDate(DateTime(2024, 1, 1)),
        expiresAt: Timestamp.fromDate(DateTime(2099, 1, 1)),
      );
      expect(room.isExpired, isFalse);
    });

    test('event room with null expiry is not expired', () {
      final room = RoomModel(
        id: 'r4',
        name: 'Event Room',
        createdBy: 'uid1',
        tags: [],
        rules: [],
        type: RoomType.event,
        createdAt: Timestamp.fromDate(DateTime(2024, 1, 1)),
      );
      expect(room.isExpired, isFalse);
    });
  });

  group('RoomModel.isPermanent', () {
    test('community type is permanent', () {
      final room = RoomModel(
        id: 'r1',
        name: 'Test',
        createdBy: 'uid1',
        tags: [],
        rules: [],
        type: RoomType.community,
        createdAt: Timestamp.fromDate(DateTime(2024, 1, 1)),
      );
      expect(room.isPermanent, isTrue);
    });

    test('event type is not permanent', () {
      final room = RoomModel(
        id: 'r2',
        name: 'Test',
        createdBy: 'uid1',
        tags: [],
        rules: [],
        type: RoomType.event,
        createdAt: Timestamp.fromDate(DateTime(2024, 1, 1)),
      );
      expect(room.isPermanent, isFalse);
    });
  });
}
