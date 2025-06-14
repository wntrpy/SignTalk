import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/core/password_validator.dart';
import 'package:signtalk/main.dart';
import 'package:signtalk/widgets/textfields/custom_textfield_auth.dart';
import 'package:signtalk/widgets/buttons/custom_back_button.dart';
import 'package:signtalk/widgets/buttons/custom_button.dart';
import 'package:signtalk/widgets/textfields/custom_password_textfield.dart';
import 'package:signtalk/widgets/custom_signtalk_logo.dart';
import 'package:signtalk/widgets/textfields/custom_textfield_dropdown.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final List<String> userTypes = ['Hearing', 'Non-Hearing']; //laman ng dropdown

  String? _passwordError; //var na naghohold ng lalamanin ng error
  String? selectedUserType; //var na naghohold ng value ng dropdown

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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.pop(); // go back to previous page in the stack
        }
      },

      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            //signtalk bg
            Image.asset(MyApp.signtalk_bg, fit: BoxFit.cover),

            //TODO: NDE MAPINDOT
            /*  Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: CustomBackButton(
              colorCode: MyApp.white,
              onPressed: () => context.go('/login_screen'),
              iconSize: 30,
            ),
          ),*/

            // back button
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 50,
              ),

              child: Column(
                //main column parent
                children: [
                  SafeArea(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
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
                          CustomTextfieldAuth(
                            labelText: "Age",
                            controller: null,
                          ),
                          SizedBox(height: 20),

                          //user type
                          CustomTextfieldDropdown(
                            hint: "User Type",
                            value: selectedUserType,
                            items: userTypes,
                            onChanged: (value) =>
                                setState(() => selectedUserType = value),
                          ),
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

                          SizedBox(height: 30),
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
      ),
    );
  }
}
