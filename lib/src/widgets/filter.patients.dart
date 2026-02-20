import 'package:flutter/material.dart';

import '../helper/date.formatter.dart';

class PatientsFilterWidget extends StatefulWidget {
  final List<String> searchCategories;
  final Function doRefresh;
  final Function(String query, String category, DateTime? from, DateTime? to)
  onFilterChanged;

  const PatientsFilterWidget({
    super.key,
    required this.searchCategories,
    required this.onFilterChanged,
    required this.doRefresh,
  });

  @override
  State<PatientsFilterWidget> createState() => _PatientsFilterWidgetState();
}

class _PatientsFilterWidgetState extends State<PatientsFilterWidget> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  DateTime? _fromDate;
  DateTime? _toDate;
  Function? doRefresh;

  @override
  void initState() {
    super.initState();
    doRefresh = widget.doRefresh;
    _selectedCategory = widget.searchCategories.first;
  }

  void _resetFilters() {
    doRefresh!();
    setState(() {
      _searchController.clear();
      _selectedCategory = widget.searchCategories.first;
      _fromDate = null;
      _toDate = null;
    });
    _notifyParent();
  }

  void _notifyParent() {
    widget.onFilterChanged(
      _searchController.text,
      _selectedCategory!,
      _fromDate,
      _toDate,
    );
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        // Reset "to" date if it becomes invalid
        if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
          _toDate = null;
        }
      });
      _notifyParent();
    }
  }

  Future<void> _pickToDate() async {
    if (_fromDate == null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate!,
      firstDate: _fromDate!, // Cannot go beyond "from" date
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _toDate = picked);
      _notifyParent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Search Bar
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _notifyParent(),
                  decoration: InputDecoration(
                    hintText: 'Search...', // French for Search...
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Category Dropdown
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items: widget.searchCategories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedCategory = val);
                    _notifyParent();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // From Date
              _DateTile(
                label: 'From', // French for "From"
                date: _fromDate,
                onTap: _pickFromDate,
              ),
              const SizedBox(width: 12),
              // To Date
              _DateTile(
                label: 'To', // French for "To"
                date: _toDate,
                isEnabled: _fromDate != null,
                onTap: _pickToDate,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  _resetFilters;
                  doRefresh;
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset'), // French for Reset
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool isEnabled;

  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                '$label: ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                date != null ? DateFormatter.fullDate(date!) : 'Select Date',
              ),
              SizedBox(width: 4),
              const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }
}
