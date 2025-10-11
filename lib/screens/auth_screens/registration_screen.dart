import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final List<String> userTypes = ['Hearing', 'Non-Hearing'];

  String? _passwordError;
  String? _nameError;
  String? _emailError;
  String? _ageError;

  String? selectedUserType;
  bool _isLoading = false;

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  bool _validateEmptyFields() {
    bool hasError = false;

    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = "Name cannot be empty");
      hasError = true;
    }

    if (_ageController.text.trim().isEmpty) {
      setState(() => _ageError = "Age cannot be empty");
      hasError = true;
    }

    if (_emailController.text.trim().isEmpty) {
      setState(() => _emailError = "Email cannot be empty");
      hasError = true;
    }

    if (_passwordController.text.trim().isEmpty) {
      setState(() => _passwordError = "Password cannot be empty");
      hasError = true;
    }

    if (_confirmPasswordController.text.trim().isEmpty) {
      setState(() => _passwordError = "Confirm password cannot be empty");
      hasError = true;
    }

    if (selectedUserType == null || selectedUserType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a user type")),
      );
      hasError = true;
    }

    return !hasError;
  }

  bool _validateAge() {
    final ageText = _ageController.text.trim();

    if (ageText.isEmpty) {
      setState(() => _ageError = "Age cannot be empty");
      return false;
    }

    final age = int.tryParse(ageText);
    if (age == null) {
      setState(() => _ageError = "Age must be a valid number");
      return false;
    }

    if (age < 1 || age > 150) {
      setState(() => _ageError = "Please enter a valid age");
      return false;
    }

    return true;
  }

  bool _validateEmailFormat() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = "Email cannot be empty");
      return false;
    }

    if (!_isValidEmail(email)) {
      setState(() => _emailError = "Please enter a valid email address");
      return false;
    }

    return true;
  }

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
    if (_isLoading) return false;

    setState(() {
      _isLoading = true;
      _nameError = null;
      _emailError = null;
      _ageError = null;
      _passwordError = null;
    });

    try {
      if (!_validateEmptyFields()) {
        setState(() => _isLoading = false);
        return false;
      }

      if (!_validateAge()) {
        setState(() => _isLoading = false);
        return false;
      }

      if (!_validateEmailFormat()) {
        setState(() => _isLoading = false);
        return false;
      }

      final nameEmailAgeValid = await _validateNameEmailAge();
      if (!nameEmailAgeValid) {
        setState(() => _isLoading = false);
        return false;
      }

      final passwordsValid = await _validatePasswords();
      if (!passwordsValid) {
        setState(() => _isLoading = false);
        return false;
      }

      int parsedAge = int.parse(_ageController.text.trim());

      final authentication.AuthProvider authProvider =
          Provider.of<authentication.AuthProvider>(context, listen: false);

      await authProvider.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        parsedAge,
        selectedUserType ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration successful!"),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() => _isLoading = false);
      return true;
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');

      setState(() {
        _emailError = errorMessage;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }

      return false;
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.pop();
        }
      },
      child: Scaffold(
        // ✅ Let Scaffold adjust when keyboard shows
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // ✅ Background stays static
            Positioned.fill(
              child: Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),
            ),

            // ✅ Use SafeArea + Padding + SingleChildScrollView
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    // ✅ Automatically scrolls when keyboard opens
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40.0,
                      vertical: 50,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Center(
                              child: CustomSigntalkLogo(
                                width: 150,
                                height: 150,
                              ),
                            ),
                            const SizedBox(height: 20),

                            CustomTextfieldAuth(
                              labelText: "Name",
                              controller: _nameController,
                              errorText: _nameError,
                              onChanged: (_) =>
                                  setState(() => _nameError = null),
                            ),
                            const SizedBox(height: 20),

                            CustomTextfieldAuth(
                              labelText: "Age",
                              controller: _ageController,
                              errorText: _ageError,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (_) =>
                                  setState(() => _ageError = null),
                            ),
                            const SizedBox(height: 20),

                            CustomTextfieldDropdown(
                              hint: "User Type",
                              value: selectedUserType,
                              items: userTypes,
                              onChanged: (value) =>
                                  setState(() => selectedUserType = value),
                            ),
                            const SizedBox(height: 20),

                            CustomTextfieldAuth(
                              labelText: "Email",
                              controller: _emailController,
                              errorText: _emailError,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (_) =>
                                  setState(() => _emailError = null),
                            ),
                            const SizedBox(height: 20),

                            // ✅ Password fields
                            CustomPasswordField(
                              controller: _passwordController,
                              labelText: 'Password',
                              errorText: _passwordError,
                              onChanged: (_) =>
                                  setState(() => _passwordError = null),
                            ),
                            const SizedBox(height: 20),

                            CustomPasswordField(
                              controller: _confirmPasswordController,
                              labelText: 'Confirm Password',
                              errorText: _passwordError,
                              onChanged: (_) =>
                                  setState(() => _passwordError = null),
                            ),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () => context.push('/login_screen'),
                                child: Text(
                                  "Already Registered?",
                                  style: TextStyle(
                                    color: AppConstants.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Align(
                              alignment: Alignment.centerRight,
                              child: CustomButton(
                                buttonText: "Register",
                                colorCode: AppConstants.orange,
                                buttonWidth: 200,
                                buttonHeight: 50,
                                onPressed: _isLoading ? null : _handleSubmit,
                                textSize: 24,
                                borderRadiusValue: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: CircularProgressIndicator(color: AppConstants.orange),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
