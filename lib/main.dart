import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:signtalk/app_colors.dart';
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

  // initialize notification listeners & local notifications
  NotificationService().init();
}

Future<void> addMissingPhotoUrlField() async {
  final usersCollection = FirebaseFirestore.instance.collection('users');

  final querySnapshot = await usersCollection.get();

  for (var doc in querySnapshot.docs) {
    final data = doc.data();

    // If 'photoUrl' does not exist, add it as an empty string
    if (!data.containsKey('photoUrl')) {
      await usersCollection.doc(doc.id).update({'photoUrl': ''});
      print('✅ Added photoUrl for user: ${doc.id}');
    }
  }

  print('🎉 Migration completed: All users now have a photoUrl field.');
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider);
    addMissingPhotoUrlField();
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(colorScheme: AppColors.lightScheme, useMaterial3: true),
      darkTheme: ThemeData(
        colorScheme: AppColors.darkScheme,
        useMaterial3: true,
      ),
    );
  }
}
