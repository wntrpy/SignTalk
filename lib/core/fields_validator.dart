import 'package:flutter/material.dart';

void validateNameEmailAge({
  required BuildContext context,
  required TextEditingController nameController,
  required TextEditingController emailController,
  required TextEditingController ageController,
  required void Function({
    String? nameError,
    String? emailError,
    String? ageError,
  }) onValidationResult,
}) {
  final name = nameController.text.trim();
  final email = emailController.text.trim();
  final age = ageController.text.trim();

  String? nameError;
  String? emailError;
  String? ageError;


   final emailRegex = RegExp(
    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
  );

  if (name.isEmpty) nameError = "Name can't be empty";
  if (email.isEmpty) {
    emailError = "Email can't be empty";
  } else if (!emailRegex.hasMatch(email)) {
    emailError = "Invalid email format";
  }

  if (age.isEmpty) {
    ageError = "Age can't be empty";
  } else if (int.tryParse(age) == null || int.parse(age) <= 0) {
    ageError = "Age must be a valid number";
  }

  onValidationResult(
    nameError: nameError,
    emailError: emailError,
    ageError: ageError,
  );
}
