import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/providers/chat_provider.dart';

bool isToggled = false; //TODO: fix

List<Map<String, dynamic>> getReceiverProfileOptions(
  BuildContext context, {
  required String chatId,
  required String loggedInUserId,
  required String receiverId,
}) {
  return [
    {
      'optionText': 'Change Nickname',
      'iconPath': AppConstants.receiver_change_nickname_icon,
      'onTap': () async {
        final newName = await showDialog<String>(
          context: context,
          builder: (context) {
            String temp = '';
            return AlertDialog(
              title: const Text("Change Nickname"),
              content: TextField(
                onChanged: (value) => temp = value,
                decoration: const InputDecoration(hintText: "Enter nickname"),
              ),
              actions: [
                // cancel
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                // reset to original name from users collection
                TextButton(
                  onPressed: () async {
                    try {
                      final userDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(receiverId)
                          .get();
                      final originalName =
                          userDoc.data()?['name'] ?? 'Unknown User';

                      // update nickname in chats doc
                      await FirebaseFirestore.instance
                          .collection('chats')
                          .doc(chatId)
                          .set({
                            'nicknames': {
                              loggedInUserId: {receiverId: originalName},
                            },
                          }, SetOptions(merge: true));

                      Navigator.pop(context, originalName);
                    } catch (e) {
                      Navigator.pop(context); // close if may unexpected error
                    }
                  },
                  child: const Text("Reset"),
                ),
                // save new nickname
                TextButton(
                  onPressed: () => Navigator.pop(context, temp),
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );

        if (newName != null && newName.trim().isNotEmpty) {
          // update Firestore nicknames (if not reset already handled above)
          await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
            'nicknames': {
              loggedInUserId: {receiverId: newName},
            },
          }, SetOptions(merge: true));
        }
      },
    },
    {
      'optionText': "3D Avatar Sign Language",
      'iconPath': AppConstants.receiver_avatar_icon,
      'trailingWidget': Switch(
        value: isToggled,
        onChanged: (val) {
          isToggled = val;
        },
      ),
    },
    {
      'optionText': "Translated Voice Speech",
      'iconPath': AppConstants.receiver_voice_speech_icon,
      'trailingWidget': StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          final chatData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final ttsMap = chatData['ttsEnabled'] as Map<String, dynamic>? ?? {};
          final ttsForMe = ttsMap[loggedInUserId] ?? false;

          return Switch(
            value: ttsForMe,
            onChanged: (val) async {
              await FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .set({
                    'ttsEnabled': {loggedInUserId: val},
                  }, SetOptions(merge: true));
            },
          );
        },
      ),
    },

    {
      'optionText': 'Mute Notification',
      'iconPath': '',
      'fallbackIcon': (context) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Icon(Icons.notifications, color: Colors.grey);
            }

            final chatData =
                snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final muteMap = chatData['mute'] as Map<String, dynamic>? ?? {};
            final isMuted = muteMap[loggedInUserId] ?? false;

            return Icon(
              isMuted ? Icons.notifications_off : Icons.notifications,
              color: isMuted ? Colors.white : Colors.white,
              size: 50,
            );
          },
        );
      },

      'trailingWidget': StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();

          final chatData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final muteMap = chatData['mute'] as Map<String, dynamic>? ?? {};
          final isMuted = muteMap[loggedInUserId] ?? false;

          return Switch(
            value: isMuted,
            onChanged: (val) async {
              await FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .set({
                    'mute': {loggedInUserId: val},
                  }, SetOptions(merge: true));
            },
          );
        },
      ),
    },

    {
      'optionText': 'Block Contact',
      'iconPath': AppConstants.receiver_block_contact_icon,
      'onTap': () async {
        final loggedInUser = FirebaseAuth.instance.currentUser;
        if (loggedInUser == null) return;

        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Block Contact"),
            content: const Text(
              "Are you sure you want to block this user? You won’t be able to send or receive messages until you unblock.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Block"),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(loggedInUser.uid)
              .set({
                'blocked': {
                  receiverId: {
                    'blocked': true,
                    'blockedAt': FieldValue.serverTimestamp(),
                  },
                },
              }, SetOptions(merge: true));

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Contact blocked")));
        }
      },
    },

    {
      'optionText': 'Delete Conversation',
      'iconPath': AppConstants.receiver_delete_icon,
      'onTap': () async {
        await Provider.of<ChatProvider>(
          context,
          listen: false,
        ).deleteConversation(chatId);
        Navigator.pop(context); // close profile
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Conversation deleted")));
      },
    },
  ];
}
