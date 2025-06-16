// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signtalk/core/navigation.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //colors nakabased sa figma
  static const Color darkViolet = Color(0xFF481872); // dark violet
  static const Color lightViolet = Color(0xFF6F22A3); // light violet
  static const Color orange = Color(0xFFFF8B00); // orange
  static const Color red = Color(0xFFFF0000); // red
  static const Color white = Color.fromARGB(255, 255, 255, 255); // white
  static const Color black = Color.fromARGB(255, 0, 0, 0); // black

  //fonts size based sa figma
  static const double fontSizeExtraSmall = 9.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 20.0;
  static const double fontSizeExtraLarge = 24.0;

  //image paths
  static const String signtalk_bg = 'assets/images/signtalk_bg.png';
  static const String signtalk_logo = 'assets/icons/signtalk_logo.png';
  static const String google_logo = 'assets/icons/google_icon.png';
  static const String welcome_screen_icon =
      'assets/images/welcome_screen_icon.png';
  static const String welcome_screen_text =
      'assets/images/welcome_screen_text.png';
  static const String welcome_screen_bg = 'assets/images/welcome_screen_bg.png';

  static const String karina_pic = 'assets/images/karina.jpg';
  static const String default_user_pfp = 'assets/icons/default_user_pfp.jpg';

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),
    );
  }
}
