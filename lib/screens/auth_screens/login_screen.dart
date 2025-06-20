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

  final customTextFieldAuthController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black), // Optional fallback color

          RepaintBoundary(
            child: Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 56.0, vertical: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CustomSigntalkLogo(width: 120, height: 120),
                const SizedBox(height: 20),

                Column(
                  children: [
                    CustomTextfieldAuth(
                      labelText: "Username or Email",
                      controller: customTextFieldAuthController,
                    ),
                    const SizedBox(height: 20),

                    CustomPasswordField(
                      controller: null,
                      labelText: "Password",
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerLeft,
                  child: CustomTextButton(
                    buttonText: "Forgot Password?",
                    onPressed: () => context.push('/forget_password_screen'),
                    textColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 150,
                    child: CustomButton(
                      buttonText: "Login",
                      colorCode: AppConstants.orange,
                      buttonWidth: 110,
                      buttonHeight: 45,
                      onPressed: () => context.push('/home_screen'),
                      textColor: AppConstants.white,
                      textSize: AppConstants.fontSizeLarge,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Column(
                  children: [
                    CustomButton(
                      buttonText: 'Sign Up',
                      colorCode: AppConstants.white,
                      buttonWidth: 120,
                      buttonHeight: 40,
                      onPressed: () => context.push('/registration_screen'),
                      textColor: AppConstants.black,
                      textSize: AppConstants.fontSizeMedium,
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        "OR",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppConstants.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Defer Google logo rendering slightly using FadeInImage or load delay (optional)
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
