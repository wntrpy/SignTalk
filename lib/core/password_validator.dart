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

  /*if (password.isEmpty && confirm.isEmpty) {
    onValidationResult("Password can't be empty");
    return;
  }

  if (password.length < 8) {
    onValidationResult('Password must be at least 8 characters');
    return;
  }

  if (password != confirm) {
    onValidationResult('Passwords do not match');
    return;
  }*/

  onValidationResult(null);
  context.go('/welcome_screen');
}
