import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/providers/settings_provider.dart';
import 'package:signtalk/widgets/custom_alert_dialog.dart';
import 'package:signtalk/widgets/settings/custom_switch_language_dialog.dart';

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
  final activeSetting = ref.watch(activeSettingProvider);

  return [
    {
      'text': 'Switch Language',
      'icon': _settingsIcon(
        context,
        AppConstants.settings_switch_language_icon,
      ),
      'onTap': () {
        ref.read(activeSettingProvider.notifier).state =
            'Switch Language'; // set active
        showDialog(
          context: context,
          builder: (context) => const CustomSwitchLanguageDialog(),
        );
      },
      'active': activeSetting == 'Switch Language', //mark as active
    },
    {
      'text': 'Dark Mode',
      'icon': Switch(
        value: isDarkMode,
        onChanged: (value) => ref.read(darkModeProvider.notifier).state = value,
      ),
      'onTap': () =>
          ref.read(activeSettingProvider.notifier).state = 'Dark Mode',
      'active': activeSetting == 'Dark Mode',
    },
    {
      'text': 'Feedback',
      'icon': _settingsIcon(context, AppConstants.settings_feedback_icon),
      'onTap': () {
        print("test");
        ref.read(activeSettingProvider.notifier).state = 'Feedback';
        showDialog(
          context: context,
          builder: (context) {
            return CustomAlertDialog(
              dialogTitle: "Send us some feedback!",
              buttonText: "Submit",
              showCancelButton: true,
              onCancel: () {
                Navigator.pop(context);
              },
              onPressed: () {
                // handle submit
              },
              customWidget: TextField(
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: "Input your feedback here...",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              dialogTextContent: '',
            );
          },
        );
      },
      'active': activeSetting == 'Feedback',
    },
    {
      'text': 'Avatar Translation Speed',
      'icon': _settingsIcon(context, AppConstants.settings_avatar_speed),
      'onTap': () => ref.read(activeSettingProvider.notifier).state =
          'Avatar Translation Speed',
      'active': activeSetting == 'Avatar Translation Speed',
    },
    {
      'text': 'Blocked Lists',
      'icon': _settingsIcon(context, AppConstants.settings_blocked_list),
      'onTap': () =>
          ref.read(activeSettingProvider.notifier).state = 'Blocked Lists',
      'active': activeSetting == 'Blocked Lists',
    },
    {
      'text': 'ASL and FSL Alphabet (Chart)',
      'icon': _settingsIcon(context, AppConstants.settings_alphabet_chart),
      'onTap': () => context.push('/settings_alphabet_chart_screen'),
    },
  ];
}
