import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/core/widgets/patient_avatar.dart';
import 'package:helty/src/models/medication_request_model.dart';
import 'package:helty/src/pharmacy/widgets/medication_attribution_widgets.dart';
import 'package:helty/src/pharmacy/widgets/medication_request_edit_dialog.dart';
import 'package:helty/src/pharmacy/widgets/medication_workflow_badges.dart';
import 'package:helty/src/pharmacy/services/pharmacy_service.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/medication_order_service.dart';
import 'package:helty/src/services/medication_request_service.dart';
import 'package:intl/intl.dart';

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

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
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
    switch (quickRange) {
      case _QuickRange.today:
        _from = _startOfDay(now);
        _to = _endOfDay(now);
        break;
      case _QuickRange.last7:
        _from = _startOfDay(now.subtract(const Duration(days: 6)));
        _to = _endOfDay(now);
        break;
      case _QuickRange.thisMonth:
        _from = DateTime(now.year, now.month, 1);
        _to = _endOfDay(now);
        break;
    }
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canLoadMore = _requests.length < _total;
    final allSelected =
        _requests.isNotEmpty && _selectedIds.length == _requests.length;
    final someSelected =
        _selectedIds.isNotEmpty && _selectedIds.length < _requests.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Requests'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading || _billing ? null : () => _load(reset: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildToolbar(theme, colorScheme, allSelected, someSelected, bp),
          if (_error != null) _buildErrorBanner(colorScheme),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _requests.isEmpty
                ? _buildEmptyState(colorScheme)
                : _buildRequestList(colorScheme, canLoadMore),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildToolbar(
    ThemeData theme,
    ColorScheme colorScheme,
    bool allSelected,
    bool someSelected,
    AppBreakpoints bp,
  ) {
    return Material(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _loading || _billing ? null : _pickDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    '${DateFormat('dd MMM yyyy').format(_from)} - ${DateFormat('dd MMM yyyy').format(_to)}',
                  ),
                ),
                FilledButton.tonal(
                  onPressed: _loading || _billing
                      ? null
                      : () => _applyQuickRange(_QuickRange.today),
                  child: const Text('Today'),
                ),
                FilledButton.tonal(
                  onPressed: _loading || _billing
                      ? null
                      : () => _applyQuickRange(_QuickRange.last7),
                  child: const Text('Last 7 days'),
                ),
                FilledButton.tonal(
                  onPressed: _loading || _billing
                      ? null
                      : () => _applyQuickRange(_QuickRange.thisMonth),
                  child: const Text('This month'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<_RequestListMode>(
                segments: const [
                  ButtonSegment<_RequestListMode>(
                    value: _RequestListMode.time,
                    label: Text('Time'),
                    icon: Icon(Icons.schedule, size: 18),
                  ),
                  ButtonSegment<_RequestListMode>(
                    value: _RequestListMode.patient,
                    label: Text('Patient'),
                    icon: Icon(Icons.person_outline, size: 18),
                  ),
                ],
                selected: {_listMode},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) return;
                  setState(() {
                    _listMode = selection.first;
                    if (selection.first == _RequestListMode.patient) {
                      _expandedPatientGroupKeys.clear();
                    }
                  });
                },
                showSelectedIcon: false,
              ),
            ),
            const SizedBox(height: 10),
            if (bp.stackPanels)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _patientFilterCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by patient hospital number…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _load(reset: true),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton.filledTonal(
                      tooltip: 'Search',
                      onPressed: _loading ? null : () => _load(reset: true),
                      icon: const Icon(Icons.arrow_forward, size: 20),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _patientFilterCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search by patient hospital number…',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _load(reset: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Search',
                    onPressed: _loading ? null : () => _load(reset: true),
                    icon: const Icon(Icons.arrow_forward, size: 20),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (_requests.isNotEmpty)
                  FilterChip(
                    label: Text(allSelected ? 'Deselect all' : 'Select all'),
                    avatar: Checkbox(
                      tristate: true,
                      value: allSelected
                          ? true
                          : someSelected
                          ? null
                          : false,
                      onChanged: _loading || _billing ? null : _toggleSelectAll,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    onSelected: _loading || _billing
                        ? null
                        : (_) => _toggleSelectAll(allSelected ? false : true),
                  ),
                _SummaryChip(
                  icon: Icons.pending_actions_outlined,
                  label: '$_total pending',
                  color: colorScheme.primary,
                ),
                if (_selectedIds.isNotEmpty)
                  _SummaryChip(
                    icon: Icons.check_circle_outline,
                    label: '${_selectedIds.length} selected',
                    color: colorScheme.tertiary,
                  ),
                FilledButton.icon(
                  onPressed: _billing || _selectedIds.isEmpty
                      ? null
                      : _billSelected,
                  icon: _billing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.receipt_long_outlined, size: 18),
                  label: Text(
                    _selectedIds.isEmpty
                        ? 'Bill selected'
                        : 'Bill ${_selectedIds.length} request${_selectedIds.length == 1 ? '' : 's'}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _load(reset: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 56,
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No pending medication requests',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Nurse-submitted requests awaiting pharmacy billing will appear here for the selected date range.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList(ColorScheme colorScheme, bool canLoadMore) {
    final entries = _buildListEntries();
    final showPatientHeader = _listMode == _RequestListMode.time;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: entries.length + (canLoadMore ? 1 : 0),
      separatorBuilder: (context, index) {
        if (index >= entries.length - 1) {
          return const SizedBox(height: 6);
        }
        final current = entries[index];
        final next = entries[index + 1];
        if (current.kind == _RequestListEntryKind.header ||
            next.kind == _RequestListEntryKind.header) {
          return const SizedBox(height: 10);
        }
        return const SizedBox(height: 6);
      },
      itemBuilder: (context, index) {
        if (index >= entries.length) {
          return Center(
            child: OutlinedButton.icon(
              onPressed: _loadingMore ? null : () => _load(reset: false),
              icon: _loadingMore
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more),
              label: Text(_loadingMore ? 'Loading…' : 'Load more'),
            ),
          );
        }

        final entry = entries[index];
        if (entry.kind == _RequestListEntryKind.header) {
          final group = entry.group!;
          final isExpanded = _expandedPatientGroupKeys.contains(group.key);
          return _PatientGroupHeader(
            firstName: group.firstName,
            surname: group.surname,
            avatarUrl: group.avatarUrl,
            patientName: group.patientName,
            hospitalNumber: group.hospitalNumber,
            requestCount: group.requests.length,
            colorScheme: colorScheme,
            isExpanded: isExpanded,
            onToggle: () {
              setState(() {
                if (isExpanded) {
                  _expandedPatientGroupKeys.remove(group.key);
                } else {
                  _expandedPatientGroupKeys.add(group.key);
                }
              });
            },
          );
        }

        final request = entry.request!;
        return _MedicationRequestCard(
          request: request,
          selected: _selectedIds.contains(request.id),
          showPatientHeader: showPatientHeader,
          firstName: _patientFirstName(request),
          surname: _patientSurname(request),
          avatarUrl: request.patient?.avatarUrl,
          patientName: _patientLabel(request),
          hospitalNumber: _patientHospitalNumber(request),
          onToggleSelect: () => _toggleRow(request),
          onEdit: () => _editRequest(request),
          onDelete: () => _deleteRequest(request),
        );
      },
    );
  }
}

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _endOfDay(DateTime d) =>
    DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

class _PatientGroupHeader extends StatelessWidget {
  const _PatientGroupHeader({
    required this.firstName,
    required this.surname,
    this.avatarUrl,
    required this.patientName,
    required this.hospitalNumber,
    required this.requestCount,
    required this.colorScheme,
    required this.isExpanded,
    required this.onToggle,
  });

  final String? firstName;
  final String? surname;
  final String? avatarUrl;
  final String patientName;
  final String? hospitalNumber;
  final int requestCount;
  final ColorScheme colorScheme;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              PatientAvatar(
                avatarUrl: avatarUrl,
                firstName: firstName,
                surname: surname,
                displayName: patientName,
                size: 32,
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hospitalNumber != null && hospitalNumber!.isNotEmpty)
                      Text(
                        hospitalNumber!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      '$requestCount request${requestCount == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationRequestCard extends StatelessWidget {
  const _MedicationRequestCard({
    required this.request,
    required this.selected,
    this.showPatientHeader = true,
    required this.firstName,
    required this.surname,
    this.avatarUrl,
    required this.patientName,
    required this.hospitalNumber,
    required this.onToggleSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final MedicationRequestModel request;
  final bool selected;
  final bool showPatientHeader;
  final String? firstName;
  final String? surname;
  final String? avatarUrl;
  final String patientName;
  final String? hospitalNumber;
  final VoidCallback onToggleSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _metaStyle = TextStyle(fontSize: 11, height: 1.25);
  static const _labelStyle = TextStyle(
    fontSize: 11,
    height: 1.25,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final order = request.medicationOrder;
    final encounter = request.encounter;
    final drugLabel = order?.currentDrugLabel ?? '—';
    final createdAt = request.createdAt;
    final relativeTime = createdAt != null
        ? DateFormatter.relativeTimeAgo(createdAt.toLocal())
        : null;
    final prescriptionLine = _prescriptionLine(order);
    final hasNotes = request.notes?.trim().isNotEmpty ?? false;
    final hasSpecialInstructions =
        order?.specialInstructions?.trim().isNotEmpty ?? false;
    final courseQty = order?.quantity;
    final showCourseQty =
        courseQty != null &&
        courseQty > 0 &&
        courseQty != request.requestedQuantity;

    return Material(
      elevation: selected ? 1 : 0,
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.15)
          : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.45)
              : colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggleSelect,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 3,
                color: selected
                    ? colorScheme.primary
                    : medicationRequestStatusColor(
                        context,
                        request.status,
                      ).withValues(alpha: 0.55),
              ),
              Checkbox(
                value: selected,
                onChanged: (_) => onToggleSelect(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopRow(context, colorScheme),
                      const SizedBox(height: 4),
                      _buildDrugRow(context, colorScheme, drugLabel, order),
                      if (order != null && order.wasSubstituted) ...[
                        const SizedBox(height: 3),
                        MedicationSubstitutionSummary(
                          prescribedDrug: order.prescribedDrugLabel,
                          currentDrug: order.currentDrugLabel,
                          compact: true,
                        ),
                      ],
                      if (prescriptionLine != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          prescriptionLine,
                          style: _metaStyle.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildBillQtyChip(
                            context,
                            colorScheme,
                            showCourseQty,
                          ),
                          if (encounter != null)
                            _EncounterChip(
                              label: encounter.typeLabel,
                              status: encounter.status,
                              colorScheme: colorScheme,
                            ),
                          if (relativeTime != null)
                            Text(
                              relativeTime,
                              style: _metaStyle.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildStaffLine(context, colorScheme, order),
                      if (createdAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Requested ${DateFormatter.dateTime(createdAt.toLocal())}',
                          style: _metaStyle.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (hasNotes) ...[
                        const SizedBox(height: 4),
                        _buildAnnotationRow(
                          context,
                          icon: Icons.notes_outlined,
                          text: request.notes!.trim(),
                          color: colorScheme.onSurfaceVariant,
                          background: null,
                        ),
                      ],
                      if (hasSpecialInstructions) ...[
                        const SizedBox(height: 4),
                        _buildAnnotationRow(
                          context,
                          icon: Icons.info_outline,
                          text: order!.specialInstructions!.trim(),
                          color: colorScheme.onTertiaryContainer,
                          background: colorScheme.tertiaryContainer.withValues(
                            alpha: 0.28,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(BuildContext context, ColorScheme colorScheme) {
    if (!showPatientHeader) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          MedicationRequestStatusBadge(status: request.status),
          if (request.isRequested) ...[
            IconButton(
              tooltip: 'Edit request',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              tooltip: 'Delete request',
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline,
                size: 18,
                color: colorScheme.error,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PatientAvatar(
          avatarUrl: avatarUrl,
          firstName: firstName,
          surname: surname,
          displayName: patientName,
          size: 26,
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patientName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (hospitalNumber != null && hospitalNumber!.isNotEmpty)
                Text(
                  hospitalNumber!,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        MedicationRequestStatusBadge(status: request.status),
        if (request.isRequested) ...[
          IconButton(
            tooltip: 'Edit request',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            tooltip: 'Delete request',
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: colorScheme.error,
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ],
    );
  }

  Widget _buildDrugRow(
    BuildContext context,
    ColorScheme colorScheme,
    String drugLabel,
    MedicationRequestOrderSummary? order,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.medication_liquid_outlined,
          size: 16,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            drugLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (order?.orderStatus != null &&
            order!.orderStatus!.trim().isNotEmpty &&
            !order.wasSubstituted)
          MedicationOrderStatusBadge(status: order.orderStatus!),
      ],
    );
  }

  Widget _buildBillQtyChip(
    BuildContext context,
    ColorScheme colorScheme,
    bool showCourseQty,
  ) {
    final order = request.medicationOrder;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onPrimaryContainer,
            height: 1.2,
          ),
          children: [
            const TextSpan(
              text: 'Bill qty ',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text:
                  '${request.requestedQuantity} unit${request.requestedQuantity == 1 ? '' : 's'}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            if (showCourseQty)
              TextSpan(
                text: ' · course ${order!.quantity}',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.75),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffLine(
    BuildContext context,
    ColorScheme colorScheme,
    MedicationRequestOrderSummary? order,
  ) {
    final doctor = order?.doctor?.displayName.trim();
    final nurse = request.requestedByNurse?.displayName.trim();
    final substitutedBy = order?.substitutedByPharmacist?.displayName.trim();
    final substitutedAt = order?.substitutedAt;

    final parts = <InlineSpan>[];
    void addPart(String label, String? value) {
      if (value == null || value.isEmpty) return;
      if (parts.isNotEmpty) {
        parts.add(
          TextSpan(
            text: ' · ',
            style: _metaStyle.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        );
      }
      parts.add(TextSpan(text: '$label: ', style: _labelStyle));
      parts.add(TextSpan(text: value, style: _metaStyle));
    }

    addPart('Dr', doctor);
    addPart('Req', nurse);
    if (substitutedBy != null && substitutedBy.isNotEmpty) {
      addPart('Sub', substitutedBy);
      if (substitutedAt != null) {
        parts.add(
          TextSpan(
            text:
                ' (${DateFormatter.relativeTimeAgo(substitutedAt.toLocal())})',
            style: _metaStyle.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        );
      }
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: _metaStyle.copyWith(color: colorScheme.onSurface),
        children: parts,
      ),
    );
  }

  String? _prescriptionLine(MedicationRequestOrderSummary? order) {
    if (order == null) return null;
    final segments = <String>[
      if (order.dose != null && order.dose!.trim().isNotEmpty)
        'Dose ${order.dose!.trim()}',
      if (order.frequency != null && order.frequency!.trim().isNotEmpty)
        'Freq ${order.frequency!.trim()}',
      if (order.duration != null && order.duration!.trim().isNotEmpty)
        'Dur ${order.duration!.trim()}',
      if (order.route != null && order.route!.trim().isNotEmpty)
        'Route ${order.route!.trim()}',
      if (order.quantity != null && order.quantity! > 0)
        'Course ${order.quantity}',
    ];
    if (segments.isEmpty) return null;
    return segments.join(' · ');
  }

  Widget _buildAnnotationRow(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
    Color? background,
  }) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: color, height: 1.25),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (background == null) return content;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: content,
    );
  }
}

class _EncounterChip extends StatelessWidget {
  const _EncounterChip({
    required this.label,
    required this.colorScheme,
    this.status,
  });

  final String label;
  final String? status;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final statusLabel = status?.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusLabel != null && statusLabel.isNotEmpty
            ? '$label · $statusLabel'
            : label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
