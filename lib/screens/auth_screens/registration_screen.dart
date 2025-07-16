import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:signtalk/core/password_validator.dart';
import 'package:signtalk/core/fields_validator.dart';
import 'package:signtalk/widgets/textfields/custom_textfield_auth.dart';
import 'package:signtalk/widgets/buttons/custom_button.dart';
import 'package:signtalk/widgets/textfields/custom_password_textfield.dart';
import 'package:signtalk/widgets/custom_signtalk_logo.dart';
import 'package:signtalk/widgets/textfields/custom_textfield_dropdown.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/providers/auth_provider.dart' as authentication;

//TODO: linisin mo frontend neto buset
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  final List<String> userTypes = ['Hearing', 'Non-Hearing']; //laman ng dropdown

  String? _passwordError; //var na naghohold ng lalamanin ng error
  String? _nameError;
  String? _emailError;
  String? _ageError;

  String? selectedUserType; //var na naghohold ng value ng dropdown

Future <bool> _handleSubmit() async {
  bool FormisValid = true;

  validateNameEmailAge(
    context: context,
    nameController: _nameController,
    emailController: _emailController,
    ageController: _ageController,
    onValidationResult: ({
      String? nameError,
      String? emailError,
      String? ageError,
    }) {
      final hasError = nameError != null || emailError != null || ageError != null;

      setState(() {
        _nameError = nameError;
        _emailError = emailError;
        _ageError = ageError;
      });

      if (hasError) FormisValid = false;
      
      
      validateAndSubmit(
        context: context,
        passwordController: _passwordController,
        confirmPasswordController: _confirmPasswordController,
        onValidationResult: (error) {
          setState(() {
            _passwordError = error;
          });
          if (error != null) FormisValid = false;
        },
      );
    },
  );
   if (!FormisValid) return false;

  final int parsedAge = int.parse(_ageController.text.trim());

  //AuthProvider registration call
  try {
    final authentication.AuthProvider authProvider = Provider.of<authentication.AuthProvider>(context, listen: false);
    await authProvider.register(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _nameController.text.trim(),
      parsedAge,
      selectedUserType ?? '',
    );
    return true;
  } catch (e) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registration failed: ${e.toString()}')),
    );
    return false;
  }
}


  //TODO: lagyan mo ng isempty validation kada field ---OK NA
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
            Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),

            //TODO: NDE MAPINDOT
            /*  Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: CustomBackButton(
              colorCode: AppConstants.white,
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
                            controller: _nameController,
                            errorText: _nameError,
                            onChanged: (value) {
                              setState(() {
                                _nameError = null; // Clear error when user types
                              });
                            },
                          ),
                          SizedBox(height: 20),

                          //age
                          CustomTextfieldAuth(
                            labelText: "Age",
                            controller: _ageController,
                            errorText: _ageError,
                             onChanged: (value) {
                              setState(() {
                                _ageError = null; // Clear error when user types
                              });
                            },
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

                          //email
                          CustomTextfieldAuth(
                            labelText: "Email",
                            controller: _emailController,
                            errorText: _emailError,
                             onChanged: (value) {
                              setState(() {
                                _emailError = null; // Clear error when user types
                              });
                            },
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
                              colorCode: AppConstants.orange,
                              buttonWidth: 200,
                              buttonHeight: 50,
                              onPressed: () async{
                               final success = await _handleSubmit(); 
                                if (success) {
                                  context.push('/login_screen');
                                }
                              },  //TODO: FIX MO LATER
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
