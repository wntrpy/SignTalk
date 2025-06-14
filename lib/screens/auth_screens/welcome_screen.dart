import 'package:flutter/material.dart';
import 'package:signtalk/main.dart';
import 'package:signtalk/widgets/buttons/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(MyApp.welcome_screen_bg, fit: BoxFit.cover),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Registered Successfully!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 30),

              Image.asset(MyApp.welcome_screen_text),
              SizedBox(height: 50),

              Image.asset(MyApp.welcome_screen_icon),
              SizedBox(height: 50),

              CustomButton(
                buttonText: "Start Chatting now!",
                colorCode: MyApp.orange,
                buttonWidth: 300,
                buttonHeight: 70,
                onPressed: () {}, //TODO: FIX LATER, NAVIGATE TO HOME
                textSize: 24,
                borderRadiusValue: 15,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
