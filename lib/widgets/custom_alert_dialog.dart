import 'package:flutter/material.dart';
import 'package:signtalk/main.dart';
import 'package:signtalk/widgets/custom_button.dart';

class CustomAlertDialog extends StatelessWidget {
  final String dialogTitle;
  final String dialogTextContent;
  final String buttonText;
  final double? buttonHeight;
  final double? buttonWidth;
  final double? dialogWidth; // dialo
  final double? dialogHeight; // daol;go height
  final void Function() onPressed;

  const CustomAlertDialog({
    super.key,
    required this.dialogTitle,
    required this.dialogTextContent,
    required this.buttonText,
    this.buttonHeight,
    this.buttonWidth,
    this.dialogWidth,
    this.dialogHeight,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: MyApp.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Only affects height if height is not provided
          children: [
            // DIALOG TITLE
            Text(
              dialogTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: MyApp.fontSizeLarge,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // DIALOG TEXT CONTENT
            Text(
              dialogTextContent,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: MyApp.fontSizeLarge,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // DIALOG BUTTON
            CustomButton(
              buttonText: buttonText,
              colorCode: MyApp.orange,
              buttonWidth: buttonWidth ?? 150,
              buttonHeight: buttonHeight ?? 50,
              onPressed: onPressed,
              textSize: MyApp.fontSizeMedium,
            ),
          ],
        ),
      ),
    );
  }
}
