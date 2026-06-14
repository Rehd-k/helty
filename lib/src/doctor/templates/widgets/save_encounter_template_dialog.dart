import 'package:flutter/material.dart';
import 'package:helty/src/doctor/templates/encounter_template_fields.dart';
import 'package:helty/src/models/encounter_template_model.dart';
import 'package:helty/src/services/encounter_service.dart';
import 'package:helty/src/services/encounter_template_service.dart';

class SaveEncounterTemplateDialog extends StatefulWidget {
  const SaveEncounterTemplateDialog({
    super.key,
    required this.encounterId,
    this.encounterType,
    this.prefill,
  });

  final String encounterId;
  final String? encounterType;
  final Map<String, dynamic>? prefill;

  static Future<EncounterTemplateModel?> show(
    BuildContext context, {
    required String encounterId,
    String? encounterType,
    Map<String, dynamic>? prefill,
  }) {
    return showDialog<EncounterTemplateModel>(
      context: context,
      builder: (ctx) => SaveEncounterTemplateDialog(
        encounterId: encounterId,
        encounterType: encounterType,
        prefill: prefill,
      ),
    );
  }

  @override
  State<SaveEncounterTemplateDialog> createState() =>
      _SaveEncounterTemplateDialogState();
}

class _SaveEncounterTemplateDialogState extends State<SaveEncounterTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _service = EncounterTemplateService();
  final _encounterService = EncounterService();

  String? _encounterType;
  Map<String, dynamic>? _clinicalFields;
  bool _loadingPrefill = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _encounterType = widget.encounterType?.trim().toUpperCase();
    _loadPrefill();
  }

  Future<void> _loadPrefill() async {
    if (widget.prefill != null) {
      setState(() {
        _clinicalFields = widget.prefill;
        _loadingPrefill = false;
      });
      return;
    }
    try {
      final enc = await _encounterService.getById(
        widget.encounterId,
        expand: ['specialtyModules', 'clinicalSections'],
      );
      if (!mounted) return;
      setState(() {
        _clinicalFields = enc != null
            ? EncounterTemplateModel.clinicalFieldsFromEncounter(enc)
            : <String, dynamic>{};
        _encounterType ??= enc?.encounterType?.trim().toUpperCase();
        _loadingPrefill = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loadingPrefill = false;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clinicalFields == null) return;

    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        if (_descriptionCtrl.text.trim().isNotEmpty)
          'description': _descriptionCtrl.text.trim(),
        if (_encounterType != null && _encounterType!.isNotEmpty)
          'encounterType': _encounterType,
        ..._clinicalFields!,
      };
      final created = await _service.create(body);
      if (!mounted) return;
      Navigator.pop(context, created);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  int get _fieldCount {
    if (_clinicalFields == null) return 0;
    var count = 0;
    for (final v in _clinicalFields!.values) {
      if (!encounterTemplateFieldIsEmpty(v)) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save as template'),
      content: SizedBox(
        width: 420,
        child: _loadingPrefill
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            : _loadError != null
            ? Text(_loadError!)
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '$_fieldCount clinical fields will be saved (patient data, orders, and vitals are excluded).',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Template name *',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 120,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 500,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      initialValue: _encounterType,
                      decoration: const InputDecoration(
                        labelText: 'Suggested encounter type',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Any type'),
                        ),
                        ...kEncounterTemplateTypes.entries.map(
                          (e) => DropdownMenuItem<String?>(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _encounterType = v),
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving || _loadingPrefill || _loadError != null
              ? null
              : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save template'),
        ),
      ],
    );
  }
}
