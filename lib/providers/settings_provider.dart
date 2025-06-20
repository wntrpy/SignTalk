import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------- GLOBAL CHECKER FOR DARK MODE VALUE ----------------------
final darkModeProvider = StateProvider<bool>((ref) => false);

// ---------------------- GLOBAL CHECKER KUNG ANONG SETTINGS OPTIONS YUNG ACTIVE ----------------------
final activeSettingProvider = StateProvider<String?>((ref) => null);
