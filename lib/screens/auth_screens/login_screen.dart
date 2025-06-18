import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/widgets/textfields/custom_textfield_auth.dart';
import 'package:signtalk/widgets/buttons/custom_button.dart';
import 'package:signtalk/widgets/textfields/custom_password_textfield.dart';
import 'package:signtalk/widgets/custom_signtalk_logo.dart';
import 'package:signtalk/widgets/buttons/custom_text_button.dart';
import 'package:signtalk/app_constants.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  //TODO: AYUSIN MO LATER
  //TODO: lagyan mo ng error text widget
  final customTextFieldAuthController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // prevents resize pag enabled yung on-screen keeb
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),

          // prevents overflow
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 56.0, vertical: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // SignTalk logo
                CustomSigntalkLogo(width: 120, height: 120),

                SizedBox(height: 20),

                //------------------------------------INPUT-FIELDS-------------------------------------------------//
                Column(
                  children: [
                    //------------------------------------USERNAME OR EMAIL-------------------------------------------------//
                    CustomTextfieldAuth(
                      labelText: "Username or Email",
                      controller: customTextFieldAuthController,
                    ),
                    SizedBox(height: 20),

                    //------------------------------------PASSWORD-------------------------------------------------//
                    CustomPasswordField(
                      controller: null,
                      labelText: "Password",
                    ),
                  ],
                ),

                SizedBox(height: 10),

                //------------------------------------FORGOT PASSWORD-------------------------------------------------//
                Align(
                  alignment: Alignment.centerLeft,
                  child: CustomTextButton(
                    buttonText: "Forgot Password?",
                    onPressed: () => context.push('/forget_password_screen'),
                  ),
                ),

                SizedBox(height: 10),

                //------------------------------------LOGIN BUTTON-------------------------------------------------//
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 150,
                    child: CustomButton(
                      buttonText: "Login",
                      colorCode: AppConstants.orange,
                      buttonWidth: 110,
                      buttonHeight: 45,
                      onPressed: () =>
                          context.push('/home_screen'), //TODO: FIX LATER
                      textColor: AppConstants.white,
                      textSize: AppConstants.fontSizeLarge,
                    ),
                  ),
                ),

                SizedBox(height: 40),

                //------------------------------------SIGN UP AND GOOGLE LOGIN-------------------------------------------------//
                Column(
                  children: [
                    //------------------------------------SIGN UP-------------------------------------------------//
                    CustomButton(
                      buttonText: 'Sign Up',
                      colorCode: AppConstants.white,
                      buttonWidth: 120,
                      buttonHeight: 40,
                      onPressed: () => context.push('/registration_screen'),
                      textColor: AppConstants.black,
                      textSize: AppConstants.fontSizeMedium,
                    ),

                    Padding(
                      padding: EdgeInsets.only(top: 12, bottom: 12),
                      child: Text(
                        "OR",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppConstants.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    //------------------------------------GOOGLE LOGIN-------------------------------------------------//
                    CustomButton(
                      buttonText: 'Log in with Google',
                      colorCode: AppConstants.white,
                      buttonWidth: 200,
                      buttonHeight: 45,
                      onPressed: () {},
                      textColor: AppConstants.black,
                      icon: Image.asset(AppConstants.google_logo),
                      textSize: AppConstants.fontSizeMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
