import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/screens/auth_screens/forget_password_new_password.dart';
import 'package:signtalk/screens/auth_screens/forget_password_screen.dart';
import 'package:signtalk/screens/auth_screens/forget_password_verification.dart';
import 'package:signtalk/screens/auth_screens/login_screen.dart';
import 'package:signtalk/screens/auth_screens/registration_screen.dart';
import 'package:signtalk/screens/auth_screens/welcome_screen.dart';
import 'package:signtalk/screens/chat_screens/chat_screen.dart';
import 'package:signtalk/screens/chat_screens/home_screen.dart';
import 'package:signtalk/screens/chat_screens/receiver_profile_screen.dart';
import 'package:signtalk/screens/chat_screens/user_profile_screen.dart';
import 'package:signtalk/screens/settings_screens/settings_alphabet_chart_screen.dart';
import 'package:signtalk/screens/settings_screens/settings_screen.dart';
import 'package:signtalk/screens/splash_screen.dart';

//routes using go_router
final GoRouter router = GoRouter(
  initialLocation: '/splash_screen',
  routes: [
    // ---------------------- AUTHENTICATION ----------------------
    goRouteWithSlide('/login_screen', (context) => LoginScreen()),
    goRouteWithSlide('/registration_screen', (context) => RegistrationScreen()),
    goRouteWithSlide('/welcome_screen', (context) => WelcomeScreen()),
    goRouteWithSlide(
      '/forget_password_screen',
      (context) => ForgetPasswordScreen(),
    ),
    goRouteWithSlide(
      '/forget_password_verification',
      (context) => ForgetPasswordVerification(),
    ),
    goRouteWithSlide(
      '/forget_password_new_password',
      (context) => ForgetPasswordNewPassword(),
    ),

    // ------------------------ CHATS ----------------------------
    goRouteWithSlide('/home_screen', (context) => HomeScreen()),
    goRouteWithSlide('/profile_screen', (context) => UserProfileScreen()),
    goRouteWithSlide('/chat_screen', (context) => ChatScreen()),
    goRouteWithSlide(
      '/receiver_profile_screen',
      (context) => ReceiverProfileScreen(),
    ),

    // ------------------------ SETTINGS ----------------------------
    goRouteWithSlide('/settings_screen', (context) => SettingScreen()),
    goRouteWithSlide(
      '/settings_alphabet_chart_screen',
      (context) => SettingsAlphabetChart(),
    ),

    // ------------------------ SPLASH (no transition) ----------
    GoRoute(
      path: '/splash_screen',
      builder: (context, state) => SplashScreen(),
    ),
  ],
);

//transition
GoRoute goRouteWithSlide(String path, Widget Function(BuildContext) builder) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: builder(context), // Lazy build
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.ease));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    ),
  );
}
