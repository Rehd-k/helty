import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../app_router.gr.dart';
import '../helper/date.formatter.dart';
import '../models/appointment_model.dart';
import '../models/frontdesk_dashboard_models.dart';
import '../models/staff_model.dart';
import '../providers/auth_provider.dart';
import '../services/appointment_service.dart';
import '../services/frontdesk_dashboard_service.dart';
import 'widgets/check_in_patient_dialog.dart';

@RoutePage()
class FrontDeskDashboardScreen extends ConsumerStatefulWidget {
  const FrontDeskDashboardScreen({super.key});

  @override
  ConsumerState<FrontDeskDashboardScreen> createState() =>
      _FrontDeskDashboardState();
}

class _FrontDeskDashboardState extends ConsumerState<FrontDeskDashboardScreen> {
  final FrontdeskDashboardService _api = FrontdeskDashboardService();
  final AppointmentService _appointmentService = AppointmentService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<DateTime, int> _calendarCounts = {};
  final Set<String> _calendarMonthsLoaded = {};
  int _calendarLoadsInFlight = 0;
  bool _loadingCalendarCounts = false;

  FrontdeskDashboardSummary? _summary;
  List<FrontdeskQueueRow> _queue = [];

  bool _loadingSummary = true;
  bool _loadingQueue = true;
  String? _summaryError;
  String? _queueError;

  Timer? _queuePoll;
  Timer? _summaryPoll;

  static const _queuePollSeconds = 20;
  static const _summaryPollMinutes = 2;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSummary();
      _loadQueue();
      _ensureCalendarCountsForMonth(_focusedDay);
      _queuePoll = Timer.periodic(
        const Duration(seconds: _queuePollSeconds),
        (_) => _loadQueue(),
      );
      _summaryPoll = Timer.periodic(
        const Duration(minutes: _summaryPollMinutes),
        (_) => _loadSummary(),
      );
    });
  }

  @override
  void dispose() {
    _queuePoll?.cancel();
    _summaryPoll?.cancel();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _summaryError = null;
      if (_summary == null) _loadingSummary = true;
    });
    try {
      final s = await _api.getSummary();
      if (!mounted) return;
      setState(() {
        _summary = s;
        _loadingSummary = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _summaryError = e.toString();
        _loadingSummary = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_summaryError!)));
      }
    }
  }

  Future<void> _loadQueue() async {
    setState(() {
      _queueError = null;
      if (_queue.isEmpty) _loadingQueue = true;
    });
    try {
      final q = await _api.getQueue();
      if (!mounted) return;
      setState(() {
        _queue = q;
        _loadingQueue = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _queueError = e.toString();
        _loadingQueue = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_queueError!)));
      }
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadSummary(), _loadQueue()]);
  }

  static DateTime _calendarDateKey(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  static String _calendarMonthKey(DateTime d) => '${d.year}-${d.month}';

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
      final counts = await _appointmentService.getCalendarCounts(
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

  Future<void> _openCheckInPatientDialog(BuildContext context) async {
    final reEnlisted = await showDialog<bool>(
      context: context,
      builder: (_) => CheckInPatientDialog(onReEnlisted: _loadQueue),
    );
    if (reEnlisted == true && mounted) {
      await _loadQueue();
    }
  }

  Future<void> _openDayAppointmentsSheet(DateTime day) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) =>
          _DayAppointmentsBottomSheet(day: day, service: _appointmentService),
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
                    ? Colors.white.withValues(alpha: 0.92)
                    : colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? colorScheme.primary : Colors.white,
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
            ? Colors.white
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

  String _welcomeName(Staff? staff) {
    if (staff == null) return 'there';
    final first = staff.firstName.trim();
    if (first.isNotEmpty) return first;
    final full = staff.fullName.trim();
    if (full.isNotEmpty) return full;
    return 'there';
  }

  String _formatAppointmentDelta(AppointmentsChange c) {
    if (c.percentChange == null) return '—';
    final p = c.percentChange!;
    if (c.direction == 'flat') return '0%';
    final sign = c.direction == 'down' ? '−' : '+';
    final abs = p.abs();
    final decimals = abs == abs.roundToDouble() ? 0 : 2;
    return '$sign${abs.toStringAsFixed(decimals)}%';
  }

  bool _appointmentDeltaNegative(AppointmentsChange c) => c.direction == 'down';

  String _statusLabel(String status) {
    switch (status) {
      case 'Waiting':
        return 'Waiting';
      case 'InRoom':
        return 'In room';
      case 'InConsultation':
        return 'In consultation';
      default:
        return status;
    }
  }

  (Color bg, Color fg) _statusColors(String status, ColorScheme scheme) {
    switch (status) {
      case 'Waiting':
        return (Colors.orange.withValues(alpha: 0.12), Colors.orange.shade800);
      case 'InRoom':
        return (Colors.blue.withValues(alpha: 0.12), Colors.blue.shade800);
      case 'InConsultation':
        return (Colors.green.withValues(alpha: 0.12), Colors.green.shade800);
      default:
        return (scheme.surfaceContainerHighest, scheme.onSurfaceVariant);
    }
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts[0];
      return s.length >= 2 ? s.substring(0, 2).toUpperCase() : s.toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Color _avatarColor(String seed, ColorScheme scheme) {
    final i = seed.hashCode.abs();
    final palette = <Color>[
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      Colors.teal,
      Colors.deepPurple,
    ];
    return palette[i % palette.length];
  }

  void _showPatientActions(
    BuildContext context,
    Offset position,
    FrontdeskQueueRow row,
  ) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: const [
        PopupMenuItem(
          value: 'enlist_consult',
          child: Text(
            'Enlist For Consultation',
            style: TextStyle(fontSize: 12),
          ),
        ),
        PopupMenuItem(
          value: 'enlist_pharmacy',
          child: Text('Enlist for pharmacy', style: TextStyle(fontSize: 12)),
        ),
        PopupMenuItem(
          value: 'bio_data',
          child: Text('Patient Bio Data', style: TextStyle(fontSize: 12)),
        ),
        PopupMenuItem(
          value: 'ward_rounds',
          child: Text('Ward Rounds', style: TextStyle(fontSize: 12)),
        ),
        PopupMenuItem(
          value: 'consults',
          child: Text('Consults', style: TextStyle(fontSize: 12)),
        ),
        PopupMenuItem(
          value: 'transactions',
          child: Text('Transactions', style: TextStyle(fontSize: 12)),
        ),
      ],
    ).then((value) {
      if (!context.mounted || value == null) return;
      if (value == 'ward_rounds') {
        context.router.push(const InpatientsListRoute());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final staff = ref.watch(currentStaffProvider);
    final welcome = _welcomeName(staff);

    final summary = _summary;
    final apptChange = summary?.appointmentsChange;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $welcome. Here is the overview for today.',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildStatCard(
                        context,
                        "Today's Appointments",
                        _loadingSummary
                            ? '…'
                            : '${summary?.appointmentsToday ?? '—'}',
                        apptChange != null
                            ? _formatAppointmentDelta(apptChange)
                            : '—',
                        Icons.calendar_today,
                        Colors.blue,
                        isNegative: apptChange != null
                            ? _appointmentDeltaNegative(apptChange)
                            : false,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        context,
                        'Checked-In',
                        _loadingSummary
                            ? '…'
                            : '${summary?.checkInsToday ?? '—'}',
                        '—',
                        Icons.check_circle_outline,
                        Colors.green,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        context,
                        'Waiting Room',
                        _loadingSummary
                            ? '…'
                            : '${summary?.waitingRoomCount ?? '—'}',
                        '—',
                        Icons.hourglass_empty,
                        Colors.orange,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        context,
                        'Discharged',
                        _loadingSummary
                            ? '…'
                            : '${summary?.dischargesToday ?? '—'}',
                        '—',
                        Icons.logout,
                        Colors.purple,
                      ),
                    ],
                  ),
                  if (_summaryError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _summaryError!,
                      style: TextStyle(fontSize: 12, color: colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Live Patient Queue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: _loadingQueue ? null : _refreshAll,
                        icon: _loadingQueue
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              )
                            : const Icon(Icons.refresh, size: 16),
                        label: Text(
                          _loadingQueue ? 'Refreshing…' : 'Refresh',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Patient Name',
                                  style: _headerStyle(colorScheme),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Time',
                                  style: _headerStyle(colorScheme),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Doctor',
                                  style: _headerStyle(colorScheme),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Status',
                                  style: _headerStyle(colorScheme),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Assigned Room',
                                  style: _headerStyle(colorScheme),
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        if (_loadingQueue && _queue.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_queue.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                _queueError != null
                                    ? 'Could not load queue.'
                                    : 'No patients in the queue right now.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _queue.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: colorScheme.outline.withValues(alpha: 0.1),
                            ),
                            itemBuilder: (context, index) {
                              final row = _queue[index];
                              final avatarColor = _avatarColor(
                                row.patientName,
                                colorScheme,
                              );
                              final (stBg, stFg) = _statusColors(
                                row.status,
                                colorScheme,
                              );
                              final timeStr = DateFormat.jm().format(
                                row.time.toLocal(),
                              );
                              final doctorStr = row.doctor != null
                                  ? row.doctor!.displayName
                                  : '—';
                              final roomStr = row.assignedRoom?.name ?? '—';

                              return GestureDetector(
                                onSecondaryTapDown: (details) =>
                                    _showPatientActions(
                                      context,
                                      details.globalPosition,
                                      row,
                                    ),
                                onLongPressStart: (details) =>
                                    _showPatientActions(
                                      context,
                                      details.globalPosition,
                                      row,
                                    ),
                                child: InkWell(
                                  onTap: () {},
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor: avatarColor
                                                    .withValues(alpha: 0.15),
                                                child: Text(
                                                  _initials(row.patientName),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: avatarColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                row.patientName,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            timeStr,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            doctorStr,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: stBg,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                _statusLabel(row.status),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: stFg,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            roomStr,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 48,
                                          child: Builder(
                                            builder: (buttonContext) {
                                              return IconButton(
                                                icon: const Icon(
                                                  Icons.more_vert,
                                                  size: 18,
                                                ),
                                                onPressed: () {
                                                  final renderBox =
                                                      buttonContext
                                                              .findRenderObject()
                                                          as RenderBox?;
                                                  final position =
                                                      renderBox?.localToGlobal(
                                                        Offset.zero,
                                                      ) ??
                                                      Offset.zero;
                                                  _showPatientActions(
                                                    buttonContext,
                                                    position,
                                                    row,
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _queue.isEmpty && !_loadingQueue
                                  ? '0 patients in queue'
                                  : '${_queue.length} patient${_queue.length == 1 ? '' : 's'} in queue',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.router.push(PatientFormRoute());
                          },
                          icon: const Icon(
                            Icons.person_add,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Register New Patient',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            context.router.push(NewAppointmentRoute());
                          },
                          icon: Icon(
                            Icons.calendar_month,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          label: Text(
                            'Book Appointment',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _openCheckInPatientDialog(context),
                          icon: Icon(
                            Icons.login,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          label: Text(
                            'Check-In Patient',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
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
                            leftChevronIcon: const Icon(
                              Icons.chevron_left,
                              size: 20,
                            ),
                            rightChevronIcon: const Icon(
                              Icons.chevron_right,
                              size: 20,
                            ),
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            weekendStyle: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: (context, day, focusedDay) {
                              return _buildCalendarDayCell(
                                context,
                                day,
                                colorScheme,
                                isSelected: false,
                                isToday: isSameDay(day, DateTime.now()),
                              );
                            },
                            selectedBuilder: (context, day, focusedDay) {
                              return _buildCalendarDayCell(
                                context,
                                day,
                                colorScheme,
                                isSelected: true,
                                isToday: isSameDay(day, DateTime.now()),
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

                        const SizedBox(height: 12),
                        Text(
                          "Today's total appointments: "
                          '${_loadingSummary ? '…' : '${_summary?.appointmentsToday ?? '—'}'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    String change,
    IconData icon,
    Color iconColor, {
    bool isNegative = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final showTrend = change != '—';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                if (showTrend)
                  Text(
                    change,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isNegative ? Colors.red : Colors.green,
                    ),
                  )
                else
                  Text(
                    change,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _headerStyle(ColorScheme colorScheme) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface.withValues(alpha: 0.5),
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
    final title = DateFormat('EEEE, MMM d, yyyy').format(widget.day);

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
