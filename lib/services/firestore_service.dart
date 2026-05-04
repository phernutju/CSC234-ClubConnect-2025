import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/message_models.dart';
import '../models/report_model.dart';
import '../models/review_model.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Users ──────────────────────────────────────────────────────────────────

  Future<void> createUser(UserModel user) =>
      _db.collection(Collections.users).doc(user.uid).set(user.toJson());

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection(Collections.users).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromJson(doc.data()!);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> fields) =>
      _db.collection(Collections.users).doc(uid).update(fields);

  // ── Rooms ──────────────────────────────────────────────────────────────────

  Future<void> createRoom(RoomModel room) =>
      _db.collection(Collections.rooms).doc(room.roomId).set(room.toJson());

  Stream<List<RoomModel>> roomsStream() => _db
      .collection(Collections.rooms)
      .snapshots()
      .map((snap) => snap.docs.map((d) => RoomModel.fromJson(d.data())).toList());

  Future<RoomModel?> getRoom(String roomId) async {
    final doc = await _db.collection(Collections.rooms).doc(roomId).get();
    if (!doc.exists) return null;
    return RoomModel.fromJson(doc.data()!);
  }

  Future<void> deleteRoom(String roomId) =>
      _db.collection(Collections.rooms).doc(roomId).delete();

  // ── Messages ───────────────────────────────────────────────────────────────

  Future<void> sendMessage(MessageModel message) => _db
      .collection(Collections.rooms)
      .doc(message.roomId)
      .collection(Collections.messages)
      .doc(message.msgId)
      .set(message.toJson());

  Stream<List<MessageModel>> messagesStream(String roomId) => _db
      .collection(Collections.rooms)
      .doc(roomId)
      .collection(Collections.messages)
      .orderBy('timestamp')
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => MessageModel.fromJson(d.data())).toList());

  Future<void> deleteMessage(String roomId, String msgId) => _db
      .collection(Collections.rooms)
      .doc(roomId)
      .collection(Collections.messages)
      .doc(msgId)
      .delete();

  // ── Reviews ────────────────────────────────────────────────────────────────

  Future<void> createReview(ReviewModel review) => _db
      .collection(Collections.reviews)
      .doc(review.reviewId)
      .set(review.toJson());

  Stream<List<ReviewModel>> reviewsStream(String targetId) => _db
      .collection(Collections.reviews)
      .where('targetId', isEqualTo: targetId)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => ReviewModel.fromJson(d.data())).toList());

  Future<void> updateReview(String reviewId, Map<String, dynamic> fields) =>
      _db.collection(Collections.reviews).doc(reviewId).update(fields);

  Future<void> deleteReview(String reviewId) =>
      _db.collection(Collections.reviews).doc(reviewId).delete();

  // ── Reports ────────────────────────────────────────────────────────────────

  Future<void> submitReport(ReportModel report) => _db
      .collection(Collections.reports)
      .doc(report.reportId)
      .set(report.toJson());

  Future<List<ReportModel>> listReports() async {
    final snap = await _db.collection(Collections.reports).get();
    return snap.docs.map((d) => ReportModel.fromJson(d.data())).toList();
  }
}
