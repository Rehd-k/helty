import 'package:flutter/material.dart';

import 'transaction_models.dart';

// Fixed minimum column widths — ensures the table scrolls horizontally when
// the available space is narrower than the sum of column widths.
const double _kColTranId = 160;
const double _kColPatient = 200;
const double _kColServices = 90;
const double _kColAmountDue = 130;
const double _kColAmountPaid = 130;
const double _kColMethod = 120;
const double _kColDiscount = 110;
const double _kColDate = 160;
const double _kColDebt = 110;
const double _kColInitiator = 150;
const double _kColStatus = 130;

/// The data table displaying all transactions.
///
/// - Scrolls **horizontally** to show all columns at full width.
/// - Column headers are clickable to sort ascending / descending.
/// - Rows support tap-to-select and right-click / long-press context menu.
class TransactionTable extends StatefulWidget {
  const TransactionTable({
    super.key,
    required this.transactions,
    required this.selectedTransactionId,
    required this.onRowTap,
    required this.onContextMenu,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
  });

  final List<TransactionMap> transactions;

  /// The `tranId` of the currently selected row, or `null` if none.
  final String? selectedTransactionId;

  /// Called when the user taps a row.
  final ValueChanged<TransactionMap> onRowTap;

  /// Called with `(context, globalPosition, transaction)` on right-click / long-press.
  final void Function(
    BuildContext context,
    Offset globalPosition,
    TransactionMap transaction,
  )
  onContextMenu;

  final TransactionSortField sortField;
  final bool sortAscending;

  /// Called when user clicks a column header.
  final void Function(TransactionSortField field) onSort;

  @override
  State<TransactionTable> createState() => _TransactionTableState();
}

class _TransactionTableState extends State<TransactionTable> {
  final ScrollController _horizontalScroll = ScrollController();
  final ScrollController _verticalScroll = ScrollController();

  @override
  void dispose() {
    _horizontalScroll.dispose();
    _verticalScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Sticky header (scrolls only horizontally)
          SingleChildScrollView(
            controller: _horizontalScroll,
            scrollDirection: Axis.horizontal,
            child: _TableHeader(
              colorScheme: colorScheme,
              sortField: widget.sortField,
              sortAscending: widget.sortAscending,
              onSort: widget.onSort,
            ),
          ),
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),

          // ── Scrollable body (both axes)
          Expanded(
            child: Scrollbar(
              controller: _verticalScroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _verticalScroll,
                child: Scrollbar(
                  controller: _horizontalScroll,
                  thumbVisibility: true,
                  notificationPredicate: (n) => n.depth == 1,
                  child: SingleChildScrollView(
                    controller: _horizontalScroll,
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      children: [
                        for (
                          int i = 0;
                          i < widget.transactions.length;
                          i++
                        ) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              color: colorScheme.outline.withValues(
                                alpha: 0.05,
                              ),
                            ),
                          _TransactionRow(
                            txn: widget.transactions[i],
                            isSelected:
                                widget.selectedTransactionId ==
                                widget.transactions[i]['tranId'] as String,
                            colorScheme: colorScheme,
                            onTap: () =>
                                widget.onRowTap(widget.transactions[i]),
                            onContextMenu: (pos) => widget.onContextMenu(
                              context,
                              pos,
                              widget.transactions[i],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.colorScheme,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
  });

  final ColorScheme colorScheme;
  final TransactionSortField sortField;
  final bool sortAscending;
  final void Function(TransactionSortField) onSort;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.02),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          _SortableHeader(
            label: 'Transaction ID',
            width: _kColTranId,
            field: TransactionSortField.tranId,
            active: sortField == TransactionSortField.tranId,
            ascending: sortAscending,
            colorScheme: colorScheme,
            onSort: onSort,
          ),
          _SortableHeader(
            label: 'Patient Name / ID',
            width: _kColPatient,
            field: TransactionSortField.patientName,
            active: sortField == TransactionSortField.patientName,
            ascending: sortAscending,
            colorScheme: colorScheme,
            onSort: onSort,
          ),
          _HeaderCell(
            label: 'Services',
            width: _kColServices,
            colorScheme: colorScheme,
          ),
          _SortableHeader(
            label: 'Amount Due',
            width: _kColAmountDue,
            field: TransactionSortField.amountDue,
            active: sortField == TransactionSortField.amountDue,
            ascending: sortAscending,
            colorScheme: colorScheme,
            onSort: onSort,
          ),
          _SortableHeader(
            label: 'Amount Paid',
            width: _kColAmountPaid,
            field: TransactionSortField.amountPaid,
            active: sortField == TransactionSortField.amountPaid,
            ascending: sortAscending,
            colorScheme: colorScheme,
            onSort: onSort,
          ),
          _HeaderCell(
            label: 'Payment Method',
            width: _kColMethod,
            colorScheme: colorScheme,
          ),
          _HeaderCell(
            label: 'Discount',
            width: _kColDiscount,
            colorScheme: colorScheme,
          ),
          _SortableHeader(
            label: 'Date & Time',
            width: _kColDate,
            field: TransactionSortField.date,
            active: sortField == TransactionSortField.date,
            ascending: sortAscending,
            colorScheme: colorScheme,
            onSort: onSort,
          ),
          _SortableHeader(
            label: 'Outstanding Debt',
            width: _kColDebt,
            field: TransactionSortField.debt,
            active: sortField == TransactionSortField.debt,
            ascending: sortAscending,
            colorScheme: colorScheme,
            onSort: onSort,
          ),
          _SortableHeader(
            label: 'Initiated By',
            width: _kColInitiator,
            field: TransactionSortField.initiator,
            active: sortField == TransactionSortField.initiator,
            ascending: sortAscending,
            colorScheme: colorScheme,
            onSort: onSort,
          ),
          _HeaderCell(
            label: 'Status',
            width: _kColStatus,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

// A non-sortable header cell.
class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.width,
    required this.colorScheme,
  });
  final String label;
  final double width;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

// A clickable column header that shows a sort indicator.
class _SortableHeader extends StatelessWidget {
  const _SortableHeader({
    required this.label,
    required this.width,
    required this.field,
    required this.active,
    required this.ascending,
    required this.colorScheme,
    required this.onSort,
  });

  final String label;
  final double width;
  final TransactionSortField field;
  final bool active;
  final bool ascending;
  final ColorScheme colorScheme;
  final void Function(TransactionSortField) onSort;

  @override
  Widget build(BuildContext context) {
    final labelColor = active
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: () => onSort(field),
      child: SizedBox(
        width: width,
        child: Row(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: labelColor,
              ),
            ),
            const SizedBox(width: 4),
            if (active)
              Icon(
                ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: colorScheme.primary,
              )
            else
              Icon(
                Icons.unfold_more,
                size: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Row ──────────────────────────────────────────────────────────────────────

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.txn,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
    required this.onContextMenu,
  });

  final TransactionMap txn;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final ValueChanged<Offset> onContextMenu;

  Color _statusColor(String? status) => switch (status) {
    'PAID' => Colors.green,
    'PARTIALLY_PAID' => Colors.orange,
    'CANCELLED' => Colors.red,
    'REFUNDED' => Colors.purple,
    'ACTIVE' => colorScheme.primary,
    _ => colorScheme.onSurface.withValues(alpha: 0.5),
  };

  @override
  Widget build(BuildContext context) {
    final status = txn['status'] as String? ?? '';
    final statusColor = _statusColor(status);

    return GestureDetector(
      onSecondaryTapDown: (d) => onContextMenu(d.globalPosition),
      onLongPressStart: (d) => onContextMenu(d.globalPosition),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.06)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Transaction ID
              SizedBox(
                width: _kColTranId,
                child: Text(
                  txn['tranId'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),

              // Patient name + ID
              SizedBox(
                width: _kColPatient,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      txn['patientName'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      txn['patientId'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // Services count
              SizedBox(
                width: _kColServices,
                child: Text(
                  '${txn['serviceCount']} services',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                ),
              ),

              // Amount due
              SizedBox(
                width: _kColAmountDue,
                child: Text(
                  '\$${(txn['amountDue'] as num).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                ),
              ),

              // Amount paid
              SizedBox(
                width: _kColAmountPaid,
                child: Text(
                  '\$${(txn['amountPaid'] as num).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),

              // Payment method
              SizedBox(
                width: _kColMethod,
                child: Text(
                  txn['paymentMethod'] as String,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                ),
              ),

              // Discount
              SizedBox(
                width: _kColDiscount,
                child: Text(
                  '\$${(txn['discount'] as num).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),

              // Date & time
              SizedBox(
                width: _kColDate,
                child: Text(
                  txn['date'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),

              // Debt
              SizedBox(
                width: _kColDebt,
                child: Text(
                  '\$${(txn['debt'] as num).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: (txn['debt'] as num) > 0
                        ? Colors.red
                        : colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),

              // Initiated by
              SizedBox(
                width: _kColInitiator,
                child: Text(
                  txn['initiator'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),

              // Status badge
              SizedBox(
                width: _kColStatus,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
