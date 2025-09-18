import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signtalk/models/message_status.dart';

// 🔹 Same offset logic as your CustomMessageBubble
const Duration kAppTzOffset = Duration(hours: 8);

DateTime _toAppLocal(dynamic ts) {
  if (ts == null) return DateTime.now().toUtc().add(kAppTzOffset);
  try {
    if (ts is DateTime) {
      return ts.toUtc().add(kAppTzOffset);
    }
    if (ts is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        ts,
        isUtc: true,
      ).add(kAppTzOffset);
    }
    // Firestore Timestamp
    final seconds = ts.seconds as int;
    final nanos = ts.nanoseconds as int;
    final epochMs = seconds * 1000 + (nanos ~/ 1000000);
    return DateTime.fromMillisecondsSinceEpoch(
      epochMs,
      isUtc: true,
    ).add(kAppTzOffset);
  } catch (_) {
    return DateTime.now().toUtc().add(kAppTzOffset);
  }
}

String _formatTimeHM(DateTime dt) => DateFormat('h:mm a').format(dt);

class CustomUserCardWidget extends StatelessWidget {
  final String userId;
  final String userName; // real display name
  final String? nickname; // optional nickname
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime lastMessageTime;
  final MessageStatus lastMessageStatus;
  final String currentUserId;
  final VoidCallback? onTap;

  const CustomUserCardWidget({
    super.key,
    required this.userId,
    required this.userName,
    this.nickname,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageTime,
    required this.lastMessageStatus,
    required this.currentUserId,
    this.onTap,
  });

  Widget buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 16, color: Colors.grey);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 16, color: Colors.grey);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 16, color: Colors.blue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMe = lastMessageSenderId == currentUserId;
    final displayName = nickname?.isNotEmpty == true ? nickname! : userName;

    // 🔹 Convert and format like in your bubble
    final localTime = _toAppLocal(lastMessageTime);
    final formattedTime = _formatTimeHM(localTime);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(child: Text(displayName[0].toUpperCase())),
      title: Text(displayName),
      subtitle: Row(
        children: [
          if (isMe) buildStatusIcon(lastMessageStatus),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: Text(
        formattedTime,
        style: const TextStyle(color: Colors.black54, fontSize: 12),
      ),
    );
  }
}
