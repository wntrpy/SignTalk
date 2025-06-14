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

  static const String karina_pic = 'assets/images/karina.jpg';

  //TODO: ibukod mo ng file to
  //routes using go_router
  final GoRouter _router = GoRouter(
    initialLocation: '/splash_screen',
    routes: [
      // ---------------------- AUTHENTICATION ----------------------
      _goRouteWithSlide('/login_screen', LoginScreen()),
      _goRouteWithSlide('/registration_screen', RegistrationScreen()),
      _goRouteWithSlide('/welcome_screen', WelcomeScreen()),
      _goRouteWithSlide('/forget_password_screen', ForgetPasswordScreen()),
      _goRouteWithSlide(
        '/forget_password_verification',
        ForgetPasswordVerification(),
      ),
      _goRouteWithSlide(
        '/forget_password_new_password',
        ForgetPasswordNewPassword(),
      ),

      // ------------------------ CHATS ----------------------------
      _goRouteWithSlide('/home_screen', HomeScreen()),

      // ------------------------ SPLASH (no transition) ----------
      GoRoute(
        path: '/splash_screen',
        builder: (context, state) => SplashScreen(),
      ),
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

GoRoute _goRouteWithSlide(String path, Widget page) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<Offset>(
          begin: const Offset(1.0, 0.0), // Slide in from right
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.ease));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    ),
  );
}
