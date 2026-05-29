import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/billings/patient_invoice.dart';
import 'package:helty/src/doctor/widgets/start_encounter_dialog.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_service.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/api_service.dart';
import 'package:helty/src/services/encounter_service.dart';

String _patientServerId(Patient p) {
  final id = p.id?.trim();
  if (id != null && id.isNotEmpty) return id;
  return p.patientId.trim();
}

Patient _patientFromCreateResponse(dynamic data) {
  if (data is! Map<String, dynamic>) {
    throw StateError('Invalid patient response');
  }
  final raw = data['patient'] ?? data['data'] ?? data;
  if (raw is Map<String, dynamic>) return Patient.fromJson(raw);
  return Patient.fromJson(data);
}

@RoutePage()
class DoctorEmergencyStartScreen extends ConsumerStatefulWidget {
  const DoctorEmergencyStartScreen({super.key});

  @override
  ConsumerState<DoctorEmergencyStartScreen> createState() =>
      _DoctorEmergencyStartScreenState();
}

class _DoctorEmergencyStartScreenState
    extends ConsumerState<DoctorEmergencyStartScreen> {
  final _patientService = PatientService();
  final _encounterService = EncounterService();
  final _apiService = ApiService();

  final _searchCtrl = TextEditingController();
  final _quickFirstName = TextEditingController();
  final _quickSurname = TextEditingController();
  final _quickAge = TextEditingController();
  final _quickGender = TextEditingController();
  final _quickWardId = TextEditingController();

  Timer? _debounce;
  List<Patient> _hits = [];
  bool _loading = false;
  bool _searchRan = false;
  Patient? _selected;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _quickFirstName.dispose();
    _quickSurname.dispose();
    _quickAge.dispose();
    _quickGender.dispose();
    _quickWardId.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final q = _searchCtrl.text.trim();
    if (q.length < 2) {
      setState(() {
        _hits = [];
        _searchRan = false;
        _selected = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), _runSearch);
  }

  Future<void> _runSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.length < 2) return;
    setState(() {
      _loading = true;
      _selected = null;
    });
    try {
      final list = await _patientService.fetchPatients(
        query: q,
        take: 20,
        skip: 0,
        isAscending: true,
        sortBy: 'surname',
        listStatusFilter: PatientListStatusFilter.none,
      );
      if (!mounted) return;
      setState(() {
        _hits = list;
        _loading = false;
        _searchRan = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _searchRan = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Patient search failed: $e')));
    }
  }

  String _patientLabel(Patient p) => '${p.firstName} ${p.surname}'.trim();

  String _patientSubtitle(Patient p) {
    final parts = <String>[];
    final card = p.cardNo.trim();
    final pid = p.patientId.trim();
    if (card.isNotEmpty) parts.add('Card: $card');
    if (pid.isNotEmpty && pid != card) parts.add('ID: $pid');
    final phone = p.phoneNumber?.trim();
    if (phone != null && phone.isNotEmpty) parts.add(phone);
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  Future<void> _createQuickPatient() async {
    if (_quickWardId.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a ward')),
      );
      return;
    }
    try {
      final resp = await _apiService.dio.post(
        '/patients',
        data: {
          'firstName': _quickFirstName.text.trim(),
          'surname': _quickSurname.text.trim(),
          'age': _quickAge.text.trim(),
          'gender': _quickGender.text.trim(),
          'wardId': _quickWardId.text.trim(),
        },
      );
      if (!mounted) return;
      final patient = _patientFromCreateResponse(resp.data);
      setState(() {
        _selected = patient;
        _hits = [patient];
        _searchRan = true;
        _searchCtrl.text = _patientLabel(patient);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to register patient: $e')));
    }
  }

  void _openQuickRegisterDialog() {
    showNewPatientInvoiceForm(
      context,
      _quickFirstName,
      _quickSurname,
      _quickAge,
      _quickGender,
      _quickWardId,
      _createQuickPatient,
    );
  }

  String? _doctorIdOrShowError() {
    final staff = ref.read(authProvider).staff;
    final doctorId = staff?.id ?? staff?.staffId ?? '';
    if (doctorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to start an encounter.')),
      );
      return null;
    }
    return doctorId;
  }

  Future<void> _startEncounterForPatient(Patient patient) async {
    final doctorId = _doctorIdOrShowError();
    if (doctorId == null) return;

    final patientId = _patientServerId(patient);
    if (patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient has no valid ID.')),
      );
      return;
    }

    final displayName = _patientLabel(patient);
    final result = await showDialog<_EmergencyStartResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StartEncounterDialog(
        patientName: displayName.isEmpty ? 'Unknown' : displayName,
        onOpen: () async {
          try {
            final encounter = await _encounterService.create(
              patientId: patientId,
              doctorId: doctorId,
              visitType: 'Emergency',
              encounterType: 'OUTPATIENT',
            );
            if (!ctx.mounted) return;
            Navigator.of(ctx).pop(
              _EmergencyStartResult(
                encounterId: encounter.id,
                patientId: patientId,
              ),
            );
          } catch (e) {
            if (!ctx.mounted) return;
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text('Failed to start encounter: $e')),
            );
          }
        },
      ),
    );

    if (result != null && mounted) {
      context.router.push(
        DoctorEncounterViewRoute(
          encounterId: result.encounterId,
          patientId: result.patientId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Emergency start',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Search any patient to begin care without payment or queue. '
              'Register a minimal record if they are not in the system.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Name, card number, or phone (min. 2 characters)…',
                prefixIcon: const Icon(Icons.search_rounded, size: 22),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (_selected != null) ...[
              const SizedBox(height: 12),
              _SelectedPatientChip(
                label: _patientLabel(_selected!),
                onClear: () => setState(() => _selected = null),
                onStart: () => _startEncounterForPatient(_selected!),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: _buildResultsArea(theme, colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsArea(ThemeData theme, ColorScheme colorScheme) {
    final q = _searchCtrl.text.trim();

    if (q.length < 2) {
      return Center(
        child: Text(
          'Type at least 2 characters to search patients.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      );
    }

    if (_searchRan && !_loading && _hits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              'No patients matching "$q".',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openQuickRegisterDialog,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Register emergency patient'),
            ),
          ],
        ),
      );
    }

    if (_hits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        itemCount: _hits.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        itemBuilder: (context, i) {
          final p = _hits[i];
          final selected = _selected != null && _patientServerId(_selected!) == _patientServerId(p);
          return ListTile(
            selected: selected,
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                p.firstName.isNotEmpty
                    ? p.firstName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(
              _patientLabel(p),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(_patientSubtitle(p)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              setState(() => _selected = p);
              _startEncounterForPatient(p);
            },
          );
        },
      ),
    );
  }
}

class _EmergencyStartResult {
  const _EmergencyStartResult({
    required this.encounterId,
    required this.patientId,
  });

  final String encounterId;
  final String patientId;
}

class _SelectedPatientChip extends StatelessWidget {
  const _SelectedPatientChip({
    required this.label,
    required this.onClear,
    required this.onStart,
  });

  final String label;
  final VoidCallback onClear;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            TextButton(onPressed: onClear, child: const Text('Clear')),
            FilledButton(
              onPressed: onStart,
              child: const Text('Start encounter'),
            ),
          ],
        ),
      ),
    );
  }
}
