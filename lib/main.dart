import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // for providerscope
import 'package:provider/provider.dart' as provider;
import 'package:signtalk/core/navigation.dart';
import 'package:signtalk/providers/dark_mode_provider.dart';
import 'package:signtalk/providers/auth_provider.dart';
import 'package:signtalk/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';


void main() async {
  // Initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); 


 runApp(
  provider.MultiProvider(
    providers: [
      provider.ChangeNotifierProvider(create: (_) => AuthProvider()),
    ],
    child: ProviderScope(child: const MyApp()),
  ),
);

}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider);
    print("Dark mode $isDarkMode");

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), //default color ng icons (white)
        //TODO: add other theme if kelanganin
      ),
      darkTheme: ThemeData.dark().copyWith(
        iconTheme: const IconThemeData(
          color: Colors.black,
        ), //color black for dark mode
        //TODO: dark theme if kelangain
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
    );
  }

 
}
