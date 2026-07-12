import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/auth/billing_permissions.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/helper/app_timezone.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/hmo_models.dart';
import 'package:helty/src/models/receivables_models.dart';
import 'package:helty/src/receivables/ui/receivables_analytics_screen.dart';
import 'package:helty/src/services/hmo_service.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/services/receivables_service.dart';

enum _ReceivableKind { hmo, discount }

@RoutePage()
class ReceivablesHmoScreen extends ConsumerWidget {
  const ReceivablesHmoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canViewReceivables(ref.watch(authProvider).staff)) {
      return _ReceivablesAccessDenied(title: 'HMO Receivables');
    }
    return const _ReceivablesScreen(kind: _ReceivableKind.hmo);
  }
}

@RoutePage()
class ReceivablesDiscountScreen extends ConsumerWidget {
  const ReceivablesDiscountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canViewReceivables(ref.watch(authProvider).staff)) {
      return _ReceivablesAccessDenied(title: 'Discount Receivables');
    }
    return const _ReceivablesScreen(kind: _ReceivableKind.discount);
  }
}

class _ReceivablesAccessDenied extends StatelessWidget {
  const _ReceivablesAccessDenied({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: Text(title)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Your account does not have permission to view receivables.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _ReceivablesScreen extends StatefulWidget {
  const _ReceivablesScreen({required this.kind});

  final _ReceivableKind kind;

  @override
  State<_ReceivablesScreen> createState() => _ReceivablesScreenState();
}

class _ReceivablesScreenState extends State<_ReceivablesScreen> {
  final _service = ReceivablesService();
  final _hmoService = HmoService();
  final _hmoNameSearchCtrl = TextEditingController();
  bool _loading = true;
  String? _error;
  List<ReceivableItem> _items = const [];
  List<HmoListItem> _hmoOptions = const [];
  DateTimeRange? _selectedRange;
  String? _selectedHmoId;
  String _hmoNameQuery = '';

  bool get _isHmo => widget.kind == _ReceivableKind.hmo;
  String get _title => _isHmo ? 'HMO Receivables' : 'Discount Receivables';

  @override
  void initState() {
    super.initState();
    final now = AppTimezone.now();
    _selectedRange = DateTimeRange(
      start: AppTimezone.startOfDay(now.subtract(const Duration(days: 6))),
      end: AppTimezone.endOfDay(now),
    );
    if (_isHmo) {
      _loadHmoOptions();
    }
    _load();
  }

  @override
  void dispose() {
    _hmoNameSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHmoOptions() async {
    try {
      final result = await _hmoService.list(take: 100);
      if (!mounted) return;
      setState(() => _hmoOptions = result.items);
    } catch (_) {}
  }

  DateTime? _rangeFromUtc() {
    final range = _selectedRange;
    if (range == null) return null;
    return AppTimezone.toUtc(
      AppTimezone.dateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      ),
    );
  }

  DateTime? _rangeToUtc() {
    final range = _selectedRange;
    if (range == null) return null;
    return AppTimezone.toUtc(
      AppTimezone.dateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        23,
        59,
        59,
        999,
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = _isHmo
          ? await _service.getHmoReceivables(
              take: 100,
              from: _rangeFromUtc(),
              to: _rangeToUtc(),
              hmoId: _selectedHmoId,
              hmoName: _hmoNameQuery.isEmpty ? null : _hmoNameQuery,
            )
          : await _service.getDiscountReceivables(
              take: 100,
              from: _rangeFromUtc(),
              to: _rangeToUtc(),
            );
      if (!mounted) return;
      setState(() => _items = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _statementPayerId(ReceivableItem item) {
    if (_isHmo) return item.payerId ?? '';
    return item.payerStaffId ?? item.payerId ?? '';
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildInvoiceDetailContent(ReceivableItem item) {
    final invoiceRef =
        item.invoiceHumanId ?? item.invoiceUuid ?? item.invoiceId ?? '-';
    final created = item.displayCreatedAt;
    final patientParts = <String>[
      if (item.patientDisplayName != null) item.patientDisplayName!,
      if (item.patientPublicId != null && item.patientPublicId!.isNotEmpty)
        'ID ${item.patientPublicId}',
    ];
    final lines = item.invoiceLines;
    final linesTotal = lines.isNotEmpty ? item.invoiceLinesTotal : item.amount;

    return SizedBox(
      width: 720,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _detailRow('Invoice', invoiceRef),
            if (item.invoiceStatus != null && item.invoiceStatus!.isNotEmpty)
              _detailRow('Invoice status', item.invoiceStatus!),
            if (created != null)
              _detailRow('Date', DateFormatter.dateTime(created.toLocal())),
            if (patientParts.isNotEmpty)
              _detailRow('Patient', patientParts.join(' · ')),
            if (_isHmo && item.payerName != null && item.payerName!.isNotEmpty)
              _detailRow('HMO', item.payerName!),
            if (!_isHmo &&
                (item.payerFirstName != null || item.payerLastName != null))
              _detailRow(
                'Payer',
                [
                  item.payerFirstName,
                  item.payerLastName,
                ].whereType<String>().where((s) => s.isNotEmpty).join(' '),
              ),
            if (item.policyName != null && item.policyName!.isNotEmpty)
              _detailRow('Policy', item.policyName!),
            if (item.coverageLabel != null)
              _detailRow('Coverage', item.coverageLabel!),
            if (item.status != null && item.status!.isNotEmpty)
              _detailRow('Coverage status', item.status!),
            _detailRow(
              'Receivable amount',
              item.outstandingAmount.toFinancial(isMoney: true),
            ),
            const SizedBox(height: 12),
            const Text(
              'Invoice items',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            if (lines.isEmpty)
              const Text('No line items on this invoice.')
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('Item')),
                    DataColumn(label: Text('Qty'), numeric: true),
                    DataColumn(label: Text('Unit price'), numeric: true),
                    DataColumn(label: Text('Amount'), numeric: true),
                  ],
                  rows: List<DataRow>.generate(lines.length, (i) {
                    final line = lines[i];
                    return DataRow(
                      cells: [
                        DataCell(Text('${i + 1}')),
                        DataCell(Text(line.displayName)),
                        DataCell(Text('${line.quantity}')),
                        DataCell(
                          Text(line.unitPrice.toFinancial(isMoney: true)),
                        ),
                        DataCell(
                          Text(line.lineTotal.toFinancial(isMoney: true)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            if (lines.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Invoice total: ${linesTotal.toFinancial(isMoney: true)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openInvoiceDetail(ReceivableItem item) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Invoice ${item.invoiceHumanId ?? item.invoiceUuid ?? ''}'),
        content: _buildInvoiceDetailContent(item),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _rangeLabel(DateTimeRange? range) {
    if (range == null) return 'All dates';
    return '${DateFormatter.shortDate(range.start)} - ${DateFormatter.shortDate(range.end)}';
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _selectedRange,
    );
    if (picked == null) return;
    setState(() {
      _selectedRange = DateTimeRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        end: DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
          999,
        ),
      );
    });
    await _load();
  }

  Future<void> _applyHmoNameSearch() async {
    setState(() => _hmoNameQuery = _hmoNameSearchCtrl.text.trim());
    await _load();
  }

  Future<void> _clearHmoFilters() async {
    _hmoNameSearchCtrl.clear();
    setState(() {
      _selectedHmoId = null;
      _hmoNameQuery = '';
    });
    await _load();
  }

  Widget _buildHmoFilterBar() {
    if (!_isHmo) return const SizedBox.shrink();
    final hasFilters = _selectedHmoId != null || _hmoNameQuery.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        children: [
          DropdownButtonFormField<String?>(
            initialValue: _selectedHmoId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'HMO',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All HMOs'),
              ),
              ..._hmoOptions.map(
                (hmo) => DropdownMenuItem<String?>(
                  value: hmo.id,
                  child: Text(hmo.name),
                ),
              ),
            ],
            onChanged: (value) async {
              setState(() => _selectedHmoId = value);
              await _load();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hmoNameSearchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Search by HMO name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _applyHmoNameSearch(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Search HMO name',
                onPressed: _applyHmoNameSearch,
                icon: const Icon(Icons.search),
              ),
              if (hasFilters)
                IconButton(
                  tooltip: 'Clear HMO filters',
                  onPressed: _clearHmoFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordRemittance(List<ReceivableItem> items) async {
    final selected = <String, bool>{
      for (final e in items.take(10)) e.coverageId: false,
    };
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          final chosen = items
              .where((e) => selected[e.coverageId] == true)
              .toList();
          final autoTotal = chosen.fold<double>(
            0,
            (s, e) => s + e.outstandingAmount,
          );
          if (amountCtrl.text.trim().isEmpty && autoTotal > 0) {
            amountCtrl.text = autoTotal.toStringAsFixed(2);
          }
          return AlertDialog(
            title: const Text('Record remittance'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...items
                        .take(10)
                        .map(
                          (e) => CheckboxListTile(
                            title: Text(
                              e.remittanceSummaryLine,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${e.outstandingAmount.toFinancial(isMoney: true)} · ${e.coverageId}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            value: selected[e.coverageId] ?? false,
                            onChanged: (v) => setDialog(() {
                              selected[e.coverageId] = v == true;
                              if ((v ?? false) == false) {
                                amountCtrl.text = items
                                    .where(
                                      (x) => selected[x.coverageId] == true,
                                    )
                                    .fold<double>(
                                      0,
                                      (s, x) => s + x.outstandingAmount,
                                    )
                                    .toStringAsFixed(2);
                              }
                            }),
                          ),
                        ),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                    TextField(
                      controller: refCtrl,
                      decoration: const InputDecoration(labelText: 'Reference'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) return;
    final chosen = items.where((e) => selected[e.coverageId] == true).toList();
    if (chosen.isEmpty) return;
    final total = double.tryParse(amountCtrl.text.trim()) ?? 0;
    final expected = chosen.fold<double>(0, (s, e) => s + e.outstandingAmount);
    if ((total - expected).abs() > 0.01) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must equal selected line totals')),
      );
      return;
    }

    final hmoId = _isHmo ? _statementPayerId(chosen.first) : null;
    final payerStaffId = _isHmo ? null : _statementPayerId(chosen.first);
    await _service.recordRemittance(
      RecordRemittancePayload(
        payerType: _isHmo ? 'HMO' : 'STAFF',
        hmoId: hmoId?.isEmpty ?? true ? null : hmoId,
        payerStaffId: payerStaffId?.isEmpty ?? true ? null : payerStaffId,
        amount: total,
        reference: refCtrl.text.trim(),
        lines: chosen
            .map(
              (e) => RemittanceLinePayload(
                coverageId: e.coverageId,
                amount: e.outstandingAmount,
              ),
            )
            .toList(),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final totalOutstanding = _items.fold<double>(
      0,
      (sum, e) => sum + e.outstandingAmount,
    );
    final totalAmount = _items.fold<double>(0, (sum, e) => sum + e.amount);
    final uniquePayers = _items
        .map((e) => (e.payerName ?? e.payerId ?? '').trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .length;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_title),
        actions: [
          IconButton(
            tooltip: 'Open receivables analytics',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ReceivablesAnalyticsScreen(),
              ),
            ),
            icon: const Icon(Icons.analytics_outlined),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ResponsiveBody(
              center: false,
              builder: (context, bp) => Column(
                children: [
                _buildHmoFilterBar(),
                Padding(
                  padding: EdgeInsets.fromLTRB(12, _isHmo ? 8 : 12, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDateRange,
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            _rangeLabel(_selectedRange),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Clear date range',
                        onPressed: () async {
                          setState(() => _selectedRange = null);
                          await _load();
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: ResponsiveWrapGrid(
                    mobileColumns: 1,
                    tabletColumns: 2,
                    desktopColumns: 4,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _summaryCard(
                        label: 'Records',
                        value: '${_items.length}',
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                      ),
                      _summaryCard(
                        label: 'Outstanding',
                        value: totalOutstanding.toFinancial(isMoney: true),
                        icon: Icons.account_balance_wallet_outlined,
                        color: Colors.orange,
                      ),
                      _summaryCard(
                        label: 'Total Amount',
                        value: totalAmount.toFinancial(isMoney: true),
                        icon: Icons.summarize_outlined,
                        color: Colors.green,
                      ),
                      _summaryCard(
                        label: _isHmo ? 'Unique HMOs' : 'Unique Payers',
                        value: '$uniquePayers',
                        icon: Icons.groups_outlined,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _ReceivablesList(
                    items: _items,
                    isHmo: _isHmo,
                    onOpenDetail: _openInvoiceDetail,
                  ),
                ),
              ],
            ),
          ),
      floatingActionButton: _items.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _recordRemittance(_items),
              icon: const Icon(Icons.request_quote_outlined),
              label: const Text('Record remittance'),
            ),
    );
  }
}

class _ReceivablesList extends StatelessWidget {
  const _ReceivablesList({
    required this.items,
    required this.isHmo,
    required this.onOpenDetail,
  });

  final List<ReceivableItem> items;
  final bool isHmo;
  final ValueChanged<ReceivableItem> onOpenDetail;

  String _titleFor(ReceivableItem item) {
    if (isHmo) {
      if (item.payerName != null && item.payerName!.trim().isNotEmpty) {
        return item.payerName!.trim();
      }
      if (item.policyName != null && item.policyName!.trim().isNotEmpty) {
        return item.policyName!.trim();
      }
      return item.kind?.trim().isNotEmpty == true ? item.kind!.trim() : 'HMO';
    }
    if (item.policyName != null && item.policyName!.isNotEmpty) {
      return item.policyName!;
    }
    if (item.kind != null && item.kind!.isNotEmpty) {
      return '${item.kind}${item.reason != null ? ' · ${item.reason}' : ''}';
    }
    return item.payerName ?? item.payerType;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No receivables found.'));
    }
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final item = items[index];
        final title = _titleFor(item);
        final patientLine = [
          if (item.patientDisplayName != null) item.patientDisplayName,
          if (item.patientPublicId != null && item.patientPublicId!.isNotEmpty)
            'ID ${item.patientPublicId}',
        ].whereType<String>().join(' · ');
        final invoiceRef =
            item.invoiceHumanId ?? item.invoiceUuid ?? item.invoiceId;
        final created = item.displayCreatedAt;
        final coverageLabel = item.coverageLabel;
        final subLines = <String>[
          if (patientLine.isNotEmpty) patientLine,
          if (invoiceRef != null && invoiceRef.isNotEmpty)
            'Invoice $invoiceRef',
          if (item.invoiceStatus != null && item.invoiceStatus!.isNotEmpty)
            item.invoiceStatus!,
          if (coverageLabel != null) 'Coverage $coverageLabel',
          if (item.status != null && item.status!.isNotEmpty) item.status!,
          if (created != null) DateFormatter.dateTime(created.toLocal()),
          if (!isHmo &&
              (item.payerFirstName != null || item.payerLastName != null))
            'Payer ${[item.payerFirstName, item.payerLastName].whereType<String>().where((s) => s.isNotEmpty).join(' ')}',
        ];
        return Material(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => onOpenDetail(item),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.amount.toFinancial(isMoney: true),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...subLines.map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              line,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.outstandingAmount.toFinancial(isMoney: true),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: items.length,
    );
  }
}
