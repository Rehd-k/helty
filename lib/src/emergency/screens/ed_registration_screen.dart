import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/billings/patient_invoice.dart';
import 'package:helty/src/emergency/models/ed_enums.dart';
import 'package:helty/src/emergency/services/emergency_service.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_service.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/api_service.dart';
import 'package:helty/src/services/staff_service.dart';

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
class EdRegistrationScreen extends ConsumerStatefulWidget {
  const EdRegistrationScreen({super.key});

  @override
  ConsumerState<EdRegistrationScreen> createState() =>
      _EdRegistrationScreenState();
}

class _EdRegistrationScreenState extends ConsumerState<EdRegistrationScreen> {
  final _patientService = PatientService();
  final _emergencyService = EmergencyService();
  final _staffService = StaffService();
  final _apiService = ApiService();

  final _searchCtrl = TextEditingController();
  final _chiefComplaintCtrl = TextEditingController();
  final _hpiCtrl = TextEditingController();

  Timer? _debounce;
  List<Patient> _hits = [];
  List<Staff> _doctors = [];
  List<Staff> _nurses = [];
  bool _loading = false;
  bool _searchRan = false;
  bool _loadingDoctors = false;
  bool _submitting = false;
  Patient? _selected;
  Staff? _selectedDoctor;
  Staff? _selectedTriageNurse;
  EdArrivalMode _arrivalMode = EdArrivalMode.walkIn;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadDoctors();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _chiefComplaintCtrl.dispose();
    _hpiCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() => _loadingDoctors = true);
    try {
      final list = await _staffService.fetchStaff(limit: 100);
      if (!mounted) return;
      setState(() {
        _doctors = list
            .where(
              (s) =>
                  s.accountType == AccountType.physician && s.isActive != false,
            )
            .toList();
        _nurses = list
            .where(
              (s) => s.accountType == AccountType.nurse && s.isActive != false,
            )
            .toList();
        _loadingDoctors = false;
        final staff = ref.read(authProvider).staff;
        if (staff != null && staff.accountType == AccountType.physician) {
          _selectedDoctor = list.cast<Staff?>().firstWhere(
            (s) => s?.id == staff.id || s?.staffId == staff.staffId,
            orElse: () => staff,
          );
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingDoctors = false);
    }
  }

  void _onSearchChanged() {
    if (!mounted) return;
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
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _runSearch();
    });
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

  Future<void> _createQuickPatient({
    required TextEditingController firstName,
    required TextEditingController surname,
    required TextEditingController age,
    required TextEditingController gender,
    required TextEditingController wardId,
  }) async {
    if (wardId.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a ward')));
      return;
    }
    try {
      final resp = await _apiService.dio.post(
        '/patients',
        data: {
          'firstName': firstName.text.trim(),
          'surname': surname.text.trim(),
          'age': age.text.trim(),
          'gender': gender.text.trim(),
          'wardId': wardId.text.trim(),
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

  Future<void> _openQuickRegisterDialog() async {
    final firstName = TextEditingController();
    final surname = TextEditingController();
    final age = TextEditingController();
    final gender = TextEditingController();
    final wardId = TextEditingController();
    try {
      await showNewPatientInvoiceForm(
        context,
        firstName,
        surname,
        age,
        gender,
        wardId,
        () => _createQuickPatient(
          firstName: firstName,
          surname: surname,
          age: age,
          gender: gender,
          wardId: wardId,
        ),
      );
    } finally {
      firstName.dispose();
      surname.dispose();
      age.dispose();
      gender.dispose();
      wardId.dispose();
    }
  }

  String? _doctorId() {
    final d = _selectedDoctor;
    if (d == null) return null;
    final id = d.id.trim();
    if (id.isNotEmpty) return id;
    return d.staffId.trim().isNotEmpty ? d.staffId.trim() : null;
  }

  String? _triageNurseId() {
    final n = _selectedTriageNurse;
    if (n == null) return null;
    final id = n.id.trim();
    if (id.isNotEmpty) return id;
    return n.staffId.trim().isNotEmpty ? n.staffId.trim() : null;
  }

  Future<void> _submitRegistration() async {
    final patient = _selected;
    if (patient == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a patient first.')));
      return;
    }
    if (_chiefComplaintCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chief complaint is required.')),
      );
      return;
    }
    final doctorId = _doctorId();
    if (doctorId == null || doctorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an assigned doctor.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await _emergencyService.registerVisit(
        patientId: _patientServerId(patient),
        doctorId: doctorId,
        chiefComplaint: _chiefComplaintCtrl.text.trim(),
        arrivalMode: _arrivalMode,
        hpi: _hpiCtrl.text.trim().isEmpty ? null : _hpiCtrl.text.trim(),
        triageNurseId: _triageNurseId(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.reusedExistingEncounter
                ? 'Patient already on the ED board — opened existing visit.'
                : 'ED visit registered.',
          ),
        ),
      );
      context.router.replace(const EdBoardRoute());
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg.contains('409')
                ? 'Patient already has an active ED visit.'
                : 'Registration failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ED Registration',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Register or find a patient and open an emergency visit.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search patient (min. 2 characters)…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(
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
            const SizedBox(height: 16),
            Expanded(flex: 2, child: _buildResultsArea(theme, scheme)),
            const SizedBox(height: 16),
            if (_selected != null) ...[
              Text(
                'Registration details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _chiefComplaintCtrl,
                decoration: const InputDecoration(
                  labelText: 'Chief complaint *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _hpiCtrl,
                decoration: const InputDecoration(
                  labelText: 'Initial HPI (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EdArrivalMode>(
                initialValue: _arrivalMode,
                decoration: const InputDecoration(
                  labelText: 'Arrival mode',
                  border: OutlineInputBorder(),
                ),
                items: EdArrivalMode.values
                    .map(
                      (m) => DropdownMenuItem(value: m, child: Text(m.label)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _arrivalMode = v);
                },
              ),
              const SizedBox(height: 12),
              if (_loadingDoctors)
                const LinearProgressIndicator(minHeight: 2)
              else
                DropdownButtonFormField<Staff>(
                  initialValue: _selectedDoctor,
                  decoration: const InputDecoration(
                    labelText: 'Assigned doctor *',
                    border: OutlineInputBorder(),
                  ),
                  items: _doctors
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text('${s.firstName} ${s.lastName}'.trim()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedDoctor = v),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Staff?>(
                initialValue: _selectedTriageNurse,
                decoration: const InputDecoration(
                  labelText: 'Triage nurse (optional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<Staff?>(
                    value: null,
                    child: Text('— None —'),
                  ),
                  ..._nurses.map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text('${s.firstName} ${s.lastName}'.trim()),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedTriageNurse = v),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submitting ? null : _submitRegistration,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.emergency_rounded),
                label: Text(_submitting ? 'Registering…' : 'Start ED visit'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsArea(ThemeData theme, ColorScheme scheme) {
    final q = _searchCtrl.text.trim();

    if (q.length < 2) {
      return Center(
        child: Text(
          'Type at least 2 characters to search patients.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      );
    }

    if (_searchRan && !_loading && _hits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No patients matching "$q".'),
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

    if (_hits.isEmpty) return const SizedBox.shrink();

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        itemCount: _hits.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
        itemBuilder: (context, i) {
          final p = _hits[i];
          final selected =
              _selected != null &&
              _patientServerId(_selected!) == _patientServerId(p);
          return ListTile(
            selected: selected,
            title: Text(
              _patientLabel(p),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              p.cardNo.isNotEmpty ? 'Card: ${p.cardNo}' : p.patientId,
            ),
            trailing: selected
                ? Icon(Icons.check_circle, color: scheme.primary)
                : null,
            onTap: () => setState(() => _selected = p),
          );
        },
      ),
    );
  }
}
