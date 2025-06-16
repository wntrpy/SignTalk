import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/main.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.pop();
        }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [Image.asset(MyApp.signtalk_bg, fit: BoxFit.cover)],
        ),
      ),
    );
  }
}
