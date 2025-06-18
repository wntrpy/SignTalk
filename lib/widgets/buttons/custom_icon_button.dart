import 'package:flutter/material.dart';

class CustomIconButton extends StatelessWidget {
  final Image? imageIcon;
  final IconData? icon;
  final Color color;
  final double size;
  final VoidCallback onPressed;

  const CustomIconButton({
    super.key,
    this.imageIcon,
    this.icon,
    required this.color,
    required this.size,
    required this.onPressed,
  }) : assert(
         imageIcon != null || icon != null,
         'Either imageIcon or icon must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: size,
      icon: imageIcon ?? Icon(icon, color: color, size: size),
      onPressed: onPressed,
    );
  }
}
