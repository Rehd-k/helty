import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/admission_billing_clearance_models.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_layout_constants.dart';
import 'package:helty/src/providers/admission_clearance_providers.dart';
import 'package:helty/src/services/admission_service.dart';

const _pageSize = 20;

@RoutePage()
class AwaitingBillingClearanceScreen extends ConsumerStatefulWidget {
  const AwaitingBillingClearanceScreen({super.key});

  @override
  ConsumerState<AwaitingBillingClearanceScreen> createState() =>
      _AwaitingBillingClearanceScreenState();
}

class _AwaitingBillingClearanceScreenState
    extends ConsumerState<AwaitingBillingClearanceScreen> {
  final _admissionService = AdmissionService();
  final _searchController = TextEditingController();

  int _skip = 0;
  String? _openingInvoiceAdmissionId;
  String? _clearingAdmissionId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  PendingClearanceQuery get _query => (skip: _skip, take: _pageSize);

  void _reload() {
    ref.invalidate(pendingBillingClearanceProvider(_query));
  }

  List<PendingBillingClearanceAdmission> _filterRows(
    List<PendingBillingClearanceAdmission> rows,
  ) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((r) {
      final name = r.patientDisplayName.toLowerCase();
      final id = r.patientHospitalId.toLowerCase();
      final ward = r.wardName.toLowerCase();
      final room = (r.room ?? '').toLowerCase();
      return name.contains(q) ||
          id.contains(q) ||
          ward.contains(q) ||
          room.contains(q);
    }).toList(growable: false);
  }

  Future<void> _openBill(PendingBillingClearanceAdmission row) async {
    if (_openingInvoiceAdmissionId != null) return;

    final invoice = row.primaryInvoice;
    if (invoice == null || invoice.id.isEmpty) {
      _showSnack('No invoice linked to this admission.');
      return;
    }

    setState(() => _openingInvoiceAdmissionId = row.id);
    try {
      await context.router.push(
        PatientBillingRoute(
          invoiceId: invoice.id,
          patientName: row.patientDisplayName,
        ),
      );
      if (mounted) _reload();
    } catch (e) {
      _showSnack('Failed to open billing: $e');
    } finally {
      if (mounted) setState(() => _openingInvoiceAdmissionId = null);
    }
  }

  Future<void> _clearAdmission(PendingBillingClearanceAdmission row) async {
    if (_clearingAdmissionId != null) return;
    if (!row.billing.allPaid) {
      _showSnack('Record all payments before clearing billing.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear billing'),
        content: Text(
          'Finalize discharge for ${row.patientDisplayName}? '
          'The patient will be moved to OPD.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _clearingAdmissionId = row.id);
    try {
      await _admissionService.billingClearance(row.id);
      if (!mounted) return;
      _showSnack('Billing cleared. Patient moved to OPD.');
      _reload();
    } on BillingClearanceBlockedException catch (e) {
      if (!mounted) return;
      _showSnack(e.message);
      _reload();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Clear failed: $e');
    } finally {
      if (mounted) setState(() => _clearingAdmissionId = null);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(pendingBillingClearanceProvider(_query));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < kInpatientCompactBreakpoint;
            final pad = compact ? 16.0 : 24.0;

            return Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTitleSection(colorScheme, async, compact),
                  const SizedBox(height: 16),
                  _buildSearchBar(colorScheme, compact),
                  const SizedBox(height: 16),
                  Expanded(
                    child: async.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => _buildError(colorScheme, e),
                      data: (page) => _buildContent(
                        colorScheme,
                        page,
                        compact,
                      ),
                    ),
                  ),
                  async.maybeWhen(
                    data: (page) => _buildPagination(colorScheme, page),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTitleSection(
    ColorScheme colorScheme,
    AsyncValue<PendingBillingClearancePage> async,
    bool compact,
  ) {
    final total = async.maybeWhen(data: (p) => p.total, orElse: () => null);

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Awaiting Billing Clearance',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Clinically discharged patients with outstanding or pending bills.',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );

    final countBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fact_check_outlined, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            total == null ? 'Loading...' : '$total pending',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titleBlock, const SizedBox(height: 12), countBadge],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        countBadge,
      ],
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme, bool compact) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, patient ID, ward or room',
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme colorScheme, Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Failed to load clearance queue',
            style: TextStyle(color: colorScheme.error),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    ColorScheme colorScheme,
    PendingBillingClearancePage page,
    bool compact,
  ) {
    final rows = _filterRows(page.admissions);
    if (rows.isEmpty) {
      return Center(
        child: Text(
          page.admissions.isEmpty
              ? 'No patients awaiting billing clearance.'
              : 'No matches for your search.',
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    if (compact) {
      return RefreshIndicator(
        onRefresh: () async => _reload(),
        child: ListView.separated(
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _buildMobileCard(colorScheme, rows[index]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: _buildWideTable(colorScheme, rows),
    );
  }

  Widget _buildWideTable(
    ColorScheme colorScheme,
    List<PendingBillingClearanceAdmission> rows,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.02),
            ),
            child: const Row(
              children: [
                _HeaderCell('PATIENT', flex: 3),
                _HeaderCell('WARD', flex: 2),
                _HeaderCell('ROOM', flex: 1),
                _HeaderCell('DISCHARGED', flex: 2),
                _HeaderCell('OUTCOME', flex: 2),
                _HeaderCell('DOCTOR', flex: 2),
                _HeaderCell('BALANCE', flex: 2, alignRight: true),
                _HeaderCell('ACTIONS', flex: 3, alignRight: true),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.06),
              ),
              itemBuilder: (context, index) {
                final row = rows[index];
                return _buildWideRow(colorScheme, row);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideRow(
    ColorScheme colorScheme,
    PendingBillingClearanceAdmission row,
  ) {
    final balance = row.billing.totalBalance;
    final isOpening = _openingInvoiceAdmissionId == row.id;
    final isClearing = _clearingAdmissionId == row.id;
    final canClear = row.billing.allPaid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.patientDisplayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  row.patientHospitalId,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(row.wardName.isEmpty ? '—' : row.wardName),
          ),
          Expanded(
            flex: 1,
            child: Text(row.room?.trim().isNotEmpty == true ? row.room! : '—'),
          ),
          Expanded(
            flex: 2,
            child: Text(
              row.dischargeDateTime != null
                  ? DateFormatter.dateTime(row.dischargeDateTime!)
                  : '—',
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(row.outcome ?? '—', overflow: TextOverflow.ellipsis),
          ),
          Expanded(flex: 2, child: Text(row.attendingDoctorName)),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                balance.toFinancial(isMoney: true),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: balance > 0 ? colorScheme.error : colorScheme.primary,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.end,
                children: [
                  TextButton(
                    onPressed: isOpening ? null : () => _openBill(row),
                    child: isOpening
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('View bill'),
                  ),
                  FilledButton(
                    onPressed: (!canClear || isClearing)
                        ? null
                        : () => _clearAdmission(row),
                    child: isClearing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Clear'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCard(
    ColorScheme colorScheme,
    PendingBillingClearanceAdmission row,
  ) {
    final balance = row.billing.totalBalance;
    final isOpening = _openingInvoiceAdmissionId == row.id;
    final isClearing = _clearingAdmissionId == row.id;
    final canClear = row.billing.allPaid;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.patientDisplayName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            Text(
              row.patientHospitalId,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text('${row.wardName} · ${row.room ?? '—'}'),
            if (row.dischargeDateTime != null)
              Text(
                'Discharged ${DateFormatter.dateTime(row.dischargeDateTime!)}',
              ),
            Text('Balance: ${balance.toFinancial(isMoney: true)}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isOpening ? null : () => _openBill(row),
                    child: const Text('View bill'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: (!canClear || isClearing)
                        ? null
                        : () => _clearAdmission(row),
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(
    ColorScheme colorScheme,
    PendingBillingClearancePage page,
  ) {
    final hasPrev = _skip > 0;
    final hasNext = _skip + page.take < page.total;
    if (!hasPrev && !hasNext) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: hasPrev
                ? () => setState(() {
                    _skip = (_skip - _pageSize).clamp(0, page.total);
                  })
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
          const SizedBox(width: 16),
          Text(
            '${_skip + 1}–${(_skip + page.admissions.length).clamp(0, page.total)} of ${page.total}',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: hasNext
                ? () => setState(() => _skip += _pageSize)
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(
    this.label, {
    this.flex = 1,
    this.alignRight = false,
  });

  final String label;
  final int flex;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Theme.of(context).colorScheme.onSurface.withValues(
              alpha: 0.55,
            ),
          ),
        ),
      ),
    );
  }
}
