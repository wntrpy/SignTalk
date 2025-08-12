import 'package:flutter/material.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/screens/chat_screens/chat_screen.dart';
import 'package:signtalk/widgets/buttons/custom_circle_pfp_button.dart';

//TODO: slidable, design sa figma

class CustomUserCardWidget extends StatelessWidget {
  final String chatId;
  final String lastMessage;
  final DateTime timestamp;
  final Map<String, dynamic> receiverData;

  const CustomUserCardWidget({
    super.key,
    required this.lastMessage,
    required this.timestamp,
    required this.chatId,
    required this.receiverData,
  });

  @override
  Widget build(BuildContext context) {
    return lastMessage != ""
        ? ListTile(
            leading: CustomCirclePfpButton(
              borderColor: AppConstants.darkViolet,
              userImage: AppConstants.default_user_pfp,
            ),
            title: Text(receiverData['name']),
            subtitle: Text(lastMessage, maxLines: 2),
            trailing: Text(
              '${timestamp.hour} : ${timestamp.minute}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatId: chatId,
                    receiverId: receiverData['uid'],
                  ),
                ),
              );
            },
          )
        : Container();
  }
}
