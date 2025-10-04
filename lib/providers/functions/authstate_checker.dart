import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:signtalk/core/firebase_api.dart';
import 'package:signtalk/providers/auth_provider.dart';
import 'package:signtalk/providers/presence_service.dart';
import 'package:signtalk/providers/system_status_provider.dart';
import 'package:signtalk/screens/auth_screens/login_screen.dart';
import 'package:signtalk/screens/chat_screens/home_screen.dart';
import 'package:signtalk/under_maintenance_screen.dart';

class AuthenticationWrapper extends ConsumerStatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  ConsumerState<AuthenticationWrapper> createState() =>
      _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends ConsumerState<AuthenticationWrapper> {
  Stream<User?>? _authStream;
  Stream<DocumentSnapshot>? _userDocStream;

  @override
  void initState() {
    super.initState();

    // listen to Firebase Auth state
    _authStream = FirebaseAuth.instance.authStateChanges();

    // listen to Firestore user doc
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userDocStream = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots();

      _userDocStream!.listen((doc) async {
        if (!doc.exists) {
          // user doc deleted by admin → force logout
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Your account has been deleted.')),
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = ref.watch(authProviderProvider);
    final systemStatus = ref.watch(systemStatusProvider);
    final presence = PresenceService();

    return systemStatus.when(
      data: (isActive) {
        if (!isActive) {
          presence.setUserOnline(false);
          return const UnderMaintenanceScreen();
        }

        // listen to auth state
        return StreamBuilder<User?>(
          stream: _authStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              final user = snapshot.data;

              if (user == null || !authProvider.isSignedin) {
                return const LoginScreen();
              } else {
                // Save token
                FirebaseApi.saveFcmToken();

                // Set presence online
                presence.setUserOnline(true);

                return const HomeScreen();
              }
            }
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text("Error: $err"))),
    );
  }
}
