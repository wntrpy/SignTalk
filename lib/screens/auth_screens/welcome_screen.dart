import 'package:flutter/material.dart';
import 'package:signtalk/main.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(MyApp.signtalk_bg, fit: BoxFit.cover),

          Column(
            children: [
              Text("Registered Successfully!"),

              Image.asset(MyApp.welcome_screen_icon),
            ],
          ),
        ],
      ),
    );
  }
}
