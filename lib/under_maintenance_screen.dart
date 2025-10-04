import 'package:flutter/material.dart';
import '../app_constants.dart';

class UnderMaintenanceScreen extends StatelessWidget {
  const UnderMaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(AppConstants.signtalk_logo, height: 120, width: 120),
            const SizedBox(height: 40),

            // Maintenance Icon
            Icon(
              Icons.build_circle_rounded,
              size: 80,
              color: AppConstants.lightViolet,
            ),
            const SizedBox(height: 40),

            // Main Text
            Text(
              "Under Maintenance",
              style: TextStyle(
                fontSize: AppConstants.fontSizeExtraLarge,
                fontWeight: FontWeight.bold,
                color: AppConstants.darkViolet,
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                "We're working hard to improve SignTalk for you.\nPlease check back later.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppConstants.fontSizeMedium,
                  color: AppConstants.lightViolet,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Optional: Refresh Button
            ElevatedButton(
              onPressed: () {
                // Add refresh logic here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Refresh",
                style: TextStyle(
                  color: AppConstants.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
