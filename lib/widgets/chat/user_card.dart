import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signtalk/screens/chat_screens/chat_screen.dart';
/*
class UserCard extends ConsumerWidget {
  final Map<String, dynamic> user;

  const UserCard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //final currentUserId = ref.watch(currentUserIdProvider);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text(user['name'][0]), // First letter as fallback
      ),
      title: Text(user['name']),
      subtitle: Text(user['email'] ?? ''),
      // Inside onTap or GestureDetector in UserCard
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              recipientId: user['uid'],
              recipientName: user['name'],
              //  currentUserId: currentUserId,
            ),
          ),
        );
      },
    );
  }
}
*/