import 'package:flutter/material.dart';

/// A reusable, modern text field tailored for your hospital's UI design
class ModernTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData? icon;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const ModernTextField({
    super.key,
    required this.label,
    required this.hint,
    this.icon,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: icon != null
                  ? Icon(icon, color: Colors.grey.shade500, size: 20)
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.colorScheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A modern card for Boolean toggles (e.g., Is Controlled? Is Refrigerated?)
class ModernSwitchCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ModernSwitchCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
