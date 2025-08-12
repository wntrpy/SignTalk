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
import 'package:signtalk/screens/auth_screens/2FA_screen.dart';
import 'package:signtalk/providers/functions/authstate_checker.dart';

//routes using go_router
final GoRouter router = GoRouter(
  initialLocation: '/splash_screen',
  routes: [
    goRouteWithSlide('/auth_wrapper', AuthenticationWrapper()),

    // ---------------------- AUTHENTICATION ----------------------
    goRouteWithSlide('/login_screen', LoginScreen()),
    goRouteWithSlide(
      '/2FA_screen',
      TwoFactorScreen(),
    ), // Two-Factor Authentication Screen
    goRouteWithSlide('/registration_screen', RegistrationScreen()),
    goRouteWithSlide('/welcome_screen', WelcomeScreen()),
    goRouteWithSlide('/forget_password_screen', ForgetPasswordScreen()),
    goRouteWithSlide(
      '/forget_password_verification',
      ForgetPasswordVerification(),
    ),
    goRouteWithSlide(
      '/forget_password_new_password',
      ForgetPasswordNewPassword(),
    ),

    // ------------------------ CHATS ----------------------------
    goRouteWithSlide('/home_screen', HomeScreen()),
    goRouteWithSlide('/profile_screen', UserProfileScreen()),
    // goRouteWithSlide('/chat_screen', ChatScreen(recipientId: '',, recipientName: '',, currentUserId: '',)),
    goRouteWithSlide('/receiver_profile_screen', ReceiverProfileScreen()),

    // ------------------------ SETTINGS ----------------------------
    goRouteWithSlide('/settings_screen', SettingScreen()),
    goRouteWithSlide(
      '/settings_alphabet_chart_screen',
      SettingsAlphabetChart(),
    ),

    // ------------------------ SPLASH (no transition) ----------
    GoRoute(
      path: '/splash_screen',
      builder: (context, state) => SplashScreen(),
    ),
  ],
);

//transition
GoRoute goRouteWithSlide(String path, Widget page) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: page,
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
