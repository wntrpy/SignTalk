import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/widgets/textfields/custom_textfield_auth.dart';
import 'package:signtalk/widgets/buttons/custom_button.dart';
import 'package:signtalk/widgets/custom_signtalk_logo.dart';
import 'package:signtalk/app_constants.dart';

class ForgetPasswordScreen extends StatelessWidget {
  const ForgetPasswordScreen({super.key});

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
                  CustomSigntalkLogo(width: 150, height: 150),
                  SizedBox(height: 50),

                  //------------------------------------EMAIL/USERNAME-------------------------------------------------//
                  CustomTextfieldAuth(
                    labelText: "Enter the email/username of your account.",
                    controller: null,
                  ),

                  SizedBox(height: 40),

                  //------------------------------------SUBMIT-------------------------------------------------//
                  CustomButton(
                    buttonText: "SUBMIT",
                    colorCode: AppConstants.orange,
                    buttonWidth: 250,
                    buttonHeight: 70,
                    onPressed: () => context.push(
                      '/forget_password_verification',
                    ), //TODO: FIX LATER
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
