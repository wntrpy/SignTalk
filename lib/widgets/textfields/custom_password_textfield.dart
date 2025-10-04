import 'package:flutter/material.dart';
import 'package:signtalk/app_constants.dart';

class CustomPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? errorText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const CustomPasswordField({
    super.key,
    required this.controller,
    required this.labelText,
    this.errorText,
    this.validator,
    this.onChanged,
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
        Text(
          widget.labelText,
          style: TextStyle(
            fontSize: AppConstants.fontSizeMedium,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          onChanged: widget.onChanged,
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
