// lib/widgets/chat/search_user_card_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/providers/chat_provider.dart';
import 'package:signtalk/screens/chat_screens/chat_screen.dart';
import 'package:signtalk/widgets/buttons/custom_circle_pfp_button.dart';

class SearchUserCardWidget extends StatelessWidget {
  final String userId;
  final String name;
  final String email;

  const SearchUserCardWidget({
    super.key,
    required this.userId,
    required this.name,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    return ListTile(
      leading: CustomCirclePfpButton(
        borderColor: Colors.white,
        userImage: AppConstants.default_user_pfp,
      ),
      title: Text(name),
      subtitle: Text(email),
      onTap: () async {
        final chatId =
            await chatProvider.getChatRoom(userId) ??
            await chatProvider.createChatRoom(userId);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatScreen(chatId: chatId, receiverId: userId),
          ),
        );
      },
    );
  }
}
