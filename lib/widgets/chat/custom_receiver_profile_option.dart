import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:signtalk/app_constants.dart';

class CustomReceiverProfileOption extends StatelessWidget {
  final String optionText;
  final String iconPath;
  final Color? color;
  final VoidCallback? onTap;
  final Widget? trailingWidget;

  final dynamic fallbackIcon;

  const CustomReceiverProfileOption({
    super.key,
    required this.optionText,
    required this.iconPath,
    this.color,
    this.onTap,
    this.trailingWidget,
    this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    Widget leadingIcon;

    if (iconPath.isNotEmpty) {
      leadingIcon = SvgPicture.asset(
        iconPath,
        width: 50,
        height: 50,
        color: color,
      );
    } else if (fallbackIcon is IconData) {
      leadingIcon = SizedBox(
        width: 50,
        height: 50,
        child: Icon(fallbackIcon, size: 40, color: color ?? Colors.white),
      );
    } else if (fallbackIcon is Widget Function(BuildContext)) {
      leadingIcon = SizedBox(
        width: 50,
        height: 50,
        child: (fallbackIcon as Widget Function(BuildContext))(context),
      );
    } else {
      leadingIcon = const SizedBox(
        width: 50,
        height: 50,
        child: Icon(Icons.help_outline, size: 40),
      );
    }

    return InkWell(
      onTap: onTap,
      splashColor: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        child: Row(
          children: [
            leadingIcon,
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
