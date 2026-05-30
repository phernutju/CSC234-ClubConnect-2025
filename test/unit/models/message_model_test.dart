import 'package:flutter_test/flutter_test.dart';
import 'package:csc234_clubconnect/models/message_model.dart';

void main() {
  group('MessageModel constructor', () {
    test('default values applied correctly', () {
      final msg = MessageModel(
        id: 'msg1',
        senderId: 'uid1',
        text: 'Hello',
        timestamp: DateTime(2024, 6, 1, 10, 0),
      );
      expect(msg.flagged, isFalse);
      expect(msg.isSystem, isFalse);
      expect(msg.seenBy, isEmpty);
      expect(msg.imageURL, '');
      expect(msg.mentions, isEmpty);
    });

    test('flagged message stores flag', () {
      final msg = MessageModel(
        id: 'msg2',
        senderId: 'uid1',
        text: 'bad content',
        timestamp: DateTime(2024, 6, 1),
        flagged: true,
      );
      expect(msg.flagged, isTrue);
    });

    test('reply fields are stored', () {
      final msg = MessageModel(
        id: 'msg3',
        senderId: 'uid1',
        text: 'reply',
        timestamp: DateTime(2024, 6, 1),
        replyToId: 'msg1',
        replyToSenderName: 'Alice',
        replyToText: 'original',
      );
      expect(msg.replyToId, 'msg1');
      expect(msg.replyToSenderName, 'Alice');
      expect(msg.replyToText, 'original');
    });

    test('mentions stored', () {
      final msg = MessageModel(
        id: 'msg4',
        senderId: 'uid1',
        text: '@bob hello',
        timestamp: DateTime(2024, 6, 1),
        mentions: ['uid_bob'],
      );
      expect(msg.mentions, contains('uid_bob'));
    });

    test('system message flag', () {
      final msg = MessageModel(
        id: 'sys1',
        senderId: '',
        text: 'User joined',
        timestamp: DateTime(2024, 6, 1),
        isSystem: true,
      );
      expect(msg.isSystem, isTrue);
    });
  });
}
