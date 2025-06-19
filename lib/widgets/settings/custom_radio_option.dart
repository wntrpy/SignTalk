import 'package:flutter/material.dart';

class CustomRadioOption extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;
  const CustomRadioOption({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Radio<String>(
        value: value,
        groupValue: groupValue,
        activeColor: Color(0xFF6F22A3),
        onChanged: (val) => onChanged(val!),
      ),
      title: Text(label),
    );
  }
}
