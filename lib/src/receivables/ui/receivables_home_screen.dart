import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/receivables_models.dart';
import 'package:helty/src/services/receivables_service.dart';

@RoutePage()
class ReceivablesHomeScreen extends StatefulWidget {
  const ReceivablesHomeScreen({super.key});

  @override
  State<ReceivablesHomeScreen> createState() => _ReceivablesHomeScreenState();
}

class _ReceivablesHomeScreenState extends State<ReceivablesHomeScreen>
    with SingleTickerProviderStateMixin {
  final _service = ReceivablesService();
  late final TabController _tab;
  bool _loading = true;
  String? _error;
  List<ReceivableItem> _hmo = const [];
  List<ReceivableItem> _discount = const [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hmo = await _service.getHmoReceivables(take: 100);
      final discount = await _service.getDiscountReceivables(take: 100);
      if (!mounted) return;
      setState(() {
        _hmo = hmo;
        _discount = discount;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String _statementPayerId(ReceivableItem item, {required bool hmo}) {
    if (hmo) return item.payerId ?? '';
    return item.payerStaffId ?? item.payerId ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final currentItems = _tab.index == 0 ? _hmo : _discount;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receivables'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'HMO'),
            Tab(text: 'Discount'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : TabBarView(
              controller: _tab,
              children: [
                _ReceivablesList(
                  items: _hmo,
                  onOpenStatement: (item) => _openStatement(item, hmo: true),
                ),
                _ReceivablesList(
                  items: _discount,
                  onOpenStatement: (item) => _openStatement(item, hmo: false),
                ),
              ],
            ),
      floatingActionButton: currentItems.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _recordRemittance(currentItems),
              icon: const Icon(Icons.request_quote_outlined),
              label: const Text('Record remittance'),
            ),
    );
  }

  Future<void> _openStatement(ReceivableItem item, {required bool hmo}) async {
    final payerId = _statementPayerId(item, hmo: hmo);
    if (payerId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing payer id for statement')),
      );
      return;
    }
    try {
      final data = hmo
          ? await _service.getHmoStatement(payerId)
          : await _service.getOwnerStatement(payerId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Statement'),
          content: SingleChildScrollView(child: Text(data.toString())),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (_) {}
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
    final hmoTab = _tab.index == 0;
    final hmoId = hmoTab ? _statementPayerId(chosen.first, hmo: true) : null;
    final payerStaffId = hmoTab
        ? null
        : _statementPayerId(chosen.first, hmo: false);
    await _service.recordRemittance(
      RecordRemittancePayload(
        payerType: hmoTab ? 'HMO' : 'STAFF',
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
}

class _ReceivablesList extends StatelessWidget {
  const _ReceivablesList({required this.items, required this.onOpenStatement});

  final List<ReceivableItem> items;
  final ValueChanged<ReceivableItem> onOpenStatement;

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
        final title = item.policyName != null && item.policyName!.isNotEmpty
            ? item.policyName!
            : (item.kind != null && item.kind!.isNotEmpty)
            ? '${item.kind}${item.reason != null ? ' · ${item.reason}' : ''}'
            : (item.payerName ?? item.payerType);
        final patientLine = [
          if (item.patientDisplayName != null) item.patientDisplayName,
          if (item.patientPublicId != null && item.patientPublicId!.isNotEmpty)
            'ID ${item.patientPublicId}',
        ].whereType<String>().join(' · ');
        final invoiceRef =
            item.invoiceHumanId ?? item.invoiceUuid ?? item.invoiceId;
        final created = item.displayCreatedAt;
        final subLines = <String>[
          if (patientLine.isNotEmpty) patientLine,
          if (invoiceRef != null && invoiceRef.isNotEmpty)
            'Invoice $invoiceRef',
          if (item.invoiceStatus != null && item.invoiceStatus!.isNotEmpty)
            item.invoiceStatus!,
          if (created != null) DateFormatter.dateTime(created.toLocal()),
          if (item.payerFirstName != null || item.payerLastName != null)
            'Payer ${[item.payerFirstName, item.payerLastName].whereType<String>().where((s) => s.isNotEmpty).join(' ')}',
        ];
        return Material(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => onOpenStatement(item),
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
