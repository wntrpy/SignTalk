import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:signtalk/app_constants.dart';

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
            print("TEST NICKNAME");
            String temp = '';
            return AlertDialog(
              title: const Text("Change Nickname"),
              content: TextField(
                onChanged: (value) => temp = value,
                decoration: const InputDecoration(hintText: "Enter nickname"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, temp),
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );

        if (newName != null && newName.trim().isNotEmpty) {
          // update Firestore nicknames
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
      'optionText': 'Translated Voice Speech',
      'iconPath': AppConstants.receiver_voice_speech_icon,
      'trailingWidget': Switch(
        value: isToggled,
        onChanged: (val) {
          isToggled = val;
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
      'onTap': () => print("Block tapped"),
    },
    {
      'optionText': 'Delete',
      'iconPath': AppConstants.receiver_delete_icon,
      'onTap': () => print("Delete tapped"),
    },
  ];
}
