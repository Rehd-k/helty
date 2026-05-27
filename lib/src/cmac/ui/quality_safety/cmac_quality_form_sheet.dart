import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/cmac_quality_safety_models.dart';
import '../../providers/cmac_providers.dart';
import '../../widgets/cmac_patient_picker_field.dart';

Future<bool?> showCmacQualityFormSheet({
  required BuildContext context,
  required WidgetRef ref,
  required QualitySafetyEntity entity,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _QualityFormSheet(entity: entity),
    ),
  );
}

class _QualityFormSheet extends ConsumerStatefulWidget {
  const _QualityFormSheet({required this.entity});

  final QualitySafetyEntity entity;

  @override
  ConsumerState<_QualityFormSheet> createState() => _QualityFormSheetState();
}

class _QualityFormSheetState extends ConsumerState<_QualityFormSheet> {
  String? _patientId;
  bool _saving = false;

  final _referring = TextEditingController();
  final _receiving = TextEditingController();
  final _reason = TextEditingController();
  String _direction = 'OUT';

  final _category = TextEditingController();
  final _description = TextEditingController();
  String _severity = 'HIGH';

  final _incidentType = TextEditingController();
  final _incidentDesc = TextEditingController();

  final _infectionType = TextEditingController();
  final _organism = TextEditingController();

  final _departmentId = TextEditingController();

  @override
  void dispose() {
    _referring.dispose();
    _receiving.dispose();
    _reason.dispose();
    _category.dispose();
    _description.dispose();
    _incidentType.dispose();
    _incidentDesc.dispose();
    _infectionType.dispose();
    _organism.dispose();
    _departmentId.dispose();
    super.dispose();
  }

  Map<String, dynamic> _body() {
    final dept = _departmentId.text.trim();
    final base = <String, dynamic>{
      'patientId': _patientId,
      if (dept.isNotEmpty) 'departmentId': dept,
    };
    switch (widget.entity) {
      case QualitySafetyEntity.referrals:
        return {
          ...base,
          'direction': _direction,
          'referringFacility': _referring.text.trim(),
          'receivingFacility': _receiving.text.trim(),
          'reason': _reason.text.trim(),
        };
      case QualitySafetyEntity.complaints:
        return {
          ...base,
          'category': _category.text.trim(),
          'description': _description.text.trim(),
          'severity': _severity,
        };
      case QualitySafetyEntity.incidents:
        return {
          ...base,
          'type': _incidentType.text.trim(),
          'description': _incidentDesc.text.trim(),
          'severity': _severity,
        };
      case QualitySafetyEntity.infections:
        return {
          ...base,
          'infectionType': _infectionType.text.trim(),
          'organism': _organism.text.trim(),
        };
    }
  }

  Future<void> _save() async {
    if (_patientId == null || _patientId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a patient')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final svc = ref.read(cmacQualitySafetyServiceProvider);
      await svc.create(widget.entity, _body());
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'New record',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            CmacPatientPickerField(
              onSelected: (id, _) =>
                  _patientId = id.isEmpty ? null : id,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _departmentId,
              decoration: const InputDecoration(
                labelText: 'Department ID (optional)',
              ),
            ),
            const SizedBox(height: 12),
            ..._entityFields(),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _entityFields() {
    switch (widget.entity) {
      case QualitySafetyEntity.referrals:
        return [
          DropdownButtonFormField<String>(
            value: _direction,
            decoration: const InputDecoration(labelText: 'Direction'),
            items: const [
              DropdownMenuItem(value: 'IN', child: Text('IN')),
              DropdownMenuItem(value: 'OUT', child: Text('OUT')),
            ],
            onChanged: (v) => setState(() => _direction = v ?? 'OUT'),
          ),
          TextField(
            controller: _referring,
            decoration: const InputDecoration(labelText: 'Referring facility'),
          ),
          TextField(
            controller: _receiving,
            decoration: const InputDecoration(labelText: 'Receiving facility'),
          ),
          TextField(
            controller: _reason,
            decoration: const InputDecoration(labelText: 'Reason'),
            maxLines: 2,
          ),
        ];
      case QualitySafetyEntity.complaints:
        return [
          TextField(
            controller: _category,
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
          DropdownButtonFormField<String>(
            value: _severity,
            decoration: const InputDecoration(labelText: 'Severity'),
            items: const [
              DropdownMenuItem(value: 'LOW', child: Text('LOW')),
              DropdownMenuItem(value: 'MEDIUM', child: Text('MEDIUM')),
              DropdownMenuItem(value: 'HIGH', child: Text('HIGH')),
            ],
            onChanged: (v) => setState(() => _severity = v ?? 'HIGH'),
          ),
        ];
      case QualitySafetyEntity.incidents:
        return [
          TextField(
            controller: _incidentType,
            decoration: const InputDecoration(labelText: 'Type'),
          ),
          TextField(
            controller: _incidentDesc,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
          DropdownButtonFormField<String>(
            value: _severity,
            decoration: const InputDecoration(labelText: 'Severity'),
            items: const [
              DropdownMenuItem(value: 'LOW', child: Text('LOW')),
              DropdownMenuItem(value: 'MEDIUM', child: Text('MEDIUM')),
              DropdownMenuItem(value: 'HIGH', child: Text('HIGH')),
            ],
            onChanged: (v) => setState(() => _severity = v ?? 'HIGH'),
          ),
        ];
      case QualitySafetyEntity.infections:
        return [
          TextField(
            controller: _infectionType,
            decoration: const InputDecoration(labelText: 'Infection type'),
          ),
          TextField(
            controller: _organism,
            decoration: const InputDecoration(labelText: 'Organism'),
          ),
        ];
    }
  }
}
