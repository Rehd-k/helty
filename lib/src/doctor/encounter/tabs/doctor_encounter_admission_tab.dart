import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/services/admission_service.dart';
import 'package:helty/src/services/encounter_service.dart';

@RoutePage()
class DoctorEncounterAdmissionTab extends StatefulWidget {
  const DoctorEncounterAdmissionTab({super.key});

  @override
  State<DoctorEncounterAdmissionTab> createState() =>
      _DoctorEncounterAdmissionTabState();
}

class _DoctorEncounterAdmissionTabState extends State<DoctorEncounterAdmissionTab> {
  final _admissionService = AdmissionService();
  final _encounterService = EncounterService();
  final _reasonCtrl = TextEditingController();
  final _wardCtrl = TextEditingController();
  final _bedCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _losCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  bool _isolationRequired = false;
  bool _submitting = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _wardCtrl.dispose();
    _bedCtrl.dispose();
    _diagnosisCtrl.dispose();
    _losCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _admitPatient() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admission reason is required')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await _admissionService.create(
        patientId: scope.patientId,
        encounterId: scope.encounterId,
        reason: _reasonCtrl.text.trim(),
        ward: _wardCtrl.text.trim().isEmpty ? null : _wardCtrl.text.trim(),
        bedPreference: _bedCtrl.text.trim().isEmpty ? null : _bedCtrl.text.trim(),
        provisionalDiagnosis: _diagnosisCtrl.text.trim().isEmpty ? null : _diagnosisCtrl.text.trim(),
        expectedLOS: _losCtrl.text.trim().isEmpty ? null : _losCtrl.text.trim(),
        isolationRequired: _isolationRequired,
        specialInstructions: _instructionsCtrl.text.trim().isEmpty ? null : _instructionsCtrl.text.trim(),
        attendingDoctorId: scope.doctorId,
      );
      await _encounterService.update(scope.encounterId, {'status': 'admitted'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admission requested. Encounter closed.')),
      );
      setState(() => _submitting = false);
      _reasonCtrl.clear();
      _wardCtrl.clear();
      _bedCtrl.clear();
      _diagnosisCtrl.clear();
      _losCtrl.clear();
      _instructionsCtrl.clear();
      _isolationRequired = false;
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = EncounterScope.of(context);
    if (scope == null) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: Text('Encounter context not available')),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Admit patient',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Admission reason *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _wardCtrl,
            decoration: const InputDecoration(
              labelText: 'Ward',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bedCtrl,
            decoration: const InputDecoration(
              labelText: 'Bed preference',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _diagnosisCtrl,
            decoration: const InputDecoration(
              labelText: 'Provisional diagnosis',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _losCtrl,
            decoration: const InputDecoration(
              labelText: 'Expected length of stay',
              hintText: 'e.g. 3 days',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _isolationRequired,
            title: const Text('Isolation required?'),
            onChanged: (v) => setState(() => _isolationRequired = v ?? false),
          ),
          TextField(
            controller: _instructionsCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Special instructions',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submitting ? null : _admitPatient,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Admit patient'),
          ),
        ],
      ),
    );
  }
}
