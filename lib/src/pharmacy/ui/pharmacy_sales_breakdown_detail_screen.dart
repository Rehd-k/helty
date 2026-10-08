import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/pharmacy/widgets/pharmacy_page_chrome.dart';
import 'package:helty/src/shared/department_colors.dart';
import 'package:helty/src/widgets/helty_surface.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../providers/super_admin_preview_provider.dart';
import '../auth/pharmacy_permissions.dart';
import '../models/pharmacy_reports_model.dart';
import '../services/pharmacy_reports_service.dart';

@RoutePage()
class PharmacySalesBreakdownDetailScreen extends ConsumerStatefulWidget {
  const PharmacySalesBreakdownDetailScreen({
    super.key,
    required this.groupBy,
    required this.groupKey,
    required this.groupLabel,
    required this.fromDate,
    required this.toDate,
    this.storeId,
    this.payerType,
  });

  final PharmacySalesGroupBy groupBy;
  final String groupKey;
  final String groupLabel;
  final DateTime fromDate;
  final DateTime toDate;
  final String? storeId;
  final String? payerType;

  @override
  ConsumerState<PharmacySalesBreakdownDetailScreen> createState() =>
      _PharmacySalesBreakdownDetailScreenState();
}

class _PharmacySalesBreakdownDetailScreenState
    extends ConsumerState<PharmacySalesBreakdownDetailScreen> {
  final PharmacyReportsService _service = PharmacyReportsService();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  static const int _pageSize = 50;

  bool _loading = true;
  String? _error;
  PharmacySalesDetailPage _page = PharmacySalesDetailPage.empty;
  int _skip = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _service.getSalesBreakdownDetails(
        PharmacySalesDetailQuery(
          fromDate: widget.fromDate,
          toDate: widget.toDate,
          groupBy: widget.groupBy,
          groupKey: widget.groupKey,
          storeId: widget.storeId,
          payerType: widget.payerType,
          search: _searchCtrl.text,
          skip: _skip,
          take: _pageSize,
        ),
      );
      if (!mounted) return;
      setState(() => _page = page);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _skip = 0;
      _fetch();
    });
  }

  NumberFormat get _money =>
      NumberFormat.currency(symbol: 'NGN ', decimalDigits: 0);
  NumberFormat get _count => NumberFormat.decimalPattern();

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(authProvider).staff;
    final preview = ref.watch(superAdminPreviewProvider);
    if (!canViewPharmacyFinancialReports(staff, preview)) {
      return _denied();
    }

    final cs = Theme.of(context).colorScheme;
    final range =
        '${DateFormatter.shortDate(widget.fromDate)} – ${DateFormatter.shortDate(widget.toDate)}';

    return Scaffold(
      backgroundColor: cs.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final width = bp.maxWidth > 0
              ? bp.maxWidth
              : MediaQuery.sizeOf(context).width;
          final useCards = width < PharmacyAccent.cardBreakpoint;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.router.maybePop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: PharmacyPageHeader(
                      title: widget.groupLabel,
                      subtitle: range,
                      icon: Icons.receipt_long_outlined,
                      iconColor: DepartmentColors.pharmacy,
                      onRefresh: _loading ? null : _fetch,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                style: const TextStyle(fontSize: 13),
                decoration: pharmacyFieldDecoration(
                  context,
                  label: 'Search',
                  hint: 'Drug, patient, or invoice',
                  icon: Icons.search,
                  iconColor: PharmacyAccent.indigo,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: HeltySurfaceCard(
                  child: Column(
                    children: [
                      Expanded(child: _body(useCards: useCards)),
                      PharmacyPaginationFooter(
                        label: _page.total == 0
                            ? 'No sale lines to display'
                            : 'Showing ${_page.total == 0 ? 0 : _skip + 1}–${(_skip + _page.rows.length).clamp(0, _page.total)} of ${_count.format(_page.total)}',
                        page: (_skip ~/ _pageSize) + 1,
                        canPrev: _skip > 0 && !_loading,
                        canNext: _skip + _pageSize < _page.total && !_loading,
                        onPrev: () {
                          setState(() => _skip -= _pageSize);
                          _fetch();
                        },
                        onNext: () {
                          setState(() => _skip += _pageSize);
                          _fetch();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _body({required bool useCards}) {
    if (_loading && _page.rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _page.rows.isEmpty) {
      return Center(child: _errorText(_error!));
    }
    if (_page.rows.isEmpty) {
      return const Center(child: Text('No sale lines found.'));
    }
    if (useCards) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        itemCount: _page.rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) => _card(_page.rows[i]),
      );
    }
    return _table();
  }

  Widget _card(PharmacySalesDetailRow row) {
    final theme = Theme.of(context);
    final when = row.dispensedAt == null
        ? '—'
        : DateFormatter.dateTime24(row.dispensedAt!);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => _openLine(row),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: HeltyEllipsisText(
                      text: row.drugName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _profitChip(row),
                ],
              ),
              const SizedBox(height: 4),
              HeltyEllipsisText(
                text: [
                  when,
                  if (row.patientName.isNotEmpty) row.patientName,
                  if (row.payerType.isNotEmpty) row.payerType,
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              HeltyEllipsisText(
                text:
                    'Qty ${_count.format(row.quantity)} · ${_money.format(row.lineSales)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _table() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        const minWidth = 860.0;
        final width = constraints.maxWidth < minWidth
            ? minWidth
            : constraints.maxWidth;
        final sheet = SizedBox(
          width: width,
          height: constraints.maxHeight,
          child: Column(
            children: [
              Container(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    _head('DRUG', 3),
                    const SizedBox(width: 12),
                    _head('PATIENT', 2),
                    const SizedBox(width: 12),
                    _head('QTY', 1),
                    const SizedBox(width: 12),
                    _head('SALES', 2),
                    const SizedBox(width: 12),
                    _head('PROFIT', 2),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _page.rows.length,
                  itemBuilder: (context, index) {
                    final row = _page.rows[index];
                    return Material(
                      color: pharmacyZebra(cs, index),
                      child: InkWell(
                        onTap: () => _openLine(row),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: HeltyEllipsisText(
                                  text: row.drugName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: HeltyEllipsisText(
                                  text: row.patientName.isEmpty
                                      ? '—'
                                      : row.patientName,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: Text(_count.format(row.quantity)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Text(_money.format(row.lineSales)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(flex: 2, child: _profitChip(row)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
        if (constraints.maxWidth >= minWidth) return sheet;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: sheet,
        );
      },
    );
  }

  Widget _head(String label, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  void _openLine(PharmacySalesDetailRow row) {
    final when = row.dispensedAt == null
        ? '—'
        : DateFormatter.dateTime24(row.dispensedAt!);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.62,
          minChildSize: 0.34,
          maxChildSize: 0.92,
          builder: (_, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Text(
                  row.drugName,
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  when,
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _line('Patient', row.patientName),
                _line('Payer', row.payerType),
                _line('Batch', row.batchNumber),
                _line('Dispensary', row.dispensaryName),
                _line('Dispensed by', row.dispensedByName),
                _line('Invoice', row.invoiceId),
                _line('Quantity', _count.format(row.quantity)),
                _line('Unit sell', _money.format(row.unitSellingPrice)),
                _line(
                  'Unit cost',
                  row.unitCost == null ? '—' : _money.format(row.unitCost!),
                ),
                _line('Sales', _money.format(row.lineSales)),
                _line(
                  'COGS',
                  row.lineCogs == null ? '—' : _money.format(row.lineCogs!),
                ),
                _line('Profit', _profitLabel(row), valueColor: _profitColor(row)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _line(String label, String value, {Color? valueColor}) {
    final shown = value.trim().isEmpty ? '—' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              shown,
              style: TextStyle(fontWeight: FontWeight.w700, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profitChip(PharmacySalesDetailRow row) {
    return HeltyStatusChip(label: _profitLabel(row), color: _profitColor(row));
  }

  String _profitLabel(PharmacySalesDetailRow row) {
    if (row.profitUnknown || row.lineProfit == null) return 'Unknown';
    return _money.format(row.lineProfit!);
  }

  Color _profitColor(PharmacySalesDetailRow row) {
    if (row.profitUnknown || row.lineProfit == null) return PharmacyAccent.amber;
    return row.lineProfit! >= 0 ? PharmacyAccent.green : const Color(0xFFDC2626);
  }

  Widget _errorText(String message) => Padding(
    padding: const EdgeInsets.all(24),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Color(0xFF991B1B)),
    ),
  );

  Widget _denied() {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sale details')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'This report is available to the head of pharmacy only.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
