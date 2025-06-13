import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final Color colorCode; // background color
  final void Function() onPressed;
  final double iconSize;
  const CustomBackButton({
    super.key,
    required this.colorCode,
    required this.onPressed,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: colorCode),
      onPressed: onPressed,
      iconSize: iconSize,
    );
  }
}
