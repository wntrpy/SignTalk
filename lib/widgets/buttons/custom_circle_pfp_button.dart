import 'package:flutter/material.dart';
import 'package:signtalk/app_constants.dart';

class CustomCirclePfpButton extends StatelessWidget {
  final Color borderColor; // color for border
  final String? userImage; // path to user image
  final void Function()? onPressed;

  // ✅ New optional size parameters
  final double width;
  final double height;

  const CustomCirclePfpButton({
    super.key,
    required this.borderColor,
    required this.userImage,
    this.onPressed,
    this.width = 50.0,
    this.height = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      splashRadius: width / 2 + 5,
      icon: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          color: borderColor,
          borderRadius: BorderRadius.circular(100),
        ),
        child: CircleAvatar(
          backgroundImage: userImage != null
              ? AssetImage(userImage!)
              : const AssetImage('assets/icons/default_user_pfp.png'),
          backgroundColor: AppConstants.orange,
        ),
      ),
    );
  }
}
