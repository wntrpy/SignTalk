import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/main.dart';
import 'package:signtalk/widgets/textfields/custom_textfield_auth.dart';
import 'package:signtalk/widgets/buttons/custom_button.dart';
import 'package:signtalk/widgets/custom_signtalk_logo.dart';
import 'package:signtalk/widgets/buttons/custom_text_button.dart';

class ForgetPasswordVerification extends StatelessWidget {
  const ForgetPasswordVerification({super.key});

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
            Image.asset(MyApp.signtalk_bg, fit: BoxFit.cover),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomSigntalkLogo(width: 150, height: 150),
                  SizedBox(height: 50),

                  CustomTextfieldAuth(
                    labelText: "A Verification Code was sent  to your Email.",
                    controller: null,
                  ),

                  CustomTextButton(
                    buttonText: "Resend Code",
                    onPressed: () {},
                  ), //TODO: fix later

                  SizedBox(height: 40),
                  CustomButton(
                    buttonText: "SUBMIT",
                    colorCode: MyApp.orange,
                    buttonWidth: 250,
                    buttonHeight: 70,
                    onPressed: () => context.push(
                      '/forget_password_new_password',
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
