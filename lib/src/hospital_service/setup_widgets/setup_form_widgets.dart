import 'package:flutter/material.dart';

// --------------------------------------------------------------------------
// Shared reusable form components for the System Setup screen.
// --------------------------------------------------------------------------

/// Icon + bilingual title row at the top of every form card.
class SetupFormHeader extends StatelessWidget {
  const SetupFormHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle; // French subtitle

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: cs.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Styled text field used across all setup forms.
class SetupTextField extends StatelessWidget {
  const SetupTextField({
    super.key,
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.isNumber = false,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final bool isNumber;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 13,
          color: cs.onSurface.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      style: TextStyle(fontSize: 14, color: cs.onSurface),
    );
  }
}

/// Styled dropdown used across all setup forms.
///
/// [items] holds the actual values stored/passed to [onChanged].
/// [itemLabels] is an optional parallel list of display strings; if omitted,
/// [items] are shown directly.
class SetupDropdown extends StatelessWidget {
  const SetupDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabels,
  });

  final String label;
  final String? value;
  final List<String> items;
  final List<String>? itemLabels; // display names (parallel to items)
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 13,
          color: cs.onSurface.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      icon: Icon(
        Icons.keyboard_arrow_down,
        size: 18,
        color: cs.onSurface.withValues(alpha: 0.6),
      ),
      style: TextStyle(fontSize: 14, color: cs.onSurface),
      items: List.generate(
        items.length,
        (i) => DropdownMenuItem(
          value: items[i],
          child: Text(
            itemLabels != null && i < itemLabels!.length
                ? itemLabels![i]
                : items[i],
          ),
        ),
      ),
    );
  }
}

/// Primary action button at the bottom of each form.
class SetupSubmitButton extends StatelessWidget {
  const SetupSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.primary,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
