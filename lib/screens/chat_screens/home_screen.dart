import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/models/message_status.dart';
import 'package:signtalk/providers/chat_provider.dart';
import 'package:signtalk/screens/chat_screens/chat_screen.dart';
import 'package:signtalk/screens/chat_screens/user_search_screen.dart';
import 'package:signtalk/widgets/buttons/custom_circle_pfp_button.dart';
import 'package:signtalk/widgets/chat/custom_user_card_widget.dart';
import 'package:signtalk/widgets/custom_signtalk_logo.dart';
import 'package:signtalk/widgets/firstname_greeting.dart';

//TODO: walang email_lowercase kapag mag reregister

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
  }

  void getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        loggedInUser = user;
      });
    }
  }

  /*
  Future<Map<String, dynamic>> _fetchChatData(String chatId) async {
    //get the users, last message, and timestamp
    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .get();
    final chatData = chatDoc.data();
    final users = chatData!['users'] as List<dynamic>;

    //get the receiver id
    final receiverId = users.firstWhere((id) => id != loggedInUser!.uid);

    //get the receiver's user doc
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId)
        .get();
    final userData = userDoc.data()!;
    return {
      'chatId': chatId,
      'lastMessage': chatData['lastMessage'] ?? '',
      'timeStamp': chatData['timestamp']?.toDate() ?? DateTime.now(),
      'userData': userData,
    };
  }
*/

  Future<Map<String, dynamic>> _fetchChatData(String chatId) async {
    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .get();
    final chatData = chatDoc.data()!;
    final users = chatData['users'] as List<dynamic>;

    final receiverId = users.firstWhere((id) => id != loggedInUser!.uid);
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId)
        .get();
    final userData = userDoc.data()!;

    // --- check nickname ---
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

    return {
      'chatId': chatId,
      'lastMessage': chatData['lastMessage'] ?? '',
      'lastMessageSenderId': chatData['lastMessageSenderId'] ?? '',
      'lastMessageStatus': chatData['lastMessageStatus'] ?? 'sent',
      'timeStamp': chatData['timestamp']?.toDate() ?? DateTime.now(),
      'userData': userData,
      'nickname': nickname,
    };
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
                //-----------------------------------------HEADER--------------------------------------------//
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CustomSigntalkLogo(width: 60, height: 60),
                              const SizedBox(width: 10),
                              const FirstNameGreeting(),
                            ],
                          ),
                          CustomCirclePfpButton(
                            borderColor: AppConstants.white,
                            userImage: AppConstants.default_user_pfp,
                            onPressed: () => context.push('/profile_screen'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      //-----------------------------------------SEARCH BAR--------------------------------------------//
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
                        return FutureBuilder<List<Map<String, dynamic>>>(
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
                            final chatDataList = snapshot.data!;

                            // Sort newest to oldest
                            chatDataList.sort(
                              (a, b) =>
                                  b['timeStamp'].compareTo(a['timeStamp']),
                            );

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

                                      // --- BLOCK CONTACT ---
                                      SlidableAction(
                                        onPressed: (_) async {
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(loggedInUser!.uid)
                                              .set({
                                                'blocked': {
                                                  chatData['userData']['uid']:
                                                      true,
                                                },
                                              }, SetOptions(merge: true));

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text("Contact blocked"),
                                            ),
                                          );
                                        },
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        icon: Icons.block,
                                        label: 'Block',
                                      ),

                                      // --- DELETE CONVERSATION ---
                                      SlidableAction(
                                        onPressed: (_) async {
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
                                        },
                                        backgroundColor: Colors.grey,
                                        foregroundColor: Colors.white,
                                        icon: Icons.delete,
                                        label: 'Delete',
                                      ),
                                    ],
                                  ),
                                  child: CustomUserCardWidget(
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
