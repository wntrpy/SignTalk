import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:signtalk/models/message_status.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<void> sendMessage(
    String chatId,
    String message,
    String receiverId,
  ) async {
    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      // Create message with initial status = sent
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

      // Update chat summary (for the list view)
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
