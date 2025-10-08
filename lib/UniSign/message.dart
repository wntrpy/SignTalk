import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final String? videoUrl;
  final DateTime timestamp;
 
  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.videoUrl,
    required this.timestamp,
  });
 
  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'videoUrl': videoUrl,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
 
  factory Message.fromMap(Map<String, dynamic> map, String id) {
    return Message(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      videoUrl: map['videoUrl'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
