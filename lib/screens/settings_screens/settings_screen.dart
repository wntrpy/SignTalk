import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/main.dart';
import 'package:signtalk/widgets/buttons/custom_circle_pfp_button.dart';
import 'package:signtalk/widgets/custom_app_bar.dart';
import 'package:signtalk/widgets/settings/custom_settings_option_card.dart';
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
          children: [
            Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),

            Column(
              children: [
                // ------------------------parang app bar----------------------------
                CustomAppBar(
                  appBarText: "Settings",
                  rightWidget: CustomCirclePfpButton(
                    borderColor: AppConstants.white,
                    userImage: AppConstants.default_user_pfp,
                    width: 40,
                    height: 40,
                  ),
                ),

                //settings option card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      CustomSettingsOptionCard(optionText: 'Switch Language'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
