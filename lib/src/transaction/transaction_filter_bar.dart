import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Filter bar for the transactions screen.
///
/// Provides controls for:
/// - Toggle: All Transactions / My Transactions
/// - User dropdown
/// - Search field type dropdown + text input
/// - Date range picker
/// - Reset button
class TransactionFilterBar extends StatelessWidget {
  const TransactionFilterBar({
    super.key,
    required this.showingMyTransactionsOnly,
    required this.selectedUserFilter,
    required this.searchField,
    required this.searchController,
    required this.selectedDateRange,
    required this.onToggleMyTransactions,
    required this.onUserFilterChanged,
    required this.onSearchFieldChanged,
    required this.onPickDateRange,
    required this.onReset,
  });

  final bool showingMyTransactionsOnly;
  final String selectedUserFilter;
  final String searchField;
  final TextEditingController searchController;
  final DateTimeRange? selectedDateRange;

  final ValueChanged<bool> onToggleMyTransactions;
  final ValueChanged<String?> onUserFilterChanged;
  final ValueChanged<String?> onSearchFieldChanged;
  final VoidCallback onPickDateRange;
  final VoidCallback onReset;

  static const List<String> _userFilterItems = [
    'All Users',
    'Sarah Jenkins',
    'Michael Chen',
    'Alan Grant',
  ];

  static const List<String> _searchFieldItems = [
    'Transaction ID',
    'Patient ID',
    'Patient Name',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // All / My Transactions toggle
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('All Transactions', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: true,
                label: Text('My Transactions', style: TextStyle(fontSize: 12)),
              ),
            ],
            selected: {showingMyTransactionsOnly},
            onSelectionChanged: (Set<bool> newSelection) =>
                onToggleMyTransactions(newSelection.first),
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),

          // User dropdown
          _DropdownFilter(
            value: selectedUserFilter,
            items: _userFilterItems,
            onChanged: onUserFilterChanged,
          ),

          // Search field type dropdown
          _DropdownFilter(
            value: searchField,
            items: _searchFieldItems,
            onChanged: onSearchFieldChanged,
          ),

          // Search input
          SizedBox(
            width: 200,
            height: 40,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search...",
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),

          // Date range picker button
          OutlinedButton.icon(
            onPressed: onPickDateRange,
            icon: Icon(Icons.date_range, size: 16, color: colorScheme.primary),
            label: Text(
              selectedDateRange == null
                  ? "Date Range"
                  : "${DateFormat('MMM d').format(selectedDateRange!.start)} - ${DateFormat('MMM d').format(selectedDateRange!.end)}",
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
          ),

          // Reset button
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text("Reset", style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

/// Internal reusable styled dropdown widget.
class _DropdownFilter extends StatelessWidget {
  const _DropdownFilter({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
