import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/purchases_model.dart';
import 'purchases_inventory_screen.dart' show FilterPillType;

class ItemFiltersPanel extends StatelessWidget {
  const ItemFiltersPanel({
    super.key,
    required this.theme,
    required this.searchController,
    required this.onPerformSearch,
    required this.filterPill,
    required this.onFilterPillChanged,
    required this.manufacturers,
    required this.suppliers,
    required this.selectedManufacturerId,
    required this.onManufacturerChanged,
    required this.selectedSupplierId,
    required this.onSupplierChanged,
    required this.manufacturingDateFrom,
    required this.manufacturingDateTo,
    required this.onManufacturingDateFromChanged,
    required this.onManufacturingDateToChanged,
    required this.expiryDateFrom,
    required this.expiryDateTo,
    required this.onExpiryDateFromChanged,
    required this.onExpiryDateToChanged,
    required this.onClear,
  });

  final ThemeData theme;

  final TextEditingController searchController;
  final VoidCallback onPerformSearch;

  final FilterPillType filterPill;
  final ValueChanged<FilterPillType> onFilterPillChanged;

  final List<PurchasesManufacturer> manufacturers;
  final List<PurchasesSupplier> suppliers;

  final String? selectedManufacturerId;
  final ValueChanged<String?> onManufacturerChanged;

  final String? selectedSupplierId;
  final ValueChanged<String?> onSupplierChanged;

  final DateTime? manufacturingDateFrom;
  final DateTime? manufacturingDateTo;
  final ValueChanged<DateTime?> onManufacturingDateFromChanged;
  final ValueChanged<DateTime?> onManufacturingDateToChanged;

  final DateTime? expiryDateFrom;
  final DateTime? expiryDateTo;
  final ValueChanged<DateTime?> onExpiryDateFromChanged;
  final ValueChanged<DateTime?> onExpiryDateToChanged;

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildSearchRow(context),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.35,
                child: FilledButton.icon(
                  onPressed: onPerformSearch,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Search'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: onClear,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPillsRow(),
          const SizedBox(height: 16),
          _buildDropdownsAndDates(context),
        ],
      ),
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: 'Search items...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      onSubmitted: (_) => onPerformSearch(),
    );
  }

  Widget _buildPillsRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          'All',
          isSelected: filterPill == FilterPillType.all,
          onTap: () => onFilterPillChanged(FilterPillType.all),
        ),
        _buildFilterChip(
          'In Stock',
          isSelected: filterPill == FilterPillType.inStock,
          onTap: () => onFilterPillChanged(FilterPillType.inStock),
        ),
        _buildFilterChip(
          'Low Stock',
          isSelected: filterPill == FilterPillType.lowStock,
          highlightColor: Colors.orange,
          onTap: () => onFilterPillChanged(FilterPillType.lowStock),
        ),
        _buildFilterChip(
          'Expiring Soon',
          isSelected: filterPill == FilterPillType.expiringSoon,
          highlightColor: Colors.red,
          onTap: () => onFilterPillChanged(FilterPillType.expiringSoon),
        ),
      ],
    );
  }

  Widget _buildDropdownsAndDates(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildFilterDropdown<String?>(
          label: 'Manufacturer',
          value: selectedManufacturerId,
          items: [
            const DropdownMenuItem(value: null, child: Text('All')),
            ...manufacturers.map(
              (m) => DropdownMenuItem<String?>(
                value: m.id,
                child: Text(m.name, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: onManufacturerChanged,
        ),
        _buildFilterDropdown<String?>(
          label: 'Supplier',
          value: selectedSupplierId,
          items: [
            const DropdownMenuItem(value: null, child: Text('All')),
            ...suppliers.map(
              (s) => DropdownMenuItem<String?>(
                value: s.id,
                child: Text(s.name, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: onSupplierChanged,
        ),
        _buildDateRangeFilter(
          context: context,
          labelFrom: 'Manufacturing from',
          labelTo: 'Manufacturing to',
          from: manufacturingDateFrom,
          to: manufacturingDateTo,
          onFrom: onManufacturingDateFromChanged,
          onTo: onManufacturingDateToChanged,
        ),
        _buildDateRangeFilter(
          context: context,
          labelFrom: 'Expiry from',
          labelTo: 'Expiry to',
          from: expiryDateFrom,
          to: expiryDateTo,
          onFrom: onExpiryDateFromChanged,
          onTo: onExpiryDateToChanged,
        ),
      ],
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          DropdownButtonFormField<T>(
            initialValue: value,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeFilter({
    required BuildContext context,
    required String labelFrom,
    required String labelTo,
    required DateTime? from,
    required DateTime? to,
    required ValueChanged<DateTime?> onFrom,
    required ValueChanged<DateTime?> onTo,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                labelFrom,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: from ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) onFrom(d);
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
                    from != null
                        ? DateFormat('yyyy-MM-dd').format(from)
                        : 'Select',
                    style: TextStyle(
                      color: from != null ? null : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                labelTo,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: to ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) onTo(d);
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
                    to != null ? DateFormat('yyyy-MM-dd').format(to) : 'Select',
                    style: TextStyle(
                      color: to != null ? null : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label, {
    required bool isSelected,
    Color? highlightColor,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? theme.colorScheme.primary : Colors.grey[700],
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.transparent,
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
