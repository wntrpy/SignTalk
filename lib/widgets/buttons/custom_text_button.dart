import 'package:flutter/material.dart';

class CustomTextButton extends StatelessWidget {
  final String buttonText;
  final void Function() onPressed;
  final Color textColor;

  const CustomTextButton({
    super.key,
    required this.buttonText,
    required this.onPressed,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(buttonText, style: TextStyle(color: textColor)),
    );
  }
}
