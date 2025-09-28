import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/providers/chat_provider.dart';
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

  // error state for message input
  String? inputError;

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

  Widget _buildBlockedUI({
    required String displayName,
    required bool isMeBlocking,
  }) {
    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
        backgroundColor: AppConstants.darkViolet,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              isMeBlocking
                  ? "You’ve blocked $displayName"
                  : "$displayName has blocked you",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            if (isMeBlocking)
              ElevatedButton(
                onPressed: () async {
                  await _firestore
                      .collection('users')
                      .doc(loggedInUser!.uid)
                      .set({
                        'blocked': {widget.receiverId: false},
                      }, SetOptions(merge: true));
                },
                child: const Text("Unblock"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(ChatProvider chatProvider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: textController,
                    onChanged: (value) {
                      setState(() {
                        if (value.length > 50) {
                          inputError = "Message cannot exceed 50 characters";
                        } else {
                          inputError = null;
                        }
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      counterText: "", // hides default counter
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: inputError != null
                              ? Colors.red
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: inputError != null
                              ? Colors.red
                              : AppConstants.lightViolet,
                          width: 1.5,
                        ),
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
                  icon: const Icon(Icons.mic, color: AppConstants.lightViolet),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: AppConstants.darkViolet,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () async {
                      if (textController.text.isNotEmpty &&
                          (inputError == null)) {
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
                          setState(() => inputError = null); // reset error
                        }
                      }
                    },
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
            if (inputError != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    inputError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    if (chatId == null) {
      return const Scaffold(body: Center(child: Text("No chat available")));
    }

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

            // Check blocking both ways
            return StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(loggedInUser!.uid)
                  .snapshots(),
              builder: (context, meSnap) {
                if (!meSnap.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final meData =
                    meSnap.data!.data() as Map<String, dynamic>? ?? {};
                final myBlocked = Map<String, dynamic>.from(
                  meData['blocked'] ?? {},
                );
                final receiverBlocked = Map<String, dynamic>.from(
                  receiverData['blocked'] ?? {},
                );

                bool isBlocked(dynamic entry) {
                  if (entry is bool) return entry; // old schema
                  if (entry is Map<String, dynamic>) {
                    return entry['blocked'] == true;
                  }
                  return false;
                }

                final isMeBlocking = isBlocked(myBlocked[widget.receiverId]);
                final isBlockedByReceiver = isBlocked(
                  receiverBlocked[loggedInUser!.uid],
                );

                if (isMeBlocking) {
                  return _buildBlockedUI(
                    displayName: displayName,
                    isMeBlocking: true,
                  );
                } else if (isBlockedByReceiver) {
                  return _buildBlockedUI(
                    displayName: displayName,
                    isMeBlocking: false,
                  );
                }

                // normal chat screen
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
                                'receiverData': receiverData,
                                'chatId': chatId,
                                'receiverId': widget.receiverId,
                                'nickname': displayName,
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
                      _buildMessageInput(chatProvider),
                    ],
                  ),
                  backgroundColor: Colors.white,
                );
              },
            );
          },
        );
      },
    );
  }
}
