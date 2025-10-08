import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:signtalk/UniSign/message.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
 
  Future<String> uploadVideo(File videoFile, String userId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('videos/$userId/video_$timestamp.mp4');
     
      print('Uploading video...');
      final uploadTask = await ref.putFile(videoFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
     
      print('Video uploaded: $downloadUrl');
      return downloadUrl;
     
    } catch (e) {
      print('Upload error: $e');
      throw Exception('Failed to upload video: $e');
    }
  }
 
  Future<void> saveMessage(Message message) async {
    try {
      await _firestore.collection('messages').add(message.toMap());
      print('Message saved to Firestore');
    } catch (e) {
      print('Save error: $e');
      throw Exception('Failed to save message: $e');
    }
  }
 
  Stream<List<Message>> getMessages(String chatId) {
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromMap(doc.data(), doc.id))
            .toList());
  }
  
}