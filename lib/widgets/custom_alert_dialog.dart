import 'package:flutter/material.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/widgets/buttons/custom_button.dart';

class CustomAlertDialog extends StatelessWidget {
  final String dialogTitle;
  final String?
  dialogTextContent; //if text widget, then dapat iprovide lang yung content ng text
  final String buttonText;
  final double? buttonHeight;
  final double? buttonWidth;
  final double? dialogWidth;
  final double? dialogHeight;
  final VoidCallback onPressed;
  final Widget? customWidget;
  final bool showCancelButton;
  final VoidCallback? onCancel;

  const CustomAlertDialog({
    super.key,
    required this.dialogTitle,
    required this.buttonText,
    this.buttonHeight,
    this.buttonWidth,
    this.dialogWidth,
    this.dialogHeight,
    required this.onPressed,
    this.customWidget,
    this.showCancelButton = false,
    this.onCancel,
    this.dialogTextContent,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth ?? 320,
        height: dialogHeight ?? 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppConstants.darkViolet,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                dialogTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.white,
                  fontSize: AppConstants.fontSizeLarge,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),

            // Custom Widget like TextField, Text, etc.
            Expanded(
              child:
                  customWidget ??
                  Text(
                    dialogTextContent ?? "No content",
                    textAlign: TextAlign.center,
                  ),
            ),

            const SizedBox(height: 16),

            // Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showCancelButton)
                  TextButton(
                    onPressed: onCancel ?? () => Navigator.of(context).pop(),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: AppConstants.fontSizeMedium,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                CustomButton(
                  buttonText: buttonText,
                  colorCode: AppConstants.orange,
                  buttonWidth: buttonWidth ?? 100,
                  buttonHeight: buttonHeight ?? 40,
                  onPressed: onPressed,
                  textSize: AppConstants.fontSizeMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
