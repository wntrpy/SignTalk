import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void validateAndSubmit({
  required BuildContext context,
  required TextEditingController passwordController,
  required TextEditingController confirmPasswordController,
  required void Function(String? errorText) onValidationResult,
}) {
  final password = passwordController.text.trim();
  final confirm = confirmPasswordController.text.trim();

  if (password.isEmpty && confirm.isEmpty) {
    onValidationResult("Password can't be empty");
    clearController(passwordController, confirmPasswordController);
    return;
  }

  if (password.length < 8) {
    onValidationResult('Password must be at least 8 characters');
    clearController(passwordController, confirmPasswordController);

    return;
  }

  if (password != confirm) {
    onValidationResult('Passwords do not match');
    clearController(passwordController, confirmPasswordController);

    return;
  }

  //NOTE: KAYA MO NACLEAR DITO KASI MAY SARILING LISTENERS MGA TEXTFIELDCONTROLLER
  //KAYA NAREREBUILD YUNG UI KAPAG MAY BINAGO KA

  onValidationResult(null);
  context.push('/welcome_screen');
}

void clearController(
  TextEditingController passwordController,
  TextEditingController confirmPasswordController,
) {
  passwordController.clear();
  confirmPasswordController.clear();
}
