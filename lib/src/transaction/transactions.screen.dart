import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'transaction_details_pane.dart';
import 'transaction_filter_bar.dart';
import 'transaction_models.dart';
import 'transaction_payment_dialog.dart';
import 'transaction_summary_section.dart';
import 'transaction_table.dart';

@RoutePage()
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  // ─── Filter state ───────────────────────────────────────────────────────────

  TransactionFilter _filter = TransactionFilter(
    currentUser: 'Sarah Jenkins',
    sortField: TransactionSortField.date,
    sortAscending: false,
  );

  final TextEditingController _searchController = TextEditingController();

  // ─── Selection state ────────────────────────────────────────────────────────

  Map<String, dynamic>? _selectedTransaction;

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Filter helpers ─────────────────────────────────────────────────────────

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _filter = TransactionFilter(currentUser: _filter.currentUser);
    });
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange:
          _filter.dateRange ??
          DateTimeRange(start: DateTime.now(), end: DateTime.now()),
    );
    if (picked != null && picked != _filter.dateRange) {
      setState(() => _filter = _filter.copyWith(dateRange: picked));
    }
  }

  List<TransactionMap> get _displayedTransactions =>
      applyTransactionFilter(kMockTransactions, _filter);

  // ─── Sort ────────────────────────────────────────────────────────────────────

  void _handleSort(TransactionSortField field) {
    setState(() {
      if (_filter.sortField == field) {
        // Flip direction
        _filter = _filter.copyWith(sortAscending: !_filter.sortAscending);
      } else {
        _filter = _filter.copyWith(sortField: field, sortAscending: true);
      }
    });
  }

  // ─── Actions ────────────────────────────────────────────────────────────────

  void _handleContextMenuAction(
    String action,
    Map<String, dynamic> transaction,
  ) {
    switch (action) {
      case 'details':
        setState(() => _selectedTransaction = transaction);
        break;
      case 'reprint':
        _showSimpleModal(
          'Reprint Receipt',
          'Reprint the receipt for ${transaction['tranId']}?',
        );
        break;
      case 'change_method':
        _openPaymentDialog(transaction);
        break;
      case 'refund':
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
        // TODO: call TransactionService.recordPayment() with result['payments']
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment of \$${(result['totalPaid'] as double).toStringAsFixed(2)} recorded.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
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

  void _showContextMenu(
    BuildContext context,
    Offset position,
    Map<String, dynamic> transaction,
  ) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: const [
        PopupMenuItem(
          value: 'details',
          child: Text('Show Details', style: TextStyle(fontSize: 13)),
        ),
        PopupMenuItem(
          value: 'reprint',
          child: Text('Reprint Receipt', style: TextStyle(fontSize: 13)),
        ),
        PopupMenuItem(
          value: 'change_method',
          child: Text('Change Payment Method', style: TextStyle(fontSize: 13)),
        ),
        PopupMenuItem(
          value: 'refund',
          child: Text(
            'Make a Refund',
            style: TextStyle(fontSize: 13, color: Colors.red),
          ),
        ),
      ],
    ).then((value) {
      if (value != null) _handleContextMenuAction(value, transaction);
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayed = _displayedTransactions;
    final totals = calculateTransactionTotals(displayed);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Financial summary row
            TransactionSummarySection(totals: totals),
            const SizedBox(height: 24),

            // 2. Filter bar
            TransactionFilterBar(
              showingMyTransactionsOnly: _filter.myTransactionsOnly,
              selectedUserFilter: _filter.initiator ?? 'All Users',
              searchField: _filter.searchField,
              searchController: _searchController,
              selectedDateRange: _filter.dateRange,
              onToggleMyTransactions: (val) => setState(
                () => _filter = _filter.copyWith(myTransactionsOnly: val),
              ),
              onUserFilterChanged: (val) =>
                  setState(() => _filter = _filter.copyWith(initiator: val)),
              onSearchFieldChanged: (val) =>
                  setState(() => _filter = _filter.copyWith(searchField: val)),
              onPickDateRange: _pickDateRange,
              onReset: _resetFilters,
            ),
            const SizedBox(height: 24),

            // 3. Table + details side-by-side
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Transaction table (2/3 width)
                  Expanded(
                    flex: 2,
                    child: TransactionTable(
                      transactions: displayed,
                      selectedTransactionId:
                          _selectedTransaction?['tranId'] as String?,
                      sortField: _filter.sortField,
                      sortAscending: _filter.sortAscending,
                      onSort: _handleSort,
                      onRowTap: (txn) =>
                          setState(() => _selectedTransaction = txn),
                      onContextMenu: _showContextMenu,
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Right: Details pane (1/3 width)
                  Expanded(
                    child: TransactionDetailsPane(
                      transaction: _selectedTransaction,
                      onReprint: () => _handleContextMenuAction(
                        'reprint',
                        _selectedTransaction!,
                      ),
                      onChangeMethod: () =>
                          _openPaymentDialog(_selectedTransaction!),
                      onRefund: () => _handleContextMenuAction(
                        'refund',
                        _selectedTransaction!,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
