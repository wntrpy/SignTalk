import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/screens/chat_screens/receiver_profile_screen.dart';

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
      'optionText': 'Notification',
      'iconPath': AppConstants.receiver_notification_icon,
      'onTap': () => print("Notifications tapped"),
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
