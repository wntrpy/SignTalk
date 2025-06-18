import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/providers/dark_mode_provider.dart';
import 'package:signtalk/widgets/buttons/custom_circle_pfp_button.dart';
import 'package:signtalk/widgets/custom_app_bar.dart';
import 'package:signtalk/widgets/settings/custom_settings_option_card.dart';
import 'package:signtalk/app_constants.dart';

class SettingScreen extends ConsumerWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.pop();
        }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),

            Column(
              children: [
                // ------------------------parang app bar----------------------------
                const CustomAppBar(
                  appBarText: "Settings",
                  rightWidget: CustomCirclePfpButton(
                    borderColor: AppConstants.white,
                    userImage: AppConstants.default_user_pfp,
                    width: 40,
                    height: 40,
                  ),
                ),

                //settings option card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      //switch language
                      CustomSettingsOptionCard(
                        optionText: "Switch Language",
                        trailing: SvgPicture.asset(
                          AppConstants.settings_switch_language_icon,
                          color: Theme.of(context)
                              .iconTheme
                              .color, //adapt sa theme (built in flutter light/dark mode)
                          width: 24, // optional
                          height: 24, // optional
                        ),
                      ),
                      SizedBox(height: 20),

                      //dark mode
                      CustomSettingsOptionCard(
                        optionText: "Dark Mode",
                        trailing: Switch(
                          value: isDarkMode,
                          onChanged: (value) {
                            ref.read(darkModeProvider.notifier).state = value;
                          },
                        ),
                      ),
                      SizedBox(height: 20),

                      //feedback
                      CustomSettingsOptionCard(
                        optionText: "Feedback",
                        trailing: SvgPicture.asset(
                          AppConstants.settings_feedback_icon,
                          color: Theme.of(context)
                              .iconTheme
                              .color, //adapt sa theme (built in flutter light/dark mode)
                          width: 24, // optional
                          height: 24, // optional
                        ),
                      ),
                      SizedBox(height: 20),

                      //avatar translation speed
                      CustomSettingsOptionCard(
                        optionText: "Avator Translation Speed",
                        trailing: SvgPicture.asset(
                          AppConstants.settings_avatar_speed,
                          color: Theme.of(context)
                              .iconTheme
                              .color, //adapt sa theme (built in flutter light/dark mode)
                          width: 24, // optional
                          height: 24, // optional
                        ),
                      ),
                      SizedBox(height: 20),

                      //blocked list
                      CustomSettingsOptionCard(
                        optionText: "Blocked Lists",
                        trailing: SvgPicture.asset(
                          AppConstants.settings_blocked_list,
                          color: Theme.of(context)
                              .iconTheme
                              .color, //adapt sa theme (built in flutter light/dark mode)
                          width: 24, // optional
                          height: 24, // optional
                        ),
                      ),
                      SizedBox(height: 20),

                      //asl and fsl alphabet chart
                      CustomSettingsOptionCard(
                        optionText: "ASL and FSL Alphabet (Chart)",
                        onTap: () =>
                            context.push('/settings_alphabet_chart_screen'),
                        trailing: SvgPicture.asset(
                          AppConstants.settings_alphabet_chart,
                          color: Theme.of(context)
                              .iconTheme
                              .color, //adapt sa theme (built in flutter light/dark mode)
                          width: 24, // optional
                          height: 24, // optional
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
