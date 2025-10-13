import 'package:flutter/material.dart';
import 'package:signtalk/app_constants.dart';

bool isNetworkUrl(String? path) {
  return path != null && (path.startsWith('http') || path.startsWith('https'));
}

class CustomCirclePfpButton extends StatelessWidget {
  final Color? borderColor; // color for border
  final String? userImage; // path to user image
  final String? userName; // user's name for initial fallback
  final void Function()? onPressed;

  final double width;
  final double height;

  const CustomCirclePfpButton({
    super.key,
    this.borderColor,
    required this.userImage,
    this.userName,
    this.onPressed,
    this.width = 50.0,
    this.height = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    // Check if we need to show initial instead of image
    bool showInitial = userImage == null || userImage!.isEmpty;

    if (showInitial) {
      return IconButton(
        onPressed: onPressed,
        splashRadius: width / 2 + 5,
        icon: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: borderColor ?? AppConstants.darkViolet,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Center(
            child: Text(
              userName != null && userName!.isNotEmpty
                  ? userName![0].toUpperCase()
                  : "?",
              style: TextStyle(
                color: AppConstants.darkViolet,
                fontSize: width * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    // Show image if available
    ImageProvider imageProvider;
    if (isNetworkUrl(userImage)) {
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
