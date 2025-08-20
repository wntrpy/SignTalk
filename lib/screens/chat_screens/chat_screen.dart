import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/providers/chat_provider.dart';
import 'package:signtalk/widgets/buttons/custom_circle_pfp_button.dart';
import 'package:signtalk/widgets/chat/custom_message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String? chatId;
  final String receiverId;

  const ChatScreen({super.key, this.chatId, required this.receiverId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  User? loggedInUser;
  String? chatId;

  @override
  void initState() {
    super.initState();
    chatId = widget.chatId;
    getCurrentUser();
  }

  void getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        loggedInUser = user;
      });
    }
  }

  // Convert Firestore Timestamp/DateTime/int/string into a correct local DateTime.
  DateTime timestampToLocal(dynamic ts) {
    try {
      if (ts is Timestamp) {
        // exact epoch ms using seconds + nanoseconds
        final int epochMs = ts.seconds * 1000 + (ts.nanoseconds ~/ 1000000);
        final DateTime dtUtc = DateTime.fromMillisecondsSinceEpoch(
          epochMs,
          isUtc: true,
        );

        // apply device timezone offset explicitly (safer than relying only on toLocal())
        final Duration tzOffset = DateTime.now().timeZoneOffset;
        final DateTime dtLocal = dtUtc.add(tzOffset);

        if (kDebugMode) {
          print('--- timestampToLocal debug ---');
          print('raw Timestamp: $ts');
          print(
            'seconds: ${ts.seconds}, nanoseconds: ${ts.nanoseconds}, epochMs: $epochMs',
          );
          print('dtUtc: $dtUtc');
          print('tzOffset: $tzOffset');
          print('dtLocal (after add offset): $dtLocal');
          print(
            'Device now: ${DateTime.now()} tzName: ${DateTime.now().timeZoneName} offset: ${DateTime.now().timeZoneOffset}',
          );
        }

        return dtLocal;
      } else if (ts is DateTime) {
        return ts.toLocal();
      } else if (ts is int) {
        final DateTime dtUtc = DateTime.fromMillisecondsSinceEpoch(
          ts,
          isUtc: true,
        );
        return dtUtc.add(DateTime.now().timeZoneOffset);
      } else if (ts is String) {
        return DateTime.parse(ts).toLocal();
      } else {
        return DateTime.now();
      }
    } catch (e) {
      if (kDebugMode) print('timestampToLocal error: $e');
      return DateTime.now();
    }
  }

  String formatLastSeen(Timestamp ts) {
    final DateTime lastSeenLocal = ts.toDate().toLocal();
    final Duration diff = DateTime.now().difference(lastSeenLocal);

    if (diff.inMinutes < 1) {
      return 'Last seen just now';
    } else if (diff.inMinutes < 60) {
      return 'Last seen ${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else if (diff.inHours < 24) {
      return 'Last seen ${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Last seen ${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final TextEditingController textController = TextEditingController();

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(widget.receiverId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('User not found')),
          );
        }

        final receiverData =
            snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final name = receiverData['name'] ?? 'User';
        final bool isOnline = receiverData['isOnline'] ?? false;
        final dynamic lastSeenTs = receiverData['lastSeen'];

        String statusText;
        if (isOnline) {
          statusText = 'Active now';
        } else if (lastSeenTs != null) {
          statusText = formatLastSeen(lastSeenTs);
        } else {
          statusText = 'Offline';
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const CustomCirclePfpButton(
                  userImage: AppConstants.default_user_pfp,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white)),
                    Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            backgroundColor: AppConstants.darkViolet,
          ),
          body: Column(
            children: [
              Expanded(
                child: chatId != null && chatId!.isNotEmpty
                    ? MessageStream(
                        chatId: chatId!,
                        timestampToLocal: timestampToLocal,
                      )
                    : const Center(child: Text("No Message Yet")),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 15,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: textController,
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // TODO: camera action
                        },
                        icon: const Icon(
                          Icons.camera_alt,
                          color: AppConstants.lightViolet,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // TODO: mic action
                        },
                        icon: const Icon(
                          Icons.mic,
                          color: AppConstants.lightViolet,
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          color: AppConstants.darkViolet,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () async {
                            if (textController.text.isNotEmpty) {
                              if (chatId == null || chatId!.isEmpty) {
                                chatId = await chatProvider.createChatRoom(
                                  widget.receiverId,
                                );
                              }
                              if (chatId != null) {
                                chatProvider.sendMessage(
                                  chatId!,
                                  textController.text,
                                  widget.receiverId,
                                );
                                textController.clear();
                              }
                            }
                          },
                          icon: const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
        );
      },
    );
  }
}

class MessageStream extends StatelessWidget {
  final String chatId;
  final DateTime Function(dynamic) timestampToLocal;

  const MessageStream({
    super.key,
    required this.chatId,
    required this.timestampToLocal,
  });

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
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final messages = snapshot.data!.docs;
        List<CustomMessageBubble> messageWidgets = [];
        for (var message in messages) {
          final messageData = message.data() as Map<String, dynamic>;
          final messageText = messageData['messageBody'];
          final messageSender = messageData['senderId'];
          final timestamp = messageData['timestamp'];

          final currentUser = FirebaseAuth.instance.currentUser!.uid;
          final messageWidget = CustomMessageBubble(
            sender: messageSender,
            text: messageText,
            isMe: currentUser == messageSender,
            timestamp: timestamp,
            timestampToLocal: timestampToLocal,
          );
          messageWidgets.add(messageWidget);
        }

        return ListView(reverse: true, children: messageWidgets);
      },
    );
  }
}
