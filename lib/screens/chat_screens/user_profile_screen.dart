import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/main.dart';
import 'package:signtalk/widgets/buttons/custom_button.dart';
import 'package:signtalk/widgets/buttons/custom_circle_pfp_button.dart';
import 'package:signtalk/widgets/buttons/custom_icon_button.dart';
import 'package:signtalk/widgets/textfields/custom_line_textfield.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.pop();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40.0),
                  bottomRight: Radius.circular(40.0),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // signtalk bg
                    Image.asset(
                      MyApp.signtalk_bg,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),

                    //main column
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // ------------------------parang app bar----------------------------
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 24.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // ------------------------BACK BUTTON----------------------------
                              CustomIconButton(
                                icon: Icons.arrow_back,
                                color: Colors.white,
                                size: 30.0,
                                onPressed: () => context
                                    .pop(), //TODO: go back to profile screen
                              ),

                              // ------------------------PROFILE TEXT----------------------------
                              Text(
                                "Profile",
                                style: TextStyle(
                                  color: MyApp.white,
                                  fontSize: MyApp.fontSizeExtraLarge,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              // ------------------------SETTINGS BUTTON----------------------------
                              CustomIconButton(
                                icon: Icons.settings,
                                color: Colors.white,
                                size: 30.0,
                                onPressed: () => context.push(
                                  '/settings_screen',
                                ), //TODO: goto settings screen
                              ),
                            ],
                          ),
                        ),

                        // ------------------------USER PFP MALAKI----------------------------
                        CustomCirclePfpButton(
                          borderColor: MyApp.white,
                          userImage: MyApp.default_user_pfp,
                          width: 120,
                          height: 120,
                        ),
                        SizedBox(height: 7),

                        // ------------------------USER FULL NAME----------------------------
                        Text(
                          "Byeon Woo Seok",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: MyApp.white,
                            fontSize: MyApp.fontSizeExtraLarge,
                          ),
                        ),
                        SizedBox(height: 15),

                        // ------------------------EDIT BUTTON----------------------------
                        CustomButton(
                          buttonText: "Edit Profile",
                          colorCode: MyApp.white,
                          buttonWidth: 150,
                          buttonHeight: 45,
                          onPressed: () {}, //TODO: fix later
                          textSize: MyApp.fontSizeMedium,
                          textColor: MyApp.darkViolet,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // white container
            Expanded(
              flex: 3,
              child: Container(
                padding: EdgeInsets.only(top: 12.0),
                width: double.infinity,
                color: MyApp.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // ------------------------NAME----------------------------
                    CustomLineTextfield(defaultValue: "Byeon", label: 'Name'),

                    // ------------------------USERNAME----------------------------
                    CustomLineTextfield(
                      defaultValue: "RyuSunJae",
                      label: 'Username',
                    ),

                    // ------------------------AGE----------------------------
                    CustomLineTextfield(defaultValue: "24", label: 'Age'),

                    // ------------------------USER TYPE----------------------------
                    CustomLineTextfield(
                      defaultValue: "Hearing",
                      label: 'User Type',
                    ),

                    // ------------------------EMAIL----------------------------
                    CustomLineTextfield(
                      defaultValue: "ByeinWooSeok@gmail.com",
                      label: 'Email',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
