import 'package:flutter/material.dart';
import 'package:signtalk/main.dart';

class CustomSettingsOptionCard extends StatelessWidget {
  final String optionText;
  const CustomSettingsOptionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
      decoration: BoxDecoration(
        color: MyApp.darkViolet,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: MyApp.darkViolet.withOpacity(0.5), // Shadow color
            spreadRadius: 2, // Spread radius
            blurRadius: 7, // Blur radius
            offset: Offset(0, 3), // Shadow position (x,y)
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            "Switch Language",
            style: TextStyle(
              color: MyApp.white,
              fontWeight: FontWeight.bold,
              fontSize: MyApp.fontSizeMedium,
            ),
          ),
        ],
      ),
    );
  }
}
