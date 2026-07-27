import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/doctor/completed/widgets/completed_encounter_scope.dart';
import 'package:helty/src/models/appointment_model.dart';
import 'package:helty/src/services/appointment_service.dart';
import 'package:intl/intl.dart';

@RoutePage()
class CompletedEncounterAppointmentsTab extends StatefulWidget {
  const CompletedEncounterAppointmentsTab({super.key});

  @override
  State<CompletedEncounterAppointmentsTab> createState() =>
      _CompletedEncounterAppointmentsTabState();
}

class _CompletedEncounterAppointmentsTabState
    extends State<CompletedEncounterAppointmentsTab> {
  final _appointmentService = AppointmentService();

  Appointment? _visitAppointment;
  bool _loadingVisit = false;
  String? _visitError;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resolveVisitAppointment();
      });
    }
  }

  Future<void> _resolveVisitAppointment() async {
    final scope = CompletedEncounterScope.of(context);
    if (scope == null) return;
    final e = scope.encounter;
    if (e.visitAppointment != null) {
      setState(() => _visitAppointment = e.visitAppointment);
      return;
    }
    final id = e.appointmentId;
    if (id == null || id.isEmpty) return;

    setState(() {
      _loadingVisit = true;
      _visitError = null;
    });
    try {
      final ap = await _appointmentService.getAppointmentById(id);
      if (!mounted) return;
      setState(() {
        _visitAppointment = ap;
        _loadingVisit = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _loadingVisit = false;
        _visitError = err.toString();
      });
    }
  }

  static String _fmtDate(DateTime d) =>
      DateFormat.yMMMd().add_Hm().format(d.toLocal());

  @override
  Widget build(BuildContext context) {
    final scope = CompletedEncounterScope.of(context);
    if (scope == null) {
      return const Center(child: Text('Encounter context not available'));
    }
    final e = scope.encounter;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final followUp = e.followUpAppointment;
    final visitId = e.appointmentId;
    final hasVisitId = visitId != null && visitId.isNotEmpty;

    if (_loadingVisit && hasVisitId && _visitAppointment == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasVisitSection =
        e.visitAppointment != null || hasVisitId || _visitError != null;
    final hasFollowUp = followUp != null;

    if (!hasVisitSection && !hasFollowUp) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No appointments linked to this encounter.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ResponsiveBody(
      center: false,
      expand: false,
      builder: (context, bp) => SingleChildScrollView(
        padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasVisitSection) ...[
            if (_visitError != null && hasVisitId)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Could not load visit appointment: $_visitError',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
            if (_visitAppointment != null)
              _AppointmentCard(
                title: 'Visit appointment',
                appointment: _visitAppointment!,
                theme: theme,
                colorScheme: colorScheme,
                fmt: _fmtDate,
              )
            else if (hasVisitId)
              _AppointmentCard(
                title: 'Visit appointment',
                fallbackDetail: 'Appointment id: $visitId',
                theme: theme,
                colorScheme: colorScheme,
                fmt: _fmtDate,
              ),
            if (hasFollowUp) const SizedBox(height: 20),
          ],
          if (followUp != null)
            _AppointmentCard(
              title: 'Follow-up appointment',
              appointment: followUp,
              theme: theme,
              colorScheme: colorScheme,
              fmt: _fmtDate,
            ),
        ],
      ),
    ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.title,
    this.appointment,
    this.fallbackDetail,
    required this.theme,
    required this.colorScheme,
    required this.fmt,
  });

  final String title;
  final Appointment? appointment;
  final String? fallbackDetail;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final String Function(DateTime) fmt;

  @override
  Widget build(BuildContext context) {
    final ap = appointment;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          if (ap != null) ...[
            _Row(label: 'When', value: fmt(ap.appointmentDate)),
            _Row(label: 'Status', value: ap.status),
            if (ap.doctorDisplayName.trim().isNotEmpty &&
                ap.doctorDisplayName != '—')
              _Row(label: 'Clinician', value: ap.doctorDisplayName),
            if (ap.notes != null && ap.notes!.trim().isNotEmpty)
              _Row(label: 'Notes', value: ap.notes!),
            if (ap.referral != null && ap.referral!.trim().isNotEmpty)
              _Row(label: 'Referral', value: ap.referral!),
          ] else if (fallbackDetail != null)
            Text(
              fallbackDetail!,
              style: theme.textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
