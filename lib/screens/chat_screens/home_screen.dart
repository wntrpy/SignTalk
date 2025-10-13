import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/models/message_status.dart';
import 'package:signtalk/providers/auth_provider.dart' as authentication;
import 'package:signtalk/providers/chat_provider.dart';
import 'package:signtalk/screens/chat_screens/chat_screen.dart';
import 'package:signtalk/screens/chat_screens/user_search_screen.dart';
import 'package:signtalk/widgets/chat/custom_user_card_widget.dart';
import 'package:signtalk/widgets/custom_profile_avatar.dart';
import 'package:signtalk/widgets/custom_signtalk_logo.dart';
import 'package:signtalk/widgets/firstname_greeting.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  User? loggedInUser;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    _checkAndShowGoogleLinkPrompt();
  }

  // ✅ ADD THIS METHOD
  Future<void> _checkAndShowGoogleLinkPrompt() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Wait a bit for the screen to fully render
      await Future.delayed(const Duration(milliseconds: 500));

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data();
      if (userData == null) return;

      // Check if user registered via email and hasn't seen the prompt yet
      final registeredViaEmail = userData['registeredViaEmail'] ?? false;
      final promptShown = userData['googleLinkPromptShown'] ?? false;
      final googleLinked = userData['googleLinked'] ?? false;

      // Only show if: registered via email, prompt not shown, and Google not linked
      if (registeredViaEmail && !promptShown && !googleLinked) {
        if (mounted) {
          _showGoogleLinkDialog();
        }
      }
    } catch (e) {
      debugPrint('Error checking Google link prompt: $e');
    }
  }

  // ✅ ADD THIS METHOD
  void _showGoogleLinkDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Cannot dismiss by tapping outside
      builder: (context) => PopScope(
        canPop: false, // Cannot dismiss with back button
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.link, color: AppConstants.orange, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Link Google Account',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'Link your Google account for easier access and secure sign-in!\n\n'
            'You can do this anytime in Settings.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Mark as shown
                final authProvider = Provider.of<authentication.AuthProvider>(
                  context,
                  listen: false,
                );
                await authProvider.markGoogleLinkPromptShown();

                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                'Not Now',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Mark as shown
                final authProvider = Provider.of<authentication.AuthProvider>(
                  context,
                  listen: false,
                );
                await authProvider.markGoogleLinkPromptShown();

                if (mounted) {
                  Navigator.of(context).pop();
                  context.push('/settings_screen');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Go to Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        loggedInUser = user;
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchChatData(String chatId) async {
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();

      if (!chatDoc.exists) return null;

      final chatData = chatDoc.data();
      if (chatData == null || chatData['users'] == null) return null;

      // ✅ Hide chat card if deleted by current user
      final deletedFor = Map<String, dynamic>.from(
        chatData['deletedFor'] ?? {},
      );
      if (deletedFor[loggedInUser!.uid] == true) {
        return null; // Hide from list
      }

      // ... rest of your existing code
      final users = chatData['users'] as List<dynamic>;
      final receiverId = users.firstWhere(
        (id) => id != loggedInUser!.uid,
        orElse: () => null,
      );
      if (receiverId == null) return null;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .get();
      final userData = userDoc.data();
      if (userData == null) return null;

      String? nickname;
      if (chatData['nicknames'] != null) {
        final nickMap = Map<String, dynamic>.from(chatData['nicknames']);
        if (nickMap.containsKey(loggedInUser?.uid)) {
          final userNicknames = Map<String, dynamic>.from(
            nickMap[loggedInUser?.uid],
          );
          nickname = userNicknames[receiverId];
        }
      }

      bool isMuted = false;
      if (chatData['mute'] != null) {
        final muteMap = Map<String, dynamic>.from(chatData['mute']);
        isMuted = muteMap[loggedInUser?.uid] ?? false;
      }

      return {
        'chatId': chatId,
        'lastMessage': chatData['lastMessage'] ?? '',
        'lastMessageSenderId': chatData['lastMessageSenderId'] ?? '',
        'lastMessageStatus': chatData['lastMessageStatus'] ?? 'sent',
        'timeStamp': chatData['timestamp'] != null
            ? (chatData['timestamp'] as Timestamp).toDate().toLocal()
            : DateTime.now(),
        'userData': userData,
        'nickname': nickname,
        'isMuted': isMuted,
      };
    } catch (e) {
      debugPrint('Error fetching chat data: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (loggedInUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),
            Column(
              children: [
                //-----------------------------------------HEADER--------------------------------------------\\
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 50),
                            child: Row(
                              children: [
                                CustomSigntalkLogo(width: 60, height: 60),
                                const SizedBox(width: 10),
                                const FirstNameGreeting(),
                              ],
                            ),
                          ),

                          //-----------------------------------------PFP--------------------------------------------\\
                          // Profile Picture Button
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(loggedInUser!.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              String? photoUrl;
                              String name = 'User';

                              if (snapshot.hasData && snapshot.data!.exists) {
                                final data =
                                    snapshot.data!.data()
                                        as Map<String, dynamic>?;
                                photoUrl = data?['photoUrl'] as String?;
                                name = data?['name'] as String? ?? 'User';
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 30),
                                child: CustomProfileAvatar(
                                  photoUrl: photoUrl,
                                  name: name,
                                  radius: 25,
                                  onTap: () => context.push('/profile_screen'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      //-----------------------------------------SEARCH BAR--------------------------------------------\\
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserSearchScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search, color: Colors.grey),
                              SizedBox(width: 10),
                              Text(
                                "Search contact...",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                //-----------------------------------------LIST OF USERS--------------------------------------------//
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40.0),
                        topRight: Radius.circular(40.0),
                      ),
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: chatProvider.getChats(loggedInUser!.uid),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        //get the LIST of raw chat documents
                        //id, users(array), last message, timestamp
                        final chatDocs = snapshot.data!.docs;
                        return FutureBuilder<List<Map<String, dynamic>?>>(
                          future: Future.wait(
                            chatDocs.map(
                              (chatDoc) => _fetchChatData(chatDoc.id),
                            ),
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            // Filter out nulls (failed fetches)
                            final chatDataList = snapshot.data!
                                .where((chatData) => chatData != null)
                                .cast<Map<String, dynamic>>()
                                .toList();

                            // Sort newest to oldest
                            chatDataList.sort(
                              (a, b) =>
                                  b['timeStamp'].compareTo(a['timeStamp']),
                            );

                            if (chatDataList.isEmpty) {
                              return const Center(
                                child: Text(
                                  "No conversations yet.",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 18,
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              itemCount: chatDataList.length,
                              itemBuilder: (context, index) {
                                final chatData = chatDataList[index];
                                return Slidable(
                                  key: ValueKey(chatData['chatId']),
                                  endActionPane: ActionPane(
                                    motion: const DrawerMotion(),
                                    children: [
                                      // --- MUTE NOTIFICATION ---
                                      StreamBuilder<DocumentSnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('chats')
                                            .doc(chatData['chatId'])
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          bool isMuted = false;
                                          if (snapshot.hasData &&
                                              snapshot.data!.data() != null) {
                                            final chat =
                                                snapshot.data!.data()
                                                    as Map<String, dynamic>;
                                            final muteMap =
                                                Map<String, dynamic>.from(
                                                  chat['mute'] ?? {},
                                                );
                                            isMuted =
                                                muteMap[loggedInUser!.uid] ??
                                                false;
                                          }

                                          return SlidableAction(
                                            onPressed: (_) async {
                                              final chatRef = FirebaseFirestore
                                                  .instance
                                                  .collection('chats')
                                                  .doc(chatData['chatId']);

                                              await chatRef.set({
                                                'mute': {
                                                  loggedInUser!.uid: !isMuted,
                                                },
                                              }, SetOptions(merge: true));

                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    isMuted
                                                        ? "Notifications unmuted"
                                                        : "Notifications muted",
                                                  ),
                                                ),
                                              );
                                            },
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,

                                            // dyanmic icon and label based sa isMuted
                                            icon: isMuted
                                                ? Icons.notifications_off
                                                : Icons.notifications,
                                            label: isMuted ? 'Unmute' : 'Mute',
                                          );
                                        },
                                      ),

                                      // --- BLOCK CONTACT (dynamic) ---
                                      StreamBuilder<DocumentSnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(loggedInUser!.uid)
                                            .snapshots(),
                                        builder: (context, userSnap) {
                                          bool isBlocked = false;
                                          if (userSnap.hasData &&
                                              userSnap.data!.data() != null) {
                                            final userData =
                                                userSnap.data!.data()
                                                    as Map<String, dynamic>;
                                            final blockedMap =
                                                Map<String, dynamic>.from(
                                                  userData['blocked'] ?? {},
                                                );
                                            final entry =
                                                blockedMap[chatData['userData']['uid']];

                                            // normalize (can be bool or map depending on old schema)
                                            if (entry is bool) {
                                              isBlocked = entry;
                                            } else if (entry
                                                is Map<String, dynamic>) {
                                              isBlocked =
                                                  entry['blocked'] == true;
                                            }
                                          }

                                          return SlidableAction(
                                            onPressed: (_) async {
                                              if (!isBlocked) {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text(
                                                      "Block Contact",
                                                    ),
                                                    content: const Text(
                                                      "Are you sure you want to block this contact?",
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              ctx,
                                                              false,
                                                            ),
                                                        child: const Text(
                                                          "Cancel",
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              ctx,
                                                              true,
                                                            ),
                                                        child: const Text(
                                                          "Block",
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm != true) return;
                                              }

                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(loggedInUser!.uid)
                                                  .set({
                                                    'blocked': {
                                                      chatData['userData']['uid']: {
                                                        'blocked': !isBlocked,
                                                        'blockedAt': !isBlocked
                                                            ? FieldValue.serverTimestamp()
                                                            : null,
                                                      },
                                                    },
                                                  }, SetOptions(merge: true));

                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    isBlocked
                                                        ? "Contact unblocked"
                                                        : "Contact blocked",
                                                  ),
                                                ),
                                              );
                                            },
                                            backgroundColor: isBlocked
                                                ? Colors.green
                                                : Colors.red,
                                            foregroundColor: Colors.white,
                                            icon: isBlocked
                                                ? Icons.lock_open
                                                : Icons.block,
                                            label: isBlocked
                                                ? 'Unblock'
                                                : 'Block',
                                          );
                                        },
                                      ),

                                      // --- DELETE (dynamic) --
                                      SlidableAction(
                                        onPressed: (_) async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text(
                                                "Delete Conversation",
                                              ),
                                              content: const Text(
                                                "Are you sure you want to delete this conversation? This action cannot be undone.",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                  child: const Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, true),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),
                                                  child: const Text("Delete"),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            await Provider.of<ChatProvider>(
                                              context,
                                              listen: false,
                                            ).deleteConversation(
                                              chatData['chatId'],
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Conversation deleted",
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        backgroundColor: Colors.grey,
                                        foregroundColor: Colors.white,
                                        icon: Icons.delete,
                                        label: 'Delete',
                                      ),
                                    ],
                                  ),
                                  child: CustomUserCardWidget(
                                    photoUrl:
                                        chatData['userData']['photoUrl']
                                            as String?,
                                    userId: chatData['userData']['uid'],
                                    userName:
                                        chatData['userData']['name'] ??
                                        'Unknown',
                                    nickname: chatData['nickname'],
                                    lastMessage: chatData['lastMessage'],
                                    lastMessageSenderId:
                                        chatData['lastMessageSenderId'],
                                    lastMessageTime: chatData['timeStamp'],
                                    lastMessageStatus: messageStatusFromString(
                                      chatData['lastMessageStatus'],
                                    ),
                                    currentUserId: loggedInUser!.uid,
                                    isMuted: chatData['isMuted'] ?? false,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                            chatId: chatData['chatId'],
                                            receiverId:
                                                chatData['userData']['uid'],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
