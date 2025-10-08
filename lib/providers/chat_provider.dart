import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:signtalk/models/message_status.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final stt.SpeechToText _speech = stt.SpeechToText();
  String lastWords = '';

  Future<void> initSpeech() async {
    bool available = await _speech.initialize(
      onError: (e) => debugPrint(' Speech error: $e'),
      onStatus: (s) => debugPrint(' Status: $s'),
    );

    if (available) {
      debugPrint(" Speech recognition available");
    } else {
      debugPrint(" Speech recognition not available on this device");
    }
  }

  Future<String> transcribeAudio(File audio) async {
    try {
      final url = Uri.parse('');
      final request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('file', audio.path));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        return response.body; // plain text transcription
      } else {
        return "[Voice message]"; // fallback
      }
    } catch (e) {
      print("Transcription failed: $e");
      return "[Voice message]";
    }
  }

  Future<void> sendVoiceMessage(
    String chatId,
    String receiverId,
    String messageText,
    String audioUrl,
    Duration duration,
  ) async {
    // Send to Firestore chats collection
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'senderId': FirebaseAuth.instance.currentUser!.uid,
          'receiverId': receiverId,
          'messageBody': messageText,
          'audioUrl': audioUrl,
          'duration': duration.inSeconds,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'sent',
        });
  }

  //tanggal
  void startListening() async {
    await _speech.listen(
      onResult: (result) {
        debugPrint("Partial: ${result.recognizedWords}");
        if (result.finalResult) {
          lastWords = result.recognizedWords;
          debugPrint("Final transcribed: $lastWords");
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: "en-US",
      cancelOnError: true,
      partialResults: true,
    );
  }

  //tanggal
  void stopListening() async {
    await _speech.stop();
    debugPrint(" Stopped listening. Final: $lastWords");
  }

  Stream<QuerySnapshot> getChats(String userId) {
    return _firestore
        .collection("chats")
        .where('users', arrayContains: userId)
        .snapshots();
  }

  Stream<QuerySnapshot> searchUsers(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _firestore
        .collection("users")
        .where('name_lowercase', isGreaterThanOrEqualTo: lowercaseQuery)
        .where('name_lowercase', isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
        .snapshots();
  }

  //tanggal
  Future<void> sendRecording(File audioFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final ref = FirebaseStorage.instance.ref().child(
        'voice_messages/$fileName',
      );

      // Upload audio file
      await ref.putFile(audioFile);
      final audioUrl = await ref.getDownloadURL();

      // Call cloud function to transcribe
      final callable = FirebaseFunctions.instance.httpsCallable(
        'transcribeAudio',
      );
      final result = await callable.call({'audioUrl': audioUrl});

      final transcribedText = (result.data['text'] ?? '').toString();

      // Always have fallback
      final messageText = transcribedText.isNotEmpty
          ? transcribedText
          : "[Voice message]";

      // Save to Firestore
      await FirebaseFirestore.instance.collection('messages').add({
        'senderId': user.uid,
        'text': messageText,
        'audioUrl': audioUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
      });

      debugPrint("Sent message with text='$messageText' and audio=$audioUrl");
    } catch (e) {
      debugPrint(" sendRecording error: $e");
    }
  }

  //tanggal
  Future<String> uploadAudioFile(File file) async {
    final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final ref = FirebaseStorage.instance.ref().child(
      'voice_messages/$fileName',
    );
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> sendMessage(
    String chatId,
    String message,
    String receiverId,
  ) async {
    

    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      // create message with initial status = sent
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': currentUser.uid,
            'receiverId': receiverId,
            'messageBody': message,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'sent', // sent status
          });

      // update chat summary (for the list view)
      await _firestore.collection('chats').doc(chatId).set({
        'users': [currentUser.uid, receiverId],
        'lastMessage': message,
        'lastMessageSenderId': currentUser.uid, // for CustomUserCardWidget
        'lastMessageStatus': 'sent', //  for CustomUserCardWidget
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<String?> getChatRoom(String receiverId) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final chatQuery = await _firestore
          .collection('chats')
          .where('users', arrayContains: currentUser.uid)
          .get();

      final chats = chatQuery.docs
          .where((chat) => chat['users'].contains(receiverId))
          .toList();

      if (chats.isNotEmpty) {
        return chats.first.id;
      }
    }
    return null;
  }

  Future<String> createChatRoom(String receiverId) async {
    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      final chatRoom = await _firestore.collection('chats').add({
        'users': [currentUser.uid, receiverId],
        'lastMessage': '',
        'timestamp': FieldValue.serverTimestamp(),
      });
      return chatRoom.id;
    }
    throw Exception('Current User is Null');
  }

  //typing status
  Future<void> updateTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  ) async {
    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'typing.$userId': isTyping,
    });
  }

  //user active state
  void setUserOnlineStatus(bool isOnline) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
            'isOnline': isOnline,
            'lastSeen': FieldValue.serverTimestamp(),
          });
    }
  }

  //read, sent, delivered indicator
  Future<void> updateMessageStatus(
    String chatId,
    String messageId,
    MessageStatus newStatus,
  ) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'status': messageStatusToString(newStatus)});

    // also update the lastMessageStatus in chats collection
    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'lastMessageStatus': messageStatusToString(newStatus),
    });
  }

  //delete convo
  Future<void> deleteConversation(String chatId) async {
    final fs = FirebaseFirestore.instance;
    final batch = fs.batch();

    final messages = await fs
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(fs.collection('chats').doc(chatId));

    await batch.commit();
  }
}
