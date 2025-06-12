import 'package:flutter/material.dart';
import 'package:signtalk/widgets/auth_widgets/custom_textfield_auth.dart';
import 'package:signtalk/widgets/custom_button.dart';
import 'package:signtalk/widgets/custom_signtalk_logo.dart';
import 'package:signtalk/widgets/custom_text_button.dart';
import '../../main.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  //TODO: AYUSIN MO LATER
  final customTextFieldAuthController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // prevents resize pag enabled yung on-screen keeb
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(MyApp.signtalk_bg, fit: BoxFit.cover),

          // prevents overflow
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 56.0, vertical: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // SignTalk logo
                CustomSigntalkLogo(width: 120, height: 120),

                SizedBox(height: 20),

                // Input fields
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

                SizedBox(height: 10),

                // Forgot password
                Align(
                  alignment: Alignment.centerLeft,
                  child: CustomTextButton(
                    buttonText: "Forgot Password?",
                    onPressed: () {},
                  ),
                ),

                SizedBox(height: 10),

                // Login button
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 150,
                    child: CustomButton(
                      buttonText: "Login",
                      colorCode: MyApp.orange,
                      buttonWidth: 110,
                      buttonHeight: 45,
                      onPressed: () {},
                      textColor: MyApp.white,
                      textSize: MyApp.fontSizeLarge,
                    ),
                  ),
                ),

                SizedBox(height: 40),

                // Sign up & Google login
                Column(
                  children: [
                    CustomButton(
                      buttonText: 'Sign Up',
                      colorCode: MyApp.white,
                      buttonWidth: 120,
                      buttonHeight: 40,
                      onPressed: () {},
                      textColor: MyApp.black,
                      textSize: MyApp.fontSizeMedium,
                    ),

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
                      onPressed: () {},
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
