import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/app_constants.dart';
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
    bool isToggled = true; //TODO: fix

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

                  // ------------------------CHANGE NICKNAME----------------------------
                  //TODO: palitan mo mga icons
                  CustomReceiverProfileOption(
                    optionText: "Change Nickname",
                    iconPath: AppConstants.receiver_change_nickname_icon,
                  ),

                  // ------------------------3D AVATAR SIGN LANGUAGE----------------------------
                  CustomReceiverProfileOption(
                    optionText: "3D Avatar Sign Language",
                    iconPath: AppConstants.receiver_avatar_icon,
                    trailingWidget: Switch(
                      value: isToggled,
                      onChanged: (val) => setState(() => isToggled = val),
                    ),
                  ),

                  // ------------------------TRANSLATED VOICE SPEECH----------------------------
                  CustomReceiverProfileOption(
                    optionText: "Translated Voice Speech",
                    iconPath: AppConstants.receiver_voice_speech_icon,
                    trailingWidget: Switch(
                      value: isToggled,
                      onChanged: (val) => setState(() => isToggled = val),
                    ),
                  ),

                  // ------------------------NOTIFICATION----------------------------
                  CustomReceiverProfileOption(
                    optionText: "Notification",
                    iconPath: AppConstants.receiver_notification_icon,
                  ),

                  // ------------------------BLOCK CONTACT----------------------------
                  CustomReceiverProfileOption(
                    optionText: "Block Contact",
                    iconPath: AppConstants.receiver_block_contact_icon,
                  ),

                  // ------------------------DELETE----------------------------
                  CustomReceiverProfileOption(
                    optionText: "Delete",
                    iconPath: AppConstants.receiver_delete_icon,
                    color: Colors.red,
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
