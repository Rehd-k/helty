import 'package:flutter/material.dart';
import 'package:helty/src/doctor/templates/encounter_template_fields.dart';
import 'package:helty/src/models/encounter_template_model.dart';

class EncounterTemplateFormDialog extends StatefulWidget {
  const EncounterTemplateFormDialog({
    super.key,
    this.initial,
    this.existingNames = const [],
  });

  final EncounterTemplateModel? initial;
  final List<String> existingNames;

  static Future<EncounterTemplateModel?> show(
    BuildContext context, {
    EncounterTemplateModel? initial,
    List<String> existingNames = const [],
  }) {
    return showDialog<EncounterTemplateModel>(
      context: context,
      builder: (ctx) => EncounterTemplateFormDialog(
        initial: initial,
        existingNames: existingNames,
      ),
    );
  }

  @override
  State<EncounterTemplateFormDialog> createState() =>
      _EncounterTemplateFormDialogState();
}

class _EncounterTemplateFormDialogState extends State<EncounterTemplateFormDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descriptionCtrl;
  String? _encounterType;

  late final Map<String, TextEditingController> _fieldCtrls;

  static const _textFields = <String, String>{
    'chiefComplaint': 'Chief complaint',
    'hpi': 'History of present illness',
    'pmh': 'Past medical history',
    'surgicalHistory': 'Surgical history',
    'drugHistory': 'Drug history',
    'allergyHistory': 'Allergy history',
    'familyHistory': 'Family history',
    'socialHistory': 'Social history',
    'examinationNotes': 'Examination notes',
    'triageNotes': 'Triage notes',
    'visitType': 'Visit type',
  };

  static const _soapFields = <String, String>{
    'soapSubjective': 'Subjective',
    'soapObjective': 'Objective',
    'soapAssessment': 'Assessment',
    'soapPlan': 'Plan',
  };

  static const _diagnosisFields = <String, String>{
    'primaryIcdCode': 'Primary ICD code',
    'primaryIcdDescription': 'Primary ICD description',
    'secondaryDiagnosesJson': 'Secondary diagnoses JSON',
  };

  static const _followUpFields = <String, String>{
    'followUpDate': 'Follow-up date (text)',
    'followUpInstructions': 'Follow-up instructions',
    'referral': 'Referral',
    'proceduresJson': 'Procedures JSON',
    'specialtyModulesJson': 'Specialty modules JSON',
    'clinicalSectionsJson': 'Clinical sections JSON',
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    final initial = widget.initial;
    _nameCtrl = TextEditingController(text: initial?.name ?? '');
    _descriptionCtrl = TextEditingController(text: initial?.description ?? '');
    _encounterType = initial?.encounterType?.trim().toUpperCase();

    _fieldCtrls = {};
    for (final key in [
      ..._textFields.keys,
      ..._soapFields.keys,
      ..._diagnosisFields.keys,
      ..._followUpFields.keys,
    ]) {
      _fieldCtrls[key] = TextEditingController(
        text: initial?.getField(key) ?? '',
      );
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    for (final c in _fieldCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Name is required';
    if (name.length > 120) return 'Max 120 characters';
    final lower = name.toLowerCase();
    final editingId = widget.initial?.id;
    for (final existing in widget.existingNames) {
      if (existing.toLowerCase() == lower &&
          (editingId == null ||
              widget.initial?.name.toLowerCase() != lower)) {
        return 'You already have a template with this name';
      }
    }
    return null;
  }

  EncounterTemplateModel _buildModel() {
    String? read(String key) {
      final v = _fieldCtrls[key]?.text.trim() ?? '';
      return v.isEmpty ? null : v;
    }

    return EncounterTemplateModel(
      id: widget.initial?.id ?? '',
      name: _nameCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      encounterType: _encounterType,
      chiefComplaint: read('chiefComplaint'),
      hpi: read('hpi'),
      pmh: read('pmh'),
      surgicalHistory: read('surgicalHistory'),
      drugHistory: read('drugHistory'),
      allergyHistory: read('allergyHistory'),
      familyHistory: read('familyHistory'),
      socialHistory: read('socialHistory'),
      examinationNotes: read('examinationNotes'),
      soapSubjective: read('soapSubjective'),
      soapObjective: read('soapObjective'),
      soapAssessment: read('soapAssessment'),
      soapPlan: read('soapPlan'),
      triageNotes: read('triageNotes'),
      visitType: read('visitType'),
      primaryIcdCode: read('primaryIcdCode'),
      primaryIcdDescription: read('primaryIcdDescription'),
      secondaryDiagnosesJson: read('secondaryDiagnosesJson'),
      proceduresJson: read('proceduresJson'),
      specialtyModulesJson: read('specialtyModulesJson'),
      clinicalSectionsJson: read('clinicalSectionsJson'),
      followUpDate: read('followUpDate'),
      followUpInstructions: read('followUpInstructions'),
      referral: read('referral'),
      doctorId: widget.initial?.doctorId,
      createdById: widget.initial?.createdById,
      updatedById: widget.initial?.updatedById,
      createdAt: widget.initial?.createdAt,
      updatedAt: widget.initial?.updatedAt,
      doctor: widget.initial?.doctor,
      createdBy: widget.initial?.createdBy,
      updatedBy: widget.initial?.updatedBy,
    );
  }

  Widget _fieldsColumn(Map<String, String> fields, {int maxLines = 4}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: fields.entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _fieldCtrls[e.key],
                  decoration: InputDecoration(
                    labelText: e.value,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: maxLines > 1,
                  ),
                  maxLines: e.key.endsWith('Json') ? 3 : maxLines,
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit template' : 'New template'),
      content: SizedBox(
        width: 560,
        height: 520,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
                maxLength: 120,
                validator: _validateName,
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
              const SizedBox(height: 8),
              TabBar(
                controller: _tabs,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'History'),
                  Tab(text: 'SOAP'),
                  Tab(text: 'Diagnosis'),
                  Tab(text: 'Follow-up'),
                  Tab(text: 'JSON'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _fieldsColumn(_textFields),
                    _fieldsColumn(_soapFields),
                    _fieldsColumn(_diagnosisFields, maxLines: 2),
                    _fieldsColumn(
                      {
                        'followUpDate': 'Follow-up date',
                        'followUpInstructions': 'Follow-up instructions',
                        'referral': 'Referral',
                      },
                    ),
                    _fieldsColumn(
                      {
                        'proceduresJson': 'Procedures JSON',
                        'specialtyModulesJson': 'Specialty modules JSON',
                        'clinicalSectionsJson': 'Clinical sections JSON',
                      },
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, _buildModel());
          },
          child: Text(isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
