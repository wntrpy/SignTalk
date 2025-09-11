// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:signtalk/core/navigation.dart'; // contains router & navigatorKey
import 'package:signtalk/core/notification_service.dart';
import 'package:signtalk/providers/app_lifecylce.dart';
import 'package:signtalk/providers/chat_provider.dart';
import 'package:signtalk/providers/dark_mode_provider.dart';
import 'package:signtalk/providers/auth_provider.dart';
import 'package:signtalk/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:signtalk/providers/presence_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "key.env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // register background handler BEFORE runApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final presenceService = PresenceService();
  final lifecycleHandler = AppLifecycleReactor(presenceService);
  WidgetsBinding.instance.addObserver(lifecycleHandler);

  // runApp first so router/navigator exist
  runApp(
    provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(create: (_) => AuthProvider()),
        provider.ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: ProviderScope(child: const MyApp()),
    ),
  );

  // initialize notification listeners & local notifications (after runApp so router is attached)
  NotificationService().init();
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider);

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      darkTheme: ThemeData.dark().copyWith(
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
    );
  }
}
