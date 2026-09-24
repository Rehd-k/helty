import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/lab/ui/widgets/lab_clinical_ui.dart';
import 'package:helty/src/widgets/helty_surface.dart';

import '../core/widgets/patient_avatar.dart';
import '../core/utils/patient_initials.dart';
import '../helper/date.formatter.dart';
import '../models/patient_vitals_model.dart';
import '../models/consultation_credit_model.dart';
import '../models/waiting_patient_model.dart';
import '../providers/module_request_flow_provider.dart';
import '../widgets/empty.widget.dart';
import '../services/api_service.dart';
import '../services/waiting_patient_service.dart';
import 'patient_model.dart';
import '../../app_router.gr.dart';

@RoutePage()
class NewPatientScreen extends ConsumerStatefulWidget {
  const NewPatientScreen({
    super.key,
    this.use = 'For Register',
    this.categoryQueries = const ['Laboratory', 'Laboratory Tests'],
  });

  /// Defines how this screen should fetch and present data.
  final String use;

  /// Categories forwarded by parent when [use] is not "For Register".
  final List<String> categoryQueries;

  @override
  ConsumerState<NewPatientScreen> createState() => _WaitingPatientScreenState();
}

class _WaitingPatientScreenState extends ConsumerState<NewPatientScreen> {
  // Filter States
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  // Networking
  final Dio _dio = ApiService().dio;
  final WaitingPatientService _waitingService = WaitingPatientService();

  // Data + UI state
  List<_UnregisteredPatientTxn> _patients = [];
  _UnregisteredPatientTxn? _selectedPatient;
  bool _isLoading = false;
  String? _errorMessage;

  static const int _rowsPerPage = 20;
  int _currentPage = 0;
  int _total = 0;
  bool _hasMore = false;
  int _loadSeq = 0;
  String _payFilter = 'all';

  bool get _isRegisterUse => widget.use.trim().toLowerCase() == 'for register';
  bool get _isNursingQueueUse =>
      widget.use.trim().toLowerCase() == 'nursingqueue';

  String get _endpoint => _isRegisterUse
      ? '/invoices/unregistered-patients'
      : _isNursingQueueUse
      ? '/waiting-patients'
      : '/invoices/by-service-categories';

  bool get _canGoPrev => !_isLoading && _currentPage > 0;
  bool get _canGoNext => !_isLoading && _hasMore;

  String get _primaryButtonLabel => _isRegisterUse
      ? 'Register Patient'
      : _isNursingQueueUse
      ? 'Send to Consulting Room'
      : 'Open Patient';

  bool _footerPrimaryEnabled(_UnregisteredPatientTxn patient) {
    if (_isRegisterUse) return true;
    if (_isNursingQueueUse) {
      return patient.isPaid && patient.hasPatientId;
    }
    return patient.canOpenModulePatient;
  }

  String _footerPrimaryLabel(_UnregisteredPatientTxn patient) {
    if (!_isRegisterUse &&
        !_isNursingQueueUse &&
        patient.isOpdWard &&
        !patient.isPaid) {
      return 'Bill Not Paid';
    }
    return _primaryButtonLabel;
  }

  String get _pageTitle {
    if (_isNursingQueueUse) return 'Nursing Queue';
    return 'Waiting Patients';
  }

  String get _pageSubtitle {
    if (_isRegisterUse) {
      return 'Register billed walk-in patients and open their file.';
    }
    if (_isNursingQueueUse) {
      return 'Send paid patients to consulting rooms.';
    }
    return 'Open paid invoices for ${widget.use} work.';
  }

  List<_UnregisteredPatientTxn> get _displayedPatients {
    switch (_payFilter) {
      case 'ready':
        return _patients.where((p) => p.canOpenModulePatient).toList();
      case 'unpaid':
        return _patients.where((p) => !p.isPaid).toList();
      default:
        return _patients;
    }
  }

  String _waitLabel(_UnregisteredPatientTxn patient) {
    final wait = LabClinicalUi.waitSince(patient.dateTime);
    if (wait == null) return '—';
    return LabClinicalUi.formatWait(wait);
  }

  Color _waitColor(_UnregisteredPatientTxn patient) {
    final wait = LabClinicalUi.waitSince(patient.dateTime);
    if (wait == null) return LabClinicalUi.iconAmber;
    return LabClinicalUi.waitColor(wait);
  }

  String get _avgWaitLabel {
    final waits = _displayedPatients
        .map((p) => LabClinicalUi.waitSince(p.dateTime))
        .whereType<Duration>()
        .toList();
    if (waits.isEmpty) return '—';
    final avgMs =
        waits.fold<int>(0, (sum, d) => sum + d.inMilliseconds) ~/ waits.length;
    return LabClinicalUi.formatWait(Duration(milliseconds: avgMs));
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
    _fetchPatients();
  }

  Future<void> _goToPage(int page) async {
    if (_isLoading) return;
    if (page < 0) return;
    if (page > _currentPage && !_canGoNext) return;
    if (page < _currentPage && !_canGoPrev) return;
    await _fetchPatients(page: page);
  }

  Future<void> _fetchPatients({bool reset = false, int? page}) async {
    if (reset) {
      _currentPage = 0;
      _hasMore = false;
    } else if (page != null) {
      _currentPage = page;
    }

    final seq = ++_loadSeq;
    final pageRequested = _currentPage < 0 ? 0 : _currentPage;
    final skip = pageRequested * _rowsPerPage;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = pageRequested;
    });

    try {
      final query = <String, dynamic>{'skip': '$skip', 'take': '$_rowsPerPage'};
      final search = _searchController.text.trim();
      final range = _selectedDateRange;
      final now = DateTime.now();
      final from = range?.start ?? DateTime(now.year, now.month, now.day);
      final to =
          range?.end ?? DateTime(now.year, now.month, now.day, 23, 59, 59);

      if (search.isNotEmpty) {
        // Backend ORs name / invoice # / payment ref via a single `search` param.
        // Do NOT send transactionId+patientName+invoiceId together — those AND
        // and almost never match a name-only query like "victor".
        query['search'] = search;
      }

      if (_isNursingQueueUse) {
        final queue = await _waitingService.fetchWaitingPatients(
          WaitingPatientQuery(
            q: search.isEmpty ? null : search,
            skip: skip,
            take: _rowsPerPage,
            fromDate: from,
            toDate: to,
          ),
        );
        if (!mounted || seq != _loadSeq) return;
        final patients = queue.data
            .map(_UnregisteredPatientTxn.fromWaitingQueue)
            .toList();
        final hasMore = patients.length >= _rowsPerPage;
        setState(() {
          _patients = patients;
          _total = queue.total;
          _hasMore = hasMore;
          _selectedPatient = patients.isNotEmpty ? patients.first : null;
        });
        return;
      }

      if (!_isRegisterUse) {
        final categories = widget.categoryQueries
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (categories.isNotEmpty) {
          // Dio serializes list values as repeated query params by default.
          query['category'] = categories;
        }
      }

      query['fromDate'] = from.toUtc().toIso8601String();
      query['toDate'] = to.toUtc().toIso8601String();

      final resp = await _dio.get(_endpoint, queryParameters: query);

      if (!mounted || seq != _loadSeq) return;

      final raw = resp.data;
      final body = raw is Map
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{};
      final list = _extractUnregisteredList(body.isEmpty ? raw : body);
      var patients = <_UnregisteredPatientTxn>[];
      for (final e in list) {
        if (e is! Map) continue;
        try {
          patients.add(
            _UnregisteredPatientTxn.fromJson(Map<String, dynamic>.from(e)),
          );
        } catch (_) {
          // Skip malformed rows; keep the rest of the table usable.
        }
      }

      // Empty page past the start → snap back.
      if (patients.isEmpty && pageRequested > 0) {
        _hasMore = false;
        _total = skip;
        await _fetchPatients(page: pageRequested - 1);
        return;
      }

      final reportedTotal = body['total'] ?? body['count'];
      var total = reportedTotal is num
          ? reportedTotal.toInt()
          : (reportedTotal is String
                ? int.tryParse(reportedTotal) ?? skip + patients.length
                : skip + patients.length);
      if (total < skip + patients.length) {
        total = skip + patients.length;
      }

      setState(() {
        _patients = patients;
        _total = total;
        // Full page of 20 → Next enabled; fewer → Next disabled.
        _hasMore = patients.length >= _rowsPerPage;
        _selectedPatient = patients.isNotEmpty ? patients.first : null;
      });
    } on DioException catch (e) {
      if (!mounted || seq != _loadSeq) return;
      final msg = _dioErrorMessage(e);
      setState(() {
        _errorMessage = msg;
        _patients = [];
        _selectedPatient = null;
        _hasMore = false;
      });
    } catch (e) {
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _errorMessage = 'Failed to load unregistered patients: $e';
        _patients = [];
        _selectedPatient = null;
        _hasMore = false;
      });
    } finally {
      if (mounted && seq == _loadSeq) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  static List<dynamic> _extractUnregisteredList(dynamic data) {
    if (data is List<dynamic>) return data;
    if (data is Map<String, dynamic>) {
      const keys = [
        'data',
        'items',
        'invoices',
        'results',
        'rows',
        'unregisteredPatients',
        'patients',
      ];
      for (final k in keys) {
        final v = data[k];
        if (v is List<dynamic>) return v;
      }
    }
    return const [];
  }

  static String _dioErrorMessage(DioException e) {
    final payload = e.response?.data;
    if (payload is Map) {
      final msg = payload['message'];
      if (msg != null) return msg.toString();
      final err = payload['error'];
      if (err != null) return err.toString();
    } else if (payload is String && payload.trim().isNotEmpty) {
      return payload;
    }
    return e.message ?? 'Failed to load unregistered patients';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayed = _displayedPatients;
    final paidCount = _patients.where((p) => p.isPaid).length;
    final unpaidCount = _patients.where((p) => !p.isPaid).length;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final width = bp.maxWidth > 0
              ? bp.maxWidth
              : MediaQuery.sizeOf(context).width;
          final compact = width < LabClinicalUi.cardBreakpoint;
          final showSideBySide = width >= LabClinicalUi.sidebarBreakpoint;
          final useSnapKpis = width < 520;

          final header = LabPageHeader(
            title: _pageTitle,
            subtitle: _pageSubtitle,
            icon: Icons.receipt_long_outlined,
            iconColor: LabClinicalUi.iconPurple,
            compact: compact,
          );
          final kpis = LabKpiStrip(
            useSnapStrip: useSnapKpis,
            items: [
              LabKpiItem(
                label: 'Total in queue',
                value: '$_total',
                caption: 'Matching current dates',
                icon: Icons.groups_outlined,
                accent: LabClinicalUi.iconBlue,
              ),
              LabKpiItem(
                label: 'Paid',
                value: '$paidCount',
                caption: 'On this page',
                icon: Icons.verified_outlined,
                accent: LabClinicalUi.iconGreen,
              ),
              LabKpiItem(
                label: 'Unpaid',
                value: '$unpaidCount',
                caption: 'On this page',
                icon: Icons.schedule_outlined,
                accent: LabClinicalUi.iconAmber,
              ),
              LabKpiItem(
                label: 'Avg. wait',
                value: _avgWaitLabel,
                caption: 'From billed time',
                icon: Icons.timer_outlined,
                accent: LabClinicalUi.iconPink,
              ),
            ],
          );
          final filters = LabFilterBar(
            searchController: _searchController,
            searchHint: 'Name, bill #, or invoice id…',
            compact: compact,
            onSearchSubmitted: (_) => _fetchPatients(reset: true),
            primaryFilter: _statusDropdown(context),
            filterMenuBody: LabDateFilterBody(
              from: _selectedDateRange?.start ?? DateTime.now(),
              to: _selectedDateRange?.end ?? DateTime.now(),
              onChanged: (from, to) {
                setState(() {
                  _selectedDateRange = DateTimeRange(
                    start: DateTime(from.year, from.month, from.day),
                    end: DateTime(to.year, to.month, to.day, 23, 59, 59),
                  );
                  _currentPage = 0;
                });
                _fetchPatients(reset: true);
              },
              onRefresh: () => _fetchPatients(reset: true),
              leading: compact ? _statusDropdown(context) : null,
            ),
          );

          final mainColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 10),
              kpis,
              const SizedBox(height: 10),
              filters,
              const SizedBox(height: 10),
              Expanded(
                child: compact
                    ? _buildPatientCards(displayed)
                    : _buildPatientTable(displayed),
              ),
            ],
          );

          if (showSideBySide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 9, child: mainColumn),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: _buildDetailsPane(fillHeight: true)),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: mainColumn),
              const SizedBox(height: 10),
              SizedBox(
                height: 280,
                child: _buildDetailsPane(fillHeight: false),
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _filterDecoration(
    BuildContext context, {
    required String label,
    required Color iconColor,
    required IconData icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      isDense: true,
      prefixIcon: Padding(
        padding: const EdgeInsets.all(6),
        child: HeltySolidIcon(
          icon: icon,
          color: iconColor,
          size: 22,
          iconSize: 13,
          radius: 6,
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      labelStyle: const TextStyle(fontSize: 11),
    );
  }

  Widget _statusDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('pay-$_payFilter'),
      initialValue: _payFilter,
      isExpanded: true,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: _filterDecoration(
        context,
        label: 'Status',
        iconColor: LabClinicalUi.iconAmber,
        icon: Icons.flag_outlined,
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All statuses')),
        DropdownMenuItem(value: 'ready', child: Text('Ready to open')),
        DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
      ],
      onChanged: (v) {
        if (v == null) return;
        setState(() => _payFilter = v);
      },
    );
  }

  Widget _buildPatientTable(List<_UnregisteredPatientTxn> patients) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const colGap = 20.0;
    final footer = LabPaginationFooter(
      skip: _currentPage * _rowsPerPage,
      pageSize: _rowsPerPage,
      shown: _patients.length,
      total: _total,
      hasMore: _hasMore,
      onPrev: () => _goToPage(_currentPage - 1),
      onNext: () => _goToPage(_currentPage + 1),
    );

    Widget head(String label, {int flex = 1, bool alignEnd = false}) {
      return Expanded(
        flex: flex,
        child: Text(
          label,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    }

    return HeltySurfaceCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
            ),
            child: Row(
              children: [
                const SizedBox(width: 4),
                head('#', flex: 1),
                const SizedBox(width: colGap),
                head('PATIENT', flex: 5),
                const SizedBox(width: colGap),
                head('BILL', flex: 2),
                const SizedBox(width: colGap),
                head('SERVICES', flex: 3),
                const SizedBox(width: colGap),
                head('WAIT', flex: 2),
                const SizedBox(width: colGap),
                head('STATUS', flex: 2),
                const SizedBox(width: colGap),
                head('ACTIONS', flex: 3, alignEnd: true),
              ],
            ),
          ),
          Expanded(child: _queueBody(patients, useCards: false)),
          footer,
        ],
      ),
    );
  }

  Widget _buildPatientCards(List<_UnregisteredPatientTxn> patients) {
    return Column(
      children: [
        Expanded(child: _queueBody(patients, useCards: true)),
        LabPaginationFooter(
          skip: _currentPage * _rowsPerPage,
          pageSize: _rowsPerPage,
          shown: _patients.length,
          total: _total,
          hasMore: _hasMore,
          onPrev: () => _goToPage(_currentPage - 1),
          onNext: () => _goToPage(_currentPage + 1),
        ),
      ],
    );
  }

  Widget _queueBody(
    List<_UnregisteredPatientTxn> patients, {
    required bool useCards,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: HeltyEllipsisText(
            text: _errorMessage!,
            maxLines: 3,
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.error),
          ),
        ),
      );
    }
    if (patients.isEmpty) {
      return Center(
        child: Text(
          'No waiting patients match the current filters.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: patients.length,
      separatorBuilder: (_, _) => useCards
          ? const SizedBox.shrink()
          : Divider(height: 1, color: cs.outline.withValues(alpha: 0.08)),
      itemBuilder: (context, index) {
        final patient = patients[index];
        final indexLabel = '${_currentPage * _rowsPerPage + index + 1}';
        if (useCards) {
          return _waitingCard(patient, indexLabel);
        }
        return ColoredBox(
          color: LabClinicalUi.zebraFill(cs, index),
          child: _waitingRow(patient, indexLabel),
        );
      },
    );
  }

  Widget _identity(_UnregisteredPatientTxn patient) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final avatarColor = LabClinicalUi.avatarColor(
      patient.patientId ?? patient.rowKey,
    );
    return Row(
      children: [
        PatientAvatar(
          avatarUrl: patient.avatarUrl,
          firstName: patient.firstName,
          surname: patient.surname,
          displayName: patient.fullName,
          size: 36,
          backgroundColor: avatarColor,
          foregroundColor: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeltyEllipsisText(
                text: patient.fullName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              HeltyEllipsisText(
                text: [
                  if (patient.age != null) '${patient.age} yrs',
                  if (patient.gender?.trim().isNotEmpty == true)
                    patient.gender!.trim(),
                  if (patient.phoneNumber?.trim().isNotEmpty == true)
                    patient.phoneNumber!,
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusChip(_UnregisteredPatientTxn patient) {
    if (patient.canOpenModulePatient) {
      return HeltyEllipsisChip(
        label: patient.isPaid ? 'Paid' : 'Ready',
        color: LabClinicalUi.iconGreen,
      );
    }
    return const HeltyEllipsisChip(
      label: 'Unpaid',
      color: LabClinicalUi.iconAmber,
    );
  }

  Widget _rowActions(_UnregisteredPatientTxn patient) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: _footerPrimaryEnabled(patient)
                ? () => _goToRegister(patient)
                : null,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: const StadiumBorder(),
            ),
            child: Text(_isRegisterUse ? 'Register' : 'Open'),
          ),
          PopupMenuButton<String>(
            tooltip: 'More actions',
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onSelected: (value) {
              switch (value) {
                case 'select':
                  setState(() => _selectedPatient = patient);
                case 'open':
                  if (_footerPrimaryEnabled(patient)) _goToRegister(patient);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'select', child: Text('View details')),
              PopupMenuItem(
                value: 'open',
                enabled: _footerPrimaryEnabled(patient),
                child: Text(_footerPrimaryLabel(patient)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _waitingRow(_UnregisteredPatientTxn patient, String indexLabel) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selected = _selectedPatient?.rowKey == patient.rowKey;
    return Material(
      color: selected ? cs.primary.withValues(alpha: 0.06) : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedPatient = patient),
        onDoubleTap: _footerPrimaryEnabled(patient)
            ? () => _goToRegister(patient)
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: HeltyEllipsisText(
                  text: indexLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(flex: 5, child: _identity(patient)),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: HeltyEllipsisText(
                  text: patient.billLabel,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 3,
                child: HeltyEllipsisText(
                  text: patient.services.isEmpty
                      ? '—'
                      : patient.services.join(', '),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: HeltyEllipsisText(
                  text: _waitLabel(patient),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _waitColor(patient),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: _statusChip(patient)),
              const SizedBox(width: 20),
              Expanded(flex: 3, child: _rowActions(patient)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _waitingCard(_UnregisteredPatientTxn patient, String indexLabel) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return HeltySurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() => _selectedPatient = patient),
        onDoubleTap: _footerPrimaryEnabled(patient)
            ? () => _goToRegister(patient)
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    indexLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _identity(patient)),
                  HeltyEllipsisText(
                    text: _waitLabel(patient),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _waitColor(patient),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              HeltyEllipsisText(
                text: patient.services.isEmpty
                    ? 'No services listed'
                    : patient.services.join(', '),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  HeltyStatusChip(
                    label: patient.billLabel,
                    color: LabClinicalUi.iconIndigo,
                  ),
                  HeltyStatusChip(
                    label: patient.canOpenModulePatient
                        ? (patient.isPaid ? 'Paid' : 'Ready')
                        : 'Unpaid',
                    color: patient.canOpenModulePatient
                        ? LabClinicalUi.iconGreen
                        : LabClinicalUi.iconAmber,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _rowActions(patient),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsPane({required bool fillHeight}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final patient = _selectedPatient;

    final actions = HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const HeltySolidIcon(
                icon: Icons.flash_on,
                color: LabClinicalUi.iconAmber,
                size: 26,
                iconSize: 14,
                radius: 7,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _sidebarAction(
            label: 'Refresh queue',
            icon: Icons.refresh,
            colors: [LabClinicalUi.iconBlue, LabClinicalUi.iconIndigo],
            onPressed: () => _fetchPatients(reset: true),
          ),
          if (!_isRegisterUse && !_isNursingQueueUse) ...[
            const SizedBox(height: 10),
            _sidebarAction(
              label: 'New patient',
              icon: Icons.person_add_alt_1,
              colors: [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.45)!],
              onPressed: () {
                final use = widget.use.trim().toLowerCase();
                final service = switch (use) {
                  'radiology' => 'Radiology',
                  'dialysis' => 'dialysis',
                  _ => 'lab',
                };
                context.router.push(EnlistPaitientRoute(serviceName: service));
              },
            ),
          ],
        ],
      ),
    );

    final details = HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: patient == null
          ? const EmptyStateWidget(
              icon: Icons.person_search_outlined,
              title: 'Select a patient',
              message: 'Choose a row to view billed services.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    PatientAvatar(
                      avatarUrl: patient.avatarUrl,
                      firstName: patient.firstName,
                      surname: patient.surname,
                      displayName: patient.fullName,
                      size: 44,
                      backgroundColor: LabClinicalUi.avatarColor(
                        patient.patientId ?? patient.rowKey,
                      ),
                      foregroundColor: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HeltyEllipsisText(
                            text: patient.fullName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          HeltyEllipsisText(
                            text: [
                              if (patient.age != null) '${patient.age} yrs',
                              if (patient.gender?.trim().isNotEmpty == true)
                                patient.gender!.trim(),
                            ].join(' · '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                HeltyStatusChip(
                  label: patient.billLabel,
                  color: LabClinicalUi.iconIndigo,
                ),
                const SizedBox(height: 8),
                HeltyEllipsisText(
                  text: DateFormatter.dateTime(patient.dateTime),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Services (${patient.services.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: patient.services.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      return HeltyEllipsisText(
                        text: patient.services[index],
                        style: theme.textTheme.bodyMedium,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _footerPrimaryEnabled(patient)
                      ? () => _goToRegister(patient)
                      : null,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(_footerPrimaryLabel(patient)),
                ),
              ],
            ),
    );

    if (!fillHeight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          actions,
          const SizedBox(height: 12),
          SizedBox(height: 220, child: details),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        actions,
        const SizedBox(height: 12),
        Expanded(child: details),
      ],
    );
  }

  Widget _sidebarAction({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goToRegister(_UnregisteredPatientTxn patient) {
    if (_isNursingQueueUse) {
      _openSendToRoomDialog(patient);
      return;
    }

    if (!_isRegisterUse) {
      if (patient.isOpdWard && !patient.isPaid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This bill is not paid yet. Open the patient after payment is complete.',
            ),
          ),
        );
        return;
      }
      final resolvedPatientId = patient.patientId?.trim() ?? '';
      // if (resolvedPatientId.isEmpty) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('Cannot open patient because patient ID is missing.'),
      //     ),
      //   );
      //   return;
      // }
      final use = widget.use.trim().toLowerCase();
      final moduleType = switch (use) {
        'radiology' => ModuleRequestFlowType.radiology,
        'dialysis' => ModuleRequestFlowType.dialysis,
        _ => ModuleRequestFlowType.laboratory,
      };
      var patientFirst = patient.firstName.trim();
      var patientLast = patient.surname.trim();
      if (patientFirst.isEmpty && patientLast.isEmpty) {
        final parts = _UnregisteredPatientTxn._namesFromPatientName(
          patient.patientNameAsPrinted,
        );
        patientFirst = parts.$1;
        patientLast = parts.$2;
      }
      final paidContext = PaidModuleRequestContext(
        moduleType: moduleType,
        patientId: resolvedPatientId,
        invoiceId: patient.transactionId,
        invoiceDisplayId: patient.billLabel,
        serviceLines: patient.serviceLines,
        invoiceStaffId: patient.invoiceStaffId,
        patientFirstName: patientFirst.isNotEmpty ? patientFirst : null,
        patientSurname: patientLast.isNotEmpty ? patientLast : null,
      );
      ref.read(paidModuleRequestContextProvider.notifier).state = paidContext;

      if (moduleType == ModuleRequestFlowType.radiology) {
        context.router.push(
          RadiologyPatientHistoryRoute(patientId: patient.patientId ?? ''),
        );
      } else if (moduleType == ModuleRequestFlowType.dialysis) {
        context.router.push(const DialysisCreateSessionRoute());
      } else {
        context.router.push(const LabCreateOrderRoute());
      }
      return;
    }

    // Build a minimal Patient model to seed the registration form.
    final String fallbackId = patient.patientId ?? patient.transactionId;

    final seededPatient = Patient(
      id: fallbackId,
      patientId: fallbackId,
      cardNo: '',
      title: '',
      surname: patient.surname,
      firstName: patient.firstName,
      otherName: null,
      dob: DateTime.now(),
      gender: '',
      maritalStatus: '',
      nationality: '',
      stateOfOrigin: '',
      lga: '',
      town: '',
      permanentAddress: '',
      religion: null,
      email: null,
      preferredLanguage: null,
      phoneNumber: patient.phoneNumber,
      addressOfResidence: null,
      profession: null,
      nextOfKinName: null,
      nextOfKinPhone: null,
      nextOfKinAddress: null,
      nextOfKinRelationship: null,
      hmo: null,
      fingerprintData: null,
      createdAt: null,
      updatedAt: null,
      createdBy: null,
      updatedBy: null,
      lockNames: true,
      fromUnregisteredFlow: true,
      unregisteredTransactionId: patient.transactionId,
    );

    context.router.push(PatientFormRoute(patient: seededPatient));
  }

  Future<void> _openSendToRoomDialog(_UnregisteredPatientTxn patient) async {
    if (!patient.hasPatientId || patient.invoiceUuid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient or invoice is missing for queue action.'),
        ),
      );
      return;
    }

    final rooms = await _waitingService.fetchConsultingRooms();
    if (!mounted) return;
    if (rooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No consulting rooms configured.')),
      );
      return;
    }
    String selectedRoomId = rooms.first.id;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Send to consulting room'),
          content: StatefulBuilder(
            builder: (context, setModalState) {
              return DropdownButtonFormField<String>(
                initialValue: selectedRoomId,
                items: rooms
                    .map(
                      (r) => DropdownMenuItem<String>(
                        value: r.id,
                        child: Text(r.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setModalState(() => selectedRoomId = v);
                },
                decoration: const InputDecoration(
                  labelText: 'Consulting room',
                  border: OutlineInputBorder(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
    if (submitted != true) return;

    // Link vitals to invoice first if missing.
    if (!patient.hasVitals) {
      await _waitingService.createPatientVitals(
        CreatePatientVitalsDto(
          invoiceId: patient.invoiceUuid,
          patientId: patient.patientId,
        ),
      );
    }
    await _waitingService.sendInvoiceToRoom(
      invoiceId: patient.invoiceUuid,
      consultingRoomId: selectedRoomId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Patient sent to consulting room.')),
    );
    _fetchPatients();
  }
}

/// Row from `GET /invoices/unregistered-patients` (invoice-led billing).
///
/// [transactionId] is the invoice identifier (UUID or human `invoiceId` code).
/// [patientId] is the server patient UUID when present on the row (walk-in / placeholder).
/// [invoiceDisplayId] is the human-facing bill number when the API sends it.
class _UnregisteredPatientTxn {
  _UnregisteredPatientTxn({
    required this.transactionId,
    required this.surname,
    required this.firstName,
    required this.services,
    required this.dateTime,
    this.phoneNumber,
    this.age,
    this.gender,
    this.ward,
    this.patientId,
    this.invoiceDisplayId,
    this.patientNameAsPrinted,
    this.invoiceStatus,
    this.serviceLines = const [],
    this.consultationServices = const [],
    this.rowAppearsPaid = false,
    this.invoiceUuid = '',
    this.hasVitals = false,
    this.invoiceStaffId,
    this.avatarUrl,
  });

  /// Invoice id (UUID or bill code) — also sent as [Patient.unregisteredTransactionId] for linkage.
  final String transactionId;

  /// Human-facing bill code (`invoiceID`), when present.
  final String? invoiceDisplayId;

  /// Full name exactly as returned by the API (`patientName`), when present.
  final String? patientNameAsPrinted;
  final String? invoiceStatus;
  final List<PaidInvoiceServiceLine> serviceLines;
  final List<ConsultationServiceLine> consultationServices;

  ConsultationServiceLine? get primaryConsultationCredit {
    if (consultationServices.isEmpty) return null;
    ConsultationServiceLine? best;
    for (final line in consultationServices) {
      if (!line.hasCreditMetadata) continue;
      if (best == null || line.visitsRemaining > best.visitsRemaining) {
        best = line;
      }
    }
    return best ?? consultationServices.first;
  }

  /// True when status/amounts/lines indicate the invoice is paid enough to open.
  final bool rowAppearsPaid;
  final String invoiceUuid;
  final bool hasVitals;

  /// Invoice requesting / billing staff id when returned by the API.
  final String? invoiceStaffId;
  final String surname;
  final String firstName;
  final String? phoneNumber;
  final int? age;
  final String? gender;
  final String? ward;
  final List<String> services;
  final DateTime dateTime;

  /// Patient UUID from the API row (`patientId`) — prefer over nested `patient.id`.
  final String? patientId;
  final String? avatarUrl;
  bool get hasPatientId => (patientId ?? '').trim().isNotEmpty;

  String get rowKey {
    final pid = patientId?.trim();
    if (pid != null && pid.isNotEmpty) return pid;
    if (transactionId.isNotEmpty) return transactionId;
    final d = invoiceDisplayId?.trim();
    if (d != null && d.isNotEmpty) return d;
    return '${fullName}_${dateTime.millisecondsSinceEpoch}';
  }

  String get billLabel {
    final human = invoiceDisplayId?.trim();
    if (human != null && human.isNotEmpty) return human;
    final id = transactionId.trim();
    if (id.length <= 12) return id.isEmpty ? '—' : id;
    return '${id.substring(0, 8)}…';
  }

  String get fullName {
    final printed = patientNameAsPrinted?.trim();
    if (printed != null && printed.isNotEmpty) return printed;
    final combined = '$surname $firstName'.trim();
    if (combined.isNotEmpty) return combined;
    return '—';
  }

  bool get isPaid => rowAppearsPaid;

  bool get isOpdWard {
    final w = (ward ?? 'OPD').trim().toUpperCase();
    return w.isEmpty || w == 'OPD';
  }

  /// Lab/Radiology: non-OPD may open unpaid; OPD requires payment.
  bool get canOpenModulePatient => !isOpdWard || isPaid;

  factory _UnregisteredPatientTxn.fromWaitingQueue(WaitingPatientModel row) {
    final patient = row.patient;
    return _UnregisteredPatientTxn(
      transactionId: row.invoiceId,
      invoiceDisplayId: row.invoiceDisplayId,
      patientNameAsPrinted: patient?.displayName.trim(),
      invoiceStatus: row.seen ? 'SEEN' : 'PAID',
      rowAppearsPaid: true,
      surname: patient?.surname ?? '',
      firstName: patient?.firstName ?? '',
      phoneNumber: patient?.phoneNumber,
      age: null,
      gender: patient?.gender,
      ward: patient?.ward,
      services: row.consultationNames,
      dateTime: row.createdAt,
      patientId: row.patientId,
      invoiceUuid: row.invoiceId,
      hasVitals: row.patientVitals?.id.isNotEmpty == true,
      serviceLines: const [],
      consultationServices: row.consultationServices,
      invoiceStaffId: null,
      avatarUrl: patient?.avatarUrl,
    );
  }

  /// Splits a single `patientName` string into given / family for the registration form.
  static (String firstName, String surname) _namesFromPatientName(String? raw) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return ('', '');
    final parts = s.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return (parts[0], '');
    final surname = parts.last;
    final firstName = parts.sublist(0, parts.length - 1).join(' ');
    return (firstName, surname);
  }

  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  /// Row-level `patientId` wins over nested `patient.id` (invoice payloads may nest partial patient).
  static String? _firstNonEmptyId(dynamic a, dynamic b, dynamic c) {
    for (final v in [a, b, c]) {
      final t = v?.toString().trim() ?? '';
      if (t.isNotEmpty) return t;
    }
    return null;
  }

  static double? _parseMoney(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim());
  }

  /// Backend list payloads often omit top-level `status`; infer from amounts / lines.
  static bool _computeAppearsPaid(
    Map<String, dynamic> root,
    Map<String, dynamic> json,
    List<dynamic> rawServices,
  ) {
    final status =
        (root['status'] ??
                json['status'] ??
                root['invoiceStatus'] ??
                json['invoiceStatus'] ??
                root['paymentStatus'] ??
                json['paymentStatus'])
            ?.toString()
            .trim()
            .toUpperCase() ??
        '';
    if (status == 'PENDING' ||
        status == 'UNPAID' ||
        status == 'PARTIAL' ||
        status == 'OVERDUE') {
      return false;
    }
    if (status == 'PAID' || status == 'FULLY_PAID') return true;
    if (json['isPaid'] == true || root['isPaid'] == true) return true;
    if (json['fullyPaid'] == true || root['fullyPaid'] == true) return true;

    final due = _parseMoney(
      root['amountDue'] ??
          json['amountDue'] ??
          root['netAmountDue'] ??
          json['netAmountDue'] ??
          root['balanceDue'] ??
          json['balanceDue'],
    );
    if (due != null && due <= 0) return true;

    if (rawServices.isEmpty) return false;
    for (final e in rawServices) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final unit = _parseMoney(m['unitPrice']) ?? 0;
      final qtyRaw = m['quantity'];
      final qty = qtyRaw is num
          ? qtyRaw.toDouble()
          : (_parseMoney(qtyRaw) ?? 1.0);
      final lineTotal = unit * qty;
      final paid = _parseMoney(m['amountPaid']) ?? 0;
      if (lineTotal > 0 && paid + 1e-6 < lineTotal) return false;
    }
    return rawServices.isNotEmpty;
  }

  static String? _parseInvoiceStaffId(
    Map<String, dynamic> root,
    Map<String, dynamic> json,
  ) {
    final staff = _asMap(root['staff']) ?? _asMap(json['staff']);
    final fromNested = staff?['id']?.toString().trim();
    if (fromNested != null && fromNested.isNotEmpty) return fromNested;
    for (final key in ['staffId', 'createdById', 'createdByStaffId']) {
      final v = root[key] ?? json[key];
      final s = v?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    // e.g. invoice line `createdBy` (requesting / billing user on that item).
    for (final source in [root, json]) {
      final items = source['invoiceItems'] as List?;
      if (items == null) continue;
      for (final e in items) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final cb = _asMap(m['createdBy']);
        final id = cb?['id']?.toString().trim();
        if (id != null && id.isNotEmpty) return id;
      }
    }
    return null;
  }

  static String? _parseWard(
    Map<String, dynamic> json,
    Map<String, dynamic>? patient,
    Map<String, dynamic> root,
  ) {
    final admission =
        _asMap(json['admission']) ??
        _asMap(patient?['admission']) ??
        _asMap(root['admission']);
    for (final v in [
      json['ward'],
      patient?['ward'],
      root['ward'],
      admission?['ward'],
      admission?['wardName'],
    ]) {
      final s = v?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return null;
  }

  static String? _serviceLineName(Map<String, dynamic> item) {
    final custom = item['customDescription']?.toString().trim();
    if (custom != null && custom.isNotEmpty) return custom;
    final svc = _asMap(item['service']);
    final name = (svc?['name'] ?? item['name'] ?? item['serviceName'])
        ?.toString()
        .trim();
    if (name != null && name.isNotEmpty) return name;
    return null;
  }

  factory _UnregisteredPatientTxn.fromJson(Map<String, dynamic> json) {
    final invoice = _asMap(json['invoice']);
    final root = invoice ?? json;

    final patient = _asMap(json['patient']) ?? _asMap(root['patient']);

    final patientNameSingle =
        json['patientName']?.toString() ?? root['patientName']?.toString();
    final printed = patientNameSingle?.trim();
    final (
      String splitFirst,
      String splitSurname,
    ) = printed != null && printed.isNotEmpty
        ? _namesFromPatientName(printed)
        : ('', '');

    final rawServices =
        (root['invoiceItems'] as List?) ??
        (root['services'] as List?) ??
        (json['services'] as List?) ??
        (json['items'] as List?) ??
        (json['invoiceItems'] as List?) ??
        const [];

    final names = <String>[];
    final lines = <PaidInvoiceServiceLine>[];
    for (final e in rawServices) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final n = _serviceLineName(m);
      if (n != null) names.add(n);
      final service = _asMap(m['service']);
      final itemId = (m['invoiceItemId'] ?? m['id'] ?? '').toString().trim();
      final serviceIdRaw = (m['serviceId'] ?? service?['id'] ?? '')
          .toString()
          .trim();
      final serviceId = serviceIdRaw.isEmpty ? null : serviceIdRaw;
      final serviceName =
          (service?['name'] ?? m['serviceName'] ?? m['name'] ?? '')
              .toString()
              .trim();
      String categoryName = '';
      final cat = m['category'];
      if (cat is String) {
        categoryName = cat.trim();
      } else if (service != null && service['category'] is Map) {
        final c = Map<String, dynamic>.from(service['category'] as Map);
        categoryName = (c['name'] ?? '').toString().trim();
      } else {
        categoryName = (m['categoryName'] ?? service?['categoryName'] ?? '')
            .toString()
            .trim();
      }
      if (itemId.isNotEmpty && serviceName.isNotEmpty) {
        lines.add(
          PaidInvoiceServiceLine(
            invoiceItemId: itemId,
            serviceId: serviceId,
            serviceName: serviceName,
            categoryName: categoryName,
          ),
        );
      }
    }

    final String? dtString =
        json['date']?.toString() ??
        root['date']?.toString() ??
        root['createdAt']?.toString() ??
        root['updatedAt']?.toString() ??
        json['createdAt']?.toString() ??
        json['datetime']?.toString();

    final invoiceUuid = root['id']?.toString().trim() ?? '';
    final legacyTxn =
        json['transactionID']?.toString() ?? json['transactionId']?.toString();
    final topInvoiceId =
        json['invoiceId']?.toString().trim() ??
        root['invoiceId']?.toString().trim() ??
        '';

    final resolvedId = invoiceUuid.isNotEmpty
        ? invoiceUuid
        : (legacyTxn != null && legacyTxn.toString().trim().isNotEmpty
              ? legacyTxn.toString().trim()
              : topInvoiceId);

    final displayBill =
        root['invoiceID']?.toString() ??
        root['invoiceId']?.toString() ??
        json['invoiceID']?.toString() ??
        json['invoiceId']?.toString();

    final displayTrimmed = displayBill?.toString().trim();
    final displayResolved =
        (displayTrimmed != null && displayTrimmed.isNotEmpty)
        ? displayTrimmed
        : (topInvoiceId.isNotEmpty ? topInvoiceId : null);

    final sn =
        (patient?['surname'] ?? root['surname'] ?? json['surname'])
            ?.toString() ??
        '';
    final fn =
        (patient?['firstName'] ??
                patient?['firstname'] ??
                root['firstName'] ??
                root['firstname'] ??
                json['firstname'] ??
                json['firstName'])
            ?.toString() ??
        '';

    final surname = sn.isNotEmpty ? sn : splitSurname;
    final firstName = fn.isNotEmpty ? fn : splitFirst;

    final appearsPaid = _computeAppearsPaid(root, json, rawServices);

    final invoiceStaffId = _parseInvoiceStaffId(root, json);

    return _UnregisteredPatientTxn(
      transactionId: resolvedId,
      invoiceDisplayId: displayResolved,
      patientNameAsPrinted: printed != null && printed.isNotEmpty
          ? printed
          : null,
      invoiceStatus: (root['status'] ?? json['status'])?.toString(),
      rowAppearsPaid: appearsPaid,
      surname: surname,
      firstName: firstName,
      phoneNumber:
          (patient?['phoneNumber'] ??
                  root['phoneNumber'] ??
                  json['phoneNumber'] ??
                  patient?['phone'] ??
                  root['phone'] ??
                  json['phone'])
              ?.toString(),
      age: (patient?['age'] ?? json['age']) is num
          ? ((patient?['age'] ?? json['age']) as num).toInt()
          : int.tryParse((patient?['age'] ?? json['age'])?.toString() ?? ''),
      gender: () {
        for (final v in [json['gender'], patient?['gender'], root['gender']]) {
          final s = v?.toString().trim();
          if (s != null && s.isNotEmpty) return s;
        }
        return null;
      }(),
      ward: _parseWard(json, patient, root),
      services: names,
      dateTime: dtString != null
          ? DateTime.tryParse(dtString) ?? DateTime.now()
          : DateTime.now(),
      patientId: _firstNonEmptyId(
        json['patientId'],
        root['patientId'],
        patient?['id'],
      ),
      serviceLines: lines,
      invoiceUuid: invoiceUuid,
      hasVitals: root['vitalsId'] != null || root['vitals'] != null,
      invoiceStaffId: invoiceStaffId,
      avatarUrl: avatarUrlFromJson(patient) ?? avatarUrlFromJson(json),
    );
  }
}
