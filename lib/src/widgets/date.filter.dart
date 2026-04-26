import 'package:flutter/material.dart';

import '../helper/date.formatter.dart';

/// Below this width, From/To stack vertically with compact date labels.
const kDateFilterCompactBreakpoint = 680.0;

/// How date chips label their selected day in [FromToDateFilter] on **wide**
/// layouts. On narrow layouts, labels are always shortened for fit.
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

  /// Display style for From/To date text on **desktop / wide** layouts.
  /// Default is [DateFilterLabelStyle.full].
  final DateFilterLabelStyle labelStyle;

  const FromToDateFilter({
    super.key,
    required this.onFilterChanged,
    required this.doRefresh,
    required this.dateFilter,
    this.labelStyle = DateFilterLabelStyle.full,
  });

  @override
  State<FromToDateFilter> createState() => _FromToDateFilterState();
}

class _FromToDateFilterState extends State<FromToDateFilter> {
  DateTime? _fromDate;
  DateTime? _toDate;
  Function? doRefresh;

  @override
  void initState() {
    super.initState();
    doRefresh = widget.doRefresh;
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
    );
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
      );
    });
    _notifyParent();
    doRefresh?.call();
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
      firstDate: _fromDate!,
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

  Widget _resetButton(ColorScheme scheme) {
    return TextButton.icon(
      onPressed: _resetFilters,
      icon: const Icon(Icons.refresh, size: 18),
      label: const Text('Reset'),
      style: TextButton.styleFrom(foregroundColor: scheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < kDateFilterCompactBreakpoint;

        return Container(
          padding: EdgeInsets.all(narrow ? 12 : 16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: narrow ? _buildCompact(scheme) : _buildWide(scheme),
        );
      },
    );
  }

  Widget _buildWide(ColorScheme scheme) {
    return Row(
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
                    labelStyle: widget.labelStyle,
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
                    labelStyle: widget.labelStyle,
                    compact: false,
                  ),
                ),
              ],
            ),
          )
        else
          const Spacer(),
        _resetButton(scheme),
      ],
    );
  }

  Widget _buildCompact(ColorScheme scheme) {
    if (!widget.dateFilter) {
      return Align(
        alignment: Alignment.centerRight,
        child: _resetButton(scheme),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DateTile(
          label: 'From',
          date: _fromDate,
          onTap: _pickFromDate,
          labelStyle: widget.labelStyle,
          compact: true,
        ),
        const SizedBox(height: 8),
        _DateTile(
          label: 'To',
          date: _toDate,
          isEnabled: _fromDate != null,
          onTap: _pickToDate,
          labelStyle: widget.labelStyle,
          compact: true,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: _resetButton(scheme),
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
  final DateFilterLabelStyle labelStyle;
  final bool compact;

  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
    this.isEnabled = true,
    this.labelStyle = DateFilterLabelStyle.full,
    this.compact = false,
  });

  String _formatDate(DateTime d) {
    if (compact) {
      switch (labelStyle) {
        case DateFilterLabelStyle.shortUs:
          return DateFormatter.shortNumericUs(d);
        case DateFilterLabelStyle.full:
          return DateFormatter.medicalDate(d);
      }
    }
    switch (labelStyle) {
      case DateFilterLabelStyle.shortUs:
        return DateFormatter.shortNumericUs(d);
      case DateFilterLabelStyle.full:
        return DateFormatter.fullDate(d);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final placeholder = compact ? 'Tap to choose' : 'Select date';

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.45,
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
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
                              date != null ? _formatDate(date!) : placeholder,
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
                              date != null ? _formatDate(date!) : placeholder,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
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
