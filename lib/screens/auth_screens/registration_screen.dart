import 'dart:async';
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
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  final List<String> userTypes = [
    'Hearing',
    'Non-Hearing',
  ]; // laman ng dropdown

  String? _passwordError; // var na naghohold ng lalamanin ng error
  String? _nameError;
  String? _emailError;
  String? _ageError;

  String? selectedUserType; // var na naghohold ng value ng dropdown

  // Wrap validateNameEmailAge in a Future so we can await it reliably
  Future<bool> _validateNameEmailAge() async {
    final completer = Completer<Map<String, String?>>();

    validateNameEmailAge(
      context: context,
      nameController: _nameController,
      emailController: _emailController,
      ageController: _ageController,
      onValidationResult:
          ({String? nameError, String? emailError, String? ageError}) {
            if (!completer.isCompleted) {
              completer.complete({
                'name': nameError,
                'email': emailError,
                'age': ageError,
              });
            }
          },
    );

    final result = await completer.future;
    setState(() {
      _nameError = result['name'];
      _emailError = result['email'];
      _ageError = result['age'];
    });

    return result['name'] == null &&
        result['email'] == null &&
        result['age'] == null;
  }

  Future<bool> _validatePasswords() async {
    // Check if empty
    if (_passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      setState(() {
        _passwordError = "Password fields cannot be empty";
      });
      return false;
    }

    final completer = Completer<String?>();

    validateAndSubmit(
      context: context,
      passwordController: _passwordController,
      confirmPasswordController: _confirmPasswordController,
      onValidationResult: (error) {
        if (!completer.isCompleted) completer.complete(error);
      },
    );

    final error = await completer.future;
    setState(() {
      _passwordError = error;
    });

    return error == null;
  }

  Future<bool> _handleSubmit() async {
    final nameEmailAgeValid = await _validateNameEmailAge();
    if (!nameEmailAgeValid) return false;

    final passwordsValid = await _validatePasswords();
    if (!passwordsValid) return false;

    if (selectedUserType == null || selectedUserType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a user type")),
      );
      return false;
    }

    int? parsedAge;
    try {
      parsedAge = int.parse(_ageController.text.trim());
    } catch (_) {
      setState(() {
        _ageError = "Age must be a valid number";
      });
      return false;
    }

    try {
      final authentication.AuthProvider authProvider =
          Provider.of<authentication.AuthProvider>(context, listen: false);

      await authProvider.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        parsedAge,
        selectedUserType ?? '',
      );

      return true; // only success here
    } catch (e) {
      setState(() {
        _emailError = e.toString().replaceFirst('Exception: ', '');
      });
      return false; // stop redirect
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    super.dispose();
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
            // signtalk bg
            Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),

            // back button
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 50,
              ),
              child: Column(
                // main column parent
                children: [
                  SafeArea(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Center(
                            child: CustomSigntalkLogo(width: 150, height: 150),
                          ),
                          //------------------------------------INPUT-FIELDS-------------------------------------------------//
                          // name
                          CustomTextfieldAuth(
                            labelText: "Name",
                            controller: _nameController,
                            errorText: _nameError,
                            onChanged: (value) {
                              setState(() {
                                _nameError =
                                    null; // Clear error when user types
                              });
                            },
                          ),
                          SizedBox(height: 20),

                          // age
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

                          // user type
                          CustomTextfieldDropdown(
                            hint: "User Type",
                            value: selectedUserType,
                            items: userTypes,
                            onChanged: (value) =>
                                setState(() => selectedUserType = value),
                          ),
                          SizedBox(height: 20),

                          // email
                          CustomTextfieldAuth(
                            labelText: "Email",
                            controller: _emailController,
                            errorText: _emailError,
                            onChanged: (value) {
                              setState(() {
                                _emailError =
                                    null; // Clear error when user types
                              });
                            },
                          ),
                          SizedBox(height: 20),

                          // password
                          CustomPasswordField(
                            controller: _passwordController,
                            labelText: 'Password',
                            errorText: _passwordError,
                          ),
                          SizedBox(height: 20),

                          // confirm
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
                              onPressed: () async {
                                final success = await _handleSubmit();
                                if (success) {
                                  context.push('/login_screen');
                                }
                              },

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
