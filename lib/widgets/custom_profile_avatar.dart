import 'package:flutter/material.dart';
import 'package:signtalk/app_constants.dart';

/// Reusable CircleAvatar that shows profile picture or initial letter
class CustomProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final VoidCallback? onTap;

  const CustomProfileAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.radius = 20,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppConstants.extraLightViolet,
      backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
          ? NetworkImage(photoUrl!)
          : null,
      child: (photoUrl == null || photoUrl!.isEmpty)
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : "?",
              style: TextStyle(
                fontSize: fontSize ?? radius * 0.8,
                fontWeight: FontWeight.bold,
                color: textColor ?? Theme.of(context).primaryColor,
              ),
            )
          : null,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}
