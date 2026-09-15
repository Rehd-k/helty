import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../helper/date.formatter.dart';
import '../models/patient_clinical_record_models.dart';
import '../services/patient_clinical_records_service.dart';

class PatientImmunizationEditor extends StatefulWidget {
  const PatientImmunizationEditor({
    super.key,
    required this.patientId,
    this.enabled = true,
  });

  final String patientId;
  final bool enabled;

  @override
  State<PatientImmunizationEditor> createState() =>
      _PatientImmunizationEditorState();
}

class _PatientImmunizationEditorState extends State<PatientImmunizationEditor> {
  final _service = PatientClinicalRecordsService();
  final _nameCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  DateTime _administeredAt = DateTime.now();
  List<PatientImmunizationRecord> _items = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant PatientImmunizationEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patientId != widget.patientId) {
      _reload();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _detailCtrl.dispose();
    _doseCtrl.dispose();
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
      final items = await _service.listImmunizations(widget.patientId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load immunizations: $e')),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _administeredAt,
      firstDate: DateTime(1950),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && mounted) {
      setState(() => _administeredAt = picked);
    }
  }

  Future<void> _add() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final created = await _service.createImmunization(
        patientId: widget.patientId,
        vaccineName: name,
        detail: _detailCtrl.text.trim(),
        doseNumber: int.tryParse(_doseCtrl.text.trim()),
        administeredAt: _administeredAt,
      );
      if (!mounted) return;
      setState(() {
        _items = [created, ..._items];
        _nameCtrl.clear();
        _detailCtrl.clear();
        _doseCtrl.clear();
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add immunization: $e')));
    }
  }

  Future<void> _delete(PatientImmunizationRecord item) async {
    try {
      await _service.deleteImmunization(
        patientId: widget.patientId,
        immunizationId: item.id,
      );
      if (!mounted) return;
      setState(() {
        _items = _items.where((e) => e.id != item.id).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove immunization: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Immunizations',
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
            'No immunizations on file.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          Column(
            children: [
              for (final item in _items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.vaccines_outlined),
                  title: Text(item.vaccineName),
                  subtitle: Text(
                    [
                      if (item.detail?.trim().isNotEmpty == true) item.detail,
                      if (item.doseNumber != null) 'Dose ${item.doseNumber}',
                      DateFormatter.medicalDate(item.administeredAt),
                    ].whereType<String>().join(' · '),
                  ),
                  trailing: widget.enabled
                      ? IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(item),
                        )
                      : null,
                ),
            ],
          ),
        if (widget.enabled) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Vaccine name',
              hintText: 'e.g. Tetanus toxoid',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _detailCtrl,
            decoration: const InputDecoration(labelText: 'Detail (optional)'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _doseCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Dose number'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(DateFormatter.medicalDate(_administeredAt)),
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
              label: const Text('Add immunization'),
            ),
          ),
        ],
      ],
    );
  }
}
