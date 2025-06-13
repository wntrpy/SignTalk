import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/core/password_validator.dart';
import 'package:signtalk/main.dart';
import 'package:signtalk/widgets/auth_widgets/custom_textfield_auth.dart';
import 'package:signtalk/widgets/custom_back_button.dart';
import 'package:signtalk/widgets/custom_button.dart';
import 'package:signtalk/widgets/custom_password_button.dart';
import 'package:signtalk/widgets/custom_signtalk_logo.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _passwordError;

  void _handleSubmit() {
    validateAndSubmit(
      context: context,
      passwordController: _passwordController,
      confirmPasswordController: _confirmPasswordController,
      onValidationResult: (error) {
        setState(() {
          _passwordError = error;
        });
      },
    );
  }

  //TODO: lagyan mo ng isempty validation kada field
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          //signtalk bg
          Image.asset(MyApp.signtalk_bg, fit: BoxFit.cover),

          // back button
          Align(
            alignment: Alignment.topLeft,
            child: CustomBackButton(
              colorCode: MyApp.white,
              onPressed: () => context.go('/login_screen'), //TODO: fix mo later
              iconSize: 30,
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 80),

            child: Column(
              //main column parent
              children: [
                SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Centered logo
                        Center(
                          child: CustomSigntalkLogo(width: 150, height: 150),
                        ),

                        //------------------------------------INPUT-FIELDS-------------------------------------------------//
                        //name
                        CustomTextfieldAuth(
                          labelText: "Name",
                          controller: null,
                        ),
                        SizedBox(height: 20),
                        //age
                        CustomTextfieldAuth(labelText: "Age", controller: null),
                        SizedBox(height: 20),

                        //username
                        CustomTextfieldAuth(
                          labelText: "Username",
                          controller: null,
                        ),
                        SizedBox(height: 20),

                        //email
                        CustomTextfieldAuth(
                          labelText: "Email",
                          controller: null,
                        ),
                        SizedBox(height: 20),

                        //password
                        CustomPasswordField(
                          controller: _passwordController,
                          labelText: 'Password',
                          errorText: _passwordError,
                        ),
                        SizedBox(height: 20),

                        //confirm
                        CustomPasswordField(
                          controller: _confirmPasswordController,
                          labelText: 'Confirm Password',
                          errorText: _passwordError,
                        ),

                        SizedBox(height: 20),
                        Container(
                          margin: EdgeInsets.only(left: 170),
                          child: CustomButton(
                            buttonText: "Register",
                            colorCode: MyApp.orange,
                            buttonWidth: 200,
                            buttonHeight: 50,
                            onPressed: _handleSubmit, //TODO: FIX MO LATER
                            textSize: 24,
                            borderRadiusValue: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
