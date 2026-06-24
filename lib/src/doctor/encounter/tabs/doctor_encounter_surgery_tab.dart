import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/auth/theatre_permissions.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/service_service.dart';
import 'package:helty/src/theatre/models/theatre_models.dart';
import 'package:helty/src/theatre/providers/theatre_providers.dart';
import 'package:helty/src/theatre/widgets/surgery_request_dialog.dart';
import 'package:helty/src/theatre/widgets/theatre_status_chip.dart';

@RoutePage()
class DoctorEncounterSurgeryTab extends ConsumerStatefulWidget {
  const DoctorEncounterSurgeryTab({super.key});

  @override
  ConsumerState<DoctorEncounterSurgeryTab> createState() =>
      _DoctorEncounterSurgeryTabState();
}

class _DoctorEncounterSurgeryTabState
    extends ConsumerState<DoctorEncounterSurgeryTab> {
  final _serviceService = ServiceService();
  List<SurgeryRequest> _requests = [];
  bool _loading = true;
  bool _loadScheduled = false;
  bool _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    setState(() => _loading = true);
    try {
      final list = await ref
          .read(theatreApiServiceProvider)
          .getSurgeryRequestsForEncounter(scope.encounterId);
      if (!mounted) return;
      setState(() {
        _requests = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _requests = [];
        _loading = false;
      });
    }
  }

  Future<void> _openRequestDialog() async {
    final scope = EncounterScope.of(context);
    final staff = ref.read(authProvider).staff;
    if (scope == null || staff?.id == null) return;
    if (!canBookSurgeryRequests(staff)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot book surgery requests.')),
      );
      return;
    }

    final result = await showSurgeryRequestDialog(
      context: context,
      serviceService: _serviceService,
    );
    if (result == null || !mounted) return;

    final serviceId = result.service.serviceId.isNotEmpty
        ? result.service.serviceId
        : result.service.id;

    setState(() => _submitting = true);
    try {
      await ref.read(theatreApiServiceProvider).createSurgeryRequest(
        encounterId: scope.encounterId,
        patientId: scope.patientId,
        requestedById: staff!.id,
        serviceId: serviceId,
        admissionId: scope.activeAdmissionId,
        priority: result.priority,
        clinicalNotes: result.clinicalNotes,
        preferredDate: result.preferredDate,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Surgery request submitted')),
      );
      await _load();
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _cancelRequest(SurgeryRequest request) async {
    if (request.status != SurgeryRequestStatus.requested &&
        request.status != SurgeryRequestStatus.scheduled) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel surgery request'),
        content: Text(
          'Cancel ${request.service?.name ?? 'this surgery request'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(theatreApiServiceProvider).patchSurgeryRequest(
        request.id,
        status: SurgeryRequestStatus.cancelled,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Surgery request cancelled')),
      );
      await _load();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  bool _canCancel(SurgeryRequest request) {
    final staff = ref.read(authProvider).staff;
    if (!canBookSurgeryRequests(staff)) return false;
    return request.status == SurgeryRequestStatus.requested ||
        request.status == SurgeryRequestStatus.scheduled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final staff = ref.watch(authProvider).staff;
    final canBook = canBookSurgeryRequests(staff);
    final scope = EncounterScope.of(context);
    final canEdit = scope?.canEdit ?? false;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Surgery requests',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (canBook && canEdit)
              FilledButton.icon(
                onPressed: _submitting ? null : _openRequestDialog,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_rounded),
                label: const Text('Request surgery'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_requests.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No surgery requests for this encounter.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: _requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final request = _requests[index];
                return Card(
                  child: ListTile(
                    title: Text(request.service?.name ?? 'Surgery'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (request.priority != null)
                          Text('Priority: ${request.priority!.displayLabel}'),
                        if (request.preferredDate != null)
                          Text(
                            'Preferred: ${DateFormatter.dateTime(request.preferredDate!)}',
                          ),
                        if (request.schedule?.scheduledAt != null)
                          Text(
                            'Scheduled: ${DateFormatter.dateTime(request.schedule!.scheduledAt!)}',
                          ),
                        if (request.clinicalNotes != null &&
                            request.clinicalNotes!.isNotEmpty)
                          Text(request.clinicalNotes!),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TheatreStatusChip(status: request.status),
                        if (_canCancel(request))
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined),
                            tooltip: 'Cancel',
                            onPressed: () => _cancelRequest(request),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
