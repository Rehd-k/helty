import 'package:flutter/material.dart';

import '../helper/date.formatter.dart';

/// When parent width is below this, filters stack vertically (phone / narrow).
const kPatientsFilterCompactBreakpoint = 680.0;

class PatientsFilterWidget extends StatefulWidget {
  final List<Map<String, String>> searchCategories;
  final Function doRefresh;
  final bool dateFilter;
  final Function(String query, String category, DateTime? from, DateTime? to)
  onFilterChanged;

  const PatientsFilterWidget({
    super.key,
    required this.searchCategories,
    required this.onFilterChanged,
    required this.doRefresh,
    required this.dateFilter,
  });

  @override
  State<PatientsFilterWidget> createState() => _PatientsFilterWidgetState();
}

class _PatientsFilterWidgetState extends State<PatientsFilterWidget> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.searchCategories.first['name'];
    if (widget.dateFilter) {
      final now = DateTime.now();
      _fromDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
      _toDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    } else {
      _fromDate = null;
      _toDate = null;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyParent();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = widget.searchCategories.first['name'];
      if (widget.dateFilter) {
        final now = DateTime.now();
        _fromDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
        _toDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      } else {
        _fromDate = null;
        _toDate = null;
      }
    });
    _notifyParent();
  }

  void _notifyParent() {
    widget.onFilterChanged(
      _searchController.text,
      _selectedCategory!,
      widget.dateFilter ? _fromDate : null,
      widget.dateFilter ? _toDate : null,
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
      firstDate: _fromDate!,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _toDate = picked);
      _notifyParent();
    }
  }

  InputDecoration _fieldDecoration(ColorScheme scheme) {
    return InputDecoration(
      hintText: 'Search…',
      prefixIcon: const Icon(Icons.search, size: 22),
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
    );
  }

  InputDecoration _dropdownDecoration(ColorScheme scheme) {
    return InputDecoration(
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.12)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow =
              constraints.maxWidth < kPatientsFilterCompactBreakpoint;

          return Padding(
            padding: EdgeInsets.all(narrow ? 12 : 16),
            child: narrow
                ? _buildCompactLayout(context, scheme)
                : _buildWideLayout(context, scheme),
          );
        },
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _notifyParent(),
                decoration: _fieldDecoration(scheme),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: _dropdownDecoration(scheme),
                items: widget.searchCategories.map((cat) {
                  return DropdownMenuItem(
                    value: cat['name'],
                    child: Text(cat['value']!),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() => _selectedCategory = val);
                  _notifyParent();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.dateFilter)
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _DateTile(
                        label: 'From',
                        date: _fromDate,
                        onTap: _pickFromDate,
                        compact: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateTile(
                        label: 'To',
                        date: _toDate,
                        isEnabled: _fromDate != null,
                        onTap: _pickToDate,
                        compact: false,
                      ),
                    ),
                  ],
                ),
              )
            else
              const Spacer(),
            TextButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset'),
              style: TextButton.styleFrom(foregroundColor: scheme.error),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactLayout(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => _notifyParent(),
          decoration: _fieldDecoration(scheme),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          isExpanded: true,
          decoration: _dropdownDecoration(scheme),
          items: widget.searchCategories.map((cat) {
            return DropdownMenuItem(
              value: cat['name'],
              child: Text(cat['value']!),
            );
          }).toList(),
          onChanged: (val) {
            if (val == null) return;
            setState(() => _selectedCategory = val);
            _notifyParent();
          },
        ),
        if (widget.dateFilter) ...[
          const SizedBox(height: 10),
          _DateTile(
            label: 'From',
            date: _fromDate,
            onTap: _pickFromDate,
            compact: true,
          ),
          const SizedBox(height: 8),
          _DateTile(
            label: 'To',
            date: _toDate,
            isEnabled: _fromDate != null,
            onTap: _pickToDate,
            compact: true,
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _resetFilters,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reset'),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
          ),
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool isEnabled;
  final bool compact;

  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
    this.isEnabled = true,
    this.compact = false,
  });

  String _dateLabel(BuildContext context) {
    if (date == null) {
      return compact ? 'Tap to choose' : 'Select date';
    }
    if (compact) {
      return DateFormatter.shortDate(date!);
    }
    return DateFormatter.medicalDate(date!);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.45,
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 14,
              vertical: compact ? 10 : 12,
            ),
            child: compact
                ? Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: textTheme.labelMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _dateLabel(context),
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant,
                        size: 22,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 22,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label.toUpperCase(),
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dateLabel(context),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
