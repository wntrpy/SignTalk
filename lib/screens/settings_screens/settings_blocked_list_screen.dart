import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signtalk/app_constants.dart';

class SettingsBlockedListScreen extends StatelessWidget {
  const SettingsBlockedListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),

        title: const Text(
          "Blocked Users",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppConstants.darkViolet,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final blockedMap = Map<String, dynamic>.from(
            userData['blocked'] ?? {},
          );

          // Filter only users who are blocked == true
          final blockedUsers = blockedMap.entries
              .where(
                (e) =>
                    e.value is Map &&
                    (e.value['blocked'] == true || e.value == true),
              ) // fallback if old format
              .toList();

          if (blockedUsers.isEmpty) {
            return const Center(child: Text("No blocked users"));
          }

          return ListView.builder(
            itemCount: blockedUsers.length,
            itemBuilder: (context, index) {
              final userId = blockedUsers[index].key;
              final data = blockedUsers[index].value;
              final blockedAt = data is Map ? data['blockedAt'] : null;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    return const SizedBox.shrink();
                  }

                  final userInfo =
                      userSnap.data!.data() as Map<String, dynamic>? ?? {};
                  final name = userInfo['name'] ?? 'Unknown';

                  String blockedDateText = "";
                  if (blockedAt is Timestamp) {
                    final date = blockedAt.toDate();
                    blockedDateText =
                        "Blocked on ${DateFormat('yMMMd').add_jm().format(date)}";
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "?",
                      ),
                    ),
                    title: Text(name),
                    subtitle: Text(blockedDateText),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.remove_circle,
                        color: AppConstants.darkViolet,
                      ),
                      onPressed: () async {
                        // Unblock user
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser.uid)
                            .set({
                              'blocked': {userId: FieldValue.delete()},
                            }, SetOptions(merge: true));

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("$name unblocked")),
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
    );
  }
}
