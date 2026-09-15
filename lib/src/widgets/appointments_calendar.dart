import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../helper/app_timezone.dart';
import '../helper/date.formatter.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';

/// Month calendar that badges each day with booked appointment counts.
/// Shared by front desk and doctor My Appointments.
class AppointmentsCalendarCard extends StatefulWidget {
  const AppointmentsCalendarCard({
    super.key,
    this.footer,
    this.appointmentService,
    this.onDaySelected,
  });

  /// Optional caption under the month grid (e.g. today's total).
  final Widget? footer;

  final AppointmentService? appointmentService;

  /// Extra callback after a day is selected (sheet still opens).
  final ValueChanged<DateTime>? onDaySelected;

  @override
  State<AppointmentsCalendarCard> createState() =>
      _AppointmentsCalendarCardState();
}

class _AppointmentsCalendarCardState extends State<AppointmentsCalendarCard> {
  late final AppointmentService _service;
  DateTime _focusedDay = AppTimezone.now();
  DateTime? _selectedDay;
  final Map<DateTime, int> _calendarCounts = {};
  final Set<String> _calendarMonthsLoaded = {};
  int _calendarLoadsInFlight = 0;
  bool _loadingCalendarCounts = false;

  static DateTime _calendarDateKey(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  static String _calendarMonthKey(DateTime d) => '${d.year}-${d.month}';

  @override
  void initState() {
    super.initState();
    _service = widget.appointmentService ?? AppointmentService();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureCalendarCountsForMonth(_focusedDay);
    });
  }

  int _appointmentCountOnDay(DateTime day) =>
      _calendarCounts[_calendarDateKey(day)] ?? 0;

  Future<void> _ensureCalendarCountsForMonth(DateTime month) async {
    final key = _calendarMonthKey(month);
    if (_calendarMonthsLoaded.contains(key)) return;

    _calendarLoadsInFlight++;
    if (_calendarLoadsInFlight == 1 && mounted) {
      setState(() => _loadingCalendarCounts = true);
    }

    try {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999);
      final counts = await _service.getCalendarCounts(
        fromDate: start,
        toDate: end,
      );
      if (!mounted) return;
      setState(() {
        _calendarCounts.addAll(counts);
        _calendarMonthsLoaded.add(key);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load appointment counts: $e')),
      );
    } finally {
      _calendarLoadsInFlight--;
      if (mounted && _calendarLoadsInFlight == 0) {
        setState(() => _loadingCalendarCounts = false);
      }
    }
  }

  Future<void> _openDayAppointmentsSheet(DateTime day) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) =>
          _DayAppointmentsBottomSheet(day: day, service: _service),
    );
  }

  Widget _buildCalendarDayCell(
    BuildContext context,
    DateTime day,
    ColorScheme colorScheme, {
    required bool isSelected,
    required bool isToday,
  }) {
    final count = _appointmentCountOnDay(day);
    final badge = count > 0
        ? Positioned(
            right: 2,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.onPrimary.withValues(alpha: 0.92)
                    : colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onPrimary,
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    final number = Text(
      '${day.day}',
      style: TextStyle(
        fontSize: 12,
        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? colorScheme.onPrimary
            : (isToday ? colorScheme.primary : colorScheme.onSurface),
      ),
    );

    if (isSelected) {
      return Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.all(6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: number,
            ),
          ),
          badge,
        ],
      );
    }
    if (isToday) {
      return Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.all(6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: number,
            ),
          ),
          badge,
        ],
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        Center(child: number),
        badge,
      ],
    );
  }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_loadingCalendarCounts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(
                minHeight: 2,
                borderRadius: BorderRadius.circular(2),
                color: colorScheme.primary,
              ),
            ),
          TableCalendar(
            firstDay: DateTime.utc(2020, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              widget.onDaySelected?.call(selectedDay);
              _openDayAppointmentsSheet(selectedDay);
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
              _ensureCalendarCountsForMonth(focusedDay);
            },
            calendarFormat: CalendarFormat.month,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: false,
              titleTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              leftChevronIcon: const Icon(Icons.chevron_left, size: 20),
              rightChevronIcon: const Icon(Icons.chevron_right, size: 20),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              weekendStyle: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                return _buildCalendarDayCell(
                  context,
                  day,
                  colorScheme,
                  isSelected: false,
                  isToday: isSameDay(day, AppTimezone.now()),
                );
              },
              selectedBuilder: (context, day, focusedDay) {
                return _buildCalendarDayCell(
                  context,
                  day,
                  colorScheme,
                  isSelected: true,
                  isToday: isSameDay(day, AppTimezone.now()),
                );
              },
              todayBuilder: (context, day, focusedDay) {
                final sel = isSameDay(_selectedDay, day);
                return _buildCalendarDayCell(
                  context,
                  day,
                  colorScheme,
                  isSelected: sel,
                  isToday: true,
                );
              },
            ),
          ),
          if (widget.footer != null) ...[
            const SizedBox(height: 12),
            widget.footer!,
          ],
        ],
      ),
    );
  }
}

class _DayAppointmentsBottomSheet extends StatefulWidget {
  const _DayAppointmentsBottomSheet({required this.day, required this.service});

  final DateTime day;
  final AppointmentService service;

  @override
  State<_DayAppointmentsBottomSheet> createState() =>
      _DayAppointmentsBottomSheetState();
}

class _DayAppointmentsBottomSheetState
    extends State<_DayAppointmentsBottomSheet> {
  late final Future<({List<Appointment> items, int total})> _future;

  @override
  void initState() {
    super.initState();
    final start = DateTime(widget.day.year, widget.day.month, widget.day.day);
    final end = DateTime(
      widget.day.year,
      widget.day.month,
      widget.day.day,
      23,
      59,
      59,
      999,
    );
    _future = widget.service.findAll(
      skip: 0,
      take: 200,
      fromDate: start,
      toDate: end,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = DateFormatter.shortDate(widget.day);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            Expanded(
              child: FutureBuilder<({List<Appointment> items, int total})>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          '${snap.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  final data = snap.data!;
                  final items = data.items;
                  if (items.isEmpty) {
                    return ListView(
                      controller: scrollController,
                      children: const [
                        SizedBox(height: 48),
                        Center(child: Text('No appointments on this day.')),
                      ],
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount:
                        items.length + (data.total > items.length ? 1 : 0),
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    itemBuilder: (context, i) {
                      if (i == items.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '${data.total} total — showing first ${items.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      final a = items[i];
                      final local = a.appointmentDate.toLocal();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          a.patientDisplayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${DateFormatter.medicalDate(local)} · ${DateFormat.jm().format(local)}\n'
                          '${a.doctorDisplayName} · ${a.status}',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        isThreeLine: true,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
