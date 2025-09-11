import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signtalk/core/firebase_api.dart';
import 'package:signtalk/providers/auth_provider.dart';
import 'package:signtalk/providers/system_status_provider.dart';
import 'package:signtalk/screens/auth_screens/login_screen.dart';
import 'package:signtalk/screens/chat_screens/home_screen.dart';
import 'package:signtalk/under_maintenance_screen.dart';

class AuthenticationWrapper extends ConsumerWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authProvider = ref.watch(authProviderProvider);
    final systemStatus = ref.watch(systemStatusProvider);

    return systemStatus.when(
      data: (isActive) {
        if (!isActive) {
          // system under maintenance
          return const UnderMaintenanceScreen();
        }

        // system is active = check if user is signed in
        /*     if (authProvider.isSignedin) {
          return const HomeScreen();
        } else {
          FirebaseApi.saveFcmToken();

          return const LoginScreen();
        }*/

        // inside AuthenticationWrapper build(...)
        if (authProvider.isSignedin) {
          // Save token for signed-in user
          FirebaseApi.saveFcmToken(); // fire-and-forget
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text("Error: $err"))),
    );
  }
}
