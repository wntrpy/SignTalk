import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/widgets/buttons/custom_circle_pfp_button.dart';
import 'package:signtalk/widgets/custom_app_bar.dart';
import 'package:signtalk/widgets/textfields/custom_line_textfield.dart';
import 'package:signtalk/app_constants.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  void changeEditButtonState() {
    //pag penendot yng button dapat:
    //mabago yung color to orange
    //mabago yung text to save
    //maenable yung pag-iinput ng text sa textfield
    //riverpod state, na nagchecheck if false or true ba yung value
    //if false, yung default button
    //if true, then change to orange and such
  }

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
                      AppConstants.signtalk_bg,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),

                    //main column
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // ------------------------parang app bar----------------------------
                        CustomAppBar(appBarText: "Profile"),

                        // ------------------------USER PFP MALAKI----------------------------
                        CustomCirclePfpButton(
                          borderColor: AppConstants.white,
                          userImage: AppConstants.default_user_pfp,
                          width: 120,
                          height: 120,
                        ),
                        SizedBox(height: 7),

                        // ------------------------USER FULL NAME----------------------------
                        Text(
                          "Byeon Woo Seok",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppConstants.white,
                            fontSize: AppConstants.fontSizeExtraLarge,
                          ),
                        ),
                        SizedBox(height: 15),

                        // ------------------------EDIT BUTTON----------------------------
                        CustomButton(
                          buttonText: "Edit Profile",
                          colorCode: AppConstants.white,
                          buttonWidth: 150,
                          buttonHeight: 45,
                          onPressed: () {}, //TODO: fix later
                          textSize: AppConstants.fontSizeMedium,
                          textColor: AppConstants.darkViolet,
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
                color: AppConstants.white,
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
