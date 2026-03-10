import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'transaction_models.dart' show TransactionStatus;

/// Slide-in filters panel for the Transactions screen.
/// Date from/to use inline date pickers (no full-screen range modal).
class TransactionFiltersPanel extends StatelessWidget {
  const TransactionFiltersPanel({
    super.key,
    required this.theme,
    required this.dateFrom,
    required this.dateTo,
    required this.onDateFromChanged,
    required this.onDateToChanged,
    required this.status,
    required this.onStatusChanged,
    required this.myTransactionsOnly,
    required this.onMyTransactionsOnlyChanged,
    required this.selectedUserId,
    required this.userOptions,
    required this.onUserChanged,
    required this.onApply,
    required this.onReset,
  });

  final ThemeData theme;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final ValueChanged<DateTime?> onDateFromChanged;
  final ValueChanged<DateTime?> onDateToChanged;
  final TransactionStatus? status;
  final ValueChanged<TransactionStatus?> onStatusChanged;
  final bool myTransactionsOnly;
  final ValueChanged<bool> onMyTransactionsOnlyChanged;
  final String? selectedUserId;
  final List<String> userOptions;
  final ValueChanged<String?> onUserChanged;
  final VoidCallback onApply;
  final VoidCallback onReset;

  static const List<TransactionStatus> _statusOptions = [
    TransactionStatus.paid,
    TransactionStatus.active,
    TransactionStatus.partiallyPaid,
    TransactionStatus.draft,
    TransactionStatus.cancelled,
    TransactionStatus.refunded,
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _buildDateRow(context),
          const SizedBox(height: 16),
          _buildStatusDropdown(context),
          const SizedBox(height: 16),
          _buildMyTransactionsSwitch(context),
          if (userOptions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildUserDropdown(context),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onApply,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Apply'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date from',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: dateFrom ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (d != null) onDateFromChanged(d);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              dateFrom != null
                  ? DateFormat('yyyy-MM-dd').format(dateFrom!)
                  : 'Select',
              style: TextStyle(
                color: dateFrom != null ? null : Colors.grey[600],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Date to',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: dateTo ?? dateFrom ?? DateTime.now(),
              firstDate: dateFrom ?? DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (d != null) onDateToChanged(d);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              dateTo != null
                  ? DateFormat('yyyy-MM-dd').format(dateTo!)
                  : 'Select',
              style: TextStyle(color: dateTo != null ? null : Colors.grey[600]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Status', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        DropdownButtonFormField<TransactionStatus?>(
          initialValue: status,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          isExpanded: true,
          items: [
            const DropdownMenuItem<TransactionStatus?>(
              value: null,
              child: Text('All'),
            ),
            ..._statusOptions.map(
              (s) => DropdownMenuItem<TransactionStatus?>(
                value: s,
                child: Text(s.label),
              ),
            ),
          ],
          onChanged: onStatusChanged,
        ),
      ],
    );
  }

  Widget _buildMyTransactionsSwitch(BuildContext context) {
    return SwitchListTile(
      title: Text('My transactions only', style: theme.textTheme.bodyMedium),
      value: myTransactionsOnly,
      onChanged: onMyTransactionsOnlyChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildUserDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('User', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: selectedUserId,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          isExpanded: true,
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Users'),
            ),
            ...userOptions.map(
              (u) => DropdownMenuItem<String>(
                value: u,
                child: Text(u, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: onUserChanged,
        ),
      ],
    );
  }
}
