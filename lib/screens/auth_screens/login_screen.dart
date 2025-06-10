import 'package:flutter/material.dart';
import 'package:signtalk/widgets/auth_widgets/custom_textfield_auth.dart';
import 'package:signtalk/widgets/custom_button.dart';
import 'package:signtalk/widgets/custom_signtalk_logo.dart';
import 'package:signtalk/widgets/custom_text_button.dart';
import '../../main.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  //para sa CustomTextFieldAuth
  //TODO: AYUSIN MO LATER
  final customTextFieldAuthController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(MyApp.signtalk_bg, fit: BoxFit.cover),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 56.0, vertical: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //signtalk icon
                CustomSigntalkLogo(width: 120, height: 120),

                //column for input fields
                Column(
                  children: [
                    CustomTextfieldAuth(
                      labelText: "Username or Email",
                      controller: customTextFieldAuthController,
                    ),
                    SizedBox(height: 20),

                    CustomTextfieldAuth(
                      labelText: "Password",
                      controller: customTextFieldAuthController,
                    ),
                  ],
                ),

                //forgot password
                Align(
                  alignment: Alignment.centerLeft,
                  child: CustomTextButton(
                    buttonText: "Forgot Password?",
                    onPressed: () {}, //TODO: replace mo later
                  ),
                ),

                //login button
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 150,
                    child: CustomButton(
                      buttonText: "Login",
                      colorCode: MyApp.orange,
                      buttonWidth: 110,
                      buttonHeight: 45,
                      onPressed: () {}, //TODO: replace mo later
                      textColor: MyApp.white,
                      textSize: MyApp.fontSizeLarge,
                    ),
                  ),
                ),

                //sign up button and login w google container
                SizedBox(height: 40),
                Column(
                  children: [
                    CustomButton(
                      buttonText: 'Sign Up',
                      colorCode: MyApp.white,
                      buttonWidth: 120,
                      buttonHeight: 40,
                      onPressed: () {}, //TODO: replace mo later
                      textColor: MyApp.black,
                      textSize: MyApp.fontSizeMedium,
                    ),

                    //or text
                    Padding(
                      padding: EdgeInsets.only(top: 12, bottom: 12),
                      child: Text(
                        "OR",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: MyApp.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    CustomButton(
                      buttonText: 'Log in with Google',
                      colorCode: MyApp.white,
                      buttonWidth: 200,
                      buttonHeight: 45,
                      onPressed: () {}, //TODO: replace mo later
                      textColor: MyApp.black,
                      icon: Image.asset(MyApp.google_logo),
                      textSize: MyApp.fontSizeMedium,
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
