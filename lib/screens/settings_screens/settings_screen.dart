import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/core/helper/helper_settings_screen.dart';
import 'package:signtalk/widgets/buttons/custom_circle_pfp_button.dart';
import 'package:signtalk/widgets/custom_app_bar.dart';
import 'package:signtalk/widgets/settings/custom_settings_option_card.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/providers/user_info_provider.dart';

class SettingScreen extends ConsumerWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final settingsOptions = getSettingsOptions(context, ref);
    const spacer = SizedBox(height: 20);
    
    return userAsync.when(
      data: (user) => PopScope(
      canPop: false,
      onPopInvoked: (didPop) => !didPop ? context.pop() : null,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),
            Column(
              children: [
                CustomAppBar(
                  appBarText: "Settings",
                  rightWidget: CustomCirclePfpButton(
                    borderColor: AppConstants.white,
                    userImage: user.photoUrl ?? AppConstants.default_user_pfp,
                    width: 40,
                    height: 40,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      ...settingsOptions.map(
                        (option) => Column(
                          children: [
                            CustomSettingsOptionCard(
                              optionText: option['text'],
                              trailing: option['icon'],
                              onTap: option['onTap'],
                            ),
                            spacer,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );    
  }
}
