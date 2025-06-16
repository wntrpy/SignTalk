import 'package:flutter/material.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/widgets/buttons/custom_button.dart';

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
        width: dialogWidth ?? 100,
        height: dialogHeight ?? 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppConstants.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // DIALOG TITLE
            Text(
              dialogTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppConstants.fontSizeLarge,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // DIALOG TEXT CONTENT
            Text(
              dialogTextContent,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppConstants.fontSizeLarge,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // DIALOG BUTTON
            CustomButton(
              buttonText: buttonText,
              colorCode: AppConstants.orange,
              buttonWidth: buttonWidth ?? 150,
              buttonHeight: buttonHeight ?? 50,
              onPressed: onPressed,
              textSize: AppConstants.fontSizeMedium,
            ),
          ],
        ),
      ),
    );
  }
}
