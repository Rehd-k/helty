import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/app_timezone.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/medications/rx_schedule_utils.dart';
import 'package:helty/src/models/medication_administration_model.dart';
import 'package:helty/src/models/medication_dose_schedule_model.dart';
import 'package:helty/src/models/medication_order_model.dart';
import 'package:helty/src/models/medication_request_model.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_chart_table.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_layout_constants.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_metrics.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_responsive_row_or_column.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/widgets/helty_surface.dart';
import 'package:helty/src/pharmacy/models/pharmacy_model.dart';
import 'package:helty/src/pharmacy/services/pharmacy_service.dart';
import 'package:helty/src/services/medication_administration_service.dart';
import 'package:helty/src/services/medication_dose_schedule_service.dart';
import 'package:helty/src/services/medication_order_service.dart';
import 'package:helty/src/models/staff_attribution.dart';
import 'package:helty/src/pharmacy/utils/medication_request_permissions.dart';
import 'package:helty/src/pharmacy/widgets/medication_attribution_widgets.dart';
import 'package:helty/src/pharmacy/widgets/medication_workflow_badges.dart';
import 'package:helty/src/services/medication_request_service.dart';

@RoutePage()
class InpatientMedicationsScreen extends StatefulWidget {
  const InpatientMedicationsScreen({super.key});

  @override
  State<InpatientMedicationsScreen> createState() =>
      _InpatientMedicationsScreenState();
}

class _InpatientMedicationsScreenState
    extends State<InpatientMedicationsScreen> {
  final _medicationOrderService = MedicationOrderService();
  final _medicationAdministrationService = MedicationAdministrationService();
  final _medicationRequestService = MedicationRequestService();
  final _doseScheduleService = MedicationDoseScheduleService();

  List<MedicationOrderModel> _orders = [];
  List<MedicationAdministrationModel> _administrations = [];
  Map<String, MedicationDoseScheduleModel> _schedulesByOrderId = {};
  bool _loadingMar = true;

  /// Drug group keys the user has collapsed in MAR history (default: expanded).
  final Set<String> _collapsedHistoryDrugKeys = {};

  /// When true, MAR history is grouped by drug; when false, flat chronological.
  bool _historyGroupedByDrug = true;

  /// Orders with expanded medication-request history panels.
  final Set<String> _expandedRequestHistoryOrderIds = {};

  /// Expired/stopped orders section (collapsed by default).
  bool _inactiveOrdersSectionExpanded = false;

  /// Tracks scope changes so we refetch when [encounterId] appears after load.
  String? _loadKey;

  static String _formatOrderSummaryLine(MedicationOrderModel o) {
    final parts = <String>[o.drugName.trim()];
    if (o.dose != null && o.dose!.trim().isNotEmpty) parts.add(o.dose!.trim());
    if (o.route != null && o.route!.trim().isNotEmpty) {
      parts.add(o.route!.trim());
    }
    if (o.frequency != null && o.frequency!.trim().isNotEmpty) {
      parts.add(o.frequency!.trim());
    }
    return 'Drug: ${parts.join(' ')}';
  }

  static String _mapAdminStatusToApi(String ui) {
    switch (ui) {
      case 'Missed':
        return 'MISSED';
      case 'Refused':
        return 'REFUSED';
      case 'Given':
      default:
        return 'GIVEN';
    }
  }

  static String _dioErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return e.message ?? 'Request failed';
  }

  static String _formatHistoryTime(MedicationAdministrationModel a) {
    final t = a.sortTime;
    if (t == null) return '—';
    return '${DateFormatter.timeOnly(t)} · ${DateFormatter.shortDate(t)}';
  }

  static String _formatAdministeredQuantity(double? quantity) {
    if (quantity == null) return '—';
    final s = quantity.toStringAsFixed(3);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static String _formatDispensary(MedicationAdministrationModel a) {
    final name = a.pharmacyLocationName?.trim();
    if (name == null || name.isEmpty) return '—';
    final stock = a.stockDeductedQuantity;
    if (stock != null && stock > 0) return '$name (−$stock)';
    return name;
  }

  static String _drugGroupKey(MedicationAdministrationModel a) {
    final name = (a.drugName ?? '').trim().toLowerCase();
    if (name.isEmpty) return '__unknown__:${a.id}';
    return name;
  }

  static String _statusLabel(String status) {
    final s = status.trim().toUpperCase();
    switch (s) {
      case 'GIVEN':
        return 'Given';
      case 'MISSED':
        return 'Missed';
      case 'REFUSED':
        return 'Refused';
      default:
        return status.trim().isEmpty ? '—' : status;
    }
  }

  static Color _statusColor(BuildContext context, String status) {
    switch (status.trim().toUpperCase()) {
      case 'GIVEN':
        return InpatientMetrics.waitGreen;
      case 'MISSED':
        return InpatientMetrics.waitRed;
      case 'REFUSED':
        return InpatientMetrics.waitAmber;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  /// Groups administrations by drug; each group sorted newest-first.
  List<({String key, List<MedicationAdministrationModel> items})>
  _groupAdministrationsByDrug() {
    final map = <String, List<MedicationAdministrationModel>>{};
    for (final a in _administrations) {
      map.putIfAbsent(_drugGroupKey(a), () => []).add(a);
    }
    final groups =
        map.entries
            .map(
              (e) => (
                key: e.key,
                items: List<MedicationAdministrationModel>.from(e.value),
              ),
            )
            .toList()
          ..sort((a, b) {
            final ta = a.items.first.sortTime;
            final tb = b.items.first.sortTime;
            if (ta == null && tb == null) return 0;
            if (ta == null) return 1;
            if (tb == null) return -1;
            return tb.compareTo(ta);
          });
    return groups;
  }

  static String _formatDrugSubtitle(MedicationAdministrationModel a) {
    final parts = <String>[];
    if (a.dose != null && a.dose!.trim().isNotEmpty) parts.add(a.dose!.trim());
    if (a.route != null && a.route!.trim().isNotEmpty) {
      parts.add(a.route!.trim());
    }
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  String _groupStatusSummary(List<MedicationAdministrationModel> items) {
    var given = 0;
    var missed = 0;
    var refused = 0;
    for (final a in items) {
      switch (a.status.trim().toUpperCase()) {
        case 'GIVEN':
          given++;
        case 'MISSED':
          missed++;
        case 'REFUSED':
          refused++;
      }
    }
    final parts = <String>[];
    if (given > 0) parts.add('$given given');
    if (missed > 0) parts.add('$missed missed');
    if (refused > 0) parts.add('$refused refused');
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  /// Parses quantity for GIVEN administrations (max 3 decimal places).
  static double? _parseAdministeredQuantity(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    final value = double.tryParse(t);
    if (value == null || value <= 0) return null;
    final parts = t.split('.');
    if (parts.length == 2 && parts[1].length > 3) return null;
    return value;
  }

  MedicationDoseScheduleModel? _scheduleForOrder(MedicationOrderModel order) {
    if (order.doseSchedule != null) return order.doseSchedule;
    return _schedulesByOrderId[order.id];
  }

  MedicationDoseScheduleModel _effectiveSchedule(
    MedicationOrderModel order,
  ) {
    final fromApi = _scheduleForOrder(order);
    if (fromApi != null) return fromApi;
    return _computeClientSchedule(order);
  }

  MedicationDoseScheduleModel _computeClientSchedule(
    MedicationOrderModel order,
  ) {
    final givenForOrder = _administrations
        .where((a) => a.status.trim().toUpperCase() == 'GIVEN')
        .where((a) => (a.drugName ?? '').trim() == order.drugName.trim())
        .toList()
      ..sort((a, b) {
        final ta = a.actualTime ?? a.scheduledTime;
        final tb = b.actualTime ?? b.scheduledTime;
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return ta.compareTo(tb);
      });

    final stopped =
        order.administrationStatus == MedicationAdministrationStatus.stopped;
    if (givenForOrder.isEmpty) {
      return MedicationDoseScheduleModel(
        scheduleStatus: stopped
            ? MedicationScheduleStatus.stopped
            : MedicationScheduleStatus.notStarted,
      );
    }

    final first = givenForOrder.first;
    final last = givenForOrder.last;
    final firstTime = first.actualTime ?? first.scheduledTime ?? AppTimezone.now();
    final lastTime = last.actualTime ?? last.scheduledTime ?? firstTime;
    final parsed = parseRxDurationPhrase(order.duration ?? '');
    final applied = applyGivenDoseToSchedule(
      actualTime: lastTime,
      frequencyRaw: order.frequency ?? '',
      durationPhrase: order.duration,
      durationValue: parsed?.value,
      durationUnit: parsed?.unit,
      existingScheduleStartedAt: firstTime,
      existingDoseSequenceNumber: givenForOrder.length - 1,
      administrationStopped: stopped,
      now: AppTimezone.now(),
    );
    return MedicationDoseScheduleModel(
      scheduleStartedAt: applied.scheduleStartedAt,
      courseEndsAt: applied.courseEndsAt,
      nextDueAt: applied.nextDueAt,
      lastAdministeredAt: lastTime,
      doseSequenceNumber: applied.doseSequenceNumber,
      scheduleStatus: applied.scheduleStatus,
      durationValue: parsed?.value,
      durationUnit: parsed?.unit,
    );
  }

  bool _isInactiveOrder(MedicationOrderModel order) {
    if (order.administrationStatus == MedicationAdministrationStatus.stopped) {
      return true;
    }
    final status = _effectiveSchedule(order).scheduleStatus;
    return status == MedicationScheduleStatus.expired ||
        status == MedicationScheduleStatus.stopped;
  }

  List<MedicationOrderModel> get _dueOrders {
    final due = <MedicationOrderModel>[];
    for (final order in _orders) {
      if (order.administrationStatus != MedicationAdministrationStatus.active) {
        continue;
      }
      final schedule = _effectiveSchedule(order);
      if (schedule.scheduleStatus.isDueAttention) {
        due.add(order);
      }
    }
    due.sort((a, b) {
      final sa = _effectiveSchedule(a).nextDueAt;
      final sb = _effectiveSchedule(b).nextDueAt;
      if (sa == null && sb == null) return 0;
      if (sa == null) return 1;
      if (sb == null) return -1;
      return sa.compareTo(sb);
    });
    return due;
  }

  int get _activeOrderCount =>
      _orders.where((o) => !_isInactiveOrder(o)).length;

  int _adminCountToday(String status) {
    final n = DateTime.now();
    var count = 0;
    for (final a in _administrations) {
      if (a.status.trim().toUpperCase() != status) continue;
      final t = a.sortTime;
      if (t == null) continue;
      if (t.year == n.year && t.month == n.month && t.day == n.day) {
        count++;
      }
    }
    return count;
  }

  int get _pendingRequestCount {
    var n = 0;
    for (final o in _orders) {
      for (final r in o.medicationRequests) {
        if (r.status == MedicationRequestStatus.requested) n++;
      }
    }
    return n;
  }

  static String _formatScheduleLine(MedicationDoseScheduleModel schedule) {
    final now = AppTimezone.now();
    switch (schedule.scheduleStatus) {
      case MedicationScheduleStatus.notStarted:
        return 'Schedule starts when first dose is given';
      case MedicationScheduleStatus.expired:
        final end = schedule.courseEndsAt;
        return end != null
            ? 'Course expired ${DateFormatter.shortDate(end)}'
            : 'Course expired — doctor consent required';
      case MedicationScheduleStatus.dueSoon:
      case MedicationScheduleStatus.overdue:
        final due = schedule.nextDueAt;
        if (due == null) return schedule.scheduleStatus.label;
        if (now.isAfter(due)) {
          final diff = now.difference(due);
          if (diff.inHours >= 1) {
            return 'Overdue by ${diff.inHours}h ${diff.inMinutes % 60}m';
          }
          return 'Overdue by ${diff.inMinutes}m';
        }
        return 'Next due ${DateFormatter.timeOnly(due)}';
      case MedicationScheduleStatus.active:
      case MedicationScheduleStatus.stopped:
        final due = schedule.nextDueAt;
        if (due != null) {
          return 'Next due ${DateFormatter.timeOnly(due)} · ${DateFormatter.shortDate(due)}';
        }
        final end = schedule.courseEndsAt;
        if (end != null) {
          return 'Course ends ${DateFormatter.shortDate(end)}';
        }
        return schedule.scheduleStatus.label;
    }
  }

  static Color? _scheduleAccentColor(
    BuildContext context,
    MedicationScheduleStatus status,
  ) {
    return switch (status) {
      MedicationScheduleStatus.expired => InpatientMetrics.waitRed,
      MedicationScheduleStatus.overdue => InpatientMetrics.waitRed,
      MedicationScheduleStatus.dueSoon => InpatientMetrics.waitAmber,
      _ => null,
    };
  }

  Future<void> _loadMarData() async {
    if (!mounted) return;
    final scope = InpatientViewScope.of(context);
    final encounterId = scope?.encounterId;
    final admissionId = scope?.admissionId;
    final embedded = List<MedicationOrderModel>.from(
      scope?.embeddedMedicationOrders ?? const [],
    );

    setState(() => _loadingMar = true);
    try {
      List<MedicationOrderModel> orders;
      if (encounterId == null || encounterId.isEmpty) {
        orders = embedded;
      } else {
        final list = await _medicationOrderService.getByEncounter(encounterId);
        orders = list.isNotEmpty ? list : embedded;
      }

      var admins = <MedicationAdministrationModel>[];
      if (admissionId != null && admissionId.isNotEmpty) {
        try {
          admins = await _medicationAdministrationService.listByAdmission(
            admissionId,
          );
        } catch (_) {
          admins = [];
        }
      }

      var schedules = <String, MedicationDoseScheduleModel>{};
      if (admissionId != null && admissionId.isNotEmpty) {
        try {
          final items = await _doseScheduleService.listByAdmission(admissionId);
          for (final item in items) {
            if (item.doseSchedule != null) {
              schedules[item.medicationOrderId] = item.doseSchedule!;
            }
          }
        } catch (_) {
          schedules = {};
        }
      }

      admins.sort((a, b) {
        final ta = a.sortTime;
        final tb = b.sortTime;
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });

      if (!mounted) return;
      setState(() {
        _orders = orders;
        _administrations = admins;
        _schedulesByOrderId = schedules;
        _loadingMar = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _orders = embedded;
        _administrations = [];
        _schedulesByOrderId = {};
        _loadingMar = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = InpatientViewScope.of(context);
    final encId = scope?.encounterId;
    final admId = scope?.admissionId;
    final embedded = scope?.embeddedMedicationOrders ?? const [];
    final embSig = embedded.isEmpty
        ? '0'
        : '${embedded.length}:${embedded.first.id}';
    final loadKey = '${encId ?? ''}|${admId ?? ''}|$embSig';
    if (loadKey != _loadKey) {
      _loadKey = loadKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadMarData();
      });
    }
    if (scope == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('Inpatient context not available')),
      );
    }

    final isDoctor = scope.isDoctor;
    final due = _dueOrders;

    return ResponsiveBody(
      expand: false,
      builder: (context, bp) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InpatientTabToolbar(
              icon: Icons.medication_outlined,
              iconColor: InpatientMetrics.iconTeal,
              title: 'Medications',
              subtitle: 'Orders, pharmacy requests, and MAR history',
              actions: [
                if (isDoctor)
                  FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'To add prescriptions, open the doctor encounter view for this patient.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add medication'),
                    style: inpatientCompactFill(),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _MedicationsKpiStrip(
              loading: _loadingMar,
              due: due.length,
              active: _activeOrderCount,
              givenToday: _adminCountToday('GIVEN'),
              pendingRequests: _pendingRequestCount,
            ),
            if (!isDoctor && due.isNotEmpty) ...[
              const SizedBox(height: 10),
              SectionCard(
                title: 'Due now',
                subtitle: 'Medications due soon or overdue',
                icon: Icons.schedule,
                iconColor: InpatientMetrics.waitAmber,
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                child: _buildDueNowList(context, scope),
              ),
            ],
            const SizedBox(height: 10),
            InpatientResponsiveRowOrColumn(
              gap: 12,
              first: SectionCard(
                title: 'Active orders',
                subtitle: 'Standing and PRN orders for this stay',
                icon: Icons.vaccines_outlined,
                iconColor: InpatientMetrics.iconBlue,
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                child: _buildActiveOrdersTable(context, scope),
              ),
              second: SectionCard(
                title: 'Administration history',
                subtitle: _historyGroupedByDrug
                    ? 'Grouped by drug — newest first'
                    : 'Chronological — newest first',
                icon: Icons.history,
                iconColor: InpatientMetrics.iconIndigo,
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                actions: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(
                        () => _historyGroupedByDrug = !_historyGroupedByDrug,
                      );
                    },
                    icon: Icon(
                      _historyGroupedByDrug
                          ? Icons.view_list
                          : Icons.category_outlined,
                      size: 16,
                    ),
                    label: Text(
                      _historyGroupedByDrug
                          ? 'Show chronologically'
                          : 'Group by drug',
                    ),
                    style: inpatientCompactOutline(),
                  ),
                ],
                child: _buildHistoryTable(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueNowList(BuildContext context, InpatientViewScope scope) {
    final theme = Theme.of(context);
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _dueOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final order = _dueOrders[index];
        final schedule = _effectiveSchedule(order);
        final overdue =
            schedule.scheduleStatus == MedicationScheduleStatus.overdue;
        final accent = _scheduleAccentColor(context, schedule.scheduleStatus) ??
            InpatientMetrics.waitAmber;
        return HeltySurfaceCard(
          onTap: () => _openAdministerDialog(
            context,
            scope,
            order,
            prefilledDueAt: schedule.nextDueAt,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              HeltySolidIcon(
                icon: overdue
                    ? Icons.warning_amber_rounded
                    : Icons.schedule,
                color: accent,
                size: 28,
                iconSize: 15,
                radius: 7,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeltyEllipsisText(
                      text: order.drugName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    HeltyEllipsisText(
                      text: _formatScheduleLine(schedule),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: OutlinedButton(
                  onPressed: () => _openAdministerDialog(
                    context,
                    scope,
                    order,
                    prefilledDueAt: schedule.nextDueAt,
                  ),
                  style: inpatientCompactOutline(),
                  child: const Text('Give'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildOrderCard(
    BuildContext context,
    InpatientViewScope scope,
    MedicationOrderModel order,
  ) {
    return _ActiveOrderCard(
      order: order,
      doseSchedule: _effectiveSchedule(order),
      scope: scope,
      currentNurseId: scope.staffId?.trim() ?? '',
      expanded: _expandedRequestHistoryOrderIds.contains(order.id),
      onToggleHistory: () {
        setState(() {
          if (_expandedRequestHistoryOrderIds.contains(order.id)) {
            _expandedRequestHistoryOrderIds.remove(order.id);
          } else {
            _expandedRequestHistoryOrderIds.add(order.id);
          }
        });
      },
      onRequest: () => _openRequestDialog(context, scope, order),
      onAdminister: () => _openAdministerDialog(
        context,
        scope,
        order,
        prefilledDueAt: _effectiveSchedule(order).nextDueAt,
      ),
      onCancelRequest: (requestId) => _cancelMedicationRequest(
        context,
        requestId,
        requireNurseIdFromScope(context) ?? '',
      ),
    );
  }

  Widget _buildInactiveOrdersSection(
    BuildContext context,
    InpatientViewScope scope,
    List<MedicationOrderModel> inactiveOrders,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.45,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: InkWell(
            onTap: () => setState(
              () => _inactiveOrdersSectionExpanded =
                  !_inactiveOrdersSectionExpanded,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  HeltySolidIcon(
                    icon: Icons.event_busy_outlined,
                    color: InpatientMetrics.waitRed,
                    size: 26,
                    iconSize: 14,
                    radius: 7,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: HeltyEllipsisText(
                      text:
                          'Expired & discontinued (${inactiveOrders.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    _inactiveOrdersSectionExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_inactiveOrdersSectionExpanded) ...[
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: inactiveOrders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _buildOrderCard(context, scope, inactiveOrders[index]),
          ),
        ],
      ],
    );
  }

  Widget _buildActiveOrdersTable(
    BuildContext context,
    InpatientViewScope scope,
  ) {
    if (_loadingMar) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_orders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No active medication orders for this admission.'),
      );
    }

    final activeOrders =
        _orders.where((o) => !_isInactiveOrder(o)).toList(growable: false);
    final inactiveOrders =
        _orders.where(_isInactiveOrder).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (activeOrders.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No active medication orders for this admission.'),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activeOrders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _buildOrderCard(context, scope, activeOrders[index]),
          ),
        if (inactiveOrders.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInactiveOrdersSection(context, scope, inactiveOrders),
        ],
      ],
    );
  }

  Future<void> _openRequestDialog(
    BuildContext context,
    InpatientViewScope scope,
    MedicationOrderModel order,
  ) async {
    final nurseId = requireNurseIdFromScope(context);
    if (nurseId == null) return;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _RequestMedicationDialog(
        order: order,
        requestService: _medicationRequestService,
        nurseId: nurseId,
      ),
    );

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medication request submitted to pharmacy')),
      );
      setState(() => _expandedRequestHistoryOrderIds.add(order.id));
      await _loadMarData();
    }
  }

  Future<void> _cancelMedicationRequest(
    BuildContext context,
    String requestId,
    String nurseId,
  ) async {
    if (nurseId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel request?'),
        content: const Text(
          'This will remove the pending pharmacy request before billing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await _medicationRequestService.cancel(
        id: requestId,
        cancelledByStaffId: nurseId,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medication request cancelled')),
      );
      await _loadMarData();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget _buildHistoryTable(BuildContext context) {
    if (_loadingMar) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_administrations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No medication administrations recorded yet.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (!_historyGroupedByDrug) {
      return InpatientChartTable(
        columns: _kHistoryChartColumns,
        rowCount: _administrations.length,
        minWidth: 980,
        emptyMessage: 'No medication administrations recorded yet.',
        footerLabel: _administrations.length == 1
            ? '1 administration'
            : '${_administrations.length} administrations',
        cellBuilder: (context, index) =>
            _historyCells(context, _administrations[index]),
      );
    }

    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w800,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth < 980 ? 980.0 : constraints.maxWidth;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HistoryTableHeader(
                      columns: const [
                        'TIME',
                        'DRUG',
                        'DOSE',
                        'ROUTE',
                        'QTY',
                        'DISPENSARY',
                        'STATUS',
                        'NURSE',
                        'REASON',
                      ],
                      style: headerStyle,
                    ),
                    ..._groupAdministrationsByDrug().expand((group) {
                      if (group.items.length == 1) {
                        return [
                          _HistoryAdministrationRow(
                            administration: group.items.first,
                            headerStyle: headerStyle,
                          ),
                        ];
                      }
                      return [
                        _HistoryDrugGroupSection(
                          groupKey: group.key,
                          items: group.items,
                          expanded:
                              !_collapsedHistoryDrugKeys.contains(group.key),
                          headerStyle: headerStyle,
                          formatTime: _formatHistoryTime,
                          formatQty: _formatAdministeredQuantity,
                          formatDrugSubtitle: _formatDrugSubtitle,
                          statusSummary: _groupStatusSummary(group.items),
                          statusLabel: _statusLabel,
                          statusColor: _statusColor,
                          onToggle: () {
                            setState(() {
                              if (_collapsedHistoryDrugKeys.contains(
                                group.key,
                              )) {
                                _collapsedHistoryDrugKeys.remove(group.key);
                              } else {
                                _collapsedHistoryDrugKeys.add(group.key);
                              }
                            });
                          },
                        ),
                      ];
                    }),
                  ],
                ),
              ),
            );
          },
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.12),
              ),
            ),
          ),
          child: Text(
            _administrations.length == 1
                ? '1 administration'
                : '${_administrations.length} administrations',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _historyCells(
    BuildContext context,
    MedicationAdministrationModel a,
  ) {
    final reason = a.reasonIfNotGiven?.trim();
    return [
      HeltyEllipsisText(text: _formatHistoryTime(a)),
      HeltyEllipsisText(text: a.drugName ?? '—'),
      HeltyEllipsisText(
        text: a.dose == null || a.dose!.trim().isEmpty ? '—' : a.dose!,
      ),
      HeltyEllipsisText(
        text: a.route == null || a.route!.trim().isEmpty ? '—' : a.route!,
      ),
      HeltyEllipsisText(text: _formatAdministeredQuantity(a.quantity)),
      HeltyEllipsisText(text: _formatDispensary(a)),
      HeltyStatusChip(
        label: _statusLabel(a.status),
        color: _statusColor(context, a.status),
      ),
      HeltyEllipsisText(text: a.nurseDisplayName ?? '—'),
      HeltyEllipsisText(text: (reason == null || reason.isEmpty) ? '—' : reason),
    ];
  }

  Future<void> _openAdministerDialog(
    BuildContext context,
    InpatientViewScope scope,
    MedicationOrderModel order, {
    DateTime? prefilledDueAt,
  }) async {
    final schedule = _effectiveSchedule(order);
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _AdministerMedicationDialog(
        scope: scope,
        order: order,
        doseSchedule: schedule,
        prefilledDueAt: prefilledDueAt ?? schedule.nextDueAt,
        administrationService: _medicationAdministrationService,
      ),
    );

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Medication administration saved and billed to inpatient account.',
          ),
        ),
      );
      await _loadMarData();
    }
  }
}

class _AdministerMedicationDialog extends StatefulWidget {
  const _AdministerMedicationDialog({
    required this.scope,
    required this.order,
    required this.doseSchedule,
    required this.administrationService,
    this.prefilledDueAt,
  });

  final InpatientViewScope scope;
  final MedicationOrderModel order;
  final MedicationDoseScheduleModel doseSchedule;
  final DateTime? prefilledDueAt;
  final MedicationAdministrationService administrationService;

  @override
  State<_AdministerMedicationDialog> createState() =>
      _AdministerMedicationDialogState();
}

class _AdministerMedicationDialogState
    extends State<_AdministerMedicationDialog> {
  final _pharmacyApi = PharmacyApiService();

  String _status = 'Given';
  bool _saving = false;
  bool _loadingDispensaries = false;
  String? _dispensaryLoadError;
  String? _selectedDispensaryId;
  List<PharmacyLocation> _dispensaryLocations = [];

  late final TextEditingController _timeCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _reasonCtrl;
  late final TextEditingController _signatureCtrl;

  @override
  void initState() {
    super.initState();
    final order = widget.order;
    final schedule = widget.doseSchedule;
    final defaultTime = schedule.isNotStarted
        ? AppTimezone.now()
        : (widget.prefilledDueAt ?? schedule.nextDueAt ?? AppTimezone.now());
    _timeCtrl = TextEditingController(
      text: DateFormatter.timeOnly(defaultTime),
    );
    _quantityCtrl = TextEditingController(
      text: order.quantity != null && order.quantity! > 0
          ? order.quantity.toString()
          : '',
    );
    _reasonCtrl = TextEditingController();
    _signatureCtrl = TextEditingController();
    _loadDispensaryLocations();
  }

  Future<void> _loadDispensaryLocations() async {
    setState(() {
      _loadingDispensaries = true;
      _dispensaryLoadError = null;
    });
    try {
      final page = await _pharmacyApi.getPharmacyLocations(
        const PharmacyQueryParams(
          pageSize: 100,
          filters: {'locationType': 'DISPENSARY'},
        ),
      );
      if (!mounted) return;
      final dispensaries = page.items
          .where(
            (l) =>
                l.type == PharmacyLocationType.DISPENSARY &&
                l.isActive &&
                l.id != null &&
                l.id!.isNotEmpty,
          )
          .toList();
      setState(() {
        _dispensaryLocations = dispensaries;
        if (_selectedDispensaryId != null &&
            !dispensaries.any((l) => l.id == _selectedDispensaryId)) {
          _selectedDispensaryId = null;
        }
        _loadingDispensaries = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dispensaryLocations = [];
        _selectedDispensaryId = null;
        _loadingDispensaries = false;
        _dispensaryLoadError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _timeCtrl.dispose();
    _quantityCtrl.dispose();
    _reasonCtrl.dispose();
    _signatureCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final admissionId = widget.scope.admissionId;
    if (admissionId == null || admissionId.isEmpty) {
      _showMessage('Admission is not available for MAR save.');
      return;
    }

    final apiStatus = _InpatientMedicationsScreenState._mapAdminStatusToApi(
      _status,
    );
    final parsedTime = AppTimezone.parseTimeOnDate(
      _timeCtrl.text,
      AppTimezone.now(),
    );
    if (parsedTime == null) {
      _showMessage('Enter a valid time (e.g. 2:30 PM).');
      return;
    }
    final scheduled = parsedTime;
    final actualTime = apiStatus == 'GIVEN' ? parsedTime : null;

    double? administeredQuantity;
    if (apiStatus == 'GIVEN') {
      administeredQuantity =
          _InpatientMedicationsScreenState._parseAdministeredQuantity(
            _quantityCtrl.text,
          );
      if (administeredQuantity == null) {
        _showMessage(
          'Enter a valid quantity administered (greater than 0, '
          'up to 3 decimal places).',
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      await _createAdministration(
        admissionId: admissionId,
        apiStatus: apiStatus,
        scheduled: scheduled,
        actualTime: actualTime,
        administeredQuantity: administeredQuantity,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on MedicationCourseDurationExpiredException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      await _handleCourseExpired(
        admissionId: admissionId,
        apiStatus: apiStatus,
        scheduled: scheduled,
        actualTime: actualTime,
        administeredQuantity: administeredQuantity,
        error: e,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(_InpatientMedicationsScreenState._dioErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Save failed: $e');
    }
  }

  Future<void> _createAdministration({
    required String admissionId,
    required String apiStatus,
    required DateTime scheduled,
    DateTime? actualTime,
    double? administeredQuantity,
    bool acknowledgeBeyondDuration = false,
  }) {
    return widget.administrationService
        .create(
          admissionId: admissionId,
          medicationOrderId: widget.order.id,
          scheduledTime: scheduled,
          actualTime: actualTime,
          status: apiStatus,
          quantity: administeredQuantity,
          reasonIfNotGiven: _status != 'Given' ? _reasonCtrl.text : null,
          pharmacyLocationId: _selectedDispensaryId,
          acknowledgeBeyondDuration: acknowledgeBeyondDuration,
        )
        .then((_) {});
  }

  Future<void> _handleCourseExpired({
    required String admissionId,
    required String apiStatus,
    required DateTime scheduled,
    DateTime? actualTime,
    double? administeredQuantity,
    required MedicationCourseDurationExpiredException error,
  }) async {
    final hasConsent = widget.doseSchedule.hasBeyondDurationConsent;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Course duration ended'),
        content: Text(
          hasConsent
              ? '${error.message}\n\nDoctor consent is on file. Proceed with administration?'
              : '${error.message}\n\nAsk the prescribing doctor to extend the duration or authorize administration before continuing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          if (hasConsent)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Proceed'),
            ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await _createAdministration(
        admissionId: admissionId,
        apiStatus: apiStatus,
        scheduled: scheduled,
        actualTime: actualTime,
        administeredQuantity: administeredQuantity,
        acknowledgeBeyondDuration: true,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Save failed: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final order = widget.order;
    final patientName = widget.scope.patientDisplayName ?? '—';
    final hospNo = widget.scope.hospitalNumber ?? '—';
    final orderLine = _InpatientMedicationsScreenState._formatOrderSummaryLine(
      order,
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Administer Medication'),
      content: SizedBox(
        width: inpatientDialogBodyWidth(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Confirm patient and order',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text('Patient: $patientName â€¢ Hosp No: $hospNo\n$orderLine'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (widget.doseSchedule.scheduleStatus ==
                MedicationScheduleStatus.expired)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.error),
                ),
                child: Text(
                  widget.doseSchedule.hasBeyondDurationConsent
                      ? 'Course expired — doctor consent on file'
                      : 'Course expired — obtain doctor consent before giving',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (!widget.doseSchedule.isNotStarted &&
                widget.doseSchedule.nextDueAt != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Next scheduled dose: '
                  '${DateFormatter.timeOnly(widget.doseSchedule.nextDueAt!)} '
                  '(${_InpatientMedicationsScreenState._formatScheduleLine(widget.doseSchedule)})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else if (widget.doseSchedule.isNotStarted)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Recording the first dose starts the administration schedule.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (_loadingDispensaries)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              )
            else if (_dispensaryLoadError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Could not load dispensaries. You can still save without '
                  'selecting one.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                ),
              )
            else
              DropdownButtonFormField<String?>(
                initialValue: _selectedDispensaryId,
                decoration: const InputDecoration(
                  labelText: 'Pharmacy dispensary',
                  helperText:
                      'Optional — deduct stock from selected dispensary when '
                      'status is Given',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None (no stock deduction)'),
                  ),
                  ..._dispensaryLocations.map(
                    (l) => DropdownMenuItem<String?>(
                      value: l.id,
                      child: Text(l.name),
                    ),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (val) => setState(() => _selectedDispensaryId = val),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _timeCtrl,
              enabled: !_saving,
              decoration: InputDecoration(
                labelText: widget.doseSchedule.isNotStarted
                    ? 'First dose time'
                    : 'Actual administration time',
                hintText: 'e.g. 2:30 PM',
                helperText: widget.doseSchedule.isNotStarted
                    ? 'This anchors the dose schedule for this order'
                    : 'Enter time as hh:mm AM or PM',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'Given', child: Text('Given')),
                DropdownMenuItem(value: 'Missed', child: Text('Missed')),
                DropdownMenuItem(value: 'Refused', child: Text('Refused')),
              ],
              onChanged: _saving
                  ? null
                  : (val) {
                      if (val != null) setState(() => _status = val);
                    },
            ),
            const SizedBox(height: 12),
            if (_status == 'Given')
              TextFormField(
                controller: _quantityCtrl,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                decoration: InputDecoration(
                  labelText: 'Quantity administered *',
                  hintText: order.quantity != null
                      ? 'e.g. ${order.quantity}'
                      : 'e.g. 1 or 2.5',
                  helperText:
                      'Required when status is Given (up to 3 decimals)',
                ),
              )
            else
              TextFormField(
                controller: _reasonCtrl,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Reason (if not given)',
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _signatureCtrl,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Digital signature / PIN',
              ),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

const List<InpatientChartColumn> _kHistoryChartColumns = [
  InpatientChartColumn('TIME', flex: 2),
  InpatientChartColumn('DRUG', flex: 3),
  InpatientChartColumn('DOSE'),
  InpatientChartColumn('ROUTE'),
  InpatientChartColumn('QTY'),
  InpatientChartColumn('DISPENSARY', flex: 3),
  InpatientChartColumn('STATUS'),
  InpatientChartColumn('NURSE', flex: 2),
  InpatientChartColumn('REASON', flex: 2),
];

const List<int> _kHistoryColumnFlex = [2, 3, 2, 2, 2, 2, 2, 2, 3];
const double _kHistoryColGap = 20;

class _HistoryTableHeader extends StatelessWidget {
  const _HistoryTableHeader({required this.columns, this.style});

  final List<String> columns;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      child: Row(
        children: [
          for (var i = 0; i < columns.length; i++) ...[
            if (i > 0) const SizedBox(width: _kHistoryColGap),
            Expanded(
              flex: _kHistoryColumnFlex[i],
              child: HeltyEllipsisText(text: columns[i], style: style),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryAdministrationRow extends StatelessWidget {
  const _HistoryAdministrationRow({
    required this.administration,
    this.headerStyle,
    this.highlight = false,
  });

  final MedicationAdministrationModel administration;
  final TextStyle? headerStyle;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = administration;
    final statusColor = _InpatientMedicationsScreenState._statusColor(
      context,
      a.status,
    );

    return Container(
      color: highlight
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: _kHistoryColumnFlex[0],
            child: Text(_InpatientMedicationsScreenState._formatHistoryTime(a)),
          ),
          Expanded(
            flex: _kHistoryColumnFlex[1],
            child: Text(a.drugName ?? '—', style: headerStyle),
          ),
          Expanded(flex: _kHistoryColumnFlex[2], child: Text(a.dose ?? '')),
          Expanded(flex: _kHistoryColumnFlex[3], child: Text(a.route ?? '')),
          Expanded(
            flex: _kHistoryColumnFlex[4],
            child: Text(
              _InpatientMedicationsScreenState._formatAdministeredQuantity(
                a.quantity,
              ),
            ),
          ),
          Expanded(
            flex: _kHistoryColumnFlex[5],
            child: Text(
              _InpatientMedicationsScreenState._formatDispensary(a),
            ),
          ),
          Expanded(
            flex: _kHistoryColumnFlex[6],
            child: Text(
              _InpatientMedicationsScreenState._statusLabel(a.status),
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: _kHistoryColumnFlex[7],
            child: Text(a.nurseDisplayName ?? '—'),
          ),
          Expanded(
            flex: _kHistoryColumnFlex[8],
            child: Text(a.reasonIfNotGiven ?? ''),
          ),
        ],
      ),
    );
  }
}

class _HistoryDrugGroupSection extends StatelessWidget {
  const _HistoryDrugGroupSection({
    required this.groupKey,
    required this.items,
    required this.expanded,
    required this.onToggle,
    required this.formatTime,
    required this.formatQty,
    required this.formatDrugSubtitle,
    required this.statusSummary,
    required this.statusLabel,
    required this.statusColor,
    required this.headerStyle,
  });

  final String groupKey;
  final List<MedicationAdministrationModel> items;
  final bool expanded;
  final VoidCallback onToggle;
  final String Function(MedicationAdministrationModel) formatTime;
  final String Function(double?) formatQty;
  final String Function(MedicationAdministrationModel) formatDrugSubtitle;
  final String statusSummary;
  final String Function(String) statusLabel;
  final Color? Function(BuildContext, String) statusColor;
  final TextStyle? headerStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final latest = items.first;
    final drugName = latest.drugName ?? '—';
    final latestStatusColor = statusColor(context, latest.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: scheme.primaryContainer.withValues(alpha: 0.18),
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 22,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: _kHistoryColumnFlex[0],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatTime(latest),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!expanded && items.length > 1)
                          Text(
                            '+${items.length - 1} earlier',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: _kHistoryColumnFlex[1],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drugName,
                          style: headerStyle?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${items.length} administrations · $statusSummary',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: _kHistoryColumnFlex[2],
                    child: Text(formatDrugSubtitle(latest)),
                  ),
                  Expanded(
                    flex: _kHistoryColumnFlex[3],
                    child: Text(latest.route ?? ''),
                  ),
                  Expanded(
                    flex: _kHistoryColumnFlex[4],
                    child: Text(expanded ? '—' : formatQty(latest.quantity)),
                  ),
                  Expanded(
                    flex: _kHistoryColumnFlex[5],
                    child: Text(
                      expanded
                          ? '—'
                          : _InpatientMedicationsScreenState._formatDispensary(
                              latest,
                            ),
                    ),
                  ),
                  Expanded(
                    flex: _kHistoryColumnFlex[6],
                    child: Text(
                      expanded ? statusSummary : statusLabel(latest.status),
                      style: !expanded
                          ? TextStyle(
                              color: latestStatusColor,
                              fontWeight: FontWeight.w600,
                            )
                          : theme.textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    flex: _kHistoryColumnFlex[7],
                    child: Text(
                      expanded ? '—' : (latest.nurseDisplayName ?? '—'),
                    ),
                  ),
                  Expanded(
                    flex: _kHistoryColumnFlex[8],
                    child: Text(
                      expanded
                          ? 'Tap to collapse'
                          : (latest.reasonIfNotGiven ?? ''),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: expanded
                            ? scheme.onSurfaceVariant
                            : null,
                        fontStyle: expanded ? FontStyle.italic : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded)
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: scheme.primary.withValues(alpha: 0.35),
                  width: 3,
                ),
              ),
            ),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 12),
                  _HistoryAdministrationRow(
                    administration: items[i],
                    highlight: i.isOdd,
                  ),
                ],
              ],
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({
    required this.order,
    required this.doseSchedule,
    required this.scope,
    required this.currentNurseId,
    required this.expanded,
    required this.onToggleHistory,
    required this.onRequest,
    required this.onAdminister,
    required this.onCancelRequest,
  });

  final MedicationOrderModel order;
  final MedicationDoseScheduleModel doseSchedule;
  final InpatientViewScope scope;
  final String currentNurseId;
  final bool expanded;
  final VoidCallback onToggleHistory;
  final VoidCallback onRequest;
  final VoidCallback onAdminister;
  final ValueChanged<String> onCancelRequest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAdminister =
        order.administrationStatus == MedicationAdministrationStatus.active;
    final canRequest = canNurseRequestMedication(
      order: order,
      isOutpatient: scope.isOutpatient,
      isNurse: scope.isNurse,
      isAdmissionActive: scope.isAdmissionActive,
    );
    final requestDisableReason = canRequest
        ? null
        : nurseMedicationRequestDisableReason(
            order: order,
            isOutpatient: scope.isOutpatient,
            isNurse: scope.isNurse,
            isAdmissionActive: scope.isAdmissionActive,
            admissionStatus: scope.admissionStatus,
          );
    final requestCount = order.medicationRequests.length;
    final scheduleAccent =
        _InpatientMedicationsScreenState._scheduleAccentColor(
      context,
      doseSchedule.scheduleStatus,
    );
    final isExpired =
        doseSchedule.scheduleStatus == MedicationScheduleStatus.expired;

    return HeltySurfaceCard(
      padding: const EdgeInsets.all(10),
      color: isExpired
          ? InpatientMetrics.waitRed.withValues(alpha: 0.06)
          : scheduleAccent?.withValues(alpha: 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              HeltySolidIcon(
                icon: Icons.medication_outlined,
                color: isExpired
                    ? InpatientMetrics.waitRed
                    : (scheduleAccent ?? InpatientMetrics.iconTeal),
                size: 26,
                iconSize: 14,
                radius: 7,
              ),
              HeltyEllipsisText(
                text: order.wasSubstituted
                    ? order.currentDrugLabel
                    : order.drugName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              MedicationOrderStatusBadge(status: order.status),
              HeltyStatusChip(
                label: order.administrationStatus.label,
                color: isExpired
                    ? InpatientMetrics.waitRed
                    : InpatientMetrics.iconBlue,
              ),
              if (doseSchedule.scheduleStatus !=
                  MedicationScheduleStatus.notStarted)
                HeltyStatusChip(
                  label: doseSchedule.scheduleStatus.label,
                  color: scheduleAccent ?? InpatientMetrics.iconIndigo,
                ),
            ],
          ),
            if (order.wasSubstituted) ...[
              const SizedBox(height: 6),
              MedicationSubstitutionSummary(
                prescribedDrug: order.prescribedDrugLabel,
                currentDrug: order.currentDrugLabel,
                compact: true,
              ),
            ],
            if (order.doctor != null &&
                order.doctor!.displayName.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Prescribing doctor: ${order.doctor!.displayName}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 6),
            Text(
              [
                if (order.dose != null && order.dose!.isNotEmpty) order.dose,
                if (order.route != null && order.route!.isNotEmpty) order.route,
                if (order.frequency != null && order.frequency!.isNotEmpty)
                  order.frequency,
                if (order.duration != null && order.duration!.isNotEmpty)
                  order.duration,
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              _InpatientMedicationsScreenState._formatScheduleLine(doseSchedule),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheduleAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                if (scope.isNurse && !scope.isOutpatient) ...[
                  if (requestDisableReason != null)
                    Tooltip(
                      message: requestDisableReason,
                      child: FilledButton.tonal(
                        onPressed: null,
                        style: inpatientCompactFill(),
                        child: const Text('Request'),
                      ),
                    )
                  else
                    FilledButton.tonal(
                      onPressed: onRequest,
                      style: inpatientCompactFill(),
                      child: const Text('Request'),
                    ),
                  if (canAdminister)
                    OutlinedButton(
                      onPressed: onAdminister,
                      style: inpatientCompactOutline(),
                      child: const Text('Administer'),
                    ),
                ],
                if (requestCount > 0 || expanded)
                  TextButton.icon(
                    onPressed: onToggleHistory,
                    style: inpatientCompactOutline(),
                    icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                    label: Text(
                      requestCount > 0
                          ? 'Requests ($requestCount)'
                          : 'Request history',
                    ),
                  ),
              ],
            ),
            if (expanded) ...[
              const Divider(height: 20),
              if (order.medicationRequests.isEmpty)
                Text(
                  'No pharmacy requests yet.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ...order.medicationRequests.map((req) {
                  final when = req.createdAt;
                  final canCancel = req.canCancelAsNurse(currentNurseId);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      'Qty ${req.requestedQuantity} · ${req.status.label}',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MedicationRequestAttribution(
                          request: req,
                          compact: true,
                        ),
                        if (when != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(DateFormatter.dateTime(when)),
                          ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MedicationRequestStatusBadge(status: req.status),
                        if (canCancel &&
                            scope.isNurse &&
                            !scope.isOutpatient) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Cancel request',
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => onCancelRequest(req.id),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
            ],
          ],
        ),
    );
  }
}

class _RequestMedicationDialog extends StatefulWidget {
  const _RequestMedicationDialog({
    required this.order,
    required this.requestService,
    required this.nurseId,
  });

  final MedicationOrderModel order;
  final MedicationRequestService requestService;
  final String nurseId;

  @override
  State<_RequestMedicationDialog> createState() =>
      _RequestMedicationDialogState();
}

class _RequestMedicationDialogState extends State<_RequestMedicationDialog> {
  final _qtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qty = int.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= 0) {
      setState(() => _error = 'Enter a positive whole number for quantity.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.requestService.create(
        medicationOrderId: widget.order.id,
        requestedQuantity: qty,
        requestedByNurseId: widget.nurseId,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request medication'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.order.drugName,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Requested quantity *',
                hintText: 'Billing / dispense units',
                border: OutlineInputBorder(),
              ),
              enabled: !_saving,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              enabled: !_saving,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit request'),
        ),
      ],
    );
  }
}

class _MedicationsKpiStrip extends StatelessWidget {
  const _MedicationsKpiStrip({
    required this.loading,
    required this.due,
    required this.active,
    required this.givenToday,
    required this.pendingRequests,
  });

  final bool loading;
  final int due;
  final int active;
  final int givenToday;
  final int pendingRequests;

  String _v(int n) => loading ? '—' : '$n';

  @override
  Widget build(BuildContext context) {
    final items = [
      InpatientKpiTile(
        icon: Icons.schedule,
        color: InpatientMetrics.waitAmber,
        label: 'Due now',
        value: _v(due),
        caption: 'Due soon or overdue',
      ),
      InpatientKpiTile(
        icon: Icons.vaccines_outlined,
        color: InpatientMetrics.iconBlue,
        label: 'Active',
        value: _v(active),
        caption: 'Standing / PRN orders',
      ),
      InpatientKpiTile(
        icon: Icons.check_circle_outline,
        color: InpatientMetrics.waitGreen,
        label: 'Given today',
        value: _v(givenToday),
        caption: 'Administrations today',
      ),
      InpatientKpiTile(
        icon: Icons.local_pharmacy_outlined,
        color: InpatientMetrics.iconPurple,
        label: 'Pending',
        value: _v(pendingRequests),
        caption: 'Pharmacy requests',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 820) {
          return Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: items[i]),
              ],
            ],
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 72,
          ),
          itemBuilder: (context, i) => items[i],
        );
      },
    );
  }
}
