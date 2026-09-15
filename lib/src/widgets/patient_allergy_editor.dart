import 'package:flutter/material.dart';

import '../models/patient_clinical_record_models.dart';
import '../services/patient_clinical_records_service.dart';

class PatientAllergyEditor extends StatefulWidget {
  const PatientAllergyEditor({
    super.key,
    required this.patientId,
    this.compact = false,
    this.enabled = true,
  });

  final String patientId;
  final bool compact;
  final bool enabled;

  @override
  State<PatientAllergyEditor> createState() => _PatientAllergyEditorState();
}

class _PatientAllergyEditorState extends State<PatientAllergyEditor> {
  final _service = PatientClinicalRecordsService();
  final _allergenCtrl = TextEditingController();
  final _reactionCtrl = TextEditingController();
  String? _severity = 'MODERATE';
  List<PatientAllergyRecord> _items = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant PatientAllergyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patientId != widget.patientId) {
      _reload();
    }
  }

  @override
  void dispose() {
    _allergenCtrl.dispose();
    _reactionCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    if (widget.patientId.trim().isEmpty) {
      setState(() {
        _items = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final items = await _service.listAllergies(widget.patientId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load allergies: $e')));
    }
  }

  Future<void> _add() async {
    final allergen = _allergenCtrl.text.trim();
    if (allergen.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final created = await _service.createAllergy(
        patientId: widget.patientId,
        allergen: allergen,
        reaction: _reactionCtrl.text.trim(),
        severity: _severity,
      );
      if (!mounted) return;
      setState(() {
        _items = [created, ..._items];
        _allergenCtrl.clear();
        _reactionCtrl.clear();
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add allergy: $e')));
    }
  }

  Future<void> _delete(PatientAllergyRecord item) async {
    try {
      await _service.deleteAllergy(
        patientId: widget.patientId,
        allergyId: item.id,
      );
      if (!mounted) return;
      setState(() {
        _items = _items.where((e) => e.id != item.id).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove allergy: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Allergies',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(minHeight: 2),
          )
        else if (_items.isEmpty)
          Text(
            'No known allergies on file.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in _items)
                InputChip(
                  label: Text(item.displayLabel),
                  onDeleted: widget.enabled ? () => _delete(item) : null,
                ),
            ],
          ),
        if (widget.enabled) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _allergenCtrl,
            decoration: const InputDecoration(
              labelText: 'Allergen',
              hintText: 'e.g. Penicillin',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 8),
          if (widget.compact)
            Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _severity,
                  decoration: const InputDecoration(labelText: 'Severity'),
                  items: [
                    for (final value in kAllergySeverities)
                      DropdownMenuItem(
                        value: value,
                        child: Text(_titleCase(value)),
                      ),
                  ],
                  onChanged: (value) => setState(() => _severity = value),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reactionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reaction (optional)',
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _severity,
                    decoration: const InputDecoration(labelText: 'Severity'),
                    items: [
                      for (final value in kAllergySeverities)
                        DropdownMenuItem(
                          value: value,
                          child: Text(_titleCase(value)),
                        ),
                    ],
                    onChanged: (value) => setState(() => _severity = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _reactionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Reaction (optional)',
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: _saving ? null : _add,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add, size: 18),
              label: const Text('Add allergy'),
            ),
          ),
        ],
      ],
    );
  }
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
}
