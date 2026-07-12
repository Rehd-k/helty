import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/accounts/widgets/accounts_data_table_box.dart';
import 'package:helty/src/accounts/widgets/accounts_money_format.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/invoice_billing_models.dart';
import 'package:helty/src/providers/invoices_providers.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/wallet/wallet_deposit_dialog.dart';
import 'package:helty/src/wallet/wallet_payment_resolver.dart';
import 'package:helty/src/wallet/wallet_providers.dart';
import 'package:helty/src/wallet/wallet_receipt_helper.dart';
import 'package:helty/src/wallet/wallet_reference_labels.dart';

@RoutePage()
class PatientWalletHistoryScreen extends ConsumerStatefulWidget {
  const PatientWalletHistoryScreen({
    super.key,
    required this.patientUuid,
    this.patientName = '',
    this.chartNumber,
  });

  final String patientUuid;
  final String patientName;
  final String? chartNumber;

  @override
  ConsumerState<PatientWalletHistoryScreen> createState() =>
      _PatientWalletHistoryScreenState();
}

class _PatientWalletHistoryScreenState
    extends ConsumerState<PatientWalletHistoryScreen> {
  static const _pageSize = 20;

  int _pageIndex = 0;
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _typeFilter;
  bool _reprintBusy = false;

  WalletHistoryQuery get _query => WalletHistoryQuery(
    patientUuid: widget.patientUuid,
    skip: _pageIndex * _pageSize,
    limit: _pageSize,
    fromDate: _fromDate,
    toDate: _toDate,
    typeFilter: _typeFilter,
  );

  void _invalidate() {
    ref.invalidate(patientWalletHistoryProvider(_query));
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );
    if (range == null) return;
    setState(() {
      _fromDate = range.start;
      _toDate = range.end;
      _pageIndex = 0;
    });
  }

  void _clearDateRange() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _pageIndex = 0;
    });
  }

  Future<void> _reprint(BillingWalletTransaction txn, double balance) async {
    if (_reprintBusy) return;
    setState(() => _reprintBusy = true);
    try {
      final patientName = widget.patientName.trim().isNotEmpty
          ? widget.patientName
          : (ref.read(patientWalletHistoryProvider(_query)).valueOrNull
                    ?.patientName ??
                'Patient');
      final chartNumber =
          widget.chartNumber ??
          ref
              .read(patientWalletHistoryProvider(_query))
              .valueOrNull
              ?.patientChartNumber ??
          '';

      if (txn.isCredit) {
        final refText = txn.reference ?? '';
        if (refText.startsWith('refund_item_')) {
          await WalletReceiptHelper.printRefund(
            context: context,
            transaction: txn,
            patientName: patientName,
            chartNumber: chartNumber,
            invoiceNumber: txn.invoice?.invoiceID,
            isReprint: true,
          );
        } else {
          await WalletReceiptHelper.printDeposit(
            context: context,
            transaction: txn,
            patientName: patientName,
            chartNumber: chartNumber,
            balanceAfter: balance,
            isReprint: true,
          );
        }
        return;
      }

      if (txn.isDebit) {
        final invoiceService = ref.read(invoiceServiceProvider);
        final resolver = WalletPaymentResolver(invoiceService);
        final paymentId = await resolver.resolvePaymentId(txn);
        if (paymentId == null || paymentId.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not find payment for this transaction.'),
              ),
            );
          }
          return;
        }
        final payment = await invoiceService.getPaymentDetail(paymentId);
        if (!mounted) return;
        await WalletReceiptHelper.printPayment(
          context: context,
          payment: payment,
          isReprint: true,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Reprint failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _reprintBusy = false);
    }
  }

  void _viewInvoice(BillingWalletTransaction txn) {
    final invoiceId = txn.invoice?.id ?? txn.invoiceId;
    if (invoiceId == null || invoiceId.isEmpty) return;
    context.router.push(
      PatientBillingRoute(
        invoiceId: invoiceId,
        patientName: widget.patientName,
      ),
    );
  }

  Future<void> _fundWallet() async {
    await WalletDepositDialog.show(
      context,
      ref: ref,
      patientUuid: widget.patientUuid,
      patientName: widget.patientName,
      chartNumber: widget.chartNumber,
      onSuccess: _invalidate,
    );
    _invalidate();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(patientWalletHistoryProvider(_query));
    final fmt = accountsNairaFormat();
    final theme = Theme.of(context);
    final title = widget.patientName.trim().isNotEmpty
        ? 'Wallet — ${widget.patientName}'
        : 'Patient wallet';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load wallet history: $e'),
              const SizedBox(height: 12),
              FilledButton(onPressed: _invalidate, child: const Text('Retry')),
            ],
          ),
        ),
        data: (page) {
          final balance = page.walletBalance ?? page.wallet?.balance ?? 0;
          final displayChart =
              widget.chartNumber ?? page.patientChartNumber ?? '';
          final txs = page.transactions;
          final hasNext = txs.length >= _pageSize;

          return ResponsiveBody(
            center: false,
            builder: (context, bp) => ListView(
              padding: EdgeInsets.zero,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current balance',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmt.format(balance),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (displayChart.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Chart no. $displayChart',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: _fundWallet,
                            icon: const Icon(Icons.add_card_outlined),
                            label: const Text('Fund wallet'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterChip(
                    label: Text(
                      _fromDate != null && _toDate != null
                          ? '${DateFormatter.shortDate(_fromDate!)} – ${DateFormatter.shortDate(_toDate!)}'
                          : 'Date range',
                    ),
                    selected: _fromDate != null,
                    onSelected: (_) => _pickDateRange(),
                  ),
                  if (_fromDate != null)
                    TextButton(
                      onPressed: _clearDateRange,
                      child: const Text('Clear dates'),
                    ),
                  DropdownButton<String?>(
                    value: _typeFilter,
                    hint: const Text('All types'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All types')),
                      DropdownMenuItem(
                        value: 'CREDIT',
                        child: Text('Credits only'),
                      ),
                      DropdownMenuItem(
                        value: 'DEBIT',
                        child: Text('Debits only'),
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      _typeFilter = v;
                      _pageIndex = 0;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ResponsiveDataTable(
                child: AccountsDataTableBox(
                  child: DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 900,
                  columns: const [
                    DataColumn2(label: Text('Date & time'), size: ColumnSize.M),
                    DataColumn2(label: Text('Type'), size: ColumnSize.S),
                    DataColumn2(label: Text('Amount'), size: ColumnSize.S),
                    DataColumn2(label: Text('Reference'), size: ColumnSize.M),
                    DataColumn2(label: Text('Invoice'), size: ColumnSize.S),
                    DataColumn2(label: Text('Actions'), size: ColumnSize.M),
                  ],
                  rows: [
                    if (txs.isEmpty)
                      const DataRow2(
                        cells: [
                          DataCell(Text('No transactions for this page')),
                          DataCell(Text('')),
                          DataCell(Text('')),
                          DataCell(Text('')),
                          DataCell(Text('')),
                          DataCell(Text('')),
                        ],
                      ),
                    for (final txn in txs)
                      DataRow2(
                        cells: [
                          DataCell(
                            Text(
                              txn.createdAt != null
                                  ? DateFormatter.dateTimeWithSeconds(
                                      txn.createdAt!,
                                    )
                                  : '—',
                            ),
                          ),
                          DataCell(Text(walletTransactionTypeLabel(txn.type))),
                          DataCell(
                            Text(
                              '${txn.isCredit ? '+' : '−'}${txn.amount.toFinancial(isMoney: true)}',
                              style: TextStyle(
                                color: txn.isCredit
                                    ? Colors.green.shade700
                                    : theme.colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(walletReferenceLabel(txn.reference)),
                          ),
                          DataCell(
                            Text(txn.invoice?.invoiceID ?? '—'),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Reprint receipt',
                                  onPressed: _reprintBusy
                                      ? null
                                      : () => _reprint(txn, balance),
                                  icon: const Icon(Icons.receipt_long_outlined),
                                ),
                                if ((txn.invoice?.id ?? txn.invoiceId)
                                    case final id?
                                    when id.isNotEmpty)
                                  IconButton(
                                    tooltip: 'View invoice',
                                    onPressed: () => _viewInvoice(txn),
                                    icon: const Icon(Icons.open_in_new),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              ),
              const SizedBox(height: 12),
              ResponsiveToolbar(
                actions: [
                  Text('Page ${_pageIndex + 1}'),
                  OutlinedButton(
                    onPressed: _pageIndex > 0
                        ? () => setState(() => _pageIndex--)
                        : null,
                    child: const Text('Previous'),
                  ),
                  OutlinedButton(
                    onPressed: hasNext
                        ? () => setState(() => _pageIndex++)
                        : null,
                    child: const Text('Next'),
                  ),
                ],
              ),
            ],
          ),
          );
        },
      ),
    );
  }
}
