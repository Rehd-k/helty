import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/doctor/encounter/encounter_tab_reload.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/appointment_service.dart';
import 'package:helty/src/services/encounter_service.dart';

@RoutePage()
class DoctorEncounterFollowUpTab extends ConsumerStatefulWidget {
  const DoctorEncounterFollowUpTab({super.key});

  @override
  ConsumerState<DoctorEncounterFollowUpTab> createState() =>
      _DoctorEncounterFollowUpTabState();
}

class _DoctorEncounterFollowUpTabState
    extends ConsumerState<DoctorEncounterFollowUpTab> {
  final _encounterService = EncounterService();
  final _appointmentService = AppointmentService();
  DateTime? _followUpDate;
  String? _followUpAppointmentId;
  final _instructionsCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  bool _loading = false;
  bool _loaded = false;
  bool _loadScheduled = false;
  int _lastReloadGeneration = 0;

  @override
  void dispose() {
    _instructionsCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reloadEncounterTabIfTemplateApplied(
      context: context,
      lastReloadGeneration: _lastReloadGeneration,
      updateLastReloadGeneration: (v) => _lastReloadGeneration = v,
      loaded: _loaded,
      reload: _load,
    );
    if (!_loadScheduled) {
      _loadScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  Future<void> _load() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    try {
      final enc = await _encounterService.getById(scope.encounterId);
      if (!mounted) return;
      if (enc != null) {
        _followUpAppointmentId = enc.followUpAppointmentId;
        var appt = enc.followUpAppointment;
        if (appt == null &&
            enc.followUpAppointmentId != null &&
            enc.followUpAppointmentId!.isNotEmpty) {
          try {
            appt = await _appointmentService.getAppointmentById(
              enc.followUpAppointmentId!,
            );
          } catch (_) {}
        }
        if (appt != null) {
          _followUpAppointmentId = appt.id;
          _followUpDate = appt.appointmentDate.toLocal();
          _instructionsCtrl.text = appt.notes ?? '';
          _referralCtrl.text = appt.referral ?? '';
        } else {
          if (enc.followUpDate != null) {
            _followUpDate = DateTime.tryParse(enc.followUpDate!);
          }
          _instructionsCtrl.text = enc.followUpInstructions ?? '';
          _referralCtrl.text = enc.referral ?? '';
        }
      }
      setState(() => _loaded = true);
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _save() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    final staff = ref.read(currentStaffProvider);
    final staffId = scope.doctorId ?? staff?.id;
    final actorId = staff?.id;

    setState(() => _loading = true);
    try {
      final enc = await _encounterService.saveFollowUp(
        status: 'SCHEDULED',
        encounterId: scope.encounterId,
        patientId: scope.patientId,
        followUpDate: _followUpDate,
        notes: _instructionsCtrl.text.trim().isEmpty
            ? null
            : _instructionsCtrl.text.trim(),
        referral: _referralCtrl.text.trim().isEmpty
            ? null
            : _referralCtrl.text.trim(),
        staffId: staffId,
        createdById: actorId,
        followUpAppointmentId: _followUpAppointmentId,
        updatedById: actorId,
      );
      if (!mounted) return;
      _followUpAppointmentId = enc.followUpAppointmentId;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Follow-up saved')));
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      setState(() => _loading = false);
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

    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Follow-up date',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: Text(
              _followUpDate == null
                  ? 'Select date'
                  : '${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate:
                    _followUpDate ??
                    DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null && mounted) setState(() => _followUpDate = date);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _instructionsCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Follow-up instructions',
              border: OutlineInputBorder(),
              hintText: 'e.g. Review LFT, continue medications',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _referralCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Referral (if needed)',
              border: OutlineInputBorder(),
              hintText: 'e.g. Refer to Cardiology',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loading ? null : _save,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save follow-up'),
          ),
        ],
      ),
    );
  }
}
