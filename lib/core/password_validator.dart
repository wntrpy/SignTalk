import 'package:flutter/material.dart';

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

  // Just return success - NO navigation here
  onValidationResult(null);
}

void clearController(
  TextEditingController passwordController,
  TextEditingController confirmPasswordController,
) {
  passwordController.clear();
  confirmPasswordController.clear();
}
