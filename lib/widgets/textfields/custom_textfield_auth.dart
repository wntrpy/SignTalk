import 'package:flutter/material.dart';
import 'package:signtalk/app_constants.dart';

class CustomTextfieldAuth extends StatelessWidget {
  final String labelText;
  final TextEditingController? controller;

  const CustomTextfieldAuth({
    super.key,
    required this.labelText,
    required this.controller,
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
        ), //label text na nasa taas ng textfield
        SizedBox(height: 5),

        TextField(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          ),
        ),
      ],
    );
  }
}
