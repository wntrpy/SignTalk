import 'package:flutter/material.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/widgets/buttons/custom_circle_pfp_button.dart';
import 'package:signtalk/widgets/custom_app_bar.dart';

class SettingsAlphabetChart extends StatelessWidget {
  const SettingsAlphabetChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),

        Column(
          children: [
            // ------------------------parang app bar----------------------------
            CustomAppBar(
              appBarText: "ASL and FSL Alphabet (Chart)",
              rightWidget: CustomCirclePfpButton(
                borderColor: AppConstants.white,
                userImage: AppConstants.default_user_pfp,
                width: 40,
                height: 40,
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 20,
              ),
              child: Column(
                children: [
                  //TODO: palitan mo to ng learning mats for ASL and FSL
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
