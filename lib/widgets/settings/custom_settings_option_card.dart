import 'package:flutter/material.dart';
import 'package:signtalk/app_constants.dart';

class CustomSettingsOptionCard extends StatelessWidget {
  final String optionText;
  final Widget trailing; // anywidgetg
  final VoidCallback? onTap; // funct

  const CustomSettingsOptionCard({
    super.key,
    required this.optionText,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, //clicabke
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        decoration: BoxDecoration(
          color: AppConstants.darkViolet,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: AppConstants.darkViolet.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              optionText,
              style: TextStyle(
                color: AppConstants.white,
                fontWeight: FontWeight.bold,
                fontSize: AppConstants.fontSizeMedium,
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
