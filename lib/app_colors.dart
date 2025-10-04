import 'package:flutter/material.dart';

class AppColors {
  // 🎨 Base palette (from your Figma)
  static const Color darkViolet = Color(0xFF481872);
  static const Color lightViolet = Color(0xFF6F22A3);
  static const Color orange = Color(0xFFFF8B00);
  static const Color red = Color(0xFFFF0000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color extraLightViolet = Color(0xFFBA71E3);

  // 🌞 Light mode mapping
  static final lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: lightViolet,
    secondary: extraLightViolet,
    surface: white,
    error: red,
    onPrimary: white,
    onSecondary: black,
    onSurface: black,
    onError: white,
  );

  // 🌙 Dark mode mapping
  static final darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: darkViolet,
    secondary: orange,
    surface: black, // softer dark bg
    error: red,
    onPrimary: white,
    onSecondary: white,
    onSurface: white,
    onError: black,
  );

  /// Get current scheme from context
  static ColorScheme of(BuildContext context) => Theme.of(context).colorScheme;
}
