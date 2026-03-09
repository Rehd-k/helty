import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/lab_models.dart';

/// Renders a dynamic result-entry form from backend-defined [LabTestField]s.
/// Values are keyed by field id; use [initialValues] to pre-fill (e.g. from GET /lab/results/:orderItemId).
class LabDynamicResultForm extends StatefulWidget {
  const LabDynamicResultForm({
    super.key,
    required this.fields,
    required this.onChanged,
    this.initialValues = const {},
    this.autovalidateMode = AutovalidateMode.disabled,
  });

  final List<LabTestField> fields;
  final Map<String, String> initialValues;
  final ValueChanged<Map<String, String>> onChanged;
  final AutovalidateMode autovalidateMode;

  @override
  State<LabDynamicResultForm> createState() => LabDynamicResultFormState();
}

/// State of [LabDynamicResultForm]. Use [GlobalKey<LabDynamicResultFormState>]
/// to call [validate] and read [values] / [valuesIfValid] from parent.
class LabDynamicResultFormState extends State<LabDynamicResultForm> {
  late Map<String, String> _values;
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _values = Map<String, String>.from(widget.initialValues);
    for (final f in widget.fields) {
      if (!_values.containsKey(f.id)) {
        if (f.fieldType == LabFieldType.checkbox) {
          _values[f.id] = 'false';
        }
      }
    }
  }

  @override
  void didUpdateWidget(LabDynamicResultForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValues != widget.initialValues) {
      _values = Map<String, String>.from(widget.initialValues);
      for (final f in widget.fields) {
        if (!_values.containsKey(f.id) && f.fieldType == LabFieldType.checkbox) {
          _values[f.id] = 'false';
        }
      }
    }
  }

  void _setValue(String fieldId, String value) {
    setState(() {
      _values[fieldId] = value;
      _errors.remove(fieldId);
    });
    widget.onChanged(Map.from(_values));
  }

  String? _validate() {
    _errors.clear();
    for (final f in widget.fields) {
      final v = (_values[f.id] ?? '').trim();
      if (f.required && v.isEmpty) {
        _errors[f.id] = 'Required';
      }
    }
    if (_errors.isNotEmpty) {
      // Trigger rebuild so error text is shown.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
    return _errors.isEmpty ? null : _errors.values.first;
  }

  /// Runs validation and returns current values if valid, else null.
  Map<String, String>? get valuesIfValid {
    _validate();
    return _errors.isEmpty ? Map.from(_values) : null;
  }

  Map<String, String> get values => Map.from(_values);

  /// Call to run validation and rebuild. Returns true if valid.
  bool validate() {
    _validate();
    return _errors.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = List<LabTestField>.from(widget.fields)
      ..sort((a, b) => a.position.compareTo(b.position));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sorted.map((field) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _buildField(context, theme, field),
        );
      }).toList(),
    );
  }

  Widget _buildField(
      BuildContext context, ThemeData theme, LabTestField field) {
    final value = _values[field.id] ?? '';
    final error = _errors[field.id];
    final hint = [
      if (field.unit != null && field.unit!.isNotEmpty) 'Unit: ${field.unit}',
      if (field.referenceRange != null &&
          field.referenceRange!.isNotEmpty)
        'Ref: ${field.referenceRange}',
    ].join(' • ');

    switch (field.fieldType) {
      case LabFieldType.text:
        return _ModernTextField(
          label: field.label,
          hint: hint.isNotEmpty ? hint : null,
          value: value,
          error: error,
          required: field.required,
          onChanged: (v) => _setValue(field.id, v),
          maxLines: 2,
        );
      case LabFieldType.number:
        return _ModernTextField(
          label: field.label,
          hint: hint.isNotEmpty ? hint : null,
          value: value,
          error: error,
          required: field.required,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.\-eE]')),
          ],
          onChanged: (v) => _setValue(field.id, v),
        );
      case LabFieldType.dropdown:
        return _ModernDropdownField(
          label: field.label,
          hint: hint.isNotEmpty ? hint : null,
          value: value,
          error: error,
          required: field.required,
          options: field.options,
          onChanged: (v) => _setValue(field.id, v ?? ''),
        );
      case LabFieldType.checkbox:
        return _ModernCheckboxField(
          label: field.label,
          hint: hint.isNotEmpty ? hint : null,
          value: value.toLowerCase() == 'true' || value == '1',
          onChanged: (v) => _setValue(field.id, v ? 'true' : 'false'),
        );
      case LabFieldType.multiselect:
        return _ModernMultiselectField(
          label: field.label,
          hint: hint.isNotEmpty ? hint : null,
          value: value,
          error: error,
          required: field.required,
          options: field.options,
          onChanged: (v) => _setValue(field.id, v),
        );
      case LabFieldType.date:
        return _ModernDateField(
          label: field.label,
          hint: hint.isNotEmpty ? hint : null,
          value: value.isEmpty ? null : DateTime.tryParse(value),
          error: error,
          required: field.required,
          onChanged: (v) => _setValue(field.id, v?.toIso8601String().split('T').first ?? ''),
        );
    }
  }
}

// ── Modern field widgets ────────────────────────────────────────────────────

class _ModernTextField extends StatelessWidget {
  const _ModernTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.error,
    this.required = false,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });

  final String label;
  final String? hint;
  final String value;
  final String? error;
  final bool required;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label: label, required: required, hint: hint),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: error != null
                  ? theme.colorScheme.error
                  : theme.colorScheme.outlineVariant,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            initialValue: value,
            onChanged: onChanged,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              errorBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorText: null,
            ),
            style: theme.textTheme.bodyLarge,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _ModernDropdownField extends StatelessWidget {
  const _ModernDropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint,
    this.error,
    this.required = false,
  });

  final String label;
  final String? hint;
  final String value;
  final String? error;
  final bool required;
  final List<LabFieldOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label: label, required: required, hint: hint),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: error != null
                  ? theme.colorScheme.error
                  : theme.colorScheme.outlineVariant,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value.isEmpty ? null : value,
              isExpanded: true,
              hint: Text(hint ?? 'Select'),
              items: options
                  .map((o) => DropdownMenuItem<String>(
                        value: o.value,
                        child: Text(o.label),
                      ))
                  .toList(),
              onChanged: (v) => onChanged(v),
              borderRadius: BorderRadius.circular(10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _ModernCheckboxField extends StatelessWidget {
  const _ModernCheckboxField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              activeColor: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hint != null && hint!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    hint!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernMultiselectField extends StatelessWidget {
  const _ModernMultiselectField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint,
    this.error,
    this.required = false,
  });

  final String label;
  final String? hint;
  final String value;
  final String? error;
  final bool required;
  final List<LabFieldOption> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Value: comma-separated or JSON array string
    final selected = value.isEmpty
        ? <String>[]
        : value
            .replaceAll(RegExp(r'[\[\]"]'), '')
            .split(RegExp(r'[,]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label: label, required: required, hint: hint),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((o) {
            final isSelected = selected.contains(o.value);
            return FilterChip(
              label: Text(o.label),
              selected: isSelected,
              onSelected: (v) {
                final next = List<String>.from(selected);
                if (v) {
                  if (!next.contains(o.value)) next.add(o.value);
                } else {
                  next.remove(o.value);
                }
                onChanged(next.join(','));
              },
              selectedColor: theme.colorScheme.primaryContainer,
              checkmarkColor: theme.colorScheme.onPrimaryContainer,
              side: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }).toList(),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _ModernDateField extends StatelessWidget {
  const _ModernDateField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.error,
    this.required = false,
  });

  final String label;
  final String? hint;
  final DateTime? value;
  final String? error;
  final bool required;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label: label, required: required, hint: hint),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (picked != null) onChanged(picked);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: error != null
                    ? theme.colorScheme.error
                    : theme.colorScheme.outlineVariant,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  value != null
                      ? '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}'
                      : (hint ?? 'Pick date'),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: value != null
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.label,
    this.required = false,
    this.hint,
  });

  final String label;
  final bool required;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RichText(
      text: TextSpan(
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        children: [
          TextSpan(text: label),
          if (required)
            TextSpan(
              text: ' *',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          if (hint != null && hint!.isNotEmpty)
            TextSpan(
              text: '  · $hint',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }
}
