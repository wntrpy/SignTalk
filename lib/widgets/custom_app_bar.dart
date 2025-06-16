import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/widgets/buttons/custom_icon_button.dart';

class CustomAppBar extends StatelessWidget {
  final String appBarText;
  final Widget? rightWidget; // para sa settings screen onle

  const CustomAppBar({
    super.key,
    required this.appBarText,
    this.rightWidget, // if null, use default
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
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

          // ------------------------TEXT----------------------------
          Text(
            appBarText,
            style: TextStyle(
              color: AppConstants.white,
              fontSize: AppConstants.fontSizeExtraLarge,
              fontWeight: FontWeight.bold,
            ),
          ),

          // ------------------------RIGHT SIDE WIDGET----------------------------
          rightWidget ??
              CustomIconButton(
                icon: Icons.settings,
                color: Colors.white,
                size: 30.0,
                onPressed: () => context.push('/settings_screen'),
              ),
        ],
      ),
    );
  }
}
