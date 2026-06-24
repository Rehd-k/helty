import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/medication_request_model.dart';
import 'package:helty/src/pharmacy/widgets/medication_attribution_widgets.dart';
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

  String _patientInitials(MedicationRequestModel r) {
    final p = r.patient;
    if (p == null) return '?';
    final first = p.firstName.trim();
    final last = p.surname.trim();
    final a = first.isNotEmpty ? first[0].toUpperCase() : '';
    final b = last.isNotEmpty ? last[0].toUpperCase() : '';
    final initials = '$a$b';
    return initials.isEmpty ? '?' : initials;
  }

  String _patientLabel(MedicationRequestModel r) {
    final p = r.patient;
    if (p == null) return 'Unknown patient';
    final name = p.displayName.trim();
    return name.isEmpty ? 'Unknown patient' : name;
  }

  String? _patientHospitalNumber(MedicationRequestModel r) =>
      r.patient?.hospitalNumber?.trim();

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(theme, colorScheme, allSelected, someSelected),
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

  Widget _buildToolbar(
    ThemeData theme,
    ColorScheme colorScheme,
    bool allSelected,
    bool someSelected,
  ) {
    return Material(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              'Nurse-submitted requests awaiting pharmacy billing will appear here.',
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
      separatorBuilder: (_, __) => const SizedBox(height: 10),
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
              label: Text(_loadingMore ? 'Loading…' : 'Load more'),
            ),
          );
        }
        final request = _requests[index];
        return _MedicationRequestCard(
          request: request,
          selected: _selectedIds.contains(request.id),
          patientInitials: _patientInitials(request),
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
    required this.patientInitials,
    required this.patientName,
    required this.hospitalNumber,
    required this.onToggleSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final MedicationRequestModel request;
  final bool selected;
  final String patientInitials;
  final String patientName;
  final String? hospitalNumber;
  final VoidCallback onToggleSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final order = request.medicationOrder;
    final encounter = request.encounter;
    final isOpd = request.isOpdEncounter;
    final showSubstitution = order?.wasSubstituted ?? false;
    final drugLabel = showSubstitution
        ? order!.currentDrugLabel
        : (order?.currentDrugLabel ?? '—');
    final createdAt = request.createdAt;
    final relativeTime = createdAt != null
        ? DateFormatter.relativeTimeAgo(createdAt.toLocal())
        : null;

    return Material(
      elevation: selected ? 2 : 0,
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.18)
          : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: selected ? 1.5 : 1,
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
                width: 4,
                color: selected
                    ? colorScheme.primary
                    : medicationRequestStatusColor(
                        context,
                        request.status,
                      ).withValues(alpha: 0.6),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, colorScheme, relativeTime),
                      const SizedBox(height: 8),
                      PrescribingDoctorLine(
                        name: order?.doctor?.displayName,
                      ),
                      const SizedBox(height: 12),
                      _buildDrugSection(context, colorScheme, drugLabel, order),
                      if (order != null &&
                          order.prescriptionDetailLine.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildPrescriptionChips(context, colorScheme, order),
                      ],
                      const SizedBox(height: 12),
                      _buildRequestQuantityBanner(context, colorScheme),
                      if (request.notes != null &&
                          request.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildNotes(context, colorScheme),
                      ],
                      if (order?.specialInstructions != null &&
                          order!.specialInstructions!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildSpecialInstructions(context, colorScheme, order),
                      ],
                      const SizedBox(height: 12),
                      Divider(
                        height: 1,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildFooter(context, colorScheme, isOpd, encounter),
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

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    String? relativeTime,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: selected,
          onChanged: (_) => onToggleSelect(),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        CircleAvatar(
          radius: 20,
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            patientInitials,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colorScheme.onPrimaryContainer,
              fontSize: 14,
            ),
          ),
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
                  fontSize: 15,
                ),
              ),
              if (hospitalNumber != null && hospitalNumber!.isNotEmpty)
                Text(
                  hospitalNumber!,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            MedicationRequestStatusBadge(status: request.status),
            if (relativeTime != null) ...[
              const SizedBox(height: 4),
              Text(
                relativeTime,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDrugSection(
    BuildContext context,
    ColorScheme colorScheme,
    String drugLabel,
    MedicationRequestOrderSummary? order,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.medication_liquid_outlined,
            size: 22,
            color: colorScheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                drugLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              if (order != null && order.wasSubstituted) ...[
                const SizedBox(height: 4),
                MedicationSubstitutionSummary(
                  prescribedDrug: order.prescribedDrugLabel,
                  currentDrug: order.currentDrugLabel,
                  compact: true,
                ),
              ] else if (order?.orderStatus != null &&
                  order!.orderStatus!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                MedicationOrderStatusBadge(status: order.orderStatus!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionChips(
    BuildContext context,
    ColorScheme colorScheme,
    MedicationRequestOrderSummary order,
  ) {
    final chips = <({String label, String value})>[
      if (order.dose != null && order.dose!.trim().isNotEmpty)
        (label: 'Dose', value: order.dose!.trim()),
      if (order.frequency != null && order.frequency!.trim().isNotEmpty)
        (label: 'Frequency', value: order.frequency!.trim()),
      if (order.duration != null && order.duration!.trim().isNotEmpty)
        (label: 'Duration', value: order.duration!.trim()),
      if (order.route != null && order.route!.trim().isNotEmpty)
        (label: 'Route', value: order.route!.trim()),
      if (order.quantity != null && order.quantity! > 0)
        (label: 'Course qty', value: '${order.quantity}'),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips
          .map(
            (c) => _DetailChip(
              label: c.label,
              value: c.value,
              colorScheme: colorScheme,
            ),
          )
          .toList(),
    );
  }

  Widget _buildRequestQuantityBanner(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quantity to bill',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
                Text(
                  '${request.requestedQuantity} unit${request.requestedQuantity == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          if (request.medicationOrder?.quantity != null &&
              request.medicationOrder!.quantity! > 0 &&
              request.medicationOrder!.quantity != request.requestedQuantity)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Full course',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
                Text(
                  '${request.medicationOrder!.quantity}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNotes(BuildContext context, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.notes_outlined,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            request.notes!.trim(),
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialInstructions(
    BuildContext context,
    ColorScheme colorScheme,
    MedicationRequestOrderSummary order,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              order.specialInstructions!.trim(),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    ColorScheme colorScheme,
    bool isOpd,
    MedicationRequestEncounterRef? encounter,
  ) {
    final order = request.medicationOrder;
    final createdAt = request.createdAt;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (encounter != null)
                    _EncounterChip(
                      label: encounter.typeLabel,
                      status: encounter.status,
                      colorScheme: colorScheme,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              MedicationStaffAttributionColumn(
                prescribingDoctor: order?.doctor?.displayName,
                requestedBy: request.requestedByNurse?.displayName,
                substitutedBy: order?.substitutedByPharmacist?.displayName,
                substitutedAt: order?.substitutedAt,
                isOpd: false,
                compact: true,
                excludePrescribingDoctor: true,
              ),
              if (createdAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Requested ${DateFormatter.dateTime(createdAt.toLocal())}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (request.isRequested)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                tooltip: 'Edit request',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Delete request',
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 11, color: colorScheme.onSurface),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
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
