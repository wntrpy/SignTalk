import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/widgets/custom_signtalk_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.endOfFrame.then((_) async {
      // Hide status bar
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

      // Delay AFTER frame + preload
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        context.go('/login_screen');
      }
    });
  }

  @override
  void dispose() {
    // Reset status bar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    Future.wait([
      precacheImage(const AssetImage(AppConstants.signtalk_bg), context),
      precacheImage(const AssetImage(AppConstants.google_logo), context),
      precacheImage(const AssetImage(AppConstants.signtalk_logo), context),
      precacheImage(const AssetImage(AppConstants.default_user_pfp), context),

      // add more if they're used right after splash
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.black),

        RepaintBoundary(
          child: Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),
        ),

        Center(child: CustomSigntalkLogo(width: 200, height: 200)),
      ],
    );
  }
}
