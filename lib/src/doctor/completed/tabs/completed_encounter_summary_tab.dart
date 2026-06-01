import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/completed/widgets/completed_encounter_scope.dart';
import 'package:intl/intl.dart';

@RoutePage()
class CompletedEncounterSummaryTab extends StatelessWidget {
  const CompletedEncounterSummaryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = CompletedEncounterScope.of(context);
    if (scope == null) {
      return const Center(child: Text('Encounter context not available'));
    }
    final e = scope.encounter;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Section(
            title: 'Visit',
            children: [
              _Row(label: 'Status', value: e.status),
              _Row(label: 'Doctor', value: e.doctorLabel),
              _Row(label: 'Started', value: DateFormat.yMMMd().add_Hm().format(e.startedAt)),
              if (e.closedAt != null)
                _Row(label: 'Closed', value: DateFormat.yMMMd().add_Hm().format(e.closedAt!)),
              if (e.visitAppointment != null)
                _Row(
                  label: 'Booked visit',
                  value: DateFormat.yMMMd()
                      .add_Hm()
                      .format(e.visitAppointment!.appointmentDate.toLocal()),
                ),
              if (e.visitAppointment == null &&
                  e.appointmentId != null &&
                  e.appointmentId!.isNotEmpty)
                _Row(label: 'Appointment id', value: e.appointmentId!),
              if (e.visitType != null) _Row(label: 'Visit type', value: e.visitType!),
              if (e.insurance != null) _Row(label: 'Insurance', value: e.insurance!),
            ],
          ),
          const SizedBox(height: 24),
          _Section(
            title: 'Chief complaint',
            children: [
              Text(
                e.chiefComplaint?.isNotEmpty == true ? e.chiefComplaint! : '—',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          if (e.primaryIcdDescription != null || e.primaryIcdCode != null) ...[
            const SizedBox(height: 24),
            _Section(
              title: 'Primary diagnosis',
              children: [
                if (e.primaryIcdCode != null)
                  _Row(label: 'Code', value: e.primaryIcdCode!),
                if (e.primaryIcdDescription != null)
                  Text(
                    e.primaryIcdDescription!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
          ...children,
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
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
