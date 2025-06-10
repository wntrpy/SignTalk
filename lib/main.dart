import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
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
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 20.0;
  static const double fontSizeExtraLarge = 24.0;

  //image paths, para everytime na kakailanganin, tatawagin nalang yung static var
  static const String signtalk_bg = 'assets/images/signtalk_bg.png';
  static const String signtalk_logo = 'assets/images/signtalk_logo.png';
  static const String google_logo = 'assets/images/google_icon.png';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),

      home: SplashScreen(),
    );
  }
}
