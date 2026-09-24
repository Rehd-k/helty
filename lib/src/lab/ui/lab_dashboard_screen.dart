import 'dart:convert';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:helty/src/core/platform/save_bytes.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/widgets/patient_avatar.dart';
import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/providers/lab_providers.dart';
import 'package:helty/src/lab/ui/widgets/lab_clinical_ui.dart';
import 'package:helty/src/models/super_admin_department_preview.dart';
import 'package:helty/src/printing/pdf/lab_order_pdf.dart';
import 'package:helty/src/printing/pdf/report_template_picker.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/helper/app_timezone.dart';
import 'package:helty/src/widgets/helty_surface.dart';
import 'package:printing/printing.dart';

@RoutePage()
class LabDashboardScreen extends ConsumerStatefulWidget {
  const LabDashboardScreen({super.key});

  @override
  ConsumerState<LabDashboardScreen> createState() => _LabDashboardScreenState();
}

class _LabDashboardScreenState extends ConsumerState<LabDashboardScreen> {
  LabOrderStatus? _filterStatus;
  static const _skip = 0;
  static const _take = 100;
  static const _pageSize = 20;

  /// Summary + order list (aligned with [view_waiting_patient] defaults).
  late DateTimeRange _ordersDateRange;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _pageSkip = 0;

  @override
  void initState() {
    super.initState();
    final n = AppTimezone.now();
    _ordersDateRange = _dateRangeForDay(n);
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (q == _searchQuery) return;
      setState(() {
        _searchQuery = q;
        _pageSkip = 0;
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Lagos calendar day → local [DateTimeRange] for display and filtering.
  DateTimeRange _dateRangeForDay(DateTime day) {
    return DateTimeRange(
      start: DateTime(day.year, day.month, day.day),
      end: DateTime(day.year, day.month, day.day, 23, 59, 59, 999),
    );
  }

  /// Lagos wall-clock bounds for the orders API (converted to UTC in [LabApiService]).
  LabOrdersParams _ordersParams() {
    final r = _ordersDateRange;
    return LabOrdersParams(
      from: AppTimezone.dateTime(r.start.year, r.start.month, r.start.day),
      to: AppTimezone.dateTime(
        r.end.year,
        r.end.month,
        r.end.day,
        23,
        59,
        59,
        999,
      ),
      skip: _skip,
      take: _take,
    );
  }

  Map<LabOrderStatus, int> _statusCounts(List<LabOrder> orders) {
    final counts = {for (final s in LabOrderStatus.values) s: 0};
    for (final o in orders) {
      counts[o.status] = (counts[o.status] ?? 0) + 1;
    }
    return counts;
  }

  List<LabOrder> _filteredOrders(List<LabOrder> orders) {
    var list = _filterStatus == null
        ? orders
        : orders.where((o) => o.status == _filterStatus).toList();
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) return list;
    return list.where((o) {
      final name = o.patient?.displayName.toLowerCase() ?? '';
      final id = o.id.toLowerCase();
      final ward = o.wardDisplayLabel.toLowerCase();
      final tests = o.items
          .map((i) => i.testVersion?.test?.name ?? '')
          .join(' ')
          .toLowerCase();
      return name.contains(q) ||
          id.contains(q) ||
          ward.contains(q) ||
          tests.contains(q);
    }).toList();
  }

  void _retryOrdersLoad() {
    invalidateLabOrderCaches(ref, listParams: _ordersParams());
  }

  Future<void> _exportLabConfig() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final payload = await ref.read(labApiServiceProvider).exportLabConfig();
      final bytes = Uint8List.fromList(
        utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
      );
      final path = await FilePicker.saveFile(
        dialogTitle: 'Save lab configuration',
        fileName: 'helty-lab-config.json',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );
      if (!mounted) return;
      if (path == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Export cancelled')),
        );
        return;
      }
      // Desktop file_picker only returns a path; bytes are written on web only.
      if (!kIsWeb) {
        await writeBytesToFilePath(path, bytes);
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Lab configuration saved to $path')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _importLabConfig() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace lab configuration?'),
        content: const Text(
          'This replaces all lab categories, tests, versions, fields, '
          'antibiotics, and AST options, and removes order lines/results '
          'tied to the current catalog.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await FilePicker.pickFiles(
        dialogTitle: 'Import lab configuration',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;

      final file = picked.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not read file contents')),
        );
        return;
      }

      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Invalid lab config file')),
        );
        return;
      }

      await ref
          .read(labApiServiceProvider)
          .importLabConfig(Map<String, dynamic>.from(decoded));

      ref.invalidate(labCategoriesFutureProvider);
      ref.invalidate(labTestsFutureProvider);
      ref.invalidate(labAntibioticsFutureProvider);
      ref.invalidate(labAstResultOptionsFutureProvider);
      invalidateLabOrderCaches(ref, listParams: _ordersParams());

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Lab configuration imported')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  void _openOrder(LabOrder order) {
    context.router.push(LabOrderDetailRoute(orderId: order.id)).then((_) {
      if (mounted) {
        invalidateLabOrderCaches(ref, listParams: _ordersParams());
      }
    });
  }

  void _setStatusFilter(LabOrderStatus? status) {
    setState(() {
      _filterStatus = status;
      _pageSkip = 0;
    });
  }

  void _applyDateRange(DateTime from, DateTime to) {
    setState(() {
      _ordersDateRange = DateTimeRange(
        start: DateTime(from.year, from.month, from.day),
        end: DateTime(to.year, to.month, to.day, 23, 59, 59, 999),
      );
      _pageSkip = 0;
    });
    _retryOrdersLoad();
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
    return DropdownButtonFormField<LabOrderStatus?>(
      key: ValueKey(_filterStatus?.name ?? 'all'),
      initialValue: _filterStatus,
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
      items: [
        const DropdownMenuItem<LabOrderStatus?>(
          value: null,
          child: Text('All statuses', overflow: TextOverflow.ellipsis),
        ),
        ...LabOrderStatus.values.map(
          (s) => DropdownMenuItem<LabOrderStatus?>(
            value: s,
            child: Text(
              LabClinicalUi.statusLabel(s),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: _setStatusFilter,
    );
  }

  int _uniquePatientCount(List<LabOrder> orders) =>
      _groupOrdersByPatient(orders).length;

  List<LabKpiItem> _kpiItems(List<LabOrder> orders) {
    final counts = _statusCounts(orders);
    return [
      LabKpiItem(
        label: 'Patients',
        value: '${_uniquePatientCount(orders)}',
        caption: 'People who came — repeats count once',
        icon: Icons.groups_outlined,
        accent: LabClinicalUi.iconBlue,
      ),
      LabKpiItem(
        label: 'Orders',
        value: '${orders.length}',
        caption: 'Lab orders in range',
        icon: Icons.receipt_long_outlined,
        accent: LabClinicalUi.iconIndigo,
      ),
      LabKpiItem(
        label: 'Pending',
        value: '${counts[LabOrderStatus.pending] ?? 0}',
        caption: 'Awaiting sample or start',
        icon: Icons.schedule_outlined,
        accent: LabClinicalUi.iconAmber,
      ),
      LabKpiItem(
        label: 'Completed',
        value: '${counts[LabOrderStatus.completed] ?? 0}',
        caption: 'Results entered',
        icon: Icons.check_circle_outline,
        accent: LabClinicalUi.iconTeal,
      ),
    ];
  }

  List<LabStatusCount> _statusMix(List<LabOrder> orders) {
    final counts = _statusCounts(orders);
    return [
      for (final status in LabOrderStatus.values)
        LabStatusCount(
          label: LabClinicalUi.statusLabel(status),
          count: counts[status] ?? 0,
          color: LabClinicalUi.statusColor(status),
        ),
    ];
  }

  List<LabQuickAction> _quickActions({
    required bool isLabManager,
    required bool isSuperAdmin,
  }) {
    final cs = Theme.of(context).colorScheme;
    return [
      LabQuickAction(
        label: 'Waiting Patients',
        icon: Icons.receipt_long_outlined,
        colors: [LabClinicalUi.iconPurple, LabClinicalUi.iconPink],
        onPressed: () => context.router.push(
          NewPatientRoute(
            use: 'Laboratory',
            categoryQueries: const ['Laboratory', 'Laboratory Tests'],
          ),
        ),
      ),
      LabQuickAction(
        label: 'New patient',
        icon: Icons.person_add_alt_1,
        colors: [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.45)!],
        onPressed: () =>
            context.router.push(EnlistPaitientRoute(serviceName: 'lab')),
      ),
      LabQuickAction(
        label: 'New order',
        icon: Icons.biotech_outlined,
        colors: [LabClinicalUi.iconTeal, LabClinicalUi.iconBlue],
        onPressed: () => context.router.push(const LabCreateOrderRoute()),
      ),
      LabQuickAction(
        label: 'Report template',
        icon: Icons.article_outlined,
        colors: [LabClinicalUi.iconIndigo, LabClinicalUi.iconPurple],
        onPressed: () => showReportTemplatePicker(context, ref),
      ),
      if (isLabManager)
        LabQuickAction(
          label: 'Lab config',
          icon: Icons.settings_outlined,
          colors: [LabClinicalUi.iconAmber, LabClinicalUi.iconPink],
          onPressed: () => context.router.push(const LabConfigRoute()),
        ),
      if (isSuperAdmin) ...[
        LabQuickAction(
          label: 'Export config',
          icon: Icons.download_rounded,
          colors: [LabClinicalUi.iconBlue, LabClinicalUi.iconIndigo],
          onPressed: _exportLabConfig,
        ),
        LabQuickAction(
          label: 'Import config',
          icon: Icons.upload_rounded,
          colors: [LabClinicalUi.iconPink, LabClinicalUi.iconAmber],
          onPressed: _importLabConfig,
        ),
      ],
    ];
  }

  Widget _ordersErrorCard(Object error) {
    final theme = Theme.of(context);
    return HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const HeltySolidIcon(
            icon: Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 30,
            iconSize: 16,
            radius: 8,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: HeltyEllipsisText(
              text: 'Unable to load lab orders. $error',
              maxLines: 2,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          TextButton(onPressed: _retryOrdersLoad, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _queuePanel({
    required List<LabOrder> orders,
    required bool loading,
    required Object? error,
    required bool useCards,
  }) {
    if (error != null && orders.isEmpty && !loading) {
      return _ordersErrorCard(error);
    }
    final groups = _groupOrdersByPatient(orders);
    final pageGroups = groups.skip(_pageSkip).take(_pageSize).toList();
    final hasMore = _pageSkip + pageGroups.length < groups.length;
    return _PatientOrdersList(
      groups: pageGroups,
      skip: _pageSkip,
      pageSize: _pageSize,
      total: groups.length,
      hasMore: hasMore,
      loading: loading,
      useCards: useCards,
      emptyMessage: orders.isEmpty
          ? 'No lab orders match the current filters.'
          : 'No patients on this page.',
      onPrev: () {
        if (_pageSkip <= 0) return;
        setState(() => _pageSkip = (_pageSkip - _pageSize).clamp(0, 1 << 30));
      },
      onNext: () {
        if (!hasMore) return;
        setState(() => _pageSkip += _pageSize);
      },
      onOrderTap: _openOrder,
    );
  }

  Widget _sidebar({
    required List<LabOrder> orders,
    required bool isLabManager,
    required bool isSuperAdmin,
    required bool fillHeight,
  }) {
    return LabSidebar(
      actions: _quickActions(
        isLabManager: isLabManager,
        isSuperAdmin: isSuperAdmin,
      ),
      statusCounts: _statusMix(orders),
      fillHeight: fillHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final staff = ref.watch(currentStaffProvider);
    final isSuperAdmin = staffIsSuperAdmin(staff);
    final isLabManager =
        staff?.staffRole.toLowerCase() == 'admin' ||
        staff?.accountType?.name.toLowerCase() == 'laboratory' ||
        staff?.accountType?.name.toLowerCase() == 'lab';
    final ordersAsync = ref.watch(labOrdersFutureProvider(_ordersParams()));
    final allOrders = ordersAsync.asData?.value.data ?? const <LabOrder>[];
    final filteredOrders = _filteredOrders(allOrders);
    final loading = ordersAsync.isLoading && allOrders.isEmpty;
    final error = ordersAsync.asError?.error;

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
            title: 'Laboratory',
            subtitle:
                'Track orders, collect samples, and release verified results.',
            icon: Icons.biotech_outlined,
            iconColor: LabClinicalUi.iconPurple,
            compact: compact,
          );
          final kpis = LabKpiStrip(
            items: _kpiItems(allOrders),
            useSnapStrip: useSnapKpis,
          );
          final filters = LabFilterBar(
            searchController: _searchCtrl,
            searchHint: 'Patient, ward, order, or test…',
            compact: compact,
            onSearchSubmitted: (_) {},
            primaryFilter: _statusDropdown(context),
            filterMenuBody: LabDateFilterBody(
              from: _ordersDateRange.start,
              to: _ordersDateRange.end,
              onChanged: _applyDateRange,
              onRefresh: _retryOrdersLoad,
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
                child: _queuePanel(
                  orders: filteredOrders,
                  loading: loading,
                  error: error,
                  useCards: compact,
                ),
              ),
            ],
          );

          if (showSideBySide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 9, child: mainColumn),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _sidebar(
                    orders: allOrders,
                    isLabManager: isLabManager,
                    isSuperAdmin: isSuperAdmin,
                    fillHeight: true,
                  ),
                ),
              ],
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final bounded = constraints.maxHeight.isFinite;
              if (bounded) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: mainColumn),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 280,
                      child: SingleChildScrollView(
                        child: _sidebar(
                          orders: allOrders,
                          isLabManager: isLabManager,
                          isSuperAdmin: isSuperAdmin,
                          fillHeight: false,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: 10),
                  kpis,
                  const SizedBox(height: 10),
                  filters,
                  const SizedBox(height: 10),
                  SizedBox(
                    height: compact ? 480 : 520,
                    child: _queuePanel(
                      orders: filteredOrders,
                      loading: loading,
                      error: error,
                      useCards: compact,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _sidebar(
                    orders: allOrders,
                    isLabManager: isLabManager,
                    isSuperAdmin: isSuperAdmin,
                    fillHeight: false,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _PatientOrderGroup {
  const _PatientOrderGroup({
    required this.patientKey,
    required this.patient,
    required this.orders,
  });

  final String patientKey;
  final LabOrderPatient? patient;
  final List<LabOrder> orders;

  String get displayName => patient?.displayName.trim().isNotEmpty == true
      ? patient!.displayName
      : 'Unknown patient';

  int get totalTests =>
      orders.fold(0, (sum, order) => sum + order.items.length);

  LabOrderStatus get latestStatus =>
      orders.isEmpty ? LabOrderStatus.pending : orders.first.status;

  DateTime? get latestCreatedAt =>
      orders.isEmpty ? null : orders.first.createdAt;

  /// Ward at request time; unique labels joined when a patient has mixed wards.
  String get wardDisplayLabel {
    final labels = <String>[];
    final seen = <String>{};
    for (final order in orders) {
      final label = order.wardDisplayLabel;
      if (seen.add(label)) labels.add(label);
    }
    if (labels.isEmpty) return 'OPD';
    return labels.join(', ');
  }
}

String _labPatientGroupKey(LabOrder order) {
  final id = order.patient?.id.trim() ?? '';
  if (id.isNotEmpty) return id;
  final card = order.patient?.patientId?.trim() ?? '';
  if (card.isNotEmpty) return 'card:$card';
  return 'unknown-${order.id}';
}

List<_PatientOrderGroup> _groupOrdersByPatient(List<LabOrder> orders) {
  final map = <String, _PatientOrderGroup>{};
  for (final order in orders) {
    final key = _labPatientGroupKey(order);
    final existing = map[key];
    if (existing == null) {
      map[key] = _PatientOrderGroup(
        patientKey: key,
        patient: order.patient,
        orders: [order],
      );
    } else {
      map[key] = _PatientOrderGroup(
        patientKey: key,
        patient: existing.patient ?? order.patient,
        orders: [...existing.orders, order],
      );
    }
  }

  for (final entry in map.entries) {
    entry.value.orders.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  }

  final groups = map.values.toList()
    ..sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );
  return groups;
}

class _PatientOrdersList extends StatelessWidget {
  const _PatientOrdersList({
    required this.groups,
    required this.skip,
    required this.pageSize,
    required this.total,
    required this.hasMore,
    required this.loading,
    required this.useCards,
    required this.emptyMessage,
    required this.onPrev,
    required this.onNext,
    required this.onOrderTap,
  });

  final List<_PatientOrderGroup> groups;
  final int skip;
  final int pageSize;
  final int total;
  final bool hasMore;
  final bool loading;
  final bool useCards;
  final String emptyMessage;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(LabOrder order) onOrderTap;

  static const _colGap = 20.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final footer = LabPaginationFooter(
      skip: skip,
      pageSize: pageSize,
      shown: groups.length,
      total: total,
      hasMore: hasMore,
      onPrev: onPrev,
      onNext: onNext,
    );

    if (loading) {
      return HeltySurfaceCard(
        child: Column(
          children: [
            const Expanded(child: Center(child: CircularProgressIndicator())),
            footer,
          ],
        ),
      );
    }

    if (groups.isEmpty) {
      return HeltySurfaceCard(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            footer,
          ],
        ),
      );
    }

    if (useCards) {
      return Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                return _PatientOrdersTile(
                  group: groups[index],
                  indexLabel: '${skip + index + 1}',
                  onOrderTap: onOrderTap,
                  asCard: true,
                );
              },
            ),
          ),
          footer,
        ],
      );
    }

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
                const SizedBox(width: _colGap),
                head('PATIENT', flex: 5),
                const SizedBox(width: _colGap),
                head('WARD', flex: 3),
                const SizedBox(width: _colGap),
                head('ORDERS', flex: 2),
                const SizedBox(width: _colGap),
                head('WAIT', flex: 2),
                const SizedBox(width: _colGap),
                head('STATUS', flex: 2),
                const SizedBox(width: _colGap),
                head('ACTIONS', flex: 3, alignEnd: true),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: groups.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.08)),
              itemBuilder: (context, index) {
                return ColoredBox(
                  color: LabClinicalUi.zebraFill(cs, index),
                  child: _PatientOrdersTile(
                    group: groups[index],
                    indexLabel: '${skip + index + 1}',
                    onOrderTap: onOrderTap,
                    asCard: false,
                  ),
                );
              },
            ),
          ),
          footer,
        ],
      ),
    );
  }
}

class _PatientOrdersTile extends ConsumerStatefulWidget {
  const _PatientOrdersTile({
    required this.group,
    required this.indexLabel,
    required this.onOrderTap,
    required this.asCard,
  });

  final _PatientOrderGroup group;
  final String indexLabel;
  final void Function(LabOrder order) onOrderTap;
  final bool asCard;

  @override
  ConsumerState<_PatientOrdersTile> createState() => _PatientOrdersTileState();
}

class _PatientOrdersTileState extends ConsumerState<_PatientOrdersTile> {
  final Set<String> _selectedItemIds = {};
  bool _printing = false;
  bool _expanded = false;
  bool _loadingResults = false;
  Object? _loadError;
  Map<String, LabOrder>? _enrichedOrders;

  List<LabOrder> get _displayOrders =>
      widget.group.orders.map((o) => _enrichedOrders?[o.id] ?? o).toList();

  Iterable<LabOrderItem> get _allItems sync* {
    for (final order in _displayOrders) {
      yield* order.items;
    }
  }

  List<LabOrderItem> get _printableItems =>
      _allItems.where((item) => labOrderItemHasPrintableResults(item)).toList();

  bool get _hasPrintableSelection => _selectedItemIds.any(
    (id) => _printableItems.any((item) => item.id == id),
  );

  bool _hasSameOrderIds(List<LabOrder> a, List<LabOrder> b) {
    if (a.length != b.length) return false;
    final aIds = a.map((o) => o.id).toSet();
    return b.every((o) => aIds.contains(o.id));
  }

  @override
  void didUpdateWidget(covariant _PatientOrdersTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final groupChanged =
        oldWidget.group.patientKey != widget.group.patientKey ||
        !_hasSameOrderIds(oldWidget.group.orders, widget.group.orders);
    if (!groupChanged) return;

    _enrichedOrders = null;
    _loadError = null;
    if (_expanded) {
      _loadOrderResults();
    }
  }

  Future<void> _loadOrderResults() async {
    if (_loadingResults) return;

    final orderIds = widget.group.orders.map((o) => o.id).toList();
    final allLoaded =
        _enrichedOrders != null &&
        orderIds.every((id) => _enrichedOrders!.containsKey(id));
    if (allLoaded) return;

    setState(() {
      _loadingResults = true;
      _loadError = null;
    });

    try {
      final loaded = await Future.wait(
        orderIds.map((id) => ref.read(labOrderByIdProvider(id).future)),
      );
      if (!mounted) return;
      setState(() {
        _enrichedOrders = {for (final o in loaded) o.id: o};
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e);
    } finally {
      if (mounted) setState(() => _loadingResults = false);
    }
  }

  void _onExpansionChanged(bool expanded) {
    setState(() => _expanded = expanded);
    if (expanded) {
      _loadOrderResults();
    }
  }

  void _toggleItem(LabOrderItem item, bool? selected) {
    if (!labOrderItemHasPrintableResults(item)) return;
    setState(() {
      if (selected == true) {
        _selectedItemIds.add(item.id);
      } else {
        _selectedItemIds.remove(item.id);
      }
    });
  }

  void _toggleSelectAllPrintable(bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedItemIds.addAll(_printableItems.map((i) => i.id));
      } else {
        _selectedItemIds.removeAll(_printableItems.map((i) => i.id));
      }
    });
  }

  Future<void> _printSelected() async {
    if (!_hasPrintableSelection || _printing) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _printing = true);

    try {
      final orderIds = _displayOrders
          .where(
            (order) =>
                order.items.any((item) => _selectedItemIds.contains(item.id)),
          )
          .map((order) => order.id)
          .toSet();

      final fullOrders = <String, LabOrder>{};
      for (final orderId in orderIds) {
        fullOrders[orderId] =
            _enrichedOrders?[orderId] ??
            await ref.read(labOrderByIdProvider(orderId).future);
      }

      final patient = widget.group.patient;
      if (patient == null) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('Patient information is missing.')),
        );
        return;
      }

      final entries = <({LabOrder order, LabOrderItem item})>[];
      for (final order in fullOrders.values) {
        for (final item in order.items) {
          if (_selectedItemIds.contains(item.id) &&
              labOrderItemHasPrintableResults(item)) {
            entries.add((order: order, item: item));
          }
        }
      }

      if (entries.isEmpty) {
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('No printable results in the current selection.'),
          ),
        );
        return;
      }

      await Printing.layoutPdf(
        onLayout: (format) async {
          final bytes = await buildLabPatientItemsPdf(
            patient: patient,
            entries: entries,
            format: format,
          );
          return Uint8List.fromList(bytes);
        },
      );
    } catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final group = widget.group;
    final printableCount = _printableItems.length;
    final allPrintableSelected =
        printableCount > 0 &&
        _printableItems.every((item) => _selectedItemIds.contains(item.id));
    final wait = LabClinicalUi.waitSince(group.latestCreatedAt);
    final waitLabel = wait == null ? '—' : LabClinicalUi.formatWait(wait);
    final waitColor = wait == null
        ? cs.onSurfaceVariant
        : LabClinicalUi.waitColor(wait);
    final avatarColor = LabClinicalUi.avatarColor(
      group.patient?.id ?? group.patientKey,
    );

    final identity = Row(
      children: [
        PatientAvatar(
          avatarUrl: group.patient?.avatarUrl,
          firstName: group.patient?.firstName,
          surname: group.patient?.surname,
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
                text: group.displayName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              HeltyEllipsisText(
                text: group.patient?.patientId?.trim().isNotEmpty == true
                    ? group.patient!.patientId!
                    : group.patient?.id ?? '—',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final actions = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            onPressed: () => widget.onOrderTap(group.orders.first),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: const StadiumBorder(),
            ),
            child: const Text('View'),
          ),
          PopupMenuButton<String>(
            tooltip: 'More actions',
            icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
            onSelected: (value) {
              switch (value) {
                case 'expand':
                  _onExpansionChanged(!_expanded);
                case 'print':
                  _printSelected();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'expand',
                child: Text(_expanded ? 'Hide tests' : 'Show tests'),
              ),
              PopupMenuItem(
                value: 'print',
                enabled: _hasPrintableSelection && !_printing,
                child: const Text('Print selected tests'),
              ),
            ],
          ),
        ],
      ),
    );

    final details = _expanded
        ? Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_loadingResults)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (_loadError != null)
                  Row(
                    children: [
                      const HeltySolidIcon(
                        icon: Icons.error_outline_rounded,
                        color: Color(0xFFDC2626),
                        size: 22,
                        iconSize: 12,
                        radius: 6,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: HeltyEllipsisText(
                          text: 'Unable to load results. $_loadError',
                          maxLines: 2,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.error,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadOrderResults,
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                else ...[
                  if (printableCount > 0)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: allPrintableSelected,
                      tristate: true,
                      onChanged: (value) {
                        if (value == null) {
                          _toggleSelectAllPrintable(false);
                        } else {
                          _toggleSelectAllPrintable(value);
                        }
                      },
                      title: Text(
                        'Select all printable tests',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ..._displayOrders.map(
                    (order) => _OrderItemsSection(
                      order: order,
                      selectedItemIds: _selectedItemIds,
                      onItemToggle: _toggleItem,
                      onOrderTap: () => widget.onOrderTap(order),
                    ),
                  ),
                ],
              ],
            ),
          )
        : const SizedBox.shrink();

    if (widget.asCard) {
      return HeltySurfaceCard(
        margin: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => _onExpansionChanged(!_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.indexLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: identity),
                        Text(
                          waitLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: waitColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        HeltyStatusChip(
                          label: group.wardDisplayLabel,
                          color: LabClinicalUi.iconBlue,
                        ),
                        HeltyStatusChip(
                          label: LabClinicalUi.statusLabel(group.latestStatus),
                          color: LabClinicalUi.statusColor(group.latestStatus),
                        ),
                        HeltyStatusChip(
                          label:
                              '${group.orders.length} order${group.orders.length == 1 ? '' : 's'}',
                          color: LabClinicalUi.iconTeal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerRight, child: actions),
                  ],
                ),
              ),
            ),
            details,
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => _onExpansionChanged(!_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: HeltyEllipsisText(
                    text: widget.indexLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(flex: 5, child: identity),
                const SizedBox(width: 20),
                Expanded(
                  flex: 3,
                  child: HeltyEllipsisChip(
                    label: group.wardDisplayLabel,
                    color: LabClinicalUi.iconBlue,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: HeltyEllipsisText(
                    text: '${group.orders.length} / ${group.totalTests} tests',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: HeltyEllipsisText(
                    text: waitLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: waitColor,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: HeltyEllipsisChip(
                    label: LabClinicalUi.statusLabel(group.latestStatus),
                    color: LabClinicalUi.statusColor(group.latestStatus),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(flex: 3, child: actions),
              ],
            ),
          ),
        ),
        details,
      ],
    );
  }
}

class _OrderItemsSection extends StatelessWidget {
  const _OrderItemsSection({
    required this.order,
    required this.selectedItemIds,
    required this.onItemToggle,
    required this.onOrderTap,
  });

  final LabOrder order;
  final Set<String> selectedItemIds;
  final void Function(LabOrderItem item, bool? selected) onItemToggle;
  final VoidCallback onOrderTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = LabClinicalUi.statusColor(order.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.35,
            ),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onOrderTap,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HeltyEllipsisText(
                            text:
                                'Order #${order.id.length >= 8 ? order.id.substring(0, 8) : order.id}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          HeltyEllipsisText(
                            text: LabClinicalUi.statusLabel(order.status),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          ...order.items.map((item) {
            final printable = labOrderItemHasPrintableResults(item);
            final testName = item.testVersion?.test?.name ?? 'Test';
            return CheckboxListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 8, right: 8),
              value: selectedItemIds.contains(item.id),
              onChanged: printable ? (v) => onItemToggle(item, v) : null,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                testName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: printable
                      ? null
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                ),
              ),
              subtitle: printable
                  ? null
                  : Text(
                      'No results to print',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
            );
          }),
        ],
      ),
    );
  }
}
