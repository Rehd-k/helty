import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_router.gr.dart';
import '../../helper/app_timezone.dart';
import '../../helper/date.formatter.dart';
import '../../shared/department_colors.dart';
import '../../paitients/patient_model.dart';
import '../../paitients/patient_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/helty_surface.dart';
import '../../widgets/table/reusable_async_table.dart';

@RoutePage()
class TodayPatientsScreen extends ConsumerStatefulWidget {
  const TodayPatientsScreen({super.key});

  @override
  ConsumerState<TodayPatientsScreen> createState() =>
      _TodayPatientsScreenState();
}

class _TodayPatientsScreenState extends ConsumerState<TodayPatientsScreen> {
  final PatientService _service = PatientService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _headerDate;
  int? _total;
  int _refreshKey = 0;
  Timer? _autoRefreshTimer;

  bool get _isMedicalRecords {
    final staff = ref.read(authProvider).staff;
    final at = staff?.accountType?.name.toLowerCase() ?? '';
    final r = staff?.staffRole.toLowerCase() ?? '';
    return at == 'medical_records' || r == 'medical_records';
  }

  @override
  void initState() {
    super.initState();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 90),
      (_) => _reloadList(),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reloadList() async {
    if (!mounted) return;
    try {
      final res = await _service.fetchRegisteredToday(
        take: 1,
        q: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _headerDate = res.date;
        _total = res.total;
        _refreshKey++;
      });
    } catch (e) {
      _showFetchError(e);
    }
  }

  void _applySearch() {
    final q = _searchController.text.trim();
    if (q == _searchQuery) return;
    setState(() {
      _searchQuery = q;
      _refreshKey++;
    });
  }

  String _patientFullName(Patient patient) {
    return [
      patient.title,
      patient.surname,
      patient.firstName,
      patient.otherName,
    ].where((p) => p != null && p.toString().trim().isNotEmpty).join(' ');
  }

  String _formatHeaderDate(String? apiDate) {
    if (apiDate == null || apiDate.isEmpty) {
      return DateFormatter.medicalDate(AppTimezone.now());
    }
    final parsed = DateTime.tryParse(apiDate);
    if (parsed != null) {
      return DateFormatter.medicalDate(parsed);
    }
    return apiDate;
  }

  void _showFetchError(Object error) {
    if (!mounted) return;
    final message = switch (error) {
      DioException(response: final r) when r?.statusCode == 401 =>
        'Session expired. Please sign in again.',
      DioException(response: final r) when r?.statusCode == 403 =>
        'You do not have permission to view today\'s registrations.',
      DioException() => 'Failed to load registrations. Please try again.',
      _ => 'Failed to load registrations: $error',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<PagedData<Patient>> _fetchPage(int start, int count) async {
    try {
      final res = await _service.fetchRegisteredToday(
        skip: start,
        take: count,
        q: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (mounted) {
        setState(() {
          _headerDate = res.date;
          _total = res.total;
        });
      }
      return PagedData(totalCount: res.total, items: res.patients);
    } catch (e) {
      _showFetchError(e);
      rethrow;
    }
  }

  Future<void> _openPatient(Patient patient) async {
    await context.router.push(PatientFormRoute(patient: patient));
    if (!mounted) return;
    await _reloadList();
  }

  Widget _statusBadge(String? status) {
    final label = status?.trim().isNotEmpty == true ? status! : '—';
    final cs = Theme.of(context).colorScheme;
    final Color color;
    switch (label.toUpperCase()) {
      case 'ADMITED':
      case 'ADMITTED':
        color = cs.primary;
      case 'DECEASED':
        color = cs.outline;
      default:
        color = DepartmentColors.frontDesk;
    }
    return HeltyStatusChip(label: label, color: color);
  }

  Widget _hospitalIdCell(Patient patient) {
    final cs = Theme.of(context).colorScheme;
    if (patient.patientId.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cs.tertiaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: cs.tertiary.withValues(alpha: 0.5)),
        ),
        child: Text(
          'No ID',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Text(patient.patientId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showMrExtras = _isMedicalRecords;

    final columns = <DataColumn2>[
      const DataColumn2(label: Text('Time'), size: ColumnSize.S),
      const DataColumn2(label: Text('Hospital ID'), size: ColumnSize.S),
      const DataColumn2(label: Text('Full Name'), size: ColumnSize.L),
      const DataColumn2(label: Text('Phone'), size: ColumnSize.M),
      if (showMrExtras)
        const DataColumn2(label: Text('Status'), size: ColumnSize.S),
      const DataColumn2(label: Text('Registered By'), size: ColumnSize.M),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Registrations — ${_formatHeaderDate(_headerDate)}'),
        actions: [
          SizedBox(
            width: 280,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search name, ID, or phone',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _applySearch(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: _applySearch,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _reloadList,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ResponsiveBody(
        expand: false,
        builder: (context, bp) => RefreshIndicator(
        onRefresh: _reloadList,
        child: _total == 0 && _searchQuery.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.5,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_off_outlined,
                            size: 48,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No registrations today',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height - kToolbarHeight - 48,
                  child: ReusableAsyncTable<Patient>(
                    key: ValueKey('$_refreshKey|$_searchQuery'),
                    fetchData: _fetchPage,
                    rowsPerPage: 25,
                    idGetter: (patient) =>
                        patient.id ?? patient.patientId.ifEmpty('row'),
                    onRowTap: _openPatient,
                    columns: columns,
                    rowBuilder: (patient) {
                      final incomplete = patient.patientId.isEmpty;
                      final createdAt = patient.createdAt;
                      final timeText = createdAt != null
                          ? DateFormatter.timeOnly(createdAt.toLocal())
                          : '—';

                      DataCell cell(Widget child) {
                        if (!showMrExtras || !incomplete) {
                          return DataCell(child);
                        }
                        return DataCell(
                          Container(
                            color: colorScheme.tertiaryContainer.withValues(
                              alpha: 0.25,
                            ),
                            child: child,
                          ),
                        );
                      }

                      return [
                        cell(Text(timeText)),
                        cell(_hospitalIdCell(patient)),
                        cell(Text(_patientFullName(patient))),
                        cell(Text(patient.phoneNumber ?? '—')),
                        if (showMrExtras) cell(_statusBadge(patient.status)),
                        cell(Text(patient.createdBy ?? '')),
                      ];
                    },
                  ),
                ),
              ),
      ),
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
