import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../helper/app_timezone.dart';
import '../../helper/date.formatter.dart';
import '../../models/appointment_model.dart';
import '../../models/staff_model.dart';
import '../../providers/appointment_providers.dart';
import '../../services/appointment_service.dart';
import '../../services/staff_service.dart';
import '../../shared/department_colors.dart';
import '../../core/responsive.dart';

@RoutePage()
class AppointmentRequestsScreen extends ConsumerStatefulWidget {
  const AppointmentRequestsScreen({super.key});

  @override
  ConsumerState<AppointmentRequestsScreen> createState() =>
      _AppointmentRequestsScreenState();
}

class _AppointmentRequestsScreenState
    extends ConsumerState<AppointmentRequestsScreen> {
  final _appointmentService = AppointmentService();
  final _staffService = StaffService();
  final _searchController = TextEditingController();

  String? _busyId;
  List<Staff>? _physicians;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Staff>> _loadPhysicians() async {
    if (_physicians != null) return _physicians!;
    final list = await _staffService.fetchStaff(
      page: 1,
      limit: 250,
      isActive: true,
    );
    final physicians = list
        .where((s) => s.accountType == AccountType.physician)
        .toList(growable: false);
    _physicians = physicians.isNotEmpty
        ? physicians
        : list; // fallback if accountType missing on older payloads
    return _physicians!;
  }

  List<Appointment> _filter(List<Appointment> items) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where((a) {
          return a.patientDisplayName.toLowerCase().contains(q) ||
              a.patientId.toLowerCase().contains(q) ||
              (a.notes ?? '').toLowerCase().contains(q) ||
              (a.referral ?? '').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  Future<void> _confirm(Appointment appointment) async {
    if (_busyId != null) return;

    List<Staff> doctors;
    try {
      doctors = await _loadPhysicians();
    } catch (e) {
      _snack('Could not load doctors: $e');
      return;
    }
    if (!mounted) return;
    if (doctors.isEmpty) {
      _snack('No active physicians available to assign.');
      return;
    }

    Staff? selected = doctors.firstWhere(
      (d) => d.id == appointment.staffId,
      orElse: () => doctors.first,
    );
    DateTime? selectedDate = appointment.appointmentDate.toLocal();
    var includeDateOverride = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final dateLabel = selectedDate == null
                ? 'Keep requested date'
                : DateFormatter.dateTime(selectedDate!);
            return AlertDialog(
              title: const Text('Confirm appointment'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      appointment.patientDisplayName,
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Requested: ${DateFormatter.dateTime(appointment.appointmentDate)}',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Staff>(
                      // ignore: deprecated_member_use
                      value: selected,
                      decoration: const InputDecoration(
                        labelText: 'Assign doctor',
                        border: OutlineInputBorder(),
                      ),
                      items: doctors
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text(
                                'Dr. ${d.firstName} ${d.lastName}'.trim(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setLocal(() => selected = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Override date & time'),
                      value: includeDateOverride,
                      onChanged: (v) =>
                          setLocal(() => includeDateOverride = v),
                    ),
                    if (includeDateOverride)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(dateLabel),
                        trailing: const Icon(Icons.event_available_outlined),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate ?? AppTimezone.now(),
                            firstDate: DateTime(2020),
                            lastDate: AppTimezone.now().add(
                              const Duration(days: 365 * 2),
                            ),
                          );
                          if (date == null || !ctx.mounted) return;
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: selectedDate != null
                                ? TimeOfDay.fromDateTime(selectedDate!)
                                : const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (time == null) return;
                          setLocal(() {
                            selectedDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: selected == null
                      ? null
                      : () => Navigator.pop(ctx, true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true || selected == null || !mounted) return;

    setState(() => _busyId = appointment.id);
    try {
      await _appointmentService.confirmRequest(
        appointment.id,
        staffId: selected!.id,
        date: includeDateOverride ? selectedDate : null,
      );
      if (!mounted) return;
      _snack('Appointment confirmed for ${appointment.patientDisplayName}');
      ref.invalidate(appointmentRequestsProvider);
    } catch (e) {
      if (!mounted) return;
      _snack('Confirm failed: $e');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _deny(Appointment appointment) async {
    if (_busyId != null) return;
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deny appointment request'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Deny the request for ${appointment.patientDisplayName}?',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deny'),
          ),
        ],
      ),
    );
    final notes = notesCtrl.text;
    notesCtrl.dispose();
    if (confirmed != true || !mounted) return;

    setState(() => _busyId = appointment.id);
    try {
      await _appointmentService.denyRequest(
        appointment.id,
        notes: notes.trim().isEmpty ? null : notes.trim(),
      );
      if (!mounted) return;
      _snack('Appointment request denied');
      ref.invalidate(appointmentRequestsProvider);
    } catch (e) {
      if (!mounted) return;
      _snack('Deny failed: $e');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(appointmentRequestsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final compact = bp.isMobile;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTitle(colorScheme, async, compact),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search patient, notes…',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Failed to load requests: $e'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () =>
                              ref.invalidate(appointmentRequestsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (items) {
                    final filtered = _filter(items);
                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          items.isEmpty
                              ? 'No pending appointment requests.'
                              : 'No requests match your search.',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(appointmentRequestsProvider);
                        await ref.read(appointmentRequestsProvider.future);
                      },
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final a = filtered[index];
                          return _RequestCard(
                            appointment: a,
                            busy: _busyId == a.id,
                            compact: compact,
                            onConfirm: () => _confirm(a),
                            onDeny: () => _deny(a),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTitle(
    ColorScheme colorScheme,
    AsyncValue<List<Appointment>> async,
    bool compact,
  ) {
    final count = async.asData?.value.length;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Appointment Requests',
                style: TextStyle(
                  fontSize: compact ? 22 : 24,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count == null
                    ? 'Confirm or deny patient portal requests'
                    : '$count pending · Medical Records queue',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => ref.invalidate(appointmentRequestsProvider),
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.appointment,
    required this.busy,
    required this.compact,
    required this.onConfirm,
    required this.onDeny,
  });

  final Appointment appointment;
  final bool busy;
  final bool compact;
  final VoidCallback onConfirm;
  final VoidCallback onDeny;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateStr = DateFormat(
      'EEE, dd MMM yyyy · hh:mm a',
    ).format(appointment.appointmentDate.toLocal());

    final actions = [
      OutlinedButton(
        onPressed: busy ? null : onDeny,
        child: const Text('Deny'),
      ),
      const SizedBox(width: 8),
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: DepartmentColors.medicalRecords,
        ),
        onPressed: busy ? null : onConfirm,
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Confirm'),
      ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientDisplayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (appointment.notes != null &&
                          appointment.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          appointment.notes!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (!compact) ...actions,
              ],
            ),
            if (compact) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
