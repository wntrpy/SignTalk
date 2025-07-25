import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/widgets/custom_alert_dialog.dart';
import 'package:signtalk/widgets/buttons/custom_button.dart';
import 'package:signtalk/widgets/textfields/custom_password_textfield.dart';
import 'package:signtalk/widgets/custom_signtalk_logo.dart';

class ForgetPasswordNewPassword extends StatelessWidget {
  const ForgetPasswordNewPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.pop(); // goto previos page ion the stack
        return false; // block system back button's default exit
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //------------------------------------SIGNTALK LOGO-------------------------------------------------//
                  CustomSigntalkLogo(width: 150, height: 150),
                  SizedBox(height: 50),

                  //------------------------------------NEW PASSWORD -------------------------------------------------//
                  CustomPasswordField(
                    controller: null,
                    labelText: "New Password",
                  ),
                  SizedBox(height: 40),

                  //------------------------------------CONFIRM NEW PASSWORD-------------------------------------------------//
                  CustomPasswordField(
                    controller: null,
                    labelText: "Confirm New Password",
                  ),
                  SizedBox(height: 40),

                  SizedBox(height: 40),

                  //------------------------------------CONFIRM BUTTON-------------------------------------------------//
                  CustomButton(
                    buttonText: "Confirm",
                    colorCode: AppConstants.orange,
                    buttonWidth: 250,
                    buttonHeight: 70,
                    onPressed: () {
                      showDialog(
                        // create new dialog widget, na ang content is yung irereturn na DialogBox
                        context: context,
                        builder: (context) {
                          return CustomAlertDialog(
                            dialogTitle: 'Password Changed!',
                            dialogTextContent: 'tstsedfsdf',
                            buttonText: 'asdas',
                            onPressed: () => context.go(
                              '/login_screen',
                            ), //TODO: fix mo later
                            dialogWidth: 100.0,
                            dialogHeight: 200.0,
                          );
                        },
                      );
                    }, //TODO: FIX LATER
                    textSize: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
