import 'package:flutter/material.dart';

import '../helper/app_timezone.dart';
import '../helper/date.formatter.dart';

const _kFromAccent = Color(0xFF16A34A);
const _kToAccent = Color(0xFFEA580C);
const _kCalendarAccent = Color(0xFF7C3AED);

/// Below this width, From/To stack vertically with compact date labels.
const kDateFilterCompactBreakpoint = 680.0;

/// Kept for existing callers. From/To always shows [DateFormatter.shortDate]
/// (`dd/MM/yyyy`).
enum DateFilterLabelStyle { full, shortUs }

class FromToDateFilter extends StatefulWidget {
  final Function doRefresh;
  final bool dateFilter;
  final Function(String query, String category, DateTime? from, DateTime? to)
  onFilterChanged;

  /// Display style for From/To date text on **desktop / wide** layouts.
  /// Default is [DateFilterLabelStyle.full].
  final DateFilterLabelStyle labelStyle;

  /// Solid saturated From/To tiles (green / orange) instead of muted chips.
  final bool colorful;

  /// When set, used instead of today for the initial From/To values.
  final DateTime? initialFrom;
  final DateTime? initialTo;

  /// When false, skip the first-frame parent notify (for reuse in menus).
  final bool notifyOnInit;

  const FromToDateFilter({
    super.key,
    required this.onFilterChanged,
    required this.doRefresh,
    required this.dateFilter,
    this.labelStyle = DateFilterLabelStyle.full,
    this.colorful = false,
    this.initialFrom,
    this.initialTo,
    this.notifyOnInit = true,
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
    _fromDate = widget.initialFrom ?? AppTimezone.startOfDay();
    _toDate = widget.initialTo ?? AppTimezone.endOfDay();
    if (widget.notifyOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyParent();
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _fromDate = AppTimezone.startOfDay();
      _toDate = AppTimezone.endOfDay();
    });
    _notifyParent();
    doRefresh?.call();
  }

  void _notifyParent() {
    widget.onFilterChanged('', '', _fromDate, _toDate);
  }

  Future<DateTime?> _showThemedPicker({
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required Color accent,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('en', 'GB'),
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: accent,
              onPrimary: Colors.white,
              surfaceTint: accent,
            ),
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: accent,
              headerForegroundColor: Colors.white,
              rangePickerHeaderBackgroundColor: accent,
              rangePickerHeaderForegroundColor: Colors.white,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return null;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return accent;
                return null;
              }),
              todayForegroundColor: WidgetStateProperty.all(accent),
              todayBorder: BorderSide(color: accent, width: 1.5),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<void> _pickFromDate() async {
    final picked = await _showThemedPicker(
      initialDate: _fromDate ?? AppTimezone.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      accent: widget.colorful
          ? _kFromAccent
          : Theme.of(context).colorScheme.primary,
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

    final picked = await _showThemedPicker(
      initialDate: _toDate ?? _fromDate!,
      firstDate: _fromDate!,
      lastDate: DateTime(2100),
      accent: widget.colorful
          ? _kToAccent
          : Theme.of(context).colorScheme.primary,
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
    if (widget.colorful) {
      return FilledButton.icon(
        onPressed: _resetFilters,
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text('Reset'),
        style: FilledButton.styleFrom(
          backgroundColor: _kCalendarAccent,
          foregroundColor: Colors.white,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }
    return TextButton.icon(
      onPressed: _resetFilters,
      icon: const Icon(Icons.refresh, size: 18),
      label: const Text('Reset'),
      style: TextButton.styleFrom(foregroundColor: scheme.error),
    );
  }

  Widget _fromTile() {
    return _DateTile(
      label: 'From',
      date: _fromDate,
      onTap: _pickFromDate,
      accent: widget.colorful ? _kFromAccent : null,
    );
  }

  Widget _toTile() {
    return _DateTile(
      label: 'To',
      date: _toDate,
      isEnabled: _fromDate != null,
      onTap: _pickToDate,
      accent: widget.colorful ? _kToAccent : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.colorful
                  ? _kCalendarAccent.withValues(alpha: 0.35)
                  : scheme.outline.withValues(alpha: 0.12),
              width: widget.colorful ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.colorful
                    ? _kCalendarAccent.withValues(alpha: 0.18)
                    : scheme.shadow.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: constraints.maxWidth < kDateFilterCompactBreakpoint
              ? _buildCompact(scheme)
              : _buildWide(scheme),
        );
      },
    );
  }

  Widget _buildWide(ColorScheme scheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (widget.dateFilter) ...[_fromTile(), _toTile()],
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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [_fromTile(), _toTile(), _resetButton(scheme)],
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool isEnabled;
  final Color? accent;

  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
    this.isEnabled = true,
    this.accent,
  });

  String _formatDate(DateTime d) => DateFormatter.shortDate(d);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final colorful = accent != null;
    final onAccent = Colors.white;
    final valueColor = colorful ? onAccent : scheme.onSurface;
    final iconColor = colorful ? onAccent : scheme.primary;
    final text = date != null
        ? '$label ${_formatDate(date!)}'
        : '$label Select';

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.45,
      child: Material(
        color: colorful
            ? accent
            : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(6),
          splashColor: colorful
              ? Colors.white.withValues(alpha: 0.2)
              : scheme.primary.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_outlined, size: 14, color: iconColor),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                    fontSize: 12,
                    height: 1.1,
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
