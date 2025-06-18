import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/core/helper/helper_receiver_profile_screen.dart';
import 'package:signtalk/widgets/buttons/custom_circle_pfp_button.dart';
import 'package:signtalk/widgets/buttons/custom_icon_button.dart';
import 'package:signtalk/widgets/chat/custom_receiver_profile_option.dart';

class ReceiverProfileScreen extends StatefulWidget {
  const ReceiverProfileScreen({super.key});

  @override
  State<ReceiverProfileScreen> createState() => _ReceiverProfileScreenState();
}

class _ReceiverProfileScreenState extends State<ReceiverProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final finalReceiverProfileOptions = getReceiverProfileOptions(context);

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
            // ------------------------APP BG----------------------------
            Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),

            // ------------------------BACK BUTTON----------------------------
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 16),
              child: Align(
                alignment: Alignment.topLeft,
                child: CustomIconButton(
                  icon: Icons.arrow_back,
                  color: Colors.white,
                  size: 30.0,
                  onPressed: () => context.pop(),
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.only(top: 100, right: 20, left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ------------------------USER INFO----------------------------
                  _buildUserProfileHeader(),

                  // ------------------------OPTIONS----------------------------
                  ...finalReceiverProfileOptions.map(
                    (option) => Column(
                      children: [
                        CustomReceiverProfileOption(
                          optionText: option['optionText'],
                          iconPath: option['iconPath'],
                          trailingWidget: option['trailingWidget'],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//user info
Widget _buildUserProfileHeader() {
  return Container(
    padding: EdgeInsets.only(bottom: 15),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.white, width: 1.5)),
    ),
    child: Row(
      children: [
        CustomCirclePfpButton(
          borderColor: Colors.white,
          userImage: null,
          width: 120,
          height: 120,
        ),
        SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Kim Chaewon",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: AppConstants.fontSizeExtraLarge,
              ),
            ),
            Text(
              "kimchaewon123",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: AppConstants.fontSizeMedium,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
