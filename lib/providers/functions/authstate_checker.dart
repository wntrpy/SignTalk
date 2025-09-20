import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signtalk/core/firebase_api.dart';
import 'package:signtalk/providers/auth_provider.dart';
import 'package:signtalk/providers/presence_service.dart';
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
    final presence = PresenceService();

    return systemStatus.when(
      data: (isActive) {
        if (!isActive) {
          presence.setUserOnline(false);

          return const UnderMaintenanceScreen();
        }

        if (authProvider.isSignedin) {
          // Save token
          FirebaseApi.saveFcmToken();

          // Set presence online (fire-and-forget)
          presence.setUserOnline(true);

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
