import 'package:flutter/material.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/widgets/buttons/custom_circle_pfp_button.dart';
import 'package:signtalk/widgets/custom_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signtalk/providers/user_info_provider.dart';

class SettingsAlphabetChart extends ConsumerWidget {
  const SettingsAlphabetChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) => Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),

          Column(
            children: [
              // Custom app bar
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: CustomAppBar(
                  // ignore: avoid_hardcoded_text
                  appBarText: "ASL Alphabet",
                  rightWidget: CustomCirclePfpButton(
                    borderColor: AppConstants.white,
                    userImage: user.photoUrl ?? AppConstants.default_user_pfp,
                    width: 40,
                    height: 40,
                  ),
                ),
              ),

              // Scrollable content with chart
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 20.0,
                    ),
                    child: Column(
                      children: [
                        // ASL chart image
                        Image.asset(
                          AppConstants.asl_chart,
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
