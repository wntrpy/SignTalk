import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signtalk/app_constants.dart';

class CustomTextfieldAuth extends StatelessWidget {
  final String labelText;
  final TextEditingController? controller;
  final String? errorText;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextfieldAuth({
    super.key,
    required this.labelText,
    required this.controller,
    this.errorText,
    this.onChanged,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            fontSize: AppConstants.fontSizeMedium,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 5),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            errorText: errorText,
            errorStyle: TextStyle(color: Colors.yellow),
          ),
        ),
      ],
    );
  }
}
