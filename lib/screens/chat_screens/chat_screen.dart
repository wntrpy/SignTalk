import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/providers/chat_provider.dart';
import 'package:signtalk/widgets/buttons/custom_circle_pfp_button.dart';
import 'package:signtalk/widgets/chat/custom_message_stream.dart';

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
  final TextEditingController textController = TextEditingController();

  User? loggedInUser;
  String? chatId;

  @override
  void initState() {
    super.initState();
    chatId = widget.chatId;
    getCurrentUser();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  void getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        loggedInUser = user;
      });
    }
  }

  DateTime timestampToLocal(dynamic ts) {
    try {
      if (ts is Timestamp) {
        final int epochMs = ts.seconds * 1000 + (ts.nanoseconds ~/ 1000000);
        final DateTime dtUtc = DateTime.fromMillisecondsSinceEpoch(
          epochMs,
          isUtc: true,
        );
        final Duration tzOffset = DateTime.now().timeZoneOffset;
        return dtUtc.add(tzOffset);
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
      return 'Last seen ${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return 'Last seen ${diff.inHours} hr ago';
    } else {
      return 'Last seen ${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    if (chatId == null) {
      return const Scaffold(body: Center(child: Text("No chat available")));
    }

    // Combine both user and chat data
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(widget.receiverId).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final receiverData =
            userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final realName = receiverData['name'] ?? 'User';
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

        return StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('chats').doc(chatId).snapshots(),
          builder: (context, chatSnapshot) {
            if (!chatSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final chatData =
                chatSnapshot.data!.data() as Map<String, dynamic>? ?? {};
            String displayName = realName;

            // check for nickname
            if (chatData['nicknames'] != null && loggedInUser != null) {
              final nickMap = Map<String, dynamic>.from(
                chatData['nicknames'] ?? {},
              );
              if (nickMap.containsKey(loggedInUser!.uid)) {
                final userNicknames = Map<String, dynamic>.from(
                  nickMap[loggedInUser!.uid],
                );
                if (userNicknames.containsKey(widget.receiverId)) {
                  displayName = userNicknames[widget.receiverId];
                }
              }
            }

            return Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    InkWell(
                      child: CircleAvatar(
                        child: Text(displayName[0].toUpperCase()),
                      ),
                      onTap: () {
                        context.push(
                          '/receiver_profile_screen',
                          extra: {
                            'receiverData': receiverData, // Map<String,dynamic>
                            'chatId': chatId, // String (chat doc id)
                            'receiverId': widget.receiverId, // String
                            'nickname':
                                displayName, // String (may be real name if no nickname)
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(color: Colors.white),
                        ),
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
                    child: CustomMessageStream(
                      chatId: chatId!,
                      timestampToLocal: timestampToLocal,
                    ),
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
      },
    );
  }
}
