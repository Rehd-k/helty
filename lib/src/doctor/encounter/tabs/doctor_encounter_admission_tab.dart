import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/models/ward_models.dart';
import 'package:helty/src/services/admission_service.dart';
import 'package:helty/src/services/encounter_service.dart';
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
  final _encounterService = EncounterService();
  final _wardService = WardService();

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

  @override
  void initState() {
    super.initState();
    _loadWards();
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
      setState(() {
        _wards = wards;
        _selectedWard = wards.isNotEmpty ? wards.first : null;
      });
      if (_selectedWard != null) {
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

  Future<void> _loadBedsForWard(String wardId) async {
    setState(() {
      _loadingBeds = true;
      _selectedBed = null;
      _beds = const [];
    });
    try {
      final beds = await _wardService.fetchBedsForWard(wardId);
      if (!mounted) return;
      setState(() {
        // Only show beds that are not occupied
        _beds = beds
            .where((b) => b.status != BedStatus.occupied)
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
        bedPreference: _selectedBed?.bedNumber,
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
      await _encounterService.update(scope.encounterId, {'status': 'admitted'});
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
            Row(
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
                            final ward = _wards.firstWhere(
                              (w) => w.id == value,
                            );
                            setState(() {
                              _selectedWard = ward;
                            });
                            _loadBedsForWard(ward.id);
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
                              _selectedBed = _beds.firstWhere(
                                (b) => b.id == value,
                              );
                            });
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loadingWards || _loadingBeds)
              Row(
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
                    _loadingWards
                        ? 'Loading wards...'
                        : 'Loading available beds...',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              )
            else if (_wards.isEmpty)
              Text(
                'No wards configured. Please create wards first.',
                style: TextStyle(fontSize: 12, color: cs.error),
              )
            else if (_selectedWard != null && _beds.isEmpty)
              Text(
                'No available beds in this ward.',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
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
