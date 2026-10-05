import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/core/widgets/patient_avatar.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/models/medication_request_model.dart';
import 'package:helty/src/pharmacy/services/pharmacy_service.dart';
import 'package:helty/src/pharmacy/widgets/medication_attribution_widgets.dart';
import 'package:helty/src/pharmacy/widgets/medication_request_edit_dialog.dart';
import 'package:helty/src/pharmacy/widgets/medication_workflow_badges.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/medication_order_service.dart';
import 'package:helty/src/services/medication_request_service.dart';
import 'package:helty/src/shared/department_colors.dart';
import 'package:helty/src/widgets/helty_surface.dart';

/// Walk-in accent tiles. The page header uses [DepartmentColors.pharmacy].
abstract final class _Accent {
  static const blue = Color(0xFF2563EB);
  static const teal = Color(0xFF0D9488);
  static const purple = Color(0xFF7C3AED);
  static const pink = Color(0xFFDB2777);
  static const indigo = Color(0xFF4F46E5);
  static const green = Color(0xFF16A34A);
  static const amber = Color(0xFFEA580C);

  static const cardBreakpoint = 768.0;
  static const railBreakpoint = 1100.0;

  static const palette = [blue, teal, purple, pink, indigo, green, amber];

  static Color forSeed(String seed) {
    if (seed.isEmpty) return blue;
    var hash = 0;
    for (final code in seed.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return palette[hash % palette.length];
  }
}

enum _QuickRange { today, last7, thisMonth }

enum _RequestListMode { time, patient }

enum _RequestListEntryKind { header, row }

class _RequestListEntry {
  const _RequestListEntry.header(this.group)
    : request = null,
      kind = _RequestListEntryKind.header;

  const _RequestListEntry.row(this.request)
    : group = null,
      kind = _RequestListEntryKind.row;

  final _RequestListEntryKind kind;
  final _PatientRequestGroup? group;
  final MedicationRequestModel? request;
}

class _PatientRequestGroup {
  const _PatientRequestGroup({
    required this.key,
    required this.patientName,
    required this.hospitalNumber,
    required this.firstName,
    required this.surname,
    required this.avatarUrl,
    required this.requests,
  });

  final String key;
  final String patientName;
  final String? hospitalNumber;
  final String? firstName;
  final String? surname;
  final String? avatarUrl;
  final List<MedicationRequestModel> requests;

  DateTime get newestRequestTime => _requestTime(requests.first);
}

class _WardCount {
  const _WardCount({required this.name, required this.count});

  final String name;
  final int count;
}

class _QueueNote {
  const _QueueNote({required this.at, required this.message});

  final DateTime at;
  final String message;
}

DateTime _requestTime(MedicationRequestModel r) =>
    r.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

int _compareRequestsNewestFirst(
  MedicationRequestModel a,
  MedicationRequestModel b,
) => _requestTime(b).compareTo(_requestTime(a));

String _patientGroupKey(MedicationRequestModel r) {
  final id = r.patient?.id.trim();
  if (id != null && id.isNotEmpty) return id;
  final hn = r.patient?.hospitalNumber?.trim();
  if (hn != null && hn.isNotEmpty) return 'hn:$hn';
  return 'unknown-${r.id}';
}

List<MedicationRequestModel> _sortedRequests(
  List<MedicationRequestModel> requests,
) {
  final copy = List<MedicationRequestModel>.from(requests)
    ..sort(_compareRequestsNewestFirst);
  return copy;
}

List<_PatientRequestGroup> _groupRequestsByPatient(
  List<MedicationRequestModel> requests, {
  required String? Function(MedicationRequestModel) firstName,
  required String? Function(MedicationRequestModel) surname,
  required String Function(MedicationRequestModel) patientLabel,
  required String? Function(MedicationRequestModel) hospitalNumber,
}) {
  final map = <String, List<MedicationRequestModel>>{};
  for (final r in requests) {
    map.putIfAbsent(_patientGroupKey(r), () => []).add(r);
  }

  final groups = <_PatientRequestGroup>[];
  for (final entry in map.entries) {
    final sorted = List<MedicationRequestModel>.from(entry.value)
      ..sort(_compareRequestsNewestFirst);
    final first = sorted.first;
    groups.add(
      _PatientRequestGroup(
        key: entry.key,
        patientName: patientLabel(first),
        hospitalNumber: hospitalNumber(first),
        firstName: firstName(first),
        surname: surname(first),
        avatarUrl: first.patient?.avatarUrl,
        requests: sorted,
      ),
    );
  }

  groups.sort((a, b) => b.newestRequestTime.compareTo(a.newestRequestTime));
  return groups;
}

String _staffLine(MedicationRequestModel request) {
  final order = request.medicationOrder;
  final parts = <String>[];
  final doctor = order?.doctor?.displayName.trim();
  final nurse = request.requestedByNurse?.displayName.trim();
  final substituted = order?.substitutedByPharmacist?.displayName.trim();
  if (doctor != null && doctor.isNotEmpty) parts.add('Dr $doctor');
  if (nurse != null && nurse.isNotEmpty) parts.add('Req $nurse');
  if (substituted != null && substituted.isNotEmpty) {
    parts.add('Sub $substituted');
  }
  return parts.join(' · ');
}

String _medicationTooltip(MedicationRequestModel request) {
  final order = request.medicationOrder;
  final drug = order?.currentDrugLabel ?? '—';
  final lines = <String>[drug];
  if (order != null && order.wasSubstituted) {
    lines.add('Prescribed: ${order.prescribedDrugLabel}');
    lines.add('Current: ${order.currentDrugLabel}');
  }
  final rx = order?.prescriptionDetailLine ?? '';
  if (rx.isNotEmpty) lines.add(rx);
  final staff = _staffLine(request);
  if (staff.isNotEmpty) lines.add(staff);
  final created = request.createdAt;
  if (created != null) {
    lines.add('Requested ${DateFormatter.dateTime(created)}');
  }
  final notes = request.notes?.trim();
  if (notes != null && notes.isNotEmpty) lines.add(notes);
  final instructions = order?.specialInstructions?.trim();
  if (instructions != null && instructions.isNotEmpty) lines.add(instructions);
  return lines.join('\n');
}

@RoutePage()
class MedicationRequestsScreen extends ConsumerStatefulWidget {
  const MedicationRequestsScreen({super.key});

  @override
  ConsumerState<MedicationRequestsScreen> createState() =>
      _MedicationRequestsScreenState();
}

class _MedicationRequestsScreenState
    extends ConsumerState<MedicationRequestsScreen> {
  static const int _pageSize = 20;

  final _service = MedicationRequestService();
  final _medicationOrderService = MedicationOrderService();
  final _pharmacyApi = PharmacyApiService();
  final _patientFilterCtrl = TextEditingController();

  List<MedicationRequestModel> _requests = [];
  final Set<String> _selectedIds = {};
  final Set<String> _expandedPatientGroupKeys = {};
  final List<_QueueNote> _notes = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _billing = false;
  String? _error;
  int _total = 0;
  int _skip = 0;
  DateTime _from = _startOfDay(DateTime.now());
  DateTime _to = _endOfDay(DateTime.now());
  _RequestListMode _listMode = _RequestListMode.time;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _patientFilterCtrl.dispose();
    super.dispose();
  }

  bool get _metricsReady =>
      _requests.isNotEmpty || (!_loading && _error == null);

  int get _loadedPatientCount => _requests.map(_patientGroupKey).toSet().length;

  List<_WardCount> get _wardCounts {
    final map = <String, int>{};
    for (final request in _requests) {
      final name = request.wardDisplayLabel.trim().isEmpty
          ? '—'
          : request.wardDisplayLabel.trim();
      map[name] = (map[name] ?? 0) + 1;
    }
    final rows =
        [
          for (final entry in map.entries)
            _WardCount(name: entry.key, count: entry.value),
        ]..sort((a, b) {
          final byCount = b.count.compareTo(a.count);
          if (byCount != 0) return byCount;
          return a.name.compareTo(b.name);
        });
    return rows;
  }

  void _addNote(String message) {
    if (!mounted) return;
    setState(() {
      _notes.insert(0, _QueueNote(at: DateTime.now(), message: message));
      if (_notes.length > 30) {
        _notes.removeRange(30, _notes.length);
      }
    });
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _skip = 0;
        _requests = [];
        _selectedIds.clear();
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final patientQuery = _patientFilterCtrl.text.trim();
      final page = await _service.listPharmacyQueue(
        patientId: patientQuery.isEmpty ? null : patientQuery,
        fromDate: _from,
        toDate: _to,
        skip: reset ? 0 : _skip,
        take: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _requests = page.requests;
          _skip = page.requests.length;
        } else {
          _requests = [..._requests, ...page.requests];
          _skip += page.requests.length;
        }
        _total = page.total;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedIds.addAll(_requests.map((r) => r.id));
      } else {
        _selectedIds.clear();
      }
    });
  }

  void _toggleRow(MedicationRequestModel request) {
    setState(() {
      if (_selectedIds.contains(request.id)) {
        _selectedIds.remove(request.id);
      } else {
        _selectedIds.add(request.id);
      }
    });
  }

  Future<void> _editRequest(MedicationRequestModel request) async {
    final staffId = ref.read(authProvider).staff?.id;
    if (staffId == null || staffId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in as pharmacy staff')),
      );
      return;
    }

    final result = await showMedicationRequestEditDialog(
      context,
      request: request,
      requestService: _service,
      medicationOrderService: _medicationOrderService,
      pharmacyApi: _pharmacyApi,
      modifiedByStaffId: staffId,
    );

    if (result == null || !mounted) return;
    _addNote('Updated a request for ${_patientLabel(request)}.');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Request updated')));
    await _load(reset: true);
  }

  Future<void> _deleteRequest(MedicationRequestModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete request?'),
        content: const Text('This cancels the pending request before billing.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final staffId = ref.read(authProvider).staff?.id;
    if (staffId == null || staffId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in as pharmacy staff')),
      );
      return;
    }

    try {
      await _service.cancel(id: request.id, cancelledByStaffId: staffId);
      if (!mounted) return;
      setState(() => _selectedIds.remove(request.id));
      _addNote('Deleted a request for ${_patientLabel(request)}.');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request deleted')));
      await _load(reset: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _billSelected() async {
    final staffId = ref.read(authProvider).staff?.id;
    if (staffId == null || staffId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in as pharmacy staff')),
      );
      return;
    }

    final selected = _requests
        .where((r) => _selectedIds.contains(r.id))
        .toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one request to bill')),
      );
      return;
    }

    final byEncounter = <String, List<MedicationRequestModel>>{};
    for (final r in selected) {
      final encId = r.encounterId;
      if (encId == null || encId.isEmpty) continue;
      byEncounter.putIfAbsent(encId, () => []).add(r);
    }

    if (byEncounter.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected requests have no encounter id')),
      );
      return;
    }

    setState(() => _billing = true);
    String? lastInvoiceId;
    String? lastInvoiceLabel;

    try {
      for (final entry in byEncounter.entries) {
        final result = await _service.bill(
          encounterId: entry.key,
          billedByStaffId: staffId,
          requestIds: entry.value.map((r) => r.id).toList(),
        );
        lastInvoiceId = result.invoice.id;
        lastInvoiceLabel = result.invoice.invoiceDisplayId ?? result.invoice.id;
      }

      if (!mounted) return;
      final billedCount = selected.length;
      _addNote(
        lastInvoiceLabel != null
            ? 'Billed $billedCount request${billedCount == 1 ? '' : 's'} to invoice $lastInvoiceLabel.'
            : 'Billed $billedCount request${billedCount == 1 ? '' : 's'}.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lastInvoiceLabel != null
                ? 'Billed to invoice $lastInvoiceLabel — opening dispense queue'
                : 'Requests billed successfully',
          ),
        ),
      );

      await _load(reset: true);

      if (lastInvoiceId != null && lastInvoiceId.isNotEmpty && mounted) {
        context.router.push(WaitingPatientRoute(invoiceId: lastInvoiceId));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _billing = false);
    }
  }

  String? _patientFirstName(MedicationRequestModel r) =>
      r.patient?.firstName.trim().isNotEmpty == true
      ? r.patient!.firstName.trim()
      : null;

  String? _patientSurname(MedicationRequestModel r) =>
      r.patient?.surname.trim().isNotEmpty == true
      ? r.patient!.surname.trim()
      : null;

  String _patientLabel(MedicationRequestModel r) {
    final p = r.patient;
    if (p == null) return 'Unknown patient';
    final name = p.displayName.trim();
    return name.isEmpty ? 'Unknown patient' : name;
  }

  String? _patientHospitalNumber(MedicationRequestModel r) =>
      r.patient?.hospitalNumber?.trim();

  List<_RequestListEntry> _buildListEntries() {
    if (_listMode == _RequestListMode.time) {
      return _sortedRequests(
        _requests,
      ).map((r) => _RequestListEntry.row(r)).toList();
    }

    final groups = _groupRequestsByPatient(
      _requests,
      firstName: _patientFirstName,
      surname: _patientSurname,
      patientLabel: _patientLabel,
      hospitalNumber: _patientHospitalNumber,
    );
    final entries = <_RequestListEntry>[];
    for (final group in groups) {
      entries.add(_RequestListEntry.header(group));
      if (_expandedPatientGroupKeys.contains(group.key)) {
        for (final request in group.requests) {
          entries.add(_RequestListEntry.row(request));
        }
      }
    }
    return entries;
  }

  Future<void> _pickDateRange([BuildContext? pickerContext]) async {
    final range = await showDateRangePicker(
      context: pickerContext ?? context,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (range == null) return;
    setState(() {
      _from = _startOfDay(range.start);
      _to = _endOfDay(range.end);
    });
    await _load(reset: true);
  }

  void _applyQuickRange(_QuickRange quickRange) {
    final now = DateTime.now();
    setState(() {
      switch (quickRange) {
        case _QuickRange.today:
          _from = _startOfDay(now);
          _to = _endOfDay(now);
        case _QuickRange.last7:
          _from = _startOfDay(now.subtract(const Duration(days: 6)));
          _to = _endOfDay(now);
        case _QuickRange.thisMonth:
          _from = DateTime(now.year, now.month, 1);
          _to = _endOfDay(now);
      }
    });
    _load(reset: true);
  }

  void _setListMode(_RequestListMode mode) {
    setState(() {
      _listMode = mode;
      if (mode == _RequestListMode.patient) {
        _expandedPatientGroupKeys.clear();
      }
    });
  }

  Future<void> _openFilters({required bool compact}) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final width = MediaQuery.sizeOf(ctx).width;
        return Dialog(
          alignment: Alignment.topRight,
          insetPadding: const EdgeInsets.fromLTRB(16, 72, 16, 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: math.min(560, width - 32)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const HeltySolidIcon(
                            icon: Icons.tune,
                            color: _Accent.purple,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Filters',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(ctx).maybePop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (compact) ...[
                              _GroupDropdown(
                                mode: _listMode,
                                onChanged: (mode) {
                                  _setListMode(mode);
                                  setDialogState(() {});
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                            Text(
                              'Date range',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _loading || _billing
                                  ? null
                                  : () async {
                                      await _pickDateRange(ctx);
                                      setDialogState(() {});
                                    },
                              icon: const Icon(Icons.date_range, size: 18),
                              label: Text(
                                '${DateFormatter.shortDate(_from)} – ${DateFormatter.shortDate(_to)}',
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _quickChip(
                                  'Today',
                                  _QuickRange.today,
                                  setDialogState,
                                ),
                                _quickChip(
                                  'Last 7 days',
                                  _QuickRange.last7,
                                  setDialogState,
                                ),
                                _quickChip(
                                  'This month',
                                  _QuickRange.thisMonth,
                                  setDialogState,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _quickChip(
    String label,
    _QuickRange range,
    void Function(VoidCallback) setDialogState,
  ) {
    return ActionChip(
      label: Text(label),
      onPressed: _loading || _billing
          ? null
          : () {
              _applyQuickRange(range);
              setDialogState(() {});
            },
    );
  }

  Future<void> _showDetails(MedicationRequestModel request) async {
    final width = MediaQuery.sizeOf(context).width;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;
        final order = request.medicationOrder;
        final created = request.createdAt;
        final notes = request.notes?.trim();
        final instructions = order?.specialInstructions?.trim();
        final rx = order?.prescriptionDetailLine ?? '';
        final course = order?.quantity;
        final showCourse =
            course != null && course > 0 && course != request.requestedQuantity;
        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: math.min(560, width - 32)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const HeltySolidIcon(
                        icon: Icons.medication_outlined,
                        color: DepartmentColors.pharmacy,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Request details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(ctx).maybePop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(ctx).height * 0.62,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DetailIdentity(
                            request: request,
                            patientName: _patientLabel(request),
                            hospitalNumber: _patientHospitalNumber(request),
                            firstName: _patientFirstName(request),
                            surname: _patientSurname(request),
                          ),
                          const SizedBox(height: 8),
                          HeltyStatusChip(
                            label: request.status.label,
                            color: medicationRequestStatusColor(
                              ctx,
                              request.status,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _detailLabel(ctx, 'Medication'),
                          HeltyEllipsisText(
                            text: order?.currentDrugLabel ?? '—',
                            maxLines: 2,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (rx.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            HeltyEllipsisText(
                              text: rx,
                              maxLines: 2,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          MedicationRequestAttribution(request: request),
                          const SizedBox(height: 8),
                          _detailLabel(ctx, 'Bill quantity'),
                          Text(
                            '${request.requestedQuantity} unit${request.requestedQuantity == 1 ? '' : 's'}'
                            '${showCourse ? ' · course $course' : ''}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _detailLabel(ctx, 'Ward'),
                          HeltyEllipsisText(text: request.wardDisplayLabel),
                          if (request.encounter != null) ...[
                            const SizedBox(height: 8),
                            _detailLabel(ctx, 'Encounter'),
                            HeltyEllipsisText(
                              text:
                                  request.encounter!.status
                                          ?.trim()
                                          .isNotEmpty ==
                                      true
                                  ? '${request.encounter!.typeLabel} · ${request.encounter!.status}'
                                  : request.encounter!.typeLabel,
                            ),
                          ],
                          if (created != null) ...[
                            const SizedBox(height: 8),
                            _detailLabel(ctx, 'Requested'),
                            Text(DateFormatter.dateTime(created)),
                          ],
                          if (notes != null && notes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _detailLabel(ctx, 'Notes'),
                            Text(notes),
                          ],
                          if (instructions != null &&
                              instructions.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _detailLabel(ctx, 'Special instructions'),
                            Text(instructions),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      if (request.isRequested)
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _editRequest(request);
                          },
                          child: const Text('Edit'),
                        ),
                      if (request.isRequested)
                        TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _deleteRequest(request);
                          },
                          child: Text(
                            'Delete',
                            style: TextStyle(color: cs.error),
                          ),
                        ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAllNotes() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final width = MediaQuery.sizeOf(ctx).width;
        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: math.min(560, width - 32),
              maxHeight: 480,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const HeltySolidIcon(
                        icon: Icons.notes_outlined,
                        color: _Accent.teal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Notes',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(ctx).maybePop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: math.min(
                        360,
                        MediaQuery.sizeOf(ctx).height * 0.5,
                      ),
                    ),
                    child: _notes.isEmpty
                        ? Text(
                            'No recent activity this session.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : ListView(
                            shrinkWrap: true,
                            children: [
                              for (final note in _notes)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(note.message),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allSelected =
        _requests.isNotEmpty && _selectedIds.length == _requests.length;
    final someSelected =
        _selectedIds.isNotEmpty && _selectedIds.length < _requests.length;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final width = bp.maxWidth > 0
              ? bp.maxWidth
              : MediaQuery.sizeOf(context).width;
          final compact = width < _Accent.cardBreakpoint;
          final showRail = width >= _Accent.railBreakpoint;
          final pendingValue = _metricsReady ? '$_total' : '—';
          final patientsValue = _metricsReady ? '$_loadedPatientCount' : '—';
          final loadedValue = _metricsReady ? '${_requests.length}' : '—';

          final header = _QueueHeader(
            onRefresh: _loading || _billing ? null : () => _load(reset: true),
          );
          final kpis = _KpiStrip(
            pending: pendingValue,
            selected: '${_selectedIds.length}',
            patients: patientsValue,
            loaded: loadedValue,
            useSnapStrip: width < 520,
          );
          final filters = _FilterBar(
            controller: _patientFilterCtrl,
            compact: compact,
            mode: _listMode,
            busy: _loading || _billing,
            onSearch: () => _load(reset: true),
            onModeChanged: _setListMode,
            onOpenFilters: () => _openFilters(compact: compact),
          );

          final mainColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 10),
              kpis,
              const SizedBox(height: 10),
              filters,
              if (_error != null && _requests.isNotEmpty) ...[
                const SizedBox(height: 10),
                _ErrorBanner(
                  message: _error!,
                  onRetry: () => _load(reset: true),
                ),
              ],
              const SizedBox(height: 10),
              Expanded(
                child: _QueueBody(
                  entries: _buildListEntries(),
                  useCards: compact,
                  loading: _loading && _requests.isEmpty,
                  loadingMore: _loadingMore,
                  error: _requests.isEmpty ? _error : null,
                  requests: _requests,
                  selectedIds: _selectedIds,
                  total: _total,
                  allSelected: allSelected,
                  someSelected: someSelected,
                  billing: _billing,
                  busy: _loading || _billing,
                  showPatientOnRow: _listMode == _RequestListMode.time,
                  patientName: _patientLabel,
                  hospitalNumber: _patientHospitalNumber,
                  firstName: _patientFirstName,
                  surname: _patientSurname,
                  onToggleAll: _toggleSelectAll,
                  onToggle: _toggleRow,
                  onView: _showDetails,
                  onEdit: _editRequest,
                  onDelete: _deleteRequest,
                  onBill: _selectedIds.isEmpty || _billing
                      ? null
                      : _billSelected,
                  onLoadMore: _requests.length < _total && !_loadingMore
                      ? () => _load(reset: false)
                      : null,
                  onRetry: () => _load(reset: true),
                  onToggleGroup: (key, expanded) {
                    setState(() {
                      if (expanded) {
                        _expandedPatientGroupKeys.remove(key);
                      } else {
                        _expandedPatientGroupKeys.add(key);
                      }
                    });
                  },
                  isGroupExpanded: _expandedPatientGroupKeys.contains,
                ),
              ),
            ],
          );

          final rail = _QueueRail(
            fillHeight: showRail,
            billing: _billing,
            canBill: _selectedIds.isNotEmpty && !_billing,
            canRefresh: !_loading && !_billing,
            canSelect: _requests.isNotEmpty && !_loading && !_billing,
            allSelected: allSelected,
            selectedCount: _selectedIds.length,
            wardCounts: _wardCounts,
            notes: _notes,
            onBill: _billSelected,
            onRefresh: () => _load(reset: true),
            onToggleSelectAll: () => _toggleSelectAll(!allSelected),
            onViewAllNotes: _showAllNotes,
          );

          if (showRail) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 9, child: mainColumn),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: rail),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: mainColumn),
              const SizedBox(height: 10),
              SizedBox(height: 280, child: SingleChildScrollView(child: rail)),
            ],
          );
        },
      ),
    );
  }
}

Widget _detailLabel(BuildContext context, String label) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _endOfDay(DateTime d) =>
    DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

class _QueueHeader extends StatelessWidget {
  const _QueueHeader({required this.onRefresh});

  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      children: [
        const HeltySolidIcon(
          icon: Icons.medication_outlined,
          color: DepartmentColors.pharmacy,
          size: 34,
          iconSize: 18,
          radius: AppTheme.radiusMd,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Medication Requests',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              HeltyEllipsisText(
                text: 'Nurse-submitted requests awaiting pharmacy billing.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _KpiItem {
  const _KpiItem({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color accent;
}

class _KpiStrip extends StatelessWidget {
  const _KpiStrip({
    required this.pending,
    required this.selected,
    required this.patients,
    required this.loaded,
    required this.useSnapStrip,
  });

  final String pending;
  final String selected;
  final String patients;
  final String loaded;
  final bool useSnapStrip;

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiItem(
        label: 'Pending',
        value: pending,
        caption: 'In the pharmacy queue',
        icon: Icons.pending_actions_outlined,
        accent: _Accent.blue,
      ),
      _KpiItem(
        label: 'Selected',
        value: selected,
        caption: 'Ready to bill',
        icon: Icons.check_circle_outline,
        accent: _Accent.teal,
      ),
      _KpiItem(
        label: 'Patients',
        value: patients,
        caption: 'On the loaded page',
        icon: Icons.groups_outlined,
        accent: _Accent.purple,
      ),
      _KpiItem(
        label: 'Loaded',
        value: loaded,
        caption: 'Requests in view',
        icon: Icons.inventory_2_outlined,
        accent: _Accent.amber,
      ),
    ];

    if (useSnapStrip) {
      return SizedBox(
        height: 78,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) =>
              SizedBox(width: 200, child: _KpiCard(item: items[i])),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        if (wide) {
          return Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _KpiCard(item: items[i])),
              ],
            ],
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 72,
          ),
          itemBuilder: (context, i) => _KpiCard(item: items[i]),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.item});

  final _KpiItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return HeltySurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          HeltySolidIcon(
            icon: item.icon,
            color: item.accent,
            size: 30,
            iconSize: 16,
            radius: 8,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item.value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    height: 1.15,
                  ),
                ),
                Text(
                  item.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.controller,
    required this.compact,
    required this.mode,
    required this.busy,
    required this.onSearch,
    required this.onModeChanged,
    required this.onOpenFilters,
  });

  final TextEditingController controller;
  final bool compact;
  final _RequestListMode mode;
  final bool busy;
  final VoidCallback onSearch;
  final ValueChanged<_RequestListMode> onModeChanged;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final search = TextField(
      controller: controller,
      onSubmitted: (_) => onSearch(),
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        labelText: 'Search',
        hintText: 'Patient hospital number…',
        isDense: true,
        prefixIcon: const Padding(
          padding: EdgeInsets.all(6),
          child: HeltySolidIcon(
            icon: Icons.search,
            color: _Accent.indigo,
            size: 22,
            iconSize: 13,
            radius: 6,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 34,
          minHeight: 34,
        ),
        suffixIcon: IconButton(
          tooltip: 'Search',
          onPressed: busy ? null : onSearch,
          icon: const Icon(Icons.arrow_forward, size: 18),
        ),
        filled: true,
        fillColor: cs.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        labelStyle: const TextStyle(fontSize: 11),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 3, child: search),
        if (!compact) ...[
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _GroupDropdown(mode: mode, onChanged: onModeChanged),
          ),
        ],
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Filters',
          onPressed: busy ? null : onOpenFilters,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: const HeltySolidIcon(
            icon: Icons.tune,
            color: _Accent.purple,
            size: 32,
            iconSize: 16,
            radius: 8,
          ),
        ),
      ],
    );
  }
}

class _GroupDropdown extends StatelessWidget {
  const _GroupDropdown({required this.mode, required this.onChanged});

  final _RequestListMode mode;
  final ValueChanged<_RequestListMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DropdownButtonFormField<_RequestListMode>(
      key: ValueKey(mode),
      initialValue: mode,
      isExpanded: true,
      style: TextStyle(fontSize: 12, color: cs.onSurface),
      decoration: InputDecoration(
        labelText: 'Group',
        isDense: true,
        prefixIcon: const Padding(
          padding: EdgeInsets.all(6),
          child: HeltySolidIcon(
            icon: Icons.groups_outlined,
            color: _Accent.pink,
            size: 22,
            iconSize: 13,
            radius: 6,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 34,
          minHeight: 34,
        ),
        filled: true,
        fillColor: cs.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        labelStyle: const TextStyle(fontSize: 11),
      ),
      items: const [
        DropdownMenuItem(
          value: _RequestListMode.time,
          child: Text('Newest', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: _RequestListMode.patient,
          child: Text('Patient', overflow: TextOverflow.ellipsis),
        ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return HeltySurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          HeltySolidIcon(
            icon: Icons.error_outline,
            color: cs.error,
            size: 28,
            iconSize: 16,
            radius: 7,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: HeltyEllipsisText(
              text: message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _QueueBody extends StatelessWidget {
  const _QueueBody({
    required this.entries,
    required this.useCards,
    required this.loading,
    required this.loadingMore,
    required this.error,
    required this.requests,
    required this.selectedIds,
    required this.total,
    required this.allSelected,
    required this.someSelected,
    required this.billing,
    required this.busy,
    required this.showPatientOnRow,
    required this.patientName,
    required this.hospitalNumber,
    required this.firstName,
    required this.surname,
    required this.onToggleAll,
    required this.onToggle,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.onBill,
    required this.onLoadMore,
    required this.onRetry,
    required this.onToggleGroup,
    required this.isGroupExpanded,
  });

  final List<_RequestListEntry> entries;
  final bool useCards;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final List<MedicationRequestModel> requests;
  final Set<String> selectedIds;
  final int total;
  final bool allSelected;
  final bool someSelected;
  final bool billing;
  final bool busy;
  final bool showPatientOnRow;
  final String Function(MedicationRequestModel) patientName;
  final String? Function(MedicationRequestModel) hospitalNumber;
  final String? Function(MedicationRequestModel) firstName;
  final String? Function(MedicationRequestModel) surname;
  final ValueChanged<bool?> onToggleAll;
  final ValueChanged<MedicationRequestModel> onToggle;
  final ValueChanged<MedicationRequestModel> onView;
  final ValueChanged<MedicationRequestModel> onEdit;
  final ValueChanged<MedicationRequestModel> onDelete;
  final VoidCallback? onBill;
  final VoidCallback? onLoadMore;
  final VoidCallback onRetry;
  final void Function(String key, bool expanded) onToggleGroup;
  final bool Function(String key) isGroupExpanded;

  int _rowOrdinal(int entryIndex) {
    var count = 0;
    for (var i = 0; i < entryIndex; i++) {
      if (entries[i].kind == _RequestListEntryKind.row) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final footer = _QueueFooter(
      shown: requests.length,
      total: total,
      allSelected: allSelected,
      someSelected: someSelected,
      busy: busy,
      billing: billing,
      loadingMore: loadingMore,
      compact: useCards,
      onToggleAll: requests.isEmpty ? null : onToggleAll,
      onLoadMore: onLoadMore,
      onBill: onBill,
    );

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (requests.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: error != null
                  ? _EmptyMessage(
                      title: 'Could not load requests',
                      message: error!,
                      onRetry: onRetry,
                    )
                  : const _EmptyMessage(
                      title: 'No pending medication requests',
                      message:
                          'Nurse-submitted requests awaiting pharmacy billing will appear here for the selected date range.',
                    ),
            ),
          ),
          footer,
        ],
      );
    }

    if (useCards) {
      return Column(
        children: [
          Expanded(child: _cardList(context)),
          footer,
        ],
      );
    }

    return HeltySurfaceCard(
      child: Column(
        children: [
          Expanded(child: _table(context)),
          footer,
        ],
      ),
    );
  }

  Widget _cardList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 4),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        if (entry.kind == _RequestListEntryKind.header) {
          final group = entry.group!;
          return _PatientGroupBanner(
            group: group,
            expanded: isGroupExpanded(group.key),
            onToggle: () =>
                onToggleGroup(group.key, isGroupExpanded(group.key)),
          );
        }
        final request = entry.request!;
        return _RequestCard(
          request: request,
          selected: selectedIds.contains(request.id),
          showPatient: showPatientOnRow,
          patientName: patientName(request),
          hospitalNumber: hospitalNumber(request),
          firstName: firstName(request),
          surname: surname(request),
          onToggle: () => onToggle(request),
          onView: () => onView(request),
          onEdit: () => onEdit(request),
          onDelete: () => onDelete(request),
        );
      },
    );
  }

  Widget _table(BuildContext context) {
    return LayoutBuilder(
      builder: (context, inner) {
        const minWidth = 980.0;
        final tableWidth = inner.maxWidth < minWidth
            ? minWidth
            : inner.maxWidth;
        final sheet = SizedBox(
          width: tableWidth,
          height: inner.maxHeight,
          child: Column(
            children: [
              _TableHeader(
                allSelected: allSelected,
                someSelected: someSelected,
                onToggleAll: requests.isEmpty || busy ? null : onToggleAll,
              ),
              Expanded(child: _tableRows(context)),
            ],
          ),
        );
        if (inner.maxWidth >= minWidth) return sheet;
        return _QueueTableScroller(child: sheet);
      },
    );
  }

  Widget _tableRows(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      primary: false,
      itemCount: entries.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.08)),
      itemBuilder: (context, index) {
        final entry = entries[index];
        if (entry.kind == _RequestListEntryKind.header) {
          final group = entry.group!;
          return _PatientGroupBanner(
            group: group,
            expanded: isGroupExpanded(group.key),
            flat: true,
            onToggle: () =>
                onToggleGroup(group.key, isGroupExpanded(group.key)),
          );
        }
        final request = entry.request!;
        final rowIndex = _rowOrdinal(index);
        final zebra = rowIndex.isOdd
            ? cs.onSurface.withValues(alpha: 0.035)
            : Colors.transparent;
        return _TableRow(
          request: request,
          zebra: zebra,
          indexLabel: '${rowIndex + 1}',
          selected: selectedIds.contains(request.id),
          showPatient: showPatientOnRow,
          patientName: patientName(request),
          hospitalNumber: hospitalNumber(request),
          firstName: firstName(request),
          surname: surname(request),
          onToggle: () => onToggle(request),
          onView: () => onView(request),
          onEdit: () => onEdit(request),
          onDelete: () => onDelete(request),
        );
      },
    );
  }
}

/// Horizontal table scroller with its own controller.
///
/// A bare [Scrollbar] binds the primary (vertical) controller, which this
/// horizontal view never attaches, and then throws during the next frame.
class _QueueTableScroller extends StatefulWidget {
  const _QueueTableScroller({required this.child});

  final Widget child;

  @override
  State<_QueueTableScroller> createState() => _QueueTableScrollerState();
}

class _QueueTableScrollerState extends State<_QueueTableScroller> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      notificationPredicate: (notification) => notification.depth == 0,
      child: SingleChildScrollView(
        controller: _controller,
        primary: false,
        scrollDirection: Axis.horizontal,
        child: widget.child,
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.allSelected,
    required this.someSelected,
    required this.onToggleAll,
  });

  final bool allSelected;
  final bool someSelected;
  final ValueChanged<bool?>? onToggleAll;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        border: const Border(
          left: BorderSide(color: Colors.transparent, width: 4),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Checkbox(
              tristate: true,
              value: allSelected
                  ? true
                  : someSelected
                  ? null
                  : false,
              onChanged: onToggleAll,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 20),
          _head(context, 'PATIENT', flex: 4),
          const SizedBox(width: 20),
          _head(context, 'MEDICATION', flex: 4),
          const SizedBox(width: 20),
          _head(context, 'QTY', flex: 2),
          const SizedBox(width: 20),
          _head(context, 'WARD', flex: 2),
          const SizedBox(width: 20),
          _head(context, 'STATUS', flex: 2),
          const SizedBox(width: 20),
          _head(context, 'ACTIONS', flex: 3, alignEnd: true),
        ],
      ),
    );
  }

  Widget _head(
    BuildContext context,
    String label, {
    required int flex,
    bool alignEnd = false,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.request,
    required this.zebra,
    required this.indexLabel,
    required this.selected,
    required this.showPatient,
    required this.patientName,
    required this.hospitalNumber,
    required this.firstName,
    required this.surname,
    required this.onToggle,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final MedicationRequestModel request;
  final Color zebra;
  final String indexLabel;
  final bool selected;
  final bool showPatient;
  final String patientName;
  final String? hospitalNumber;
  final String? firstName;
  final String? surname;
  final VoidCallback onToggle;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final order = request.medicationOrder;
    final drug = order?.currentDrugLabel ?? '—';
    final rx = order?.prescriptionDetailLine ?? '';
    final substituted = order?.wasSubstituted == true;
    final second = [
      if (substituted) 'Substituted',
      if (rx.isNotEmpty) rx,
    ].join(' · ');
    final stripe = medicationRequestStatusColor(context, request.status);
    final fill = selected ? cs.primary.withValues(alpha: 0.08) : zebra;

    return Material(
      color: fill,
      child: InkWell(
        onTap: onToggle,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: stripe, width: 4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Checkbox(
                  value: selected,
                  onChanged: (_) => onToggle(),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 4,
                child: showPatient
                    ? _PatientIdentity(
                        patientName: patientName,
                        hospitalNumber: hospitalNumber,
                        firstName: firstName,
                        surname: surname,
                        avatarUrl: request.patient?.avatarUrl,
                        seed: _patientGroupKey(request),
                        caption: 'Ward: ${request.wardDisplayLabel}',
                      )
                    : HeltyEllipsisText(
                        text: indexLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 4,
                child: Tooltip(
                  message: _medicationTooltip(request),
                  waitDuration: const Duration(milliseconds: 350),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HeltyEllipsisText(
                        text: drug,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (second.isNotEmpty)
                        HeltyEllipsisText(
                          text: second,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: HeltyEllipsisText(
                  text: '${request.requestedQuantity}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: HeltyEllipsisText(text: request.wardDisplayLabel),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: HeltyEllipsisChip(
                  label: request.status.label,
                  color: stripe,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: _RequestActions(
                        canModify: request.isRequested,
                        onView: onView,
                        onEdit: onEdit,
                        onDelete: onDelete,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.selected,
    required this.showPatient,
    required this.patientName,
    required this.hospitalNumber,
    required this.firstName,
    required this.surname,
    required this.onToggle,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final MedicationRequestModel request;
  final bool selected;
  final bool showPatient;
  final String patientName;
  final String? hospitalNumber;
  final String? firstName;
  final String? surname;
  final VoidCallback onToggle;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final order = request.medicationOrder;
    final drug = order?.currentDrugLabel ?? '—';
    final rx = order?.prescriptionDetailLine ?? '';
    final notes = request.notes?.trim();
    final stripe = medicationRequestStatusColor(context, request.status);
    final staff = _staffLine(request);

    return HeltySurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      color: selected ? cs.primaryContainer.withValues(alpha: 0.35) : null,
      child: InkWell(
        onTap: onToggle,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: stripe, width: 4)),
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: selected,
                    onChanged: (_) => onToggle(),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Expanded(
                    child: showPatient
                        ? _PatientIdentity(
                            patientName: patientName,
                            hospitalNumber: hospitalNumber,
                            firstName: firstName,
                            surname: surname,
                            avatarUrl: request.patient?.avatarUrl,
                            seed: _patientGroupKey(request),
                            caption: 'Ward: ${request.wardDisplayLabel}',
                          )
                        : HeltyEllipsisText(
                            text: drug,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  HeltyStatusChip(label: request.status.label, color: stripe),
                ],
              ),
              if (showPatient) ...[
                const SizedBox(height: 6),
                Tooltip(
                  message: _medicationTooltip(request),
                  child: HeltyEllipsisText(
                    text: drug,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              if (rx.isNotEmpty) ...[
                const SizedBox(height: 2),
                HeltyEllipsisText(
                  text: rx,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Flexible(
                    child: HeltyEllipsisChip(
                      label: 'Qty ${request.requestedQuantity}',
                      color: _Accent.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: HeltyEllipsisChip(
                      label: request.wardDisplayLabel,
                      color: _Accent.teal,
                    ),
                  ),
                ],
              ),
              if (staff.isNotEmpty) ...[
                const SizedBox(height: 6),
                HeltyEllipsisText(
                  text: staff,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 4),
                HeltyEllipsisText(
                  text: notes,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: _RequestActions(
                  canModify: request.isRequested,
                  onView: onView,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientIdentity extends StatelessWidget {
  const _PatientIdentity({
    required this.patientName,
    required this.hospitalNumber,
    required this.firstName,
    required this.surname,
    required this.avatarUrl,
    required this.seed,
    required this.caption,
  });

  final String patientName;
  final String? hospitalNumber;
  final String? firstName;
  final String? surname;
  final String? avatarUrl;
  final String seed;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hn = hospitalNumber?.trim();
    return Row(
      children: [
        PatientAvatar(
          avatarUrl: avatarUrl,
          firstName: firstName,
          surname: surname,
          displayName: patientName,
          size: 32,
          backgroundColor: _Accent.forSeed(seed),
          foregroundColor: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              HeltyEllipsisText(
                text: patientName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (hn != null && hn.isNotEmpty)
                HeltyEllipsisText(
                  text: hn,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              HeltyEllipsisText(
                text: caption,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PatientGroupBanner extends StatelessWidget {
  const _PatientGroupBanner({
    required this.group,
    required this.expanded,
    required this.onToggle,
    this.flat = false,
  });

  final _PatientRequestGroup group;
  final bool expanded;
  final VoidCallback onToggle;
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final count = group.requests.length;
    final row = InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            PatientAvatar(
              avatarUrl: group.avatarUrl,
              firstName: group.firstName,
              surname: group.surname,
              displayName: group.patientName,
              size: 32,
              backgroundColor: _Accent.forSeed(group.key),
              foregroundColor: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeltyEllipsisText(
                    text: group.patientName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (group.hospitalNumber != null &&
                      group.hospitalNumber!.isNotEmpty)
                    HeltyEllipsisText(
                      text: group.hospitalNumber!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            HeltyEllipsisText(
              text: '$count request${count == 1 ? '' : 's'}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );

    if (flat) {
      return Material(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        child: row,
      );
    }

    return HeltySurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: row,
    );
  }
}

class _RequestActions extends StatelessWidget {
  const _RequestActions({
    required this.canModify,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final bool canModify;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: onView,
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: const StadiumBorder(),
          ),
          child: const Text('View'),
        ),
        PopupMenuButton<String>(
          tooltip: 'More actions',
          icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
          onSelected: (value) {
            switch (value) {
              case 'view':
                onView();
              case 'edit':
                onEdit();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View details')),
            if (canModify)
              const PopupMenuItem(value: 'edit', child: Text('Edit request')),
            if (canModify)
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete request'),
              ),
          ],
        ),
      ],
    );
  }
}

class _QueueFooter extends StatelessWidget {
  const _QueueFooter({
    required this.shown,
    required this.total,
    required this.allSelected,
    required this.someSelected,
    required this.busy,
    required this.billing,
    required this.loadingMore,
    required this.compact,
    required this.onToggleAll,
    required this.onLoadMore,
    required this.onBill,
  });

  final int shown;
  final int total;
  final bool allSelected;
  final bool someSelected;
  final bool busy;
  final bool billing;
  final bool loadingMore;
  final bool compact;
  final ValueChanged<bool?>? onToggleAll;
  final VoidCallback? onLoadMore;
  final VoidCallback? onBill;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = shown == 0
        ? 'No requests to display'
        : 'Showing 1–$shown of $total requests';
    final billLabel = compact ? 'Bill' : 'Bill selected';

    final summary = Row(
      children: [
        Checkbox(
          tristate: true,
          value: allSelected
              ? true
              : someSelected
              ? null
              : false,
          onChanged: busy ? null : onToggleAll,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Expanded(
          child: HeltyEllipsisText(
            text: loadingMore ? 'Loading more…' : label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );

    final actions = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onLoadMore != null || loadingMore)
          TextButton.icon(
            onPressed: loadingMore ? null : onLoadMore,
            icon: loadingMore
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.expand_more, size: 18),
            label: Text(loadingMore ? 'Loading' : 'Load more'),
          ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: onBill,
          icon: billing
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.onPrimary,
                  ),
                )
              : const Icon(Icons.receipt_long_outlined, size: 18),
          label: Text(billLabel),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [summary, actions],
            )
          : Row(
              children: [
                Expanded(child: summary),
                actions,
              ],
            ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeltySolidIcon(
            icon: onRetry == null
                ? Icons.medication_outlined
                : Icons.error_outline,
            color: onRetry == null ? DepartmentColors.pharmacy : cs.error,
            size: 48,
            iconSize: 26,
            radius: 12,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

class _DetailIdentity extends StatelessWidget {
  const _DetailIdentity({
    required this.request,
    required this.patientName,
    required this.hospitalNumber,
    required this.firstName,
    required this.surname,
  });

  final MedicationRequestModel request;
  final String patientName;
  final String? hospitalNumber;
  final String? firstName;
  final String? surname;

  @override
  Widget build(BuildContext context) {
    return _PatientIdentity(
      patientName: patientName,
      hospitalNumber: hospitalNumber,
      firstName: firstName,
      surname: surname,
      avatarUrl: request.patient?.avatarUrl,
      seed: _patientGroupKey(request),
      caption: 'Ward: ${request.wardDisplayLabel}',
    );
  }
}

class _QueueRail extends StatelessWidget {
  const _QueueRail({
    required this.fillHeight,
    required this.billing,
    required this.canBill,
    required this.canRefresh,
    required this.canSelect,
    required this.allSelected,
    required this.selectedCount,
    required this.wardCounts,
    required this.notes,
    required this.onBill,
    required this.onRefresh,
    required this.onToggleSelectAll,
    required this.onViewAllNotes,
  });

  final bool fillHeight;
  final bool billing;
  final bool canBill;
  final bool canRefresh;
  final bool canSelect;
  final bool allSelected;
  final int selectedCount;
  final List<_WardCount> wardCounts;
  final List<_QueueNote> notes;
  final VoidCallback onBill;
  final VoidCallback onRefresh;
  final VoidCallback onToggleSelectAll;
  final VoidCallback onViewAllNotes;

  @override
  Widget build(BuildContext context) {
    final quick = _QuickActions(
      billing: billing,
      canBill: canBill,
      canRefresh: canRefresh,
      canSelect: canSelect,
      allSelected: allSelected,
      selectedCount: selectedCount,
      onBill: onBill,
      onRefresh: onRefresh,
      onToggleSelectAll: onToggleSelectAll,
    );
    final wards = _WardCard(counts: wardCounts, expanded: fillHeight);
    final notesCard = _NotesCard(
      notes: notes,
      expanded: fillHeight,
      onViewAll: onViewAllNotes,
    );

    if (!fillHeight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          quick,
          const SizedBox(height: 10),
          wards,
          const SizedBox(height: 10),
          notesCard,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        quick,
        const SizedBox(height: 10),
        Expanded(flex: 3, child: wards),
        const SizedBox(height: 10),
        Expanded(flex: 2, child: notesCard),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.billing,
    required this.canBill,
    required this.canRefresh,
    required this.canSelect,
    required this.allSelected,
    required this.selectedCount,
    required this.onBill,
    required this.onRefresh,
    required this.onToggleSelectAll,
  });

  final bool billing;
  final bool canBill;
  final bool canRefresh;
  final bool canSelect;
  final bool allSelected;
  final int selectedCount;
  final VoidCallback onBill;
  final VoidCallback onRefresh;
  final VoidCallback onToggleSelectAll;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final billLabel = selectedCount == 0
        ? 'Bill selected'
        : 'Bill $selectedCount request${selectedCount == 1 ? '' : 's'}';
    return HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const HeltySolidIcon(
                icon: Icons.flash_on,
                color: _Accent.amber,
                size: 26,
                iconSize: 14,
                radius: 7,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RailButton(
            label: billing ? 'Billing…' : billLabel,
            icon: Icons.receipt_long_outlined,
            colors: [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.45)!],
            onPressed: canBill ? onBill : null,
          ),
          const SizedBox(height: 8),
          _RailButton(
            label: 'Refresh queue',
            icon: Icons.refresh,
            colors: [
              _Accent.green,
              Color.lerp(_Accent.green, cs.primary, 0.25)!,
            ],
            onPressed: canRefresh ? onRefresh : null,
          ),
          const SizedBox(height: 8),
          _RailButton(
            label: allSelected ? 'Clear selection' : 'Select all',
            icon: allSelected
                ? Icons.deselect_outlined
                : Icons.select_all_outlined,
            colors: [_Accent.amber, Color.lerp(_Accent.amber, cs.error, 0.15)!],
            onPressed: canSelect ? onToggleSelectAll : null,
          ),
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final cs = Theme.of(context).colorScheme;
    final paint = enabled ? colors : [cs.outlineVariant, cs.outline];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: paint),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WardCard extends StatelessWidget {
  const _WardCard({required this.counts, required this.expanded});

  final List<_WardCount> counts;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final list = counts.isEmpty
        ? Text(
            'No wards on this page.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          )
        : ListView(
            shrinkWrap: !expanded,
            physics: expanded ? null : const NeverScrollableScrollPhysics(),
            children: [
              for (final row in counts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _Accent.forSeed(row.name),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: HeltyEllipsisText(
                          text: row.name,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '${row.count}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const HeltySolidIcon(
              icon: Icons.apartment_outlined,
              color: _Accent.blue,
              size: 26,
              iconSize: 14,
              radius: 7,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Requests by ward',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (expanded) Expanded(child: list) else list,
      ],
    );

    if (!expanded) {
      return HeltySurfaceCard(padding: const EdgeInsets.all(12), child: body);
    }
    return HeltySurfaceCard(padding: const EdgeInsets.all(12), child: body);
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({
    required this.notes,
    required this.expanded,
    required this.onViewAll,
  });

  final List<_QueueNote> notes;
  final bool expanded;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final preview = notes.take(expanded ? notes.length : 5).toList();
    final feed = preview.isEmpty
        ? Text(
            'No recent activity this session.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          )
        : ListView(
            shrinkWrap: !expanded,
            physics: expanded ? null : const NeverScrollableScrollPhysics(),
            children: [
              for (final note in preview)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(note.message, style: theme.textTheme.bodySmall),
                ),
            ],
          );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const HeltySolidIcon(
              icon: Icons.notes_outlined,
              color: _Accent.teal,
              size: 26,
              iconSize: 14,
              radius: 7,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Notes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(onPressed: onViewAll, child: const Text('View all')),
          ],
        ),
        const SizedBox(height: 8),
        if (expanded) Expanded(child: feed) else feed,
      ],
    );

    return HeltySurfaceCard(padding: const EdgeInsets.all(12), child: body);
  }
}
