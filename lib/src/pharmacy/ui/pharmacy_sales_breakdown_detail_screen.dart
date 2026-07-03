import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  DateFormat get _date => DateFormat('dd MMM, HH:mm');

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(authProvider).staff;
    final preview = ref.watch(superAdminPreviewProvider);
    if (!canViewPharmacyFinancialReports(staff, preview)) {
      return _denied();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupLabel),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search drug, patient or invoice',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading && _page.rows.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _page.rows.isEmpty
                ? Center(child: _errorText(_error!))
                : _page.rows.isEmpty
                ? const Center(child: Text('No sale lines found.'))
                : _list(),
          ),
          _pager(),
        ],
      ),
    );
  }

  Widget _list() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _page.rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _row(_page.rows[i]),
    );
  }

  Widget _row(PharmacySalesDetailRow r) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.drugName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                r.dispensedAt == null ? '—' : _date.format(r.dispensedAt!),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (r.batchNumber.isNotEmpty) 'Batch ${r.batchNumber}',
              if (r.patientName.isNotEmpty) r.patientName,
              if (r.payerType.isNotEmpty) r.payerType,
              if (r.dispensaryName.isNotEmpty) r.dispensaryName,
            ].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
            ),
          ),
          const Divider(height: 18),
          Wrap(
            spacing: 22,
            runSpacing: 8,
            children: [
              _metric('Qty', _count.format(r.quantity)),
              _metric('Unit sell', _money.format(r.unitSellingPrice)),
              _metric(
                'Unit cost',
                r.unitCost == null ? '—' : _money.format(r.unitCost!),
              ),
              _metric('Sales', _money.format(r.lineSales)),
              _profitMetric(r),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _profitMetric(PharmacySalesDetailRow r) {
    if (r.profitUnknown || r.lineProfit == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Profit',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          SizedBox(height: 2),
          Text(
            'Unknown',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFC2410C),
            ),
          ),
        ],
      );
    }
    final profit = r.lineProfit!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profit',
          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 2),
        Text(
          _money.format(profit),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: profit >= 0
                ? const Color(0xFF059669)
                : const Color(0xFFDC2626),
          ),
        ),
      ],
    );
  }

  Widget _pager() {
    final total = _page.total;
    final start = total == 0 ? 0 : _skip + 1;
    final end = (_skip + _page.rows.length).clamp(0, total);
    final canPrev = _skip > 0;
    final canNext = _skip + _pageSize < total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Text(
            '$start–$end of ${_count.format(total)}',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const Spacer(),
          IconButton(
            onPressed: canPrev && !_loading
                ? () {
                    setState(() => _skip -= _pageSize);
                    _fetch();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: canNext && !_loading
                ? () {
                    setState(() => _skip += _pageSize);
                    _fetch();
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
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
