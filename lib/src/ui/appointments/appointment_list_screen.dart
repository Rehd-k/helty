import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../helper/date.formatter.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import '../../widgets/filter.patients.dart';
import '../../widgets/table/reusable_async_table.dart';

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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment removed')),
      );
      setState(() => _tableEpoch++);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  void _handleAction(String action, Appointment a) {
    switch (action) {
      case 'delete':
        _deleteAppointment(a);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$action — coming soon')),
        );
    }
  }

  Color _statusColor(String status, ColorScheme scheme) {
    final u = status.toUpperCase();
    if (u.contains('CANCEL')) return scheme.error;
    if (u.contains('CONFIRM') || u.contains('SCHEDULE') || u.contains('BOOK')) {
      return Colors.green.shade700;
    }
    if (u.contains('PEND') || u.contains('WAIT')) return Colors.orange.shade800;
    return scheme.primary;
  }

  Widget _statusChip(String status, ColorScheme scheme) {
    final c = _statusColor(status, scheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: c,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Appointments'),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() {
              _error = null;
              _tableEpoch++;
            }),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'Browse and manage scheduled visits. Date filters map to your API '
              '`fromDate` / `toDate` query params.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: PatientsFilterWidget(
              searchCategories: const [
                {'name': 'fullName', 'value': 'Patient name'},
                {'name': 'patientId', 'value': 'Patient ID'},
              ],
              onFilterChanged:
                  (String query, String category, DateTime? from, DateTime? to) {
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                    DataColumn2(label: Text('Clinician'), size: ColumnSize.L),
                    DataColumn2(label: Text('Date & time'), size: ColumnSize.L),
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
                              style: const TextStyle(fontWeight: FontWeight.w600),
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
                              ? DateFormatter.medicalDate(a.createdAt!.toLocal())
                              : '—',
                        ),
                      ),
                      DataCell(
                        Text(
                          a.notes == null || a.notes!.isEmpty ? '—' : a.notes!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DataCell(
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 20),
                          onSelected: (v) => _handleAction(v, a),
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'view', child: Text('View')),
                            PopupMenuItem(value: 'edit', child: Text('Reschedule')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
