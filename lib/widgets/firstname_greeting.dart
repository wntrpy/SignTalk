import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:signtalk/app_constants.dart';

class FirstNameGreeting extends StatelessWidget {
  const FirstNameGreeting({super.key});

  String _extractFirstName(DocumentSnapshot? snapshot) {
    final userData = snapshot?.data() as Map<String, dynamic>?;
    final fullName = (userData?['name'] ?? 'User');
    return fullName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Text("Hello!");
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }

        final firstName = _extractFirstName(snapshot.data);

        return Text(
          "Hello, $firstName!",
          style: const TextStyle(
            fontSize: AppConstants.fontSizeLarge,
            color: AppConstants.white,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}
