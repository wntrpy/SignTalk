import 'package:flutter/material.dart';
import 'package:signtalk/app_constants.dart';

bool isNetworkUrl(String? path) {
  return path != null && (path.startsWith('http') || path.startsWith('https'));
}

class CustomCirclePfpButton extends StatelessWidget {
  final Color? borderColor; // color for border
  final String? userImage; // path to user image
  final void Function()? onPressed;

  // ✅ New optional size parameters
  final double width;
  final double height;

  const CustomCirclePfpButton({
    super.key,
    this.borderColor,
    required this.userImage,
    this.onPressed,
    this.width = 50.0,
    this.height = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;

    if (userImage == null || userImage!.isEmpty) {
      imageProvider = AssetImage(AppConstants.default_user_pfp);
    } else if (isNetworkUrl(userImage)) {
      imageProvider = NetworkImage(userImage!);
    } else {
      imageProvider = AssetImage(userImage!);
    }

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
          backgroundImage: imageProvider,
          backgroundColor: AppConstants.orange,
        ),
      ),
    );
  }
}
