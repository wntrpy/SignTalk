import 'package:flutter/material.dart';
import 'package:signtalk/main.dart';

class CustomSigntalkLogo extends StatelessWidget {
  final double width;
  final double height;
  const CustomSigntalkLogo({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(MyApp.signtalk_logo, width: width, height: height);
  }
}
