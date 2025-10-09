import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/providers/chat_provider.dart';
import 'package:signtalk/widgets/chat/custom_message_stream.dart';
import 'package:record/record.dart';
import 'package:signtalk/widgets/custom_profile_avatar.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  final AudioRecorder _audioRecorder = AudioRecorder();

  String? recordedAudioPath; // path of current recording
  String? sttText; // result of speech-to-text
  bool isPlaying = false; // for replay in input

  User? loggedInUser;
  String? chatId;
  String? inputError;

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceText = '';

  @override
  void initState() {
    super.initState();
    chatId = widget.chatId;
    getCurrentUser();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    textController.dispose();
    _audioRecorder.dispose();
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

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (kDebugMode) print('🎤 Status: $status');
        if (status == 'done') _stopListening();
      },
      onError: (err) {
        if (kDebugMode) print('❌ Speech error: $err');
        _stopListening();
      },
    );

    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          const SnackBar(content: Text('Speech recognition unavailable')),
        );
      }
      return;
    }

    setState(() {
      _isListening = true;
      _voiceText = '';
    });

    _speech.listen(
      onResult: (result) {
        setState(() {
          _voiceText = result.recognizedWords;
          textController.text = _voiceText;
        });
      },
      localeId: 'en_US',
      listenMode: stt.ListenMode.dictation,
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _sendTextMessage(BuildContext context) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final text = textController.text.trim();
    if (text.isEmpty) return;

    if (chatId == null || chatId!.isEmpty) {
      chatId = await chatProvider.createChatRoom(widget.receiverId);
    }
    if (chatId == null) return;

    await chatProvider.sendMessage(chatId!, text, widget.receiverId);

    textController.clear();
    setState(() {
      inputError = null;
      _voiceText = '';
    });
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

  //block screen
  Widget _buildBlockedUI({
    required String displayName,
    required bool isMeBlocking,
  }) {
    return Scaffold(
      appBar: AppBar(
        title: Text(displayName, style: TextStyle(color: AppConstants.white)),
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
                  ? "You've blocked $displayName"
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

  Widget _buildMessageInput(ChatProvider chatProvider, BuildContext context) {
    if (_isListening) {
      //listening UI
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.mic, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Listening...",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
            IconButton(
              onPressed: _stopListening,
              icon: const Icon(Icons.stop, color: AppConstants.lightViolet),
            ),
          ],
        ),
      );
    } else if (_voiceText.isNotEmpty) {
      // Review transcribed text UI
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: textController..text = _voiceText,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: "Your speech...",
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                ),
                onChanged: (value) => _voiceText = value,
              ),
            ),
            IconButton(
              onPressed: () {
                _voiceText = '';
                textController.clear();
                setState(() {});
              },
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppConstants.darkViolet,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {
                  _sendTextMessage(context);
                },

                icon: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } else {
      //Normal typing UI
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: textController,
                onChanged: (value) {
                  setState(() {
                    inputError = value.length > 50
                        ? "Message cannot exceed 50 characters"
                        : null;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  counterText: "",
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
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
              onPressed: _isListening ? _stopListening : _startListening,
              icon: Icon(
                _isListening ? Icons.mic_off : Icons.mic,
                color: AppConstants.lightViolet,
              ),
            ),
            FloatingActionButton(
              onPressed: () => context.push(
                "/camera_screen",
                extra: {'chatId': chatId, 'receiverId': widget.receiverId},
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: AppConstants.darkViolet,
              child: Icon(Icons.videocam),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppConstants.darkViolet,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {
                  if (inputError == null) _sendTextMessage(context);
                },
                icon: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
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
                  if (entry is bool) return entry;
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

                return Scaffold(
                  appBar: AppBar(
                    title: Row(
                      children: [
                        CustomProfileAvatar(
                          name: displayName,
                          photoUrl: receiverData['photoUrl'],
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
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isOnline
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
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
                      _buildMessageInput(chatProvider, context),
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
