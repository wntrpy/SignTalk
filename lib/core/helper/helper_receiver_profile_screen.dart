import 'package:flutter/material.dart';
import 'package:signtalk/app_constants.dart';

bool isToggled = false; //TODO: fix

List<Map<String, dynamic>> getReceiverProfileOptions(BuildContext context) {
  return [
    {
      'optionText': 'Change Nickname',
      'iconPath': AppConstants.receiver_change_nickname_icon,
    },
    {
      'optionText': "3D Avatar Sign Language",
      'iconPath': AppConstants.receiver_avatar_icon,
      'trailingWidget': Switch(onChanged: null, value: isToggled),
    },
    {
      'optionText': 'Translated Voice Speech',
      'iconPath': AppConstants.receiver_voice_speech_icon,
      'trailingWidget': Switch(onChanged: null, value: isToggled),
    },
    {
      'optionText': 'Notification',
      'iconPath': AppConstants.receiver_notification_icon,
    },
    {
      'optionText': 'Block Contact',
      'iconPath': AppConstants.receiver_block_contact_icon,
    },
    {'optionText': 'Delete', 'iconPath': AppConstants.receiver_delete_icon},
  ];
}
