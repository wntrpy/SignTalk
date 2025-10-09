import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:signtalk/app_constants.dart';

class SettingsAlphabetChart extends ConsumerWidget {
  const SettingsAlphabetChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("No user logged in")));
    }

    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: userDocRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("User data not found"));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final displayName = userData['name'] ?? '';
        final photoUrl = userData['photoUrl'] ?? '';

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Background
              Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),

              Column(
                children: [
                  // ---------------- Custom App Bar ----------------
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 24.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Back Button
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          iconSize: 30.0,
                          onPressed: () => context.pop(),
                        ),

                        // Title
                        Expanded(
                          child: Text(
                            "ASL Alphabet",
                            style: TextStyle(
                              color: AppConstants.white,
                              fontSize: AppConstants.fontSizeExtraLarge,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Profile Picture or Fallback Initial
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          backgroundImage: (photoUrl.isNotEmpty)
                              ? NetworkImage(photoUrl)
                              : null,
                          child: (photoUrl.isEmpty)
                              ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: AppConstants.darkViolet,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),

                  // ---------------- Scrollable Chart ----------------
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 20.0,
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            AppConstants.asl_chart,
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
