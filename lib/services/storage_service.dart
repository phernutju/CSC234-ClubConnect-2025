import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<String> uploadChatImage(Uint8List bytes, String chatId) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('chat_images/$chatId/$name');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<String> uploadCommunityImage(Uint8List bytes, String communityId) async {
    try{
      
    
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('community_covers/$communityId/$name');
    
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    
    return ref.getDownloadURL();
    }
    catch(e){
      print('Error uploading community image: $e');
      rethrow;
    }
  }

  Future<String> uploadUserAvatar(Uint8List bytes, String userId) async {
    final ref = _storage.ref().child('user_avatars/$userId/avatar.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}
