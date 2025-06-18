import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/widgets/buttons/custom_circle_pfp_button.dart';
import 'package:signtalk/widgets/buttons/custom_icon_button.dart';

class CustomChatAppBar extends StatelessWidget {
  //TODO: need ng args pa din here since lahat ng data manggagaling sa chat screen?
  final String fullName;

  const CustomChatAppBar({super.key, required this.fullName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ------------------------BACK BUTTON----------------------------
          CustomIconButton(
            icon: Icons.arrow_back,
            color: Colors.white,
            size: 30.0,
            onPressed: () => context.pop(),
          ),

          // ------------------------CIRCLE PFP----------------------------
          CustomCirclePfpButton(
            borderColor: Colors.white,
            userImage: AppConstants.default_user_pfp,
            width: 40,
            height: 40,
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------------FULL NAME----------------------------
              _fullName(context, fullName),

              // ------------------------TIME STAMP----------------------------
              Text(
                "last seen 12:05 PM",
                style: TextStyle(color: Colors.white),
              ), //TODO: palitan later
            ],
          ),

          // ------------------------OPTION (yung 3dots)----------------------------
          CustomIconButton(
            imageIcon: Image.asset(AppConstants.receiver_avatar_icon),
            color: Colors.white,
            size: 5.0,
            onPressed: () => context.push(
              '/receiver_profile_screen',
            ), //TODO: fix later ?? idk
          ),
        ],
      ),
    );
  }
}

Widget _fullName(BuildContext context, String fullName) {
  return Container(
    width: MediaQuery.of(context).size.width * 0.5, // 50% of screen width
    constraints: const BoxConstraints(
      maxWidth: 200, // max w
      minHeight: 0, // min h
    ),
    child: Text(
      fullName,
      style: TextStyle(
        color: AppConstants.white,
        fontSize: AppConstants.fontSizeLarge,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.start,
      overflow: TextOverflow.visible,
      maxLines: 2, // max lines bago mag new lione
    ),
  );
}
