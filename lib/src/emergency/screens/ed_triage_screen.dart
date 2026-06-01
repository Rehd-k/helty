import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/emergency/models/ed_enums.dart';
import 'package:helty/src/emergency/services/emergency_service.dart';
import 'package:helty/src/models/patient_vitals_model.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_service.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/clinical_specialty_service.dart';
import 'package:helty/src/services/encounter_service.dart';
import 'package:helty/src/services/waiting_patient_service.dart';

@RoutePage()
class EdTriageScreen extends ConsumerStatefulWidget {
  const EdTriageScreen({
    super.key,
    required this.encounterId,
    required this.patientId,
    this.emergencyVisitId,
  });

  final String encounterId;
  final String patientId;
  final String? emergencyVisitId;

  @override
  ConsumerState<EdTriageScreen> createState() => _EdTriageScreenState();
}

class _EdTriageScreenState extends ConsumerState<EdTriageScreen> {
  final _emergencyService = EmergencyService();
  final _encounterService = EncounterService();
  final _clinicalService = ClinicalSpecialtyService();
  final _vitalsService = WaitingPatientService();
  final _patientService = PatientService();

  final _formKey = GlobalKey<FormState>();
  final _abcsCtrl = TextEditingController();
  final _interventionsCtrl = TextEditingController();
  final _vitalsNotesCtrl = TextEditingController();
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();
  final _painCtrl = TextEditingController();

  Patient? _patient;
  bool _loading = true;
  bool _submitting = false;
  int? _esiLevel;

  static const _emSpecialty = 'EMERGENCY_MEDICINE';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _abcsCtrl.dispose();
    _interventionsCtrl.dispose();
    _vitalsNotesCtrl.dispose();
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _pulseCtrl.dispose();
    _tempCtrl.dispose();
    _spo2Ctrl.dispose();
    _painCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await _emergencyService.enableEmergencyModules(widget.encounterId);
      final enc = await _encounterService.getById(
        widget.encounterId,
        expand: ['clinicalSections'],
      );
      final p = await _patientService.getPatientById(widget.patientId);
      if (!mounted) return;

      if (enc != null) {
        for (final s in enc.clinicalSections ?? const []) {
          if (s.sectionKey != 'em.triage') continue;
          final data = s.data;
          _abcsCtrl.text = data['abcs']?.toString() ?? '';
          _interventionsCtrl.text = data['interventions']?.toString() ?? '';
          final rawEsi = data['esiLevel'];
          if (rawEsi is int) {
            _esiLevel = rawEsi;
          } else if (rawEsi != null) {
            _esiLevel = int.tryParse(rawEsi.toString());
          }
        }
      }

      final vitalsList =
          await _vitalsService.fetchVitalsByEncounter(widget.encounterId);
      if (vitalsList.isNotEmpty) {
        vitalsList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final v = vitalsList.first;
        if (_systolicCtrl.text.isEmpty && v.systolic != null) {
          _systolicCtrl.text = v.systolic.toString();
        }
        if (_diastolicCtrl.text.isEmpty && v.diastolic != null) {
          _diastolicCtrl.text = v.diastolic.toString();
        }
        if (_pulseCtrl.text.isEmpty && v.pulseRate != null) {
          _pulseCtrl.text = v.pulseRate.toString();
        }
        if (_tempCtrl.text.isEmpty && v.temperature != null) {
          _tempCtrl.text = v.temperature.toString();
        }
        if (_spo2Ctrl.text.isEmpty && v.spo2 != null) {
          _spo2Ctrl.text = v.spo2.toString();
        }
        if (_painCtrl.text.isEmpty && v.painScore != null) {
          _painCtrl.text = v.painScore!;
        }
        if (_vitalsNotesCtrl.text.isEmpty && v.notes != null) {
          _vitalsNotesCtrl.text = v.notes!;
        }
      }

      setState(() {
        _patient = p;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load triage: $e')));
    }
  }

  int? _parseInt(TextEditingController c) {
    final v = c.text.trim();
    if (v.isEmpty) return null;
    return int.tryParse(v);
  }

  double? _parseDouble(TextEditingController c) {
    final v = c.text.trim();
    if (v.isEmpty) return null;
    return double.tryParse(v);
  }

  Future<void> _completeTriage() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_esiLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ESI level (1–5) is required.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final nurseId =
          ref.read(authProvider).staff?.id ??
          ref.read(authProvider).staff?.staffId;

      final vitalsDto = CreatePatientVitalsDto(
        encounterId: widget.encounterId,
        patientId: widget.patientId,
        systolic: _parseInt(_systolicCtrl),
        diastolic: _parseInt(_diastolicCtrl),
        pulseRate: _parseInt(_pulseCtrl),
        temperature: _parseDouble(_tempCtrl),
        spo2: _parseDouble(_spo2Ctrl),
        painScore: _painCtrl.text.trim().isEmpty ? null : _painCtrl.text.trim(),
        notes: _vitalsNotesCtrl.text.trim().isEmpty
            ? 'Triage vitals'
            : _vitalsNotesCtrl.text.trim(),
        recordedByNurseId: nurseId,
      );
      await _vitalsService.createPatientVitals(vitalsDto);

      await _clinicalService
          .upsertSection(widget.encounterId, _emSpecialty, 'em.triage', {
            'esiLevel': _esiLevel,
            'abcs': _abcsCtrl.text.trim(),
            'interventions': _interventionsCtrl.text.trim(),
          });

      final visitId = widget.emergencyVisitId ?? widget.encounterId;
      await _emergencyService.updateVisit(
        visitId,
        workflowStatus: EdWorkflowStatus.waitingDoctor,
        esiLevel: _esiLevel,
        triageCompletedAt: DateTime.now(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Triage completed. Patient waiting for doctor.'),
        ),
      );
      context.router.replace(const EdBoardRoute());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to complete triage: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final patientName = _patient != null
        ? '${_patient!.firstName} ${_patient!.surname}'.trim()
        : 'Patient';

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: Text('Triage — $patientName')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Vitals',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _systolicCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Systolic BP',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _diastolicCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Diastolic BP',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _pulseCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Pulse',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _tempCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Temp (°C)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _spo2Ctrl,
                          decoration: const InputDecoration(
                            labelText: 'SpO2 (%)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final n = double.tryParse(v.trim());
                            if (n == null || n < 0 || n > 100) {
                              return '0–100';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _painCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Pain (0–10)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final n = int.tryParse(v.trim());
                            if (n == null || n < 0 || n > 10) {
                              return '0–10';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vitalsNotesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Vitals notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Triage assessment',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _esiLevel,
                    decoration: const InputDecoration(
                      labelText: 'ESI level (1–5) *',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      5,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('ESI ${i + 1}'),
                      ),
                    ),
                    onChanged: (v) => setState(() => _esiLevel = v),
                    validator: (_) =>
                        _esiLevel == null ? 'ESI is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _abcsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ABCs / primary survey',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _interventionsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Interventions',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _completeTriage,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_submitting ? 'Saving…' : 'Complete triage'),
                  ),
                ],
              ),
            ),
    );
  }
}
