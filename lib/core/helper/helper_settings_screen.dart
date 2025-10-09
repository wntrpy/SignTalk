import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/screens/settings_screens/settings_blocked_list_screen.dart';
import 'package:signtalk/screens/settings_screens/settings_feedback_screen.dart';

// helper method for SVG icons
Widget _settingsIcon(BuildContext context, String assetPath) {
  return SvgPicture.asset(
    assetPath,
    color: AppConstants.white,
    width: 28,
    height: 28,
  );
}

// list of settings options
List<Map<String, dynamic>> getSettingsOptions(
  BuildContext context,
  WidgetRef ref,
) {
  return [
    {
      'text': 'Feedback',
      'icon': _settingsIcon(context, AppConstants.settings_feedback_icon),
      'onTap': () => showFeedbackDialog(context),
    },

    {
      'text': 'Blocked Lists',
      'icon': _settingsIcon(context, AppConstants.settings_blocked_list),
      'onTap': () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SettingsBlockedListScreen()),
        );
      },
    },

    {
      'text': 'ASL Alphabet (Chart)',
      'icon': _settingsIcon(context, AppConstants.settings_alphabet_chart),
      'onTap': () => context.push('/settings_alphabet_chart_screen'),
    },
  ];
}
