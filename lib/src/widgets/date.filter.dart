import 'package:flutter/material.dart';

import '../helper/date.formatter.dart';

/// How date chips label their selected day in [FromToDateFilter].
enum DateFilterLabelStyle {
  /// e.g. Monday, April 5, 2026
  full,

  /// e.g. 4/5/2026
  shortUs,
}

class FromToDateFilter extends StatefulWidget {
  final Function doRefresh;
  final bool dateFilter;
  final Function(String query, String category, DateTime? from, DateTime? to)
  onFilterChanged;

  /// Display style for From/To date text. Default is [DateFilterLabelStyle.full].
  final DateFilterLabelStyle labelStyle;

  const FromToDateFilter({
    super.key,
    required this.onFilterChanged,
    required this.doRefresh,
    required this.dateFilter,
    this.labelStyle = DateFilterLabelStyle.full,
  });

  @override
  State<FromToDateFilter> createState() => _PatientsFilterWidgetState();
}

class _PatientsFilterWidgetState extends State<FromToDateFilter> {
  DateTime? _fromDate;
  DateTime? _toDate;
  Function? doRefresh;

  @override
  void initState() {
    super.initState();
    doRefresh = widget.doRefresh;
    // Default date range: start of today to end of today
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
    _toDate = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
      999,
    ); // inclusive
    // Notify parent immediately so endpoints always receive a date range
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyParent();
    });
  }

  void _resetFilters() {
    setState(() {
      final now = DateTime.now();
      _fromDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
      _toDate = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
        999,
      ); // inclusive
    });
    _notifyParent();
    if (doRefresh != null) {
      doRefresh!();
    }
  }

  void _notifyParent() {
    widget.onFilterChanged('', '', _fromDate, _toDate);
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
        _fromDate = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
        if (_toDate == null || _toDate!.isBefore(_fromDate!)) {
          _toDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            23,
            59,
            59,
            999,
          );
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
      setState(() {
        _toDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
          999,
        );
      });
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
      child: Row(
        children: [
          if (widget.dateFilter)
            Row(
              children: [
                _DateTile(
                  label: 'From',
                  date: _fromDate,
                  onTap: _pickFromDate,
                  labelStyle: widget.labelStyle,
                ),
                const SizedBox(width: 12),
                _DateTile(
                  label: 'To',
                  date: _toDate,
                  isEnabled: _fromDate != null,
                  onTap: _pickToDate,
                  labelStyle: widget.labelStyle,
                ),
              ],
            ),
          const Spacer(),
          TextButton.icon(
            onPressed: _resetFilters,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reset'),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
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
  final DateFilterLabelStyle labelStyle;

  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
    this.isEnabled = true,
    this.labelStyle = DateFilterLabelStyle.full,
  });

  String _formatDate(DateTime d) {
    switch (labelStyle) {
      case DateFilterLabelStyle.shortUs:
        return DateFormatter.shortNumericUs(d);
      case DateFilterLabelStyle.full:
        return DateFormatter.fullDate(d);
    }
  }

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
                date != null ? _formatDate(date!) : 'Select Date',
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
