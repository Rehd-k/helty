import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../helper/date.formatter.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import '../../shared/department_colors.dart';
import '../../widgets/helty_surface.dart';
import '../../widgets/filter.patients.dart';
import '../../widgets/table/reusable_async_table.dart';

/// Below this width, appointments render as cards with infinite scroll.
const _kAppointmentListBreakpoint = 720.0;

@RoutePage()
class AppointmentListScreen extends ConsumerStatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  ConsumerState<AppointmentListScreen> createState() =>
      _AppointmentListScreenState();
}

class _AppointmentListScreenState extends ConsumerState<AppointmentListScreen> {
  final AppointmentService _service = AppointmentService();

  String _query = '';
  String _filterCategory = 'fullName';
  DateTime? _fromDate;
  DateTime? _toDate;
  int _tableEpoch = 0;
  String? _error;

  String get _tableKey =>
      '$_query|$_filterCategory|${_fromDate?.millisecondsSinceEpoch}|${_toDate?.millisecondsSinceEpoch}|$_tableEpoch';

  Future<PagedData<Appointment>> _fetchPage(int start, int count) async {
    try {
      final page = await _service.findAll(
        skip: start,
        take: count,
        fromDate: _fromDate,
        toDate: _toDate,
        q: _query.isEmpty ? null : _query,
      );
      if (_error != null && mounted) setState(() => _error = null);
      final total = page.total > 0 ? page.total : start + page.items.length;
      return PagedData<Appointment>(items: page.items, totalCount: total);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load appointments: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => setState(() {
                _error = null;
                _tableEpoch++;
              }),
            ),
          ),
        );
      }
      return PagedData<Appointment>(items: [], totalCount: 0);
    }
  }

  Future<void> _deleteAppointment(Appointment a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: Text(
          'Remove the booking for ${a.patientDisplayName}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteAppointment(a.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Appointment removed')));
      setState(() => _tableEpoch++);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  void _viewAppointment(Appointment a) {
    final local = a.appointmentDate.toLocal();
    final when =
        '${DateFormatter.medicalDate(local)} · ${DateFormat.jm().format(local)}';
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        Widget kv(String k, String v) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                k,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(v),
            ],
          ),
        );
        return AlertDialog(
          title: Text(a.patientDisplayName),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                kv('Patient ID', a.patientId),
                kv('Clinician', a.doctorDisplayName),
                kv('Date & time', when),
                kv('Status', a.status),
                if (a.notes != null && a.notes!.trim().isNotEmpty)
                  kv('Notes', a.notes!.trim()),
                if (a.referral != null && a.referral!.trim().isNotEmpty)
                  kv('Referral', a.referral!.trim()),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _rescheduleAppointment(Appointment a) async {
    final local = a.appointmentDate.toLocal();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: local,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(local),
    );
    if (pickedTime == null || !mounted) return;

    final newDt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    try {
      await _service.updateAppointment(a.id, appointmentDate: newDt);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Appointment rescheduled')));
      setState(() => _tableEpoch++);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reschedule failed: $e')));
    }
  }

  void _handleAction(String action, Appointment a) {
    switch (action) {
      case 'delete':
        _deleteAppointment(a);
        break;
      case 'view':
        _viewAppointment(a);
        break;
      case 'edit':
        _rescheduleAppointment(a);
        break;
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$action — coming soon')));
    }
  }

  Color _statusColor(String status, ColorScheme scheme) {
    final u = status.toUpperCase();
    if (u.contains('CANCEL')) return scheme.error;
    if (u.contains('CONFIRM') || u.contains('SCHEDULE') || u.contains('BOOK')) {
      return DepartmentColors.pharmacy;
    }
    if (u.contains('PEND') || u.contains('WAIT')) {
      return DepartmentColors.billing;
    }
    return scheme.primary;
  }

  Widget _statusChip(String status, ColorScheme scheme) {
    final c = _statusColor(status, scheme);
    return HeltyStatusChip(label: status, color: c);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      // appBar: AppBar(
      //   title: const Text('Appointments'),
      //   scrolledUnderElevation: 0,
      //   actions: [
      //     IconButton(
      //       tooltip: 'Refresh',
      //       onPressed: () => setState(() {
      //         _error = null;
      //         _tableEpoch++;
      //       }),
      //       icon: const Icon(Icons.refresh_rounded),
      //     ),
      //   ],
      // ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null)
            MaterialBanner(
              content: Text(
                _error!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              leading: Icon(Icons.error_outline, color: colorScheme.error),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _error = null),
                  child: const Text('Dismiss'),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _error = null;
                    _tableEpoch++;
                  }),
                  child: const Text('Retry'),
                ),
              ],
            ),
          LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < _kAppointmentListBreakpoint;
              final hPad = narrow ? 12.0 : 16.0;
              return Padding(
                padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                child: Text(
                  narrow
                      ? 'Scheduled visits — pull down to refresh.'
                      : 'Browse and manage scheduled visits.',
                  style: TextStyle(
                    fontSize: narrow ? 12.5 : 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: PatientsFilterWidget(
              searchCategories: const [
                {'name': 'fullName', 'value': 'Patient name'},
                {'name': 'patientId', 'value': 'Patient ID'},
              ],
              onFilterChanged:
                  (
                    String query,
                    String category,
                    DateTime? from,
                    DateTime? to,
                  ) {
                    setState(() {
                      _query = query;
                      _filterCategory = category;
                      _fromDate = from;
                      _toDate = to;
                      _tableEpoch++;
                    });
                  },
              doRefresh: () => setState(() {
                _error = null;
                _tableEpoch++;
              }),
              dateFilter: true,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile =
                    constraints.maxWidth < _kAppointmentListBreakpoint;
                final pad = EdgeInsets.fromLTRB(
                  isMobile ? 8 : 12,
                  0,
                  isMobile ? 8 : 12,
                  12,
                );

                if (isMobile) {
                  return Padding(
                    padding: pad,
                    child: _AppointmentMobileList(
                      key: ValueKey(_tableKey),
                      fetchPage: _fetchPage,
                      buildStatusChip: (s) => _statusChip(s, colorScheme),
                      onAction: _handleAction,
                    ),
                  );
                }

                return Padding(
                  padding: pad,
                  child: Material(
                    color: colorScheme.surface,
                    elevation: 0,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: ReusableAsyncTable<Appointment>(
                      key: ValueKey(_tableKey),
                      rowsPerPage: 20,
                      fetchData: _fetchPage,
                      idGetter: (a) => a.id,
                      onSelectionChanged: (_) {},
                      columns: const [
                        DataColumn2(label: Text('Patient'), size: ColumnSize.L),
                        DataColumn2(
                          label: Text('Clinician'),
                          size: ColumnSize.L,
                        ),
                        DataColumn2(
                          label: Text('Date & time'),
                          size: ColumnSize.L,
                        ),
                        DataColumn2(label: Text('Status'), size: ColumnSize.S),
                        DataColumn2(label: Text('Created'), size: ColumnSize.S),
                        DataColumn2(label: Text('Notes'), size: ColumnSize.M),
                        DataColumn2(label: Text(''), fixedWidth: 52),
                      ],
                      rowBuilder: (a) {
                        final local = a.appointmentDate.toLocal();
                        return [
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  a.patientDisplayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  a.patientId,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(Text(a.doctorDisplayName)),
                          DataCell(
                            Text(
                              '${DateFormatter.medicalDate(local)} · ${DateFormat.jm().format(local)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DataCell(_statusChip(a.status, colorScheme)),
                          DataCell(
                            Text(
                              a.createdAt != null
                                  ? DateFormatter.medicalDate(
                                      a.createdAt!.toLocal(),
                                    )
                                  : '—',
                            ),
                          ),
                          DataCell(
                            Text(
                              a.notes == null || a.notes!.isEmpty
                                  ? '—'
                                  : a.notes!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DataCell(
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                size: 20,
                              ),
                              onSelected: (v) => _handleAction(v, a),
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'view',
                                  child: Text('View'),
                                ),
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Reschedule'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentMobileList extends StatefulWidget {
  const _AppointmentMobileList({
    super.key,
    required this.fetchPage,
    required this.buildStatusChip,
    required this.onAction,
  });

  final Future<PagedData<Appointment>> Function(int start, int count) fetchPage;
  final Widget Function(String status) buildStatusChip;
  final void Function(String action, Appointment a) onAction;

  @override
  State<_AppointmentMobileList> createState() => _AppointmentMobileListState();
}

class _AppointmentMobileListState extends State<_AppointmentMobileList> {
  static const _pageSize = 20;

  final ScrollController _scroll = ScrollController();
  final List<Appointment> _items = [];
  int _totalCount = 0;
  bool _loading = false;
  bool _loadingMore = false;
  bool _noMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loading || _loadingMore || _noMore || _error != null) return;
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
      _items.clear();
      _noMore = false;
      _totalCount = 0;
    });
    try {
      final page = await widget.fetchPage(0, _pageSize);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _totalCount = page.totalCount;
        _noMore =
            page.items.isEmpty ||
            page.items.length < _pageSize ||
            (_totalCount > 0 && _items.length >= _totalCount);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loading || _noMore) return;
    if (_items.isEmpty) return;

    setState(() => _loadingMore = true);
    try {
      final page = await widget.fetchPage(_items.length, _pageSize);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _totalCount = page.totalCount;
        if (page.items.isEmpty ||
            page.items.length < _pageSize ||
            (_totalCount > 0 && _items.length >= _totalCount)) {
          _noMore = true;
        }
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading && _items.isEmpty) {
      return Center(child: CircularProgressIndicator(color: scheme.primary));
    }

    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: scheme.error),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadInitial,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadInitial,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    size: 48,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No appointments in this range',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitial,
      color: scheme.primary,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                ),
              ),
            );
          }

          final a = _items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AppointmentMobileCard(
              appointment: a,
              statusChip: widget.buildStatusChip(a.status),
              onAction: widget.onAction,
            ),
          );
        },
      ),
    );
  }
}

class _AppointmentMobileCard extends StatelessWidget {
  const _AppointmentMobileCard({
    required this.appointment,
    required this.statusChip,
    required this.onAction,
  });

  final Appointment appointment;
  final Widget statusChip;
  final void Function(String action, Appointment a) onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final local = appointment.appointmentDate.toLocal();
    final when =
        '${DateFormatter.medicalDate(local)} · ${DateFormat.jm().format(local)}';
    final notes = appointment.notes?.trim();
    final created = appointment.createdAt != null
        ? DateFormatter.medicalDate(appointment.createdAt!.toLocal())
        : '—';

    return Material(
      color: scheme.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onAction('view', appointment),
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.patientDisplayName,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            appointment.patientId,
                            style: textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                      onSelected: (v) => onAction(v, appointment),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'view', child: Text('View')),
                        PopupMenuItem(value: 'edit', child: Text('Reschedule')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: scheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        appointment.doctorDisplayName,
                        style: textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: scheme.tertiary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        when,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    statusChip,
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Created $created',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (appointment.createdByDisplayName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Created by: ${appointment.createdByDisplayName}',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    notes,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
