import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/models/admission_model.dart';
import 'package:helty/src/models/ward_models.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_service.dart';
import 'package:helty/src/services/admission_service.dart';
import 'package:helty/src/services/ward_service.dart';

@RoutePage()
class DoctorEncounterAdmissionTab extends StatefulWidget {
  const DoctorEncounterAdmissionTab({super.key});

  @override
  State<DoctorEncounterAdmissionTab> createState() =>
      _DoctorEncounterAdmissionTabState();
}

class _DoctorEncounterAdmissionTabState
    extends State<DoctorEncounterAdmissionTab> {
  final _admissionService = AdmissionService();
  final _wardService = WardService();
  final _patientService = PatientService();

  Patient? _patient;
  bool _loadingPatient = true;
  AdmissionModel? _activeAdmission;
  bool _loadingAdmission = false;

  final _reasonCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _losCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  bool _isolationRequired = false;
  bool _submitting = false;

  List<Ward> _wards = const [];
  Ward? _selectedWard;
  List<Bed> _beds = const [];
  Bed? _selectedBed;
  bool _loadingWards = false;
  bool _loadingBeds = false;

  bool get _canSubmit =>
      _reasonCtrl.text.trim().isNotEmpty &&
      _selectedWard != null &&
      _selectedBed != null &&
      !_submitting;

  bool get _canSubmitTransfer {
    if (_submitting || _activeAdmission == null) return false;
    if (_selectedWard == null || _selectedBed == null) return false;
    final currentWardId = _activeAdmission!.wardId ?? _patient?.wardId;
    final currentBedId = _activeAdmission!.bedId ?? _patient?.bedId;
    final wardChanged = _selectedWard!.id != currentWardId;
    final bedChanged = _selectedBed!.id != currentBedId;
    return wardChanged || bedChanged;
  }

  String get _currentWardLabel {
    final fromEntity = _activeAdmission?.wardEntity?['name']?.toString();
    final w = fromEntity ?? _activeAdmission?.ward ?? _patient?.ward;
    return (w != null && w.trim().isNotEmpty) ? w.trim() : '—';
  }

  String get _currentBedLabel {
    final fromBed = _activeAdmission?.bed?['bedNumber']?.toString();
    final b = fromBed ?? _activeAdmission?.bedPreference ?? _patient?.bedNumber;
    return (b != null && b.trim().isNotEmpty) ? b.trim() : '—';
  }

  @override
  void initState() {
    super.initState();
    _loadWards();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPatient());
  }

  static bool _isAdmittedPatientStatus(String? status) {
    final s = status?.trim();
    if (s == null || s.isEmpty) return false;
    final u = s.toUpperCase();
    return u == 'ADMITED' || u == 'ADMITTED';
  }

  static AdmissionModel? _pickActiveAdmission(List<AdmissionModel> list) {
    AdmissionModel? fallback;
    for (final a in list) {
      if (a.dischargeDate != null || a.dischargeDateTime != null) continue;
      final st = a.status.toUpperCase();
      if (st == 'DISCHARGED' || st == 'CANCELLED') continue;
      return a;
    }
    for (final a in list) {
      if (a.dischargeDate != null || a.dischargeDateTime != null) continue;
      fallback ??= a;
    }
    return fallback;
  }

  Future<void> _loadPatient() async {
    final scope = EncounterScope.of(context);
    if (scope == null) {
      if (mounted) setState(() => _loadingPatient = false);
      return;
    }
    setState(() => _loadingPatient = true);
    try {
      final p = await _patientService.getPatientById(scope.patientId);
      if (!mounted) return;
      setState(() {
        _patient = p;
        _loadingPatient = false;
      });
      if (_isAdmittedPatientStatus(p.status)) {
        await _loadActiveAdmission(scope.patientId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _patient = null;
        _loadingPatient = false;
      });
    }
  }

  Future<void> _loadActiveAdmission(String patientId) async {
    setState(() => _loadingAdmission = true);
    try {
      final admissions = await _admissionService.getByPatientId(patientId);
      if (!mounted) return;
      setState(() {
        _activeAdmission = _pickActiveAdmission(admissions);
        _loadingAdmission = false;
      });
      if (_activeAdmission != null) {
        await _syncTransferWardBedFromAdmission();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _activeAdmission = null;
        _loadingAdmission = false;
      });
    }
  }

  Future<void> _syncTransferWardBedFromAdmission() async {
    final wardId = _activeAdmission?.wardId ?? _patient?.wardId;
    if (wardId == null || wardId.isEmpty || _wards.isEmpty) return;

    Ward? ward;
    for (final w in _wards) {
      if (w.id == wardId) {
        ward = w;
        break;
      }
    }
    if (ward == null) return;

    final bedId = _activeAdmission?.bedId ?? _patient?.bedId;
    setState(() => _selectedWard = ward);
    await _loadBedsForWard(ward.id, includeBedId: bedId);
    if (bedId == null || bedId.isEmpty || !mounted) return;
    final bed = _beds.where((b) => b.id == bedId).firstOrNull;
    if (bed != null) {
      setState(() => _selectedBed = bed);
    }
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _diagnosisCtrl.dispose();
    _losCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWards() async {
    setState(() {
      _loadingWards = true;
    });
    try {
      final wards = await _wardService.fetchWards();
      if (!mounted) return;
      final admitted = _isAdmittedPatientStatus(_patient?.status);
      setState(() {
        _wards = wards;
        if (!admitted) {
          _selectedWard = wards.isNotEmpty ? wards.first : null;
        }
      });
      if (admitted) {
        await _syncTransferWardBedFromAdmission();
      } else if (_selectedWard != null) {
        await _loadBedsForWard(_selectedWard!.id);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load wards')));
    } finally {
      if (mounted) {
        setState(() {
          _loadingWards = false;
        });
      }
    }
  }

  Future<void> _loadBedsForWard(String wardId, {String? includeBedId}) async {
    setState(() {
      _loadingBeds = true;
      _selectedBed = null;
      _beds = const [];
    });
    try {
      final beds = await _wardService.fetchBedsForWard(wardId);
      if (!mounted) return;
      setState(() {
        _beds = beds
            .where(
              (b) => b.status != BedStatus.occupied || b.id == includeBedId,
            )
            .toList(growable: false);
        _selectedBed = _beds.isNotEmpty ? _beds.first : null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load beds for ward')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingBeds = false;
        });
      }
    }
  }

  Future<void> _admitPatient() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admission reason, ward and bed must all be selected.'),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await _admissionService.create(
        patientId: scope.patientId,
        encounterId: scope.encounterId,
        reason: _reasonCtrl.text.trim(),
        ward: _selectedWard?.name,
        wardId: _selectedWard?.id,
        bedPreference: _selectedBed?.id,
        provisionalDiagnosis: _diagnosisCtrl.text.trim().isEmpty
            ? null
            : _diagnosisCtrl.text.trim(),
        expectedLOS: _losCtrl.text.trim().isEmpty ? null : _losCtrl.text.trim(),
        isolationRequired: _isolationRequired,
        specialInstructions: _instructionsCtrl.text.trim().isEmpty
            ? null
            : _instructionsCtrl.text.trim(),
        attendingDoctorId: scope.doctorId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admission requested. Encounter closed.')),
      );
      setState(() => _submitting = false);
      _reasonCtrl.clear();
      _diagnosisCtrl.clear();
      _losCtrl.clear();
      _instructionsCtrl.clear();
      _isolationRequired = false;
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _updateAdmissionLocation() async {
    final admission = _activeAdmission;
    if (admission == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No active admission record found. Cannot update ward.',
          ),
        ),
      );
      return;
    }
    if (!_canSubmitTransfer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a different ward or bed to update location.'),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await _admissionService.patch(admission.id, {
        'wardId': _selectedWard!.id,
        'ward': _selectedWard!.name,
        'bedId': _selectedBed!.id,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient location updated.')),
      );
      final scope = EncounterScope.of(context);
      if (scope != null) {
        await _loadPatient();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildWardBedRow(ThemeData theme, ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedWard?.id,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Ward *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _wards
                .map(
                  (w) => DropdownMenuItem<String>(
                    value: w.id,
                    child: Text(w.name),
                  ),
                )
                .toList(),
            onChanged: _loadingWards
                ? null
                : (value) {
                    if (value == null) return;
                    final ward = _wards.firstWhere((w) => w.id == value);
                    setState(() => _selectedWard = ward);
                    final keepBedId = _isAdmittedPatientStatus(_patient?.status)
                        ? (_activeAdmission?.bedId ?? _patient?.bedId)
                        : null;
                    _loadBedsForWard(ward.id, includeBedId: keepBedId);
                  },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedBed?.id,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Bed *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _beds
                .map(
                  (b) => DropdownMenuItem<String>(
                    value: b.id,
                    child: Text(b.bedNumber),
                  ),
                )
                .toList(),
            onChanged: _loadingBeds
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedBed = _beds.firstWhere((b) => b.id == value);
                    });
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildWardBedLoadingHint(ColorScheme cs) {
    if (!_loadingWards && !_loadingBeds) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _loadingWards ? 'Loading wards...' : 'Loading available beds...',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWardBedAvailabilityHint(ColorScheme cs) {
    if (_loadingWards || _loadingBeds) return const SizedBox.shrink();
    if (_wards.isEmpty) {
      return Text(
        'No wards configured. Please create wards first.',
        style: TextStyle(fontSize: 12, color: cs.error),
      );
    }
    if (_selectedWard != null && _beds.isEmpty) {
      return Text(
        'No available beds in this ward.',
        style: TextStyle(
          fontSize: 12,
          color: cs.onSurface.withValues(alpha: 0.7),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTransferForm(ThemeData theme, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update ward location',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Transfer the patient to another ward or bed (e.g. ICU, surgical).',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                Icon(Icons.swap_horiz, color: cs.primary),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.place_outlined, color: cs.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current location',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ward: $_currentWardLabel  ·  Bed: $_currentBedLabel',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_loadingAdmission) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ] else if (_activeAdmission == null) ...[
              const SizedBox(height: 12),
              Text(
                'Patient is admitted but no active admission record was found. Ward update may not save.',
                style: TextStyle(fontSize: 12, color: cs.error),
              ),
            ],
            const SizedBox(height: 16),
            _buildWardBedRow(theme, cs),
            _buildWardBedLoadingHint(cs),
            const SizedBox(height: 4),
            _buildWardBedAvailabilityHint(cs),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _canSubmitTransfer ? _updateAdmissionLocation : null,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Update location'),
              ),
            ),
          ],
        ),
      ),
    );
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

    final cs = theme.colorScheme;

    if (_loadingPatient) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isAdmittedPatientStatus(_patient?.status)) {
      return _buildTransferForm(theme, cs);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admit patient',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose ward and bed, then confirm admission.',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                Icon(Icons.local_hospital_outlined, color: cs.primary),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonCtrl,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Admission reason *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildWardBedRow(theme, cs),
            _buildWardBedLoadingHint(cs),
            const SizedBox(height: 4),
            _buildWardBedAvailabilityHint(cs),
            const SizedBox(height: 12),
            TextField(
              controller: _diagnosisCtrl,
              decoration: InputDecoration(
                labelText: 'Provisional diagnosis',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _losCtrl,
              decoration: InputDecoration(
                labelText: 'Expected length of stay',
                hintText: 'e.g. 3 days',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _isolationRequired,
              contentPadding: EdgeInsets.zero,
              title: const Text('Isolation required?'),
              onChanged: (v) => setState(() => _isolationRequired = v ?? false),
            ),
            TextField(
              controller: _instructionsCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Special instructions',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _canSubmit ? _admitPatient : null,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Admit patient'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
