import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signtalk/providers/auth_provider.dart';
import 'package:signtalk/screens/auth_screens/login_screen.dart';
import 'package:signtalk/screens/chat_screens/home_screen.dart';

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Check if the auth state is signed in
        if (authProvider.isSignedin) {
          return HomeScreen();
        }
        else {
          // If not signed in, redirect to the login screen
          return LoginScreen();
        }
      },
    );

  }
}