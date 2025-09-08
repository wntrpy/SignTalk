import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/providers/dark_mode_provider.dart';
import 'package:signtalk/screens/settings_screens/settings_feedback_screen.dart';

// helper method for SVG icons
Widget _settingsIcon(BuildContext context, String assetPath) {
  return SvgPicture.asset(
    assetPath,
    color: Theme.of(context).iconTheme.color,
    width: 24,
    height: 24,
  );
}

// list of settings options
List<Map<String, dynamic>> getSettingsOptions(
  BuildContext context,
  WidgetRef ref,
) {
  final isDarkMode = ref.watch(darkModeProvider);

  return [
    {
      'text': 'Switch Language',
      'icon': _settingsIcon(
        context,
        AppConstants.settings_switch_language_icon,
      ),
      'onTap': null,
    },
    {
      'text': 'Dark Mode',
      'icon': Switch(
        value: isDarkMode,
        onChanged: (value) => ref.read(darkModeProvider.notifier).state = value,
      ),
      'onTap': null,
    },
    {
      'text': 'Feedback',
      'icon': _settingsIcon(context, AppConstants.settings_feedback_icon),
      'onTap': () => showFeedbackDialog(context),
    },

    {
      'text': 'Blocked Lists',
      'icon': _settingsIcon(context, AppConstants.settings_blocked_list),
      'onTap': null,
    },
    {
      'text': 'ASL Alphabet (Chart)',
      'icon': _settingsIcon(context, AppConstants.settings_alphabet_chart),
      'onTap': () => context.push('/settings_alphabet_chart_screen'),
    },
  ];
}
