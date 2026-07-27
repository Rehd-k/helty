import 'package:flutter/material.dart';

/// Text field that follows the global [InputDecorationTheme].
class BuildModernTextField extends StatelessWidget {
  final ColorScheme colorScheme;
  final String label;
  final String hint;
  final bool isNumber;
  final TextEditingController controller;

  const BuildModernTextField({
    super.key,
    required this.colorScheme,
    required this.label,
    required this.hint,
    required this.isNumber,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }
}
