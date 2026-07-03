import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/pharmacy/models/pharmacy_refill_models.dart';
import 'package:helty/src/pharmacy/services/pharmacy_refill_service.dart';
import 'package:helty/src/pharmacy/widgets/medication_workflow_badges.dart';
import 'package:helty/src/pharmacy/widgets/pharmacy_refill_bill_dialog.dart';
import 'package:helty/src/pharmacy/widgets/pharmacy_refill_review_dialog.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:intl/intl.dart';

enum _QuickRange { today, last7, thisMonth }

@RoutePage()
class PharmacyRefillRequestsScreen extends ConsumerStatefulWidget {
  const PharmacyRefillRequestsScreen({super.key});

  @override
  ConsumerState<PharmacyRefillRequestsScreen> createState() =>
      _PharmacyRefillRequestsScreenState();
}

class _PharmacyRefillRequestsScreenState
    extends ConsumerState<PharmacyRefillRequestsScreen> {
  static const int _pageSize = 20;

  final _service = PharmacyRefillService();
  final _patientFilterCtrl = TextEditingController();

  List<PrescriptionRefillRequest> _requests = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _working = false;
  String? _error;
  int _total = 0;
  int _skip = 0;
  RefillRequestStatus _status = RefillRequestStatus.pending;
  DateTime _from = _startOfDay(DateTime.now());
  DateTime _to = _endOfDay(DateTime.now());

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
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final patientQuery = _patientFilterCtrl.text.trim();
      final page = await _service.list(
        status: _status,
        patientId: patientQuery.isEmpty ? null : patientQuery,
        fromDate: _from,
        toDate: _to,
        skip: reset ? 0 : _skip,
        take: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _requests = page.data;
          _skip = page.data.length;
        } else {
          _requests = [..._requests, ...page.data];
          _skip += page.data.length;
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

  String? _requireStaffId() {
    final staffId = ref.read(authProvider).staff?.id;
    if (staffId == null || staffId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in as pharmacy staff')),
      );
      return null;
    }
    return staffId;
  }

  void _replaceRequest(PrescriptionRefillRequest updated) {
    final idx = _requests.indexWhere((r) => r.id == updated.id);
    if (idx < 0) return;
    setState(() {
      // Drop rows that no longer match the active status filter.
      if (updated.status != _status) {
        _requests.removeAt(idx);
      } else {
        _requests[idx] = updated;
      }
    });
  }

  Future<void> _review(
    PrescriptionRefillRequest request, {
    required bool approve,
  }) async {
    final staffId = _requireStaffId();
    if (staffId == null) return;

    final updated = await showPharmacyRefillReviewDialog(
      context,
      request: request,
      service: _service,
      reviewedByStaffId: staffId,
      approve: approve,
    );
    if (updated == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(approve ? 'Refill approved' : 'Refill rejected')),
    );
    _replaceRequest(updated);
  }

  Future<void> _bill(PrescriptionRefillRequest request) async {
    final staffId = _requireStaffId();
    if (staffId == null) return;

    final result = await showPharmacyRefillBillDialog(
      context,
      request: request,
      service: _service,
      billedByStaffId: staffId,
    );
    if (result == null || !mounted) return;

    final label = result.invoice.invoiceDisplayId ?? result.invoice.id;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Billed to invoice $label — opening dispense queue')),
    );
    await _load(reset: true);

    final invoiceId = result.invoice.id;
    if (invoiceId.isNotEmpty && mounted) {
      context.router.push(WaitingPatientRoute(invoiceId: invoiceId));
    }
  }

  void _openMedicineSales(PrescriptionRefillRequest request) {
    final patient = request.patient;
    if (patient == null) return;
    final staffId = ref.read(authProvider).staff?.id ?? '';
    context.router.push(
      DispenseRoute(
        patientId: patient.patientId ?? '',
        patientName: patient.displayName,
        id: patient.id,
        staffId: staffId.isEmpty ? null : staffId,
      ),
    );
  }

  Future<void> _confirmRefill(PrescriptionRefillRequest request) async {
    final staffId = _requireStaffId();
    if (staffId == null) return;

    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm refill fulfilled?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mark this refill as fulfilled after billing and dispensing '
              'through Medicine Sales. The patient app supply will update.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    final notes = notesCtrl.text;
    notesCtrl.dispose();
    if (confirmed != true) return;

    setState(() => _working = true);
    try {
      final updated = await _service.markFulfilled(
        id: request.id,
        reviewedByStaffId: staffId,
        pharmacyNotes: notes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refill marked fulfilled')),
      );
      _replaceRequest(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
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
        _from = _startOfDay(DateTime(now.year, now.month, 1));
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Refill Requests'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading || _working ? null : () => _load(reset: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(theme, colorScheme),
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
    );
  }

  Widget _buildToolbar(ThemeData theme, ColorScheme colorScheme) {
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
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<RefillRequestStatus>(
                    initialValue: _status,
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: [
                      for (final status in RefillRequestStatus.values)
                        DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                    ],
                    onChanged: _loading || _working
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => _status = value);
                            _load(reset: true);
                          },
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _loading || _working ? null : _pickDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    '${DateFormat('dd MMM yyyy').format(_from)} - ${DateFormat('dd MMM yyyy').format(_to)}',
                  ),
                ),
                FilledButton.tonal(
                  onPressed: _loading || _working
                      ? null
                      : () => _applyQuickRange(_QuickRange.today),
                  child: const Text('Today'),
                ),
                FilledButton.tonal(
                  onPressed: _loading || _working
                      ? null
                      : () => _applyQuickRange(_QuickRange.last7),
                  child: const Text('Last 7 days'),
                ),
                FilledButton.tonal(
                  onPressed: _loading || _working
                      ? null
                      : () => _applyQuickRange(_QuickRange.thisMonth),
                  child: const Text('This month'),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
            Align(
              alignment: Alignment.centerLeft,
              child: _SummaryChip(
                icon: Icons.autorenew_outlined,
                label: '$_total ${_status.label.toLowerCase()}',
                color: colorScheme.primary,
              ),
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
              Icons.autorenew_outlined,
              size: 56,
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${_status.label.toLowerCase()} refill requests',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Patient-initiated refill requests for the selected date range will appear here.',
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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: _requests.length + (canLoadMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        if (index >= _requests.length) {
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
              label: const Text('Load more'),
            ),
          );
        }
        return _RefillRequestCard(
          request: _requests[index],
          working: _working,
          onApprove: () => _review(_requests[index], approve: true),
          onReject: () => _review(_requests[index], approve: false),
          onBill: () => _bill(_requests[index]),
          onMedicineSales: () => _openMedicineSales(_requests[index]),
          onConfirmRefill: () => _confirmRefill(_requests[index]),
          onOpenDispense: () {
            final invoiceId = _requests[index].invoiceItem?.invoiceId;
            if (invoiceId != null && invoiceId.isNotEmpty) {
              context.router.push(WaitingPatientRoute(invoiceId: invoiceId));
            }
          },
        );
      },
    );
  }
}

class _RefillRequestCard extends StatelessWidget {
  const _RefillRequestCard({
    required this.request,
    required this.working,
    required this.onApprove,
    required this.onReject,
    required this.onBill,
    required this.onMedicineSales,
    required this.onConfirmRefill,
    required this.onOpenDispense,
  });

  final PrescriptionRefillRequest request;
  final bool working;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onBill;
  final VoidCallback onMedicineSales;
  final VoidCallback onConfirmRefill;
  final VoidCallback onOpenDispense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final prescription = request.prescription;
    final item = prescription?.firstItem;
    final drugName = prescription?.drug ??
        item?.drug?.displayName ??
        'Prescription';
    final patient = request.patient;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient?.displayName ?? 'Unknown patient',
                        style: theme.textTheme.titleMedium,
                      ),
                      if (patient?.patientId != null)
                        Text(
                          patient!.patientId!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                RefillRequestStatusBadge(status: request.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(drugName, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (item?.dosage != null)
                  _MetaLabel(icon: Icons.straighten, text: item!.dosage!),
                if (item?.frequency != null)
                  _MetaLabel(icon: Icons.schedule, text: item!.frequency!),
                if (request.refillsRemaining != null)
                  _MetaLabel(
                    icon: Icons.replay,
                    text: '${request.refillsRemaining} refills left',
                  ),
                if (prescription?.doctor?.displayName != null)
                  _MetaLabel(
                    icon: Icons.person_outline,
                    text: 'Dr. ${prescription!.doctor!.displayName}',
                  ),
                if (request.createdAt != null)
                  _MetaLabel(
                    icon: Icons.event,
                    text: DateFormatter.dateTime(request.createdAt!),
                  ),
              ],
            ),
            if (request.notes != null && request.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        request.notes!.trim(),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final actions = <Widget>[];

    switch (request.status) {
      case RefillRequestStatus.pending:
        actions.addAll([
          FilledButton.icon(
            onPressed: working ? null : onApprove,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Approve'),
          ),
          OutlinedButton.icon(
            onPressed: working ? null : onReject,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Reject'),
          ),
        ]);
        break;
      case RefillRequestStatus.approved:
        if (request.isBilled) {
          actions.add(
            FilledButton.icon(
              onPressed: working ? null : onOpenDispense,
              icon: const Icon(Icons.local_pharmacy_outlined, size: 18),
              label: const Text('Open dispense queue'),
            ),
          );
        } else {
          actions.addAll([
            FilledButton.icon(
              onPressed: working ? null : onBill,
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text('Bill'),
            ),
            OutlinedButton.icon(
              onPressed: working ? null : onMedicineSales,
              icon: const Icon(Icons.point_of_sale_outlined, size: 18),
              label: const Text('Medicine Sales'),
            ),
          ]);
        }
        actions.add(
          TextButton.icon(
            onPressed: working ? null : onConfirmRefill,
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Confirm refill'),
          ),
        );
        break;
      case RefillRequestStatus.rejected:
      case RefillRequestStatus.fulfilled:
      case RefillRequestStatus.cancelled:
        break;
    }

    if (actions.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 8, children: actions);
  }
}

class _MetaLabel extends StatelessWidget {
  const _MetaLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.bodySmall),
      ],
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
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _endOfDay(DateTime d) =>
    DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
