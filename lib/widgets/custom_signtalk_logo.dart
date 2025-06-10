import 'package:flutter/material.dart';
import 'package:signtalk/main.dart';

class CustomSigntalkLogo extends StatelessWidget {
  final int width;
  final int height;
  const CustomSigntalkLogo({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(MyApp.signtalk_logo, width: 120, height: 120);
  }
}
