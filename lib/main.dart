import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/screens/auth_screens/forget_password_new_password.dart';
import 'package:signtalk/screens/auth_screens/forget_password_screen.dart';
import 'package:signtalk/screens/auth_screens/forget_password_verification.dart';
import 'package:signtalk/screens/auth_screens/login_screen.dart';
import 'package:signtalk/screens/auth_screens/registration_screen.dart';
import 'package:signtalk/screens/auth_screens/welcome_screen.dart';
import 'package:signtalk/screens/chat_screens/home_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  //colors nakabased sa figma
  static const Color darkViolet = Color(0xFF481872); // dark violet
  static const Color lightViolet = Color(0xFF6F22A3); // light violet
  static const Color orange = Color(0xFFFF8B00); // orange
  static const Color red = Color(0xFFFF0000); // red
  static const Color white = Color.fromARGB(255, 255, 255, 255); // white
  static const Color black = Color.fromARGB(255, 0, 0, 0); // black

  //fonts size based sa figma
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 20.0;
  static const double fontSizeExtraLarge = 24.0;

  //image paths
  static const String signtalk_bg = 'assets/images/signtalk_bg.png';
  static const String signtalk_logo = 'assets/images/signtalk_logo.png';
  static const String google_logo = 'assets/images/google_icon.png';
  static const String welcome_screen_icon =
      'assets/images/welcome_screen_icon.png';
  static const String welcome_screen_text =
      'assets/images/welcome_screen_text.png';
  static const String welcome_screen_bg = 'assets/images/welcome_screen_bg.png';

  //routes using go_router
  final GoRouter _router = GoRouter(
    initialLocation: '/splash_screen',
    routes: [
      //--------------------------AUTHENTICATIONS---------------------------
      GoRoute(
        path: '/splash_screen',
        builder: (context, state) => SplashScreen(),
      ),
      GoRoute(
        path: '/login_screen',
        builder: (context, state) => LoginScreen(),
      ),
      GoRoute(
        path: '/registration_screen',
        builder: (context, state) => RegistrationScreen(),
      ),
      GoRoute(
        path: '/welcome_screen',
        builder: (context, state) => WelcomeScreen(),
      ),
      GoRoute(
        path: '/forget_password_screen',
        builder: (context, state) => ForgetPasswordScreen(),
      ),
      GoRoute(
        path: '/forget_password_verification',
        builder: (context, state) => ForgetPasswordVerification(),
      ),
      GoRoute(
        path: '/forget_password_new_password',
        builder: (context, state) => ForgetPasswordNewPassword(),
      ),

      //--------------------------CHATS---------------------------
      GoRoute(path: '/home_screen', builder: (context, state) => HomeScreen()),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),
    );
  }
}
