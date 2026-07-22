import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/auth/theatre_permissions.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/ward_models.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/ward_service.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/core/widgets/patient_avatar.dart';
import 'package:helty/src/theatre/models/theatre_models.dart';
import 'package:helty/src/theatre/providers/theatre_providers.dart';
import 'package:helty/src/theatre/widgets/theatre_add_consumable_sheet.dart';
import 'package:helty/src/theatre/widgets/theatre_status_chip.dart';

@RoutePage()
class TheatreCaseDetailScreen extends ConsumerStatefulWidget {
  const TheatreCaseDetailScreen({
    super.key,
    required this.surgeryRequestId,
  });

  final String surgeryRequestId;

  @override
  ConsumerState<TheatreCaseDetailScreen> createState() =>
      _TheatreCaseDetailScreenState();
}

class _TheatreCaseDetailScreenState
    extends ConsumerState<TheatreCaseDetailScreen> {
  SurgeryRequest? _request;
  bool _loading = true;
  bool _updating = false;
  String? _error;

  final _findingsCtrl = TextEditingController();
  final _complicationsCtrl = TextEditingController();
  final _operativeNotesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _findingsCtrl.dispose();
    _complicationsCtrl.dispose();
    _operativeNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final request = await ref
          .read(theatreApiServiceProvider)
          .getCase(widget.surgeryRequestId);
      if (!mounted) return;
      setState(() {
        _request = request;
        _loading = false;
      });
      _syncNotesFromCase(request.theatreCase);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _syncNotesFromCase(TheatreCase? theatreCase) {
    if (theatreCase == null) return;
    _findingsCtrl.text = theatreCase.findings ?? '';
    _complicationsCtrl.text = theatreCase.complications ?? '';
    _operativeNotesCtrl.text = theatreCase.operativeNotes ?? '';
  }

  Future<void> _runAction(Future<SurgeryRequest> Function() action) async {
    setState(() => _updating = true);
    try {
      final updated = await action();
      if (!mounted) return;
      setState(() {
        _request = updated;
        _updating = false;
      });
      _syncNotesFromCase(updated.theatreCase);
      invalidateTheatreCase(ref, widget.surgeryRequestId);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _updating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _updating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _startCase() async {
    await _runAction(
      () => ref.read(theatreApiServiceProvider).startCase(
        widget.surgeryRequestId,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Surgery started')),
    );
  }

  Future<void> _saveNotes() async {
    final staffId = ref.read(authProvider).staff?.id;
    await _runAction(
      () => ref.read(theatreApiServiceProvider).patchCase(
        widget.surgeryRequestId,
        findings: _findingsCtrl.text.trim(),
        complications: _complicationsCtrl.text.trim(),
        operativeNotes: _operativeNotesCtrl.text.trim(),
        performedById: staffId,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Operative notes saved')),
    );
  }

  Future<void> _completeCase() async {
    await _runAction(
      () => ref.read(theatreApiServiceProvider).completeCase(
        widget.surgeryRequestId,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Surgery completed')),
    );
  }

  Future<void> _billCase() async {
    final staffId = ref.read(authProvider).staff?.id;
    if (staffId == null || staffId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send to billing'),
        content: const Text(
          'Create encounter invoice lines for the surgery service and '
          'staged billable consumables?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Bill'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _runAction(
      () => ref.read(theatreApiServiceProvider).billCase(
        widget.surgeryRequestId,
        billedByStaffId: staffId,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Case billed on encounter invoice')),
    );
  }

  Future<void> _transferCase() async {
    final request = _request;
    if (request == null) return;
    final admissionId = request.admissionId;
    if (admissionId == null || admissionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No linked admission for transfer.')),
      );
      return;
    }

    final result = await showDialog<_TransferDialogResult>(
      context: context,
      builder: (ctx) => _PostOpTransferDialog(admissionId: admissionId),
    );
    if (result == null || !mounted) return;

    await _runAction(
      () => ref.read(theatreApiServiceProvider).transferCase(
        widget.surgeryRequestId,
        admissionId: admissionId,
        wardId: result.wardId,
        bedId: result.bedId,
        transferNotes: result.notes,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Patient transferred to ward')),
    );
  }

  Future<void> _addConsumable() async {
    final request = _request;
    if (request == null) return;
    if (request.status != SurgeryRequestStatus.inProgress &&
        request.status != SurgeryRequestStatus.completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consumables can be added during or after surgery.'),
        ),
      );
      return;
    }
    if (request.status == SurgeryRequestStatus.billed) return;

    final added = await showTheatreAddConsumableSheet(
      context: context,
      ref: ref,
      surgeryRequestId: widget.surgeryRequestId,
    );
    if (added != null) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consumable added')),
      );
    }
  }

  Future<void> _removeConsumable(TheatreCaseConsumable line) async {
    if (line.invoiceItemId != null && line.invoiceItemId!.isNotEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove consumable'),
        content: Text(
          'Remove ${line.consumable?.name ?? line.consumableId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _updating = true);
    try {
      await ref.read(theatreApiServiceProvider).deleteCaseConsumable(
        widget.surgeryRequestId,
        line.id,
      );
      await _load();
      if (!mounted) return;
      setState(() => _updating = false);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _updating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Surgery case')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _request == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Surgery case')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Case not found'),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final request = _request!;
    final staff = ref.watch(authProvider).staff;
    final canClinical = canManageTheatreClinical(staff);
    final canBill = canBillTheatreCase(staff);
    final patientName = request.patient?.displayName ?? request.patientId;
    final procedureName = request.service?.name ?? 'Surgery';
    final theatreCase = request.theatreCase;
    final consumables = theatreCase?.consumables ?? const [];
    final canEditNotes =
        canClinical &&
        (request.status == SurgeryRequestStatus.inProgress ||
            request.status == SurgeryRequestStatus.completed);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Surgery case'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: ResponsiveBody(
        center: false,
        expand: false,
        builder: (context, bp) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PatientAvatar(
                          avatarUrl: request.patient?.avatarUrl,
                          firstName: request.patient?.firstName,
                          surname: request.patient?.surname,
                          displayName: patientName,
                          size: 48,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            patientName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(procedureName),
                    const SizedBox(height: 8),
                    TheatreStatusChip(status: request.status),
                    if (request.priority != null) ...[
                      const SizedBox(height: 8),
                      Text('Priority: ${request.priority!.displayLabel}'),
                    ],
                    if (request.schedule?.scheduledAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Scheduled: ${DateFormatter.dateTime(request.schedule!.scheduledAt!)}',
                      ),
                      if (request.schedule?.theatreRoom?.name != null)
                        Text('Room: ${request.schedule!.theatreRoom!.name}'),
                    ],
                    if (request.clinicalNotes != null &&
                        request.clinicalNotes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Clinical notes: ${request.clinicalNotes}'),
                    ],
                    if (request.invoiceId != null) ...[
                      const SizedBox(height: 8),
                      Text('Invoice: ${request.invoiceId}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildStatusActions(
              request,
              canClinical: canClinical,
              canBill: canBill,
            ),
            const SizedBox(height: 24),
            Text(
              'Operative documentation',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (canEditNotes) ...[
              TextField(
                controller: _findingsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Findings',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _complicationsCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Complications',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _operativeNotesCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Operative notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: _updating ? null : _saveNotes,
                  child: const Text('Save notes'),
                ),
              ),
            ] else if (theatreCase != null) ...[
              if (theatreCase.findings != null &&
                  theatreCase.findings!.isNotEmpty)
                Text('Findings: ${theatreCase.findings}'),
              if (theatreCase.complications != null &&
                  theatreCase.complications!.isNotEmpty)
                Text('Complications: ${theatreCase.complications}'),
              if (theatreCase.operativeNotes != null &&
                  theatreCase.operativeNotes!.isNotEmpty)
                Text('Operative notes: ${theatreCase.operativeNotes}'),
            ] else
              Text(
                'No operative notes yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Consumables',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (canClinical &&
                    request.status != SurgeryRequestStatus.billed &&
                    request.status != SurgeryRequestStatus.cancelled)
                  FilledButton.tonalIcon(
                    onPressed: _updating ? null : _addConsumable,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (consumables.isEmpty)
              Text(
                'No consumables added yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...consumables.map(
                (c) => Card(
                  child: ListTile(
                    title: Text(c.consumable?.name ?? c.consumableId),
                    subtitle: Text(
                      'Qty ${c.quantity} · ${c.unitPrice} each'
                      '${c.billable ? '' : ' · non-billable'}',
                    ),
                    trailing: canClinical &&
                            c.invoiceItemId == null &&
                            request.status != SurgeryRequestStatus.billed
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: _updating
                                ? null
                                : () => _removeConsumable(c),
                          )
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStatusActions(
    SurgeryRequest request, {
    required bool canClinical,
    required bool canBill,
  }) {
    if (_updating) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (request.status) {
      case SurgeryRequestStatus.requested:
        return const Chip(
          label: Text('Awaiting theatre schedule'),
        );
      case SurgeryRequestStatus.scheduled:
        if (!canClinical) {
          return const Chip(label: Text('Scheduled — awaiting start'));
        }
        return FilledButton.icon(
          onPressed: _startCase,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start surgery'),
        );
      case SurgeryRequestStatus.inProgress:
        if (!canClinical) {
          return const Chip(label: Text('Surgery in progress'));
        }
        return FilledButton.icon(
          onPressed: _completeCase,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Complete surgery'),
        );
      case SurgeryRequestStatus.completed:
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (canBill)
              FilledButton.icon(
                onPressed: _billCase,
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Send to billing'),
              ),
            if (canClinical &&
                request.admissionId != null &&
                request.admissionId!.isNotEmpty)
              OutlinedButton.icon(
                onPressed: _transferCase,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Post-op transfer'),
              ),
          ],
        );
      case SurgeryRequestStatus.billed:
        return const Chip(
          avatar: Icon(Icons.check_circle_outline, size: 18),
          label: Text('Billed'),
        );
      case SurgeryRequestStatus.cancelled:
        return const Chip(
          avatar: Icon(Icons.cancel_outlined, size: 18),
          label: Text('Cancelled'),
        );
    }
  }
}

class _TransferDialogResult {
  const _TransferDialogResult({
    required this.wardId,
    required this.bedId,
    this.notes,
  });

  final String wardId;
  final String bedId;
  final String? notes;
}

class _PostOpTransferDialog extends StatefulWidget {
  const _PostOpTransferDialog({required this.admissionId});

  final String admissionId;

  @override
  State<_PostOpTransferDialog> createState() => _PostOpTransferDialogState();
}

class _PostOpTransferDialogState extends State<_PostOpTransferDialog> {
  final _wardService = WardService();
  final _notesCtrl = TextEditingController();

  List<Ward> _wards = [];
  List<Bed> _beds = [];
  Ward? _selectedWard;
  Bed? _selectedBed;
  bool _loadingWards = true;
  bool _loadingBeds = false;

  @override
  void initState() {
    super.initState();
    _loadWards();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWards() async {
    try {
      final wards = await _wardService.fetchWards();
      if (!mounted) return;
      setState(() {
        _wards = wards;
        _loadingWards = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingWards = false);
    }
  }

  Future<void> _loadBeds(String wardId) async {
    setState(() {
      _loadingBeds = true;
      _selectedBed = null;
    });
    try {
      final beds = await _wardService.fetchBedsForWard(wardId);
      if (!mounted) return;
      setState(() {
        _beds = beds
            .where((b) => b.status == BedStatus.available)
            .toList();
        _loadingBeds = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingBeds = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Post-op transfer'),
      content: SizedBox(
        width: 420,
        child: _loadingWards
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Ward *'),
                    items: _wards
                        .map(
                          (w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(w.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final ward = _wards.firstWhere((w) => w.id == value);
                      setState(() => _selectedWard = ward);
                      _loadBeds(ward.id);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_loadingBeds)
                    const LinearProgressIndicator()
                  else if (_selectedWard != null)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Bed *'),
                      items: _beds
                          .map(
                            (b) => DropdownMenuItem(
                              value: b.id,
                              child: Text(b.bedNumber),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(
                          () => _selectedBed = _beds.firstWhere(
                            (b) => b.id == value,
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Transfer notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedWard == null || _selectedBed == null
              ? null
              : () {
                  Navigator.of(context).pop(
                    _TransferDialogResult(
                      wardId: _selectedWard!.id,
                      bedId: _selectedBed!.id,
                      notes: _notesCtrl.text.trim().isEmpty
                          ? null
                          : _notesCtrl.text.trim(),
                    ),
                  );
                },
          child: const Text('Transfer'),
        ),
      ],
    );
  }
}
