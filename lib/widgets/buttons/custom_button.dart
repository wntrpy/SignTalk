import 'package:flutter/material.dart';
import 'package:signtalk/app_constants.dart';

class CustomButton extends StatelessWidget {
  final String buttonText;
  final Color colorCode;
  final double? buttonWidth;
  final double? buttonHeight;
  final void Function()? onPressed; // Made nullable with ?
  final Widget? icon;
  final Color? textColor;
  final double? textSize;
  final double? borderRadiusValue;

  const CustomButton({
    super.key,
    required this.buttonText,
    required this.colorCode,
    required this.buttonWidth,
    required this.buttonHeight,
    required this.onPressed,
    required this.textSize,
    this.borderRadiusValue,
    this.icon,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    Color effectiveTextColor = textColor ?? AppConstants.white;

    return SizedBox(
      width: buttonWidth,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed, // Will be null when disabled
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null
              ? colorCode
              : Colors.grey, // Grey when disabled
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusValue ?? 30),
            side: BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            Text(
              buttonText,
              style: TextStyle(
                fontSize: textSize,
                color: effectiveTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
