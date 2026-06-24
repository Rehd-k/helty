import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/emergency/models/ed_enums.dart';
import 'package:helty/src/emergency/services/emergency_service.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_providers.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/staff_service.dart';
import 'package:helty/src/widgets/patient_select_action_layout.dart';

String _patientServerId(Patient p) {
  final id = p.id?.trim();
  if (id != null && id.isNotEmpty) return id;
  return p.patientId.trim();
}

@RoutePage()
class EdRegistrationScreen extends ConsumerStatefulWidget {
  const EdRegistrationScreen({super.key});

  @override
  ConsumerState<EdRegistrationScreen> createState() =>
      _EdRegistrationScreenState();
}

class _EdRegistrationScreenState extends ConsumerState<EdRegistrationScreen> {
  final _emergencyService = EmergencyService();
  final _staffService = StaffService();

  final _chiefComplaintCtrl = TextEditingController();
  final _hpiCtrl = TextEditingController();

  List<Staff> _doctors = [];
  List<Staff> _nurses = [];
  bool _loadingDoctors = false;
  bool _submitting = false;
  Staff? _selectedDoctor;
  Staff? _selectedTriageNurse;
  EdArrivalMode _arrivalMode = EdArrivalMode.walkIn;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(patientProvider.notifier).clearPatient());
    _loadDoctors();
  }

  @override
  void dispose() {
    _chiefComplaintCtrl.dispose();
    _hpiCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() => _loadingDoctors = true);
    try {
      final results = await Future.wait([
        _staffService.fetchStaff(
          limit: 100,
          isActive: true,
          accountType: AccountType.physician,
        ),
        _staffService.fetchStaff(
          limit: 100,
          isActive: true,
          accountType: AccountType.nurse,
        ),
      ]);
      if (!mounted) return;
      final doctors = results[0];
      setState(() {
        _doctors = doctors;
        _nurses = results[1];
        _loadingDoctors = false;
        final staff = ref.read(authProvider).staff;
        if (staff != null && staff.accountType == AccountType.physician) {
          _selectedDoctor = doctors.cast<Staff?>().firstWhere(
            (s) => s?.id == staff.id || s?.staffId == staff.staffId,
            orElse: () => staff,
          );
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingDoctors = false);
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

  Future<void> _submitRegistration(Patient patient) async {
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

  Widget _buildRegistrationForm(Patient patient) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
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
          onPressed: _submitting ? null : () => _submitRegistration(patient),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedPatient = ref.watch(patientProvider).selectedPatient;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: PatientSelectActionLayout(
        serviceName: 'ED',
        title: 'ED Registration',
        subtitle: 'Register or find a patient and open an emergency visit.',
        actionPanel: selectedPatient != null
            ? _buildRegistrationForm(selectedPatient)
            : null,
      ),
    );
  }
}
