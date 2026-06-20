import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/medication_request_model.dart';
import 'package:helty/src/pharmacy/utils/medication_request_permissions.dart';
import 'package:helty/src/pharmacy/widgets/medication_request_edit_dialog.dart';
import 'package:helty/src/pharmacy/widgets/medication_workflow_badges.dart';
import 'package:helty/src/pharmacy/services/pharmacy_service.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/medication_order_service.dart';
import 'package:helty/src/services/medication_request_service.dart';

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
  bool _loading = true;
  bool _loadingMore = false;
  bool _billing = false;
  String? _error;
  int _total = 0;
  int _skip = 0;

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

  void _toggleRow(MedicationRequestModel request, bool? value) {
    setState(() {
      if (value == true) {
        _selectedIds.add(request.id);
      } else {
        _selectedIds.remove(request.id);
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request updated')),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request deleted')),
      );
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

    final selected = _requests.where((r) => _selectedIds.contains(r.id)).toList();
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
        lastInvoiceLabel =
            result.invoice.invoiceDisplayId ?? result.invoice.id;
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
        context.router.push(
          WaitingPatientRoute(invoiceId: lastInvoiceId),
        );
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

  String _patientLabel(MedicationRequestModel r) {
    final p = r.patient;
    if (p == null) return '—';
    final name = p.displayName.trim();
    if (p.hospitalNumber != null && p.hospitalNumber!.isNotEmpty) {
      return name.isEmpty ? p.hospitalNumber! : '$name (${p.hospitalNumber})';
    }
    return name.isEmpty ? '—' : name;
  }

  String _drugLabel(MedicationRequestModel r) {
    final order = r.medicationOrder;
    if (order == null) return '—';
    return order.currentDrugLabel;
  }

  String _prescribedDrugLabel(MedicationRequestModel r) {
    final order = r.medicationOrder;
    if (order == null) return '—';
    return order.prescribedDrugLabel;
  }

  String _requestedByLabel(MedicationRequestModel r) =>
      r.requestedByNurse?.displayName.trim() ?? '—';

  String _substitutedByLabel(MedicationRequestModel r) =>
      r.medicationOrder?.substitutedByPharmacist?.displayName.trim() ?? '—';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canLoadMore = _requests.length < _total;

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _patientFilterCtrl,
                    decoration: InputDecoration(
                      labelText: 'Patient ID filter',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _loading ? null : () => _load(reset: true),
                      ),
                    ),
                    onSubmitted: (_) => _load(reset: true),
                  ),
                ),
                Text(
                  '${_requests.length} of $_total REQUESTED',
                  style: theme.textTheme.bodySmall,
                ),
                FilledButton.icon(
                  onPressed: _billing || _selectedIds.isEmpty
                      ? null
                      : _billSelected,
                  icon: _billing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.receipt_long_outlined, size: 18),
                  label: Text(
                    _selectedIds.isEmpty
                        ? 'Bill selected'
                        : 'Bill selected (${_selectedIds.length})',
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _requests.isEmpty
                ? const Center(child: Text('No pending medication requests'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        showCheckboxColumn: true,
                        onSelectAll: _toggleSelectAll,
                        columns: [
                          const DataColumn(label: Text('Patient')),
                          const DataColumn(label: Text('Prescribing doctor')),
                          const DataColumn(label: Text('Prescribed drug')),
                          const DataColumn(label: Text('Current drug')),
                          const DataColumn(label: Text('Qty')),
                          DataColumn(
                            label: Text(
                              requestedByColumnLabel(isOpd: false),
                            ),
                          ),
                          const DataColumn(label: Text('Substituted by')),
                          const DataColumn(label: Text('Encounter')),
                          const DataColumn(label: Text('Requested')),
                          const DataColumn(label: Text('Status')),
                          const DataColumn(label: Text('Actions')),
                        ],
                        rows: _requests.map((r) {
                          final selected = _selectedIds.contains(r.id);
                          final isOpd = r.isOpdEncounter;
                          final order = r.medicationOrder;
                          final showSubstitution = order?.wasSubstituted ?? false;
                          return DataRow(
                            selected: selected,
                            onSelectChanged: (v) => _toggleRow(r, v),
                            cells: [
                              DataCell(Text(_patientLabel(r))),
                              DataCell(
                                Text(
                                  order?.doctor?.displayName.trim() ?? '—',
                                ),
                              ),
                              DataCell(
                                Text(
                                  showSubstitution
                                      ? _prescribedDrugLabel(r)
                                      : _drugLabel(r),
                                ),
                              ),
                              DataCell(
                                Text(
                                  showSubstitution ? _drugLabel(r) : '—',
                                ),
                              ),
                              DataCell(Text('${r.requestedQuantity}')),
                              DataCell(
                                Tooltip(
                                  message: isOpd
                                      ? requestedByColumnLabel(isOpd: true)
                                      : requestedByColumnLabel(isOpd: false),
                                  child: Text(_requestedByLabel(r)),
                                ),
                              ),
                              DataCell(
                                Text(
                                  order?.substitutedByPharmacist != null
                                      ? _substitutedByLabel(r)
                                      : '—',
                                ),
                              ),
                              DataCell(
                                Text(
                                  r.encounter?.encounterType ??
                                      r.encounter?.id ??
                                      r.encounterId ??
                                      '—',
                                ),
                              ),
                              DataCell(
                                Text(
                                  r.createdAt != null
                                      ? DateFormatter.dateTime(r.createdAt!)
                                      : '—',
                                ),
                              ),
                              DataCell(
                                MedicationRequestStatusBadge(status: r.status),
                              ),
                              DataCell(
                                r.isRequested
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Edit',
                                            icon: const Icon(Icons.edit_outlined),
                                            onPressed: () => _editRequest(r),
                                          ),
                                          IconButton(
                                            tooltip: 'Delete',
                                            icon: const Icon(Icons.delete_outline),
                                            onPressed: () => _deleteRequest(r),
                                          ),
                                        ],
                                      )
                                    : const Text('—'),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
          if (!_loading && canLoadMore)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
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
              ),
            ),
        ],
      ),
    );
  }
}
