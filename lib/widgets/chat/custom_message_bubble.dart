import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/models/message_status.dart';

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

class CustomMessageBubble extends StatelessWidget {
  final String sender;
  final String text;
  final bool isMe;
  final dynamic timestamp;
  final DateTime Function(dynamic) timestampToLocal;

  final MessageStatus status;

  const CustomMessageBubble({
    super.key,
    required this.sender,
    required this.text,
    required this.isMe,
    this.timestamp,
    required this.timestampToLocal,
    required this.status,
  });

  Widget _buildStatusIcon(MessageStatus status) {
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
    final DateTime messageTime = _toAppLocal(timestamp);
    final formatted = _formatTimeHM(messageTime);

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isMe)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Row(
                    children: [
                      Text(
                        formatted,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildStatusIcon(status), //status icon
                    ],
                  ),
                ),
              // MESSAGE BUBBLE
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      spreadRadius: 2,
                    ),
                  ],
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                  color: isMe
                      ? AppConstants.lightViolet
                      : AppConstants.extraLightViolet,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    formatted,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
