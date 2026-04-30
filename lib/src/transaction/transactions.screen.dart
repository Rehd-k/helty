import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:data_table_2/data_table_2.dart';
import 'package:helty/src/core/extensions/number.extention.dart';

import 'transaction_details_pane.dart';
import 'transaction_filters_panel.dart';
import 'transaction_models.dart';
import 'transaction_payment_dialog.dart';
import 'transaction_summary_section.dart';
import '../models/staff_model.dart';
import '../providers/auth_provider.dart';
import '../services/transaction_service.dart';
import '../widgets/receipt_escpos_service.dart';
import '../widgets/receipt_printer_picker_sheet.dart';
import '../widgets/table/reusable_async_table.dart';

@RoutePage()
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TransactionService _transactionService = TransactionService();
  final TextEditingController _searchController = TextEditingController();

  // ─── Filter state (drive TransactionQuery) ─────────────────────────────────
  String _searchQuery = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;
  TransactionStatus? _status;
  bool _myTransactionsOnly = false;

  /// Staff filter: `receivedById` from API `staffSummary` (query param `initiatedBy`).
  String? _initiatedById;
  String?
  _selectedPaymentMethod; // 'Cash', 'Transfer', 'Cheque', 'Card', or null
  bool _isFiltersOpen = false;

  // ─── Fetched data (one page for totals + table client-side pagination) ─────
  static const int _fetchPageSize = 500;
  List<TransactionMap> _transactionMaps = [];
  List<StaffSummaryEntry> _staffSummaryOptions = [];
  int _totalCount = 0;
  bool _loading = false;
  String? _loadError;
  int _tableDataGeneration = 0;

  // ─── Selection state ───────────────────────────────────────────────────────
  Map<String, dynamic>? _selectedTransaction;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  TransactionQuery _buildQuery({int skip = 0, int take = _fetchPageSize}) {
    return TransactionQuery(
      search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      fromDate: _dateFrom,
      toDate: _dateTo,
      status: _status?.label.toUpperCase().replaceAll(' ', '_'),
      initiatedBy: _initiatedById?.trim().isNotEmpty == true
          ? _initiatedById!.trim()
          : null,
      paymentMethod:
          _selectedPaymentMethod != null && _selectedPaymentMethod!.isNotEmpty
          ? _selectedPaymentMethod!.toUpperCase()
          : null,
      skip: skip,
      take: take,
      sortBy: 'createdAt',
      sortOrder: 'desc',
    );
  }

  void _rebindSelectedTransaction() {
    final prev = _selectedTransaction;
    if (prev == null) return;
    final pid = prev['id']?.toString();
    final tid = prev['tranId']?.toString();
    Map<String, dynamic>? found;
    if (pid != null && pid.isNotEmpty) {
      for (final t in _transactionMaps) {
        if (t['id']?.toString() == pid) {
          found = t;
          break;
        }
      }
    }
    if (found == null && tid != null && tid.isNotEmpty) {
      for (final t in _transactionMaps) {
        if (t['tranId']?.toString() == tid) {
          found = t;
          break;
        }
      }
    }
    _selectedTransaction = found;
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final result = await _transactionService.fetchTransactions(
        _buildQuery(skip: 0, take: _fetchPageSize),
      );
      if (!mounted) return;
      setState(() {
        _transactionMaps = result.data.map(transactionModelToMap).toList();
        _totalCount = result.total;
        _staffSummaryOptions = result.staffSummary;
        if (_initiatedById != null &&
            !_staffSummaryOptions.any(
              (e) => e.receivedById == _initiatedById,
            )) {
          _initiatedById = null;
        }
        _tableDataGeneration++;
        _rebindSelectedTransaction();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
        _transactionMaps = [];
        _totalCount = 0;
        _staffSummaryOptions = [];
        _tableDataGeneration++;
        _selectedTransaction = null;
      });
    }
  }

  void _applyFiltersFromPanel({
    required DateTime? dateFrom,
    required DateTime? dateTo,
    required TransactionStatus? status,
    required bool myTransactionsOnly,
    required String? selectedInitiatedById,
  }) {
    setState(() {
      _dateFrom = dateFrom;
      _dateTo = dateTo;
      _status = status;
      _myTransactionsOnly = myTransactionsOnly;
      _initiatedById = selectedInitiatedById;
      _isFiltersOpen = false;
    });
    _loadTransactions();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _dateFrom = null;
      _dateTo = null;
      _status = null;
      _myTransactionsOnly = false;
      _initiatedById = null;
      _selectedPaymentMethod = null;
      _isFiltersOpen = false;
    });
    _loadTransactions();
  }

  void _onSearchSubmitted(String value) {
    setState(() => _searchQuery = value);
    _loadTransactions();
  }

  Future<PagedData<TransactionMap>> _fetchTransactions(
    int start,
    int count,
  ) async {
    if (_transactionMaps.isEmpty && !_loading) {
      return PagedData(items: const [], totalCount: 0);
    }
    final end = (start + count).clamp(0, _transactionMaps.length);
    final startClamped = start.clamp(0, _transactionMaps.length);
    final items = startClamped < end
        ? _transactionMaps.sublist(startClamped, end)
        : <TransactionMap>[];
    return PagedData(items: items, totalCount: _totalCount);
  }

  void _handleContextMenuAction(
    String action,
    Map<String, dynamic> transaction,
  ) {
    switch (action) {
      case 'details':
        setState(() => _selectedTransaction = transaction);
        break;
      case 'reprint':
        _showReprintReceiptDialog(transaction);
        break;
      case 'change_method':
        _openPaymentDialog(transaction);
        break;
      case 'refund':
        if (!staffCanAccessPrivilegedBilling(ref.read(authProvider).staff)) {
          return;
        }
        _showSimpleModal(
          'Make a Refund (Le remboursement)',
          'Initiate a partial or full refund for ${transaction['tranId']}.',
        );
        break;
    }
  }

  void _openPaymentDialog(Map<String, dynamic> transaction) {
    showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ChangePaymentDialog(transaction: transaction),
    ).then((result) {
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment of ${(result['totalPaid'] as double).toFinancial(isMoney: true)} recorded.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadTransactions();
      }
    });
  }

  Future<void> _openChangeTransactionDateDialog(
    Map<String, dynamic> transaction,
  ) async {
    if (!staffCanAccessPrivilegedBilling(ref.read(authProvider).staff)) {
      return;
    }
    final paymentId = transaction['id']?.toString().trim() ?? '';
    if (paymentId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot change date: missing payment id.'),
        ),
      );
      return;
    }
    final iso = transaction['createdAtIso']?.toString();
    final initial =
        (iso != null && iso.isNotEmpty ? DateTime.tryParse(iso) : null) ??
        DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || date == null) return;

    final tod = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted || tod == null) return;

    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      tod.hour,
      tod.minute,
    );

    try {
      await _transactionService.updatePaymentPaidAt(paymentId, combined);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction date updated.')),
      );
      await _loadTransactions();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update date: $e')));
    }
  }

  void _showSimpleModal(String title, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          title,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReprintReceiptDialog(Map<String, dynamic> transaction) {
    final colorScheme = Theme.of(context).colorScheme;
    final tid = transaction['tranId']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Reprint receipt',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Choose a printer to reprint receipt $tid',
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              if (!mounted) return;
              final data = ReceiptEscposService.fromTransactionMap(transaction);
              await showReceiptPrinterPickerSheet(
                context,
                data: data,
                isCopy: true,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
            ),
            child: const Text('Print', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Renders [TransactionMap]'s `patientId` only; API shape `{'patientId': value}`.
  static String _patientIdCell(dynamic patientId) {
    if (patientId == null) return 'No ID';
    final s = patientId.toString().trim();
    return s.isEmpty ? 'No ID' : s;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canPrivilegedBilling = staffCanAccessPrivilegedBilling(
      ref.watch(authProvider).staff,
    );
    final totals = calculateTransactionTotals(_transactionMaps);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: search bar + Filters button
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText:
                              'Search by transaction ID, patient ID, first name, last name...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 20,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          filled: true,
                          fillColor: colorScheme.onSurface.withValues(
                            alpha: 0.03,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                        onSubmitted: _onSearchSubmitted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _isFiltersOpen = true),
                      icon: const Icon(Icons.filter_list, size: 18),
                      label: const Text('Filters'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        side: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Summary cards (clickable to filter by payment method)
                TransactionSummarySection(
                  totals: totals,
                  onPaymentCardTap: (method) {
                    setState(() => _selectedPaymentMethod = method);
                    _loadTransactions();
                  },
                  selectedPaymentMethod: _selectedPaymentMethod,
                ),
                const SizedBox(height: 24),

                if (_loadError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Material(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _loadError!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (_loading && _transactionMaps.isEmpty)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: ReusableAsyncTable<TransactionMap>(
                            key: ValueKey(
                              '$_searchQuery$_dateFrom$_dateTo$_status$_selectedPaymentMethod$_initiatedById$_tableDataGeneration',
                            ),
                            columns: const [
                              DataColumn2(label: Text('Transaction ID')),
                              DataColumn2(label: Text('Patient Name')),
                              DataColumn2(label: Text('Services')),
                              DataColumn2(label: Text('Amount Due')),
                              DataColumn2(label: Text('Amount Paid')),
                              DataColumn2(label: Text('Payment Method')),
                              DataColumn2(label: Text('Discount')),
                              DataColumn2(label: Text('Date & Time')),
                              DataColumn2(label: Text('Outstanding Debt')),
                              DataColumn2(label: Text('Initiated By')),
                              DataColumn2(label: Text('Status')),
                            ],
                            fetchData: _fetchTransactions,
                            idGetter: (txn) {
                              final id = txn['id']?.toString();
                              if (id != null && id.isNotEmpty) return id;
                              // Fallback for older mapped rows without `id`.
                              return '${txn['tranId']}_${txn['date']}_${txn['amountPaid']}';
                            },
                            rowBuilder: (txn) => [
                              DataCell(Text(txn['tranId'] as String)),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(() {
                                      final n =
                                          txn['patientName']
                                              ?.toString()
                                              .trim() ??
                                          '';
                                      return n.isEmpty ? '—' : n;
                                    }()),
                                    Text(
                                      // _patientIdCell(txn['patientId']),
                                      '--',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text('${txn['serviceCount']} services')),
                              DataCell(
                                Text(
                                  (txn['amountDue'] as num).toFinancial(
                                    isMoney: true,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  (txn['amountPaid'] as num).toFinancial(
                                    isMoney: true,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text((txn['paymentMethod'] as String?) ?? '—'),
                              ),
                              DataCell(
                                Text(
                                  (txn['discount'] as num?)?.toFinancial(
                                        isMoney: true,
                                      ) ??
                                      "0.00",
                                ),
                              ),
                              DataCell(Text(txn['date'] as String)),
                              DataCell(
                                Text(
                                  (txn['debt'] as num).toFinancial(
                                    isMoney: true,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text((txn['initiator'] as String?) ?? ''),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    (txn['status'] as String?)?.replaceAll(
                                          '_',
                                          ' ',
                                        ) ??
                                        '',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                            onRowTap: (txn) =>
                                setState(() => _selectedTransaction = txn),
                            contextMenuBuilder: (txn) => [
                              const PopupMenuItem(
                                value: 'details',
                                child: Text(
                                  'Show Details',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'reprint',
                                child: Text(
                                  'Reprint Receipt',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'change_method',
                                child: Text(
                                  'Change Payment Method',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              if (canPrivilegedBilling)
                                const PopupMenuItem(
                                  value: 'refund',
                                  child: Text(
                                    'Make a Refund',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                            ],
                            onContextMenuSelected: (txn, action) =>
                                _handleContextMenuAction(action as String, txn),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: TransactionDetailsPane(
                            transaction: _selectedTransaction,
                            showChangeDateAndRefund: canPrivilegedBilling,
                            onReprint: _selectedTransaction != null
                                ? () => _handleContextMenuAction(
                                    'reprint',
                                    _selectedTransaction!,
                                  )
                                : () {},
                            onChangeMethod: _selectedTransaction != null
                                ? () =>
                                      _openPaymentDialog(_selectedTransaction!)
                                : () {},
                            onChangeTransactionDate:
                                _selectedTransaction != null
                                ? () => _openChangeTransactionDateDialog(
                                    _selectedTransaction!,
                                  )
                                : () {},
                            onRefund: _selectedTransaction != null
                                ? () => _handleContextMenuAction(
                                    'refund',
                                    _selectedTransaction!,
                                  )
                                : () {},
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Slide-in filters panel (like medicine inventory)
          if (_isFiltersOpen)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: Material(
                elevation: 8,
                child: Container(
                  width: 360,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Filters',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: 'Close filters',
                              onPressed: () =>
                                  setState(() => _isFiltersOpen = false),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: TransactionFiltersPanel(
                          theme: Theme.of(context),
                          dateFrom: _dateFrom,
                          dateTo: _dateTo,
                          onDateFromChanged: (d) =>
                              setState(() => _dateFrom = d),
                          onDateToChanged: (d) => setState(() => _dateTo = d),
                          status: _status,
                          onStatusChanged: (s) => setState(() => _status = s),
                          myTransactionsOnly: _myTransactionsOnly,
                          onMyTransactionsOnlyChanged: (v) =>
                              setState(() => _myTransactionsOnly = v),
                          selectedInitiatedById: _initiatedById,
                          staffOptions: _staffSummaryOptions,
                          onInitiatedByChanged: (v) =>
                              setState(() => _initiatedById = v),
                          onApply: () => _applyFiltersFromPanel(
                            dateFrom: _dateFrom,
                            dateTo: _dateTo,
                            status: _status,
                            myTransactionsOnly: _myTransactionsOnly,
                            selectedInitiatedById: _initiatedById,
                          ),
                          onReset: _resetFilters,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
