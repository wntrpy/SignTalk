import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:signtalk/models/message_status.dart';
import 'package:signtalk/widgets/chat/custom_message_bubble.dart';

class CustomMessageStream extends StatelessWidget {
  final String chatId;
  final DateTime Function(dynamic) timestampToLocal;

  const CustomMessageStream({
    super.key,
    required this.chatId,
    required this.timestampToLocal,
  });

  Future<void> _markIncomingAsRead(
    String chatId,
    List<QueryDocumentSnapshot> docs,
  ) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final fs = FirebaseFirestore.instance;

    // collect updates
    final batch = fs.batch();
    bool shouldUpdateChatSummary = false;
    Timestamp? latestTs;

    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;
      final receiverId = data['receiverId'] as String?;
      final status = (data['status'] as String?) ?? 'sent';

      // only incoming to me, and not already read
      if (receiverId == uid && status != 'read') {
        batch.update(d.reference, {'status': 'read'});

        // track newest incoming message
        //set chat to reasd
        final ts = data['timestamp'];
        if (ts is Timestamp) {
          if (latestTs == null || ts.compareTo(latestTs) > 0) {
            latestTs = ts;
            shouldUpdateChatSummary = true;
          }
        }
      }
    }

    if (shouldUpdateChatSummary) {
      batch.set(fs.collection('chats').doc(chatId), {
        'lastMessageStatus': 'read',
      }, SetOptions(merge: true));
    }

    if (shouldUpdateChatSummary) {
      await batch.commit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        // after building the list, mark incoming as READ
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _markIncomingAsRead(chatId, docs);
        });

        final currentUser = FirebaseAuth.instance.currentUser!.uid;
        final bubbles = <CustomMessageBubble>[];

        for (final message in docs) {
          final data = message.data() as Map<String, dynamic>;
          final text = data['messageBody'] as String? ?? '';
          final senderId = data['senderId'] as String? ?? '';
          final ts = data['timestamp'];
          final statusStr = (data['status'] as String?) ?? 'sent';
          final status = messageStatusFromString(statusStr);

          bubbles.add(
            CustomMessageBubble(
              sender: senderId,
              text: text,
              isMe: currentUser == senderId,
              timestamp: ts,
              timestampToLocal: timestampToLocal,
              status: status,
            ),
          );
        }

        return ListView(reverse: true, children: bubbles);
      },
    );
  }
}
