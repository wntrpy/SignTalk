import 'package:flutter/material.dart';
import 'package:signtalk/main.dart';

class CustomLineTextfield extends StatelessWidget {
  final String label;
  final String defaultValue;
  final bool isEditable;

  const CustomLineTextfield({
    super.key,
    required this.label,
    required this.defaultValue,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: defaultValue);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------ LABEL TEXT ------------------------
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              label,
              style: TextStyle(
                color: MyApp.darkViolet,
                fontSize: MyApp.fontSizeSmall,
              ),
            ),
          ),

          // ------------------------ TEXT FIELD WITH CUSTOM UNDERLINE ------------------------
          TextField(
            controller: controller,
            enabled: isEditable,
            style: const TextStyle(color: Colors.black),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.only(left: 16.0, bottom: 8.0),
              border: InputBorder.none,
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(left: 16.0), // Align with text
            child: Divider(thickness: 1, color: Colors.black, height: 1),
          ),
        ],
      ),
    );
  }
}
