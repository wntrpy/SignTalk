import 'package:flutter/material.dart';
import 'package:signtalk/main.dart'; // for MyApp.color and font size constants

class CustomPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? errorText;

  const CustomPasswordField({
    super.key,
    required this.controller,
    required this.labelText,
    this.errorText,
  });

  @override
  State<CustomPasswordField> createState() => _CustomPasswordFieldState();
}

class _CustomPasswordFieldState extends State<CustomPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔠 Label above the textfield
        Text(
          widget.labelText,
          style: TextStyle(fontSize: MyApp.fontSizeMedium, color: Colors.white),
        ),
        const SizedBox(height: 5),

        // 🔐 TextField with white bg, rounded border, eye icon
        TextField(
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType: TextInputType.visiblePassword,
          decoration: InputDecoration(
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey[700],
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
            errorText: widget.errorText,
            errorStyle: TextStyle(color: Colors.yellow),
          ),
        ),
      ],
    );
  }
}
