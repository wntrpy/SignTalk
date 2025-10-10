import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signtalk/providers/chat_provider.dart';
import 'package:signtalk/screens/chat_screens/chat_screen.dart';
import 'package:signtalk/widgets/custom_profile_avatar.dart';

class SearchUserCardWidget extends StatelessWidget {
  final String userId;
  final String name;
  final String email;
  final String photoUrl;

  const SearchUserCardWidget({
    super.key,
    required this.userId,
    required this.name,
    required this.email,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    return ListTile(
      leading: CustomProfileAvatar(photoUrl: photoUrl, name: name),
      title: Text(name),
      subtitle: Text(email),
      onTap: () async {
        // Check if chat room exists
        final chatId = await chatProvider.getChatRoom(userId);

        // Navigate to ChatScreen
        // If chatId is null, ChatScreen will create it when first message is sent
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
