import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:signtalk/app_constants.dart';

class CustomReceiverProfileOption extends StatelessWidget {
  final String optionText;
  final String iconPath;
  final Color? color; // text and icon colors
  final VoidCallback? onTap; //functuons
  final Widget? trailingWidget; //toggle button

  const CustomReceiverProfileOption({
    super.key,
    required this.optionText,
    required this.iconPath,
    this.color,
    this.onTap,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, //TODO: change mo later
      splashColor: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        child: Row(
          children: [
            SvgPicture.asset(iconPath, width: 50, height: 50, color: color),
            const SizedBox(width: 10),
            Text(
              optionText,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: AppConstants.fontSizeMedium,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Spacer(),
            if (trailingWidget != null) trailingWidget!,
          ],
        ),
      ),
    );
  }
}
