import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/admissions/widgets/admission_ward_location_section.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/admission_alert_model.dart';
import 'package:helty/src/models/admission_model.dart';
import 'package:helty/src/models/care_plan_model.dart';
import 'package:helty/src/models/intake_output_record_model.dart';
import 'package:helty/src/models/iv_fluid_order_model.dart';
import 'package:helty/src/models/patient_vitals_model.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_responsive_row_or_column.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/services/admission_alert_service.dart';
import 'package:helty/src/services/admission_service.dart';
import 'package:helty/src/services/care_plan_service.dart';
import 'package:helty/src/services/intake_output_service.dart';
import 'package:helty/src/services/iv_fluid_order_service.dart';

@RoutePage()
class InpatientOverviewScreen extends StatefulWidget {
  const InpatientOverviewScreen({super.key});

  @override
  State<InpatientOverviewScreen> createState() =>
      _InpatientOverviewScreenState();
}

class _InpatientOverviewScreenState extends State<InpatientOverviewScreen> {
  final _admissionService = AdmissionService();
  final _ioService = IntakeOutputService();
  final _alertService = AdmissionAlertService();
  final _ivService = IvFluidOrderService();
  final _carePlanService = CarePlanService();

  AdmissionModel? _admission;
  List<IntakeOutputRecordModel> _io = [];
  int _unresolvedAlerts = 0;
  List<IvFluidOrderModel> _ivOrders = [];
  int _carePlanCount = 0;
  bool _loading = true;
  String? _error;
  String? _lastAdmissionId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = InpatientViewScope.of(context)?.admissionId;
    if (id == null || id.isEmpty) {
      if (_lastAdmissionId != null) {
        setState(() {
          _admission = null;
          _loading = false;
          _error = null;
          _lastAdmissionId = null;
        });
      }
      return;
    }
    if (id != _lastAdmissionId) {
      _lastAdmissionId = id;
      _load(id);
    }
  }

  bool _isToday(DateTime? t) {
    if (t == null) return false;
    final n = DateTime.now();
    return t.year == n.year && t.month == n.month && t.day == n.day;
  }

  double _ioTodaySum(String type) {
    final up = type.toUpperCase();
    var sum = 0.0;
    for (final r in _io) {
      if ((r.type ?? '').toUpperCase() != up) continue;
      final t = r.recordedAt ?? r.createdAt;
      if (!_isToday(t)) continue;
      sum += r.amountMl ?? 0;
    }
    return sum;
  }

  Future<void> _load(String admissionId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final admission = await _admissionService.getOneById(admissionId);
      final results = await Future.wait([
        _ioService
            .list(admissionId)
            .catchError((_) => <IntakeOutputRecordModel>[]),
        _alertService
            .list(admissionId, unresolvedOnly: true)
            .catchError((_) => <AdmissionAlertModel>[]),
        _ivService
            .list(admissionId)
            .catchError((_) => <IvFluidOrderModel>[]),
        _carePlanService
            .list(admissionId)
            .catchError((_) => <CarePlanModel>[]),
      ]);

      if (!mounted) return;
      setState(() {
        _admission = admission;
        _io = results[0] as List<IntakeOutputRecordModel>;
        _unresolvedAlerts = (results[1] as List).length;
        _ivOrders = results[2] as List<IvFluidOrderModel>;
        _carePlanCount = (results[3] as List).length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _admission = null;
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _vitalsSummary(PatientVitalsModel? v) {
    if (v == null) {
      return 'No vitals recorded yet. Use the Vitals tab to add observations.';
    }
    return '${DateFormatter.dateTime(v.createdAt)} · '
        'Temp ${v.temperature?.toString() ?? "—"} °C · '
        'BP ${v.systolic ?? "—"}/${v.diastolic ?? "—"} · '
        'HR ${v.pulseRate?.toString() ?? "—"} · '
        'SpO₂ ${v.spo2?.toString() ?? "—"}%';
  }

  PatientVitalsModel? _latestVitals() {
    final list = _admission?.patientVitals ?? [];
    if (list.isEmpty) return null;
    final sorted = List<PatientVitalsModel>.from(list)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.first;
  }

  int _activeIvCount() {
    return _ivOrders
        .where(
          (o) => (o.status ?? 'ACTIVE').toUpperCase() == 'ACTIVE',
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scope = InpatientViewScope.of(context);
    final admissionId = scope?.admissionId;

    if (admissionId == null || admissionId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('Open this patient with an admission to see overview.'),
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(
              onPressed: () => _load(admissionId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final adm = _admission;
    final orders = adm?.encounterMedicationOrders ?? [];
    final latest = _latestVitals();
    final intakeToday = _ioTodaySum('INTAKE');
    final outputToday = _ioTodaySum('OUTPUT');
    final showWardUpdate =
        scope?.isNurse == true &&
        scope?.isAdmissionActive == true &&
        adm != null;

    return ResponsiveBody(
      expand: false,
      builder: (context, bp) => SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showWardUpdate) ...[
            SectionCard(
              title: 'Ward location',
              subtitle:
                  'Transfer the patient to another ward or bed (e.g. ICU, surgical).',
              child: AdmissionWardLocationSection(
                admission: adm,
                compact: true,
                onLocationUpdated: () => _load(admissionId),
              ),
            ),
            const SizedBox(height: 16),
          ],
          InpatientResponsiveRowOrColumn(
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  title: 'Latest Vitals',
                  subtitle: 'Most recent bedside observations',
                  child: _bodyText(
                    context,
                    _vitalsSummary(latest),
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Active Medications',
                  subtitle: 'Orders on this encounter',
                  child: _bodyText(
                    context,
                    orders.isEmpty
                        ? 'No medication orders loaded for this admission.'
                        : '${orders.length} active order(s). Open the Medications tab for MAR.',
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'IV Running Status',
                  subtitle: 'Active IV fluid orders',
                  child: _bodyText(
                    context,
                    _ivOrders.isEmpty
                        ? 'No IV orders. Use the IV tab when fluids are prescribed.'
                        : '${_activeIvCount()} active line(s) · ${_ivOrders.length} total order(s).',
                  ),
                ),
              ],
            ),
            second: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  title: "Today's Intake / Output",
                  subtitle: 'Fluid balance (local date)',
                  child: _bodyText(
                    context,
                    'Intake: ${intakeToday.toStringAsFixed(0)} ml · '
                    'Output: ${outputToday.toStringAsFixed(0)} ml · '
                    'Net: ${(intakeToday - outputToday).toStringAsFixed(0)} ml',
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Care Plan Summary',
                  subtitle: 'Plans documented for this admission',
                  child: _bodyText(
                    context,
                    _carePlanCount == 0
                        ? 'No care plans yet. Use the Care Plan tab.'
                        : '$_carePlanCount care plan(s). Open the Care Plan tab for details.',
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Alerts',
                  subtitle: 'Unresolved admission alerts',
                  child: _bodyText(
                    context,
                    _unresolvedAlerts == 0
                        ? 'No unresolved alerts.'
                        : '$_unresolvedAlerts unresolved alert(s). Open the Alerts tab.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            showWardUpdate
                ? 'Other overview cards are read-only. Use the corresponding tabs to record or update data.'
                : 'Overview is read-only. Use the corresponding tabs to record or update data.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _bodyText(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.85),
            ),
      ),
    );
  }
}
