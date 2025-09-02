import 'package:flutter/material.dart';
import 'package:signtalk/models/message_status.dart';

class CustomUserCardWidget extends StatelessWidget {
  final String userId;
  final String userName;
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

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(child: Text(userName[0].toUpperCase())),
      title: Text(userName),
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
        "${lastMessageTime.hour}:${lastMessageTime.minute.toString().padLeft(2, '0')}",
        style: const TextStyle(color: Colors.black54, fontSize: 12),
      ),
    );
  }
}
