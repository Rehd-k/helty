import 'package:helty/src/helper/app_timezone.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/helper/quill_content_helper.dart';
import 'package:helty/src/models/admission_model.dart';
import 'package:helty/src/models/admission_alert_model.dart';
import 'package:helty/src/models/care_plan_model.dart';
import 'package:helty/src/models/intake_output_record_model.dart';
import 'package:helty/src/models/iv_fluid_order_model.dart';
import 'package:helty/src/models/medication_administration_model.dart';
import 'package:helty/src/models/monitoring_chart_model.dart';
import 'package:helty/src/models/nursing_note_model.dart';
import 'package:helty/src/models/patient_vitals_model.dart';
import 'package:helty/src/models/procedure_record_model.dart';
import 'package:helty/src/models/wound_assessment_model.dart';
import 'package:helty/src/services/admission_alert_service.dart';
import 'package:helty/src/services/admission_service.dart';
import 'package:helty/src/services/care_plan_service.dart';
import 'package:helty/src/services/intake_output_service.dart';
import 'package:helty/src/services/iv_fluid_order_service.dart';
import 'package:helty/src/services/medication_administration_service.dart';
import 'package:helty/src/services/monitoring_chart_service.dart';
import 'package:helty/src/services/nursing_note_service.dart';
import 'package:helty/src/services/procedure_record_service.dart';
import 'package:helty/src/services/wound_assessment_service.dart';

/// Aggregates today's nursing entries for shift handover (AI-ready payload).
class HandoverSummaryBuilder {
  HandoverSummaryBuilder({
    NursingNoteService? nursingNoteService,
    AdmissionService? admissionService,
    MedicationAdministrationService? medicationAdministrationService,
    IntakeOutputService? intakeOutputService,
    IvFluidOrderService? ivFluidOrderService,
    MonitoringChartService? monitoringChartService,
    WoundAssessmentService? woundAssessmentService,
    ProcedureRecordService? procedureRecordService,
    CarePlanService? carePlanService,
    AdmissionAlertService? admissionAlertService,
  })  : _nursingNoteService = nursingNoteService ?? NursingNoteService(),
        _admissionService = admissionService ?? AdmissionService(),
        _medicationAdministrationService =
            medicationAdministrationService ?? MedicationAdministrationService(),
        _intakeOutputService = intakeOutputService ?? IntakeOutputService(),
        _ivFluidOrderService = ivFluidOrderService ?? IvFluidOrderService(),
        _monitoringChartService =
            monitoringChartService ?? MonitoringChartService(),
        _woundAssessmentService =
            woundAssessmentService ?? WoundAssessmentService(),
        _procedureRecordService =
            procedureRecordService ?? ProcedureRecordService(),
        _carePlanService = carePlanService ?? CarePlanService(),
        _admissionAlertService =
            admissionAlertService ?? AdmissionAlertService();

  final NursingNoteService _nursingNoteService;
  final AdmissionService _admissionService;
  final MedicationAdministrationService _medicationAdministrationService;
  final IntakeOutputService _intakeOutputService;
  final IvFluidOrderService _ivFluidOrderService;
  final MonitoringChartService _monitoringChartService;
  final WoundAssessmentService _woundAssessmentService;
  final ProcedureRecordService _procedureRecordService;
  final CarePlanService _carePlanService;
  final AdmissionAlertService _admissionAlertService;

  bool _isToday(DateTime? instant) {
    if (instant == null) return false;
    return AppTimezone.isToday(instant);
  }

  DateTime? _bestTimestamp({
    DateTime? primary,
    DateTime? fallback,
  }) =>
      primary ?? fallback;

  Future<String> buildTodaySummary({
    required String admissionId,
    required String shiftType,
  }) async {
    final results = await Future.wait([
      _nursingNoteService.list(admissionId),
      _admissionService.getOneById(admissionId),
      _medicationAdministrationService.listByAdmission(admissionId),
      _intakeOutputService.list(admissionId),
      _ivFluidOrderService.list(admissionId),
      _monitoringChartService.list(admissionId),
      _woundAssessmentService.list(admissionId),
      _procedureRecordService.list(admissionId),
      _carePlanService.list(admissionId),
      _admissionAlertService.list(admissionId),
    ]);

    final notes = results[0] as List<NursingNoteModel>;
    final admission = results[1] as AdmissionModel;
    final marRows = results[2] as List<MedicationAdministrationModel>;
    final ioRecords = results[3] as List<IntakeOutputRecordModel>;
    final ivOrders = results[4] as List<IvFluidOrderModel>;
    final monitoringCharts = results[5] as List<MonitoringChartModel>;
    final woundAssessments = results[6] as List<WoundAssessmentModel>;
    final procedures = results[7] as List<ProcedureRecordModel>;
    final carePlans = results[8] as List<CarePlanModel>;
    final alerts = results[9] as List<AdmissionAlertModel>;

    final today = DateFormatter.shortDate(AppTimezone.now());
    final buf = StringBuffer();
    buf.writeln('Shift handover summary — $today ($shiftType)');
    buf.writeln('Generated from nursing entries recorded today.');
    buf.writeln();

    _writeVitalsSection(buf, admission.patientVitals);
    _writeNursingReportsSection(buf, notes);
    _writeMarSection(buf, marRows);
    _writeIoSection(buf, ioRecords);
    _writeIvSection(buf, ivOrders);
    _writeMonitoringSection(buf, monitoringCharts);
    _writeWoundSection(buf, woundAssessments);
    _writeProceduresSection(buf, procedures);
    _writeCarePlanSection(buf, carePlans);
    _writeAlertsSection(buf, alerts);

    final text = buf.toString().trim();
    if (!text.contains('--- ')) {
      return '$text\n\nNo nursing entries recorded today for this patient.';
    }
    return text;
  }

  void _writeSection(StringBuffer buf, String title, List<String> lines) {
    if (lines.isEmpty) return;
    buf.writeln('--- $title ---');
    for (final line in lines) {
      buf.writeln(line);
    }
    buf.writeln();
  }

  void _writeVitalsSection(StringBuffer buf, List<PatientVitalsModel> vitals) {
    final todayVitals = vitals.where((v) => _isToday(v.createdAt)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final lines = todayVitals.map((v) {
      final parts = <String>[
        DateFormatter.dateTime(v.createdAt),
        'Temp ${v.temperature?.toString() ?? "—"} °C',
        'BP ${v.systolic ?? "—"}/${v.diastolic ?? "—"}',
        'HR ${v.pulseRate?.toString() ?? "—"}',
        'RR ${v.respRate?.toString() ?? "—"}',
        'SpO₂ ${v.spo2?.toString() ?? "—"}%',
        if (v.painScore != null && v.painScore!.isNotEmpty)
          'Pain ${v.painScore}',
        if (v.bloodGlucose != null) 'Glucose ${v.bloodGlucose}',
        if (v.recordedBy != null && v.recordedBy!.isNotEmpty)
          'by ${v.recordedBy}',
      ];
      if (v.notes != null && v.notes!.trim().isNotEmpty) {
        parts.add('Notes: ${v.notes!.trim()}');
      }
      return parts.join(' · ');
    }).toList();

    _writeSection(buf, 'Vitals', lines);
  }

  void _writeNursingReportsSection(
    StringBuffer buf,
    List<NursingNoteModel> notes,
  ) {
    final todayNotes = notes
        .where((n) => _isToday(n.createdAt))
        .toList()
      ..sort((a, b) {
        final ta = a.createdAt;
        final tb = b.createdAt;
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });

    final lines = todayNotes.map((n) {
      final header = [
        if (n.createdAt != null) DateFormatter.dateTime(n.createdAt!),
        if (n.authorName != null && n.authorName!.isNotEmpty) n.authorName,
        n.noteType ?? 'GENERAL',
      ].where((s) => s != null && s.isNotEmpty).join(' · ');

      final body = plainTextFromStoredContent(n.content);
      if (body.isEmpty) return '[$header]\n(empty)';
      return '[$header]\n$body';
    }).toList();

    _writeSection(buf, 'Nursing reports', lines);
  }

  void _writeMarSection(
    StringBuffer buf,
    List<MedicationAdministrationModel> rows,
  ) {
    final todayRows = rows.where((r) {
      final t = _bestTimestamp(primary: r.actualTime, fallback: r.scheduledTime);
      return _isToday(t);
    }).toList();

    final lines = todayRows.map((r) {
      final when = _bestTimestamp(
        primary: r.actualTime,
        fallback: r.scheduledTime,
      );
      final parts = <String>[
        if (when != null) DateFormatter.dateTime(when),
        r.drugName ?? 'Medication',
        if (r.dose != null && r.dose!.isNotEmpty) r.dose!,
        if (r.route != null && r.route!.isNotEmpty) r.route!,
        r.status,
        if (r.quantity != null) 'qty ${r.quantity}',
        if (r.reasonIfNotGiven != null && r.reasonIfNotGiven!.isNotEmpty)
          'reason: ${r.reasonIfNotGiven}',
        if (r.nurseDisplayName != null && r.nurseDisplayName!.isNotEmpty)
          'by ${r.nurseDisplayName}',
      ];
      return parts.join(' · ');
    }).toList();

    _writeSection(buf, 'Medications (MAR)', lines);
  }

  void _writeIoSection(
    StringBuffer buf,
    List<IntakeOutputRecordModel> records,
  ) {
    final todayRecords = records.where((r) {
      final t = _bestTimestamp(primary: r.recordedAt, fallback: r.createdAt);
      return _isToday(t);
    }).toList();

    var intakeMl = 0.0;
    var outputMl = 0.0;
    final lines = <String>[];

    for (final r in todayRecords) {
      final type = (r.type ?? '').toUpperCase();
      final ml = r.amountMl ?? 0;
      if (type == 'INTAKE') intakeMl += ml;
      if (type == 'OUTPUT') outputMl += ml;

      final when = _bestTimestamp(primary: r.recordedAt, fallback: r.createdAt);
      final parts = <String>[
        if (when != null) DateFormatter.dateTime(when),
        type,
        r.category ?? '',
        '${ml.toStringAsFixed(0)} mL',
        if (r.notes != null && r.notes!.trim().isNotEmpty) r.notes!.trim(),
        if (r.nurseDisplayName != null && r.nurseDisplayName!.isNotEmpty)
          'by ${r.nurseDisplayName}',
      ].where((s) => s.isNotEmpty);
      lines.add(parts.join(' · '));
    }

    if (lines.isNotEmpty) {
      lines.insert(
        0,
        'Daily totals — Intake: ${intakeMl.toStringAsFixed(0)} mL, '
        'Output: ${outputMl.toStringAsFixed(0)} mL, '
        'Balance: ${(intakeMl - outputMl).toStringAsFixed(0)} mL',
      );
    }

    _writeSection(buf, 'Intake & Output', lines);
  }

  void _writeIvSection(StringBuffer buf, List<IvFluidOrderModel> orders) {
    final todayOrders = orders.where((o) {
      return _isToday(o.startTime);
    }).toList();

    final lines = todayOrders.map((o) {
      final parts = <String>[
        if (o.startTime != null) DateFormatter.dateTime(o.startTime!),
        o.fluidType ?? 'IV fluid',
        if (o.volume != null && o.volume!.isNotEmpty) '${o.volume} mL',
        if (o.rate != null && o.rate!.isNotEmpty) 'rate ${o.rate}',
        if (o.status != null && o.status!.isNotEmpty) o.status!,
        if (o.recorderDisplayName != null && o.recorderDisplayName!.isNotEmpty)
          'by ${o.recorderDisplayName}',
      ];
      return parts.where((s) => s.isNotEmpty).join(' · ');
    }).toList();

    _writeSection(buf, 'IV fluids', lines);
  }

  void _writeMonitoringSection(
    StringBuffer buf,
    List<MonitoringChartModel> charts,
  ) {
    final todayCharts = charts.where((c) {
      final t = _bestTimestamp(primary: c.updatedAt, fallback: c.createdAt);
      return _isToday(t);
    }).toList();

    final lines = todayCharts.map((c) {
      final when = _bestTimestamp(primary: c.updatedAt, fallback: c.createdAt);
      final valueText = c.value?.entries
              .map((e) => '${e.key}: ${e.value}')
              .join(', ') ??
          '';
      final parts = <String>[
        if (when != null) DateFormatter.dateTime(when),
        c.chartType ?? 'Chart',
        if (valueText.isNotEmpty) valueText,
        if (c.recorderDisplayName != null && c.recorderDisplayName!.isNotEmpty)
          'by ${c.recorderDisplayName}',
      ];
      return parts.where((s) => s.isNotEmpty).join(' · ');
    }).toList();

    _writeSection(buf, 'Monitoring', lines);
  }

  void _writeWoundSection(
    StringBuffer buf,
    List<WoundAssessmentModel> assessments,
  ) {
    final todayAssessments = assessments
        .where((w) => _isToday(w.recordedAt))
        .toList();

    final lines = todayAssessments.map((w) {
      final parts = <String>[
        if (w.recordedAt != null) DateFormatter.dateTime(w.recordedAt!),
        if (w.woundLocation != null && w.woundLocation!.isNotEmpty)
          w.woundLocation!,
        if (w.woundStage != null && w.woundStage!.isNotEmpty)
          'stage ${w.woundStage}',
        if (w.woundSize != null && w.woundSize!.isNotEmpty) w.woundSize!,
        if (w.exudate != null && w.exudate!.isNotEmpty) 'exudate ${w.exudate}',
        if (w.infectionSigns != null && w.infectionSigns!.isNotEmpty)
          'infection: ${w.infectionSigns}',
        if (w.nurseDisplayName != null && w.nurseDisplayName!.isNotEmpty)
          'by ${w.nurseDisplayName}',
      ];
      return parts.where((s) => s.isNotEmpty).join(' · ');
    }).toList();

    _writeSection(buf, 'Wound assessments', lines);
  }

  void _writeProceduresSection(
    StringBuffer buf,
    List<ProcedureRecordModel> procedures,
  ) {
    final todayProcedures = procedures.where((p) {
      final t = _bestTimestamp(primary: p.recordedAt, fallback: p.createdAt);
      return _isToday(t);
    }).toList();

    final lines = todayProcedures.map((p) {
      final when = _bestTimestamp(primary: p.recordedAt, fallback: p.createdAt);
      final parts = <String>[
        if (when != null) DateFormatter.dateTime(when),
        p.procedureType ?? 'Procedure',
        if (p.description != null && p.description!.isNotEmpty) p.description!,
        if (p.outcome != null && p.outcome!.isNotEmpty) 'outcome: ${p.outcome}',
        if (p.complications != null && p.complications!.isNotEmpty)
          'complications: ${p.complications}',
        if (p.nurseDisplayName != null && p.nurseDisplayName!.isNotEmpty)
          'by ${p.nurseDisplayName}',
      ];
      return parts.where((s) => s.isNotEmpty).join(' · ');
    }).toList();

    _writeSection(buf, 'Procedures', lines);
  }

  void _writeCarePlanSection(StringBuffer buf, List<CarePlanModel> plans) {
    final todayPlans = plans.where((p) {
      final t = _bestTimestamp(primary: p.updatedAt, fallback: p.createdAt);
      return _isToday(t);
    }).toList();

    final lines = todayPlans.map((p) {
      final when = _bestTimestamp(primary: p.updatedAt, fallback: p.createdAt);
      final parts = <String>[
        if (when != null) DateFormatter.dateTime(when),
        if (p.problem != null && p.problem!.isNotEmpty) 'Problem: ${p.problem}',
        if (p.goal != null && p.goal!.isNotEmpty) 'Goal: ${p.goal}',
        if (p.interventions != null && p.interventions!.isNotEmpty)
          'Interventions: ${p.interventions}',
        if (p.evaluation != null && p.evaluation!.isNotEmpty)
          'Evaluation: ${p.evaluation}',
        if (p.status != null && p.status!.isNotEmpty) 'Status: ${p.status}',
        if (p.recorderDisplayName != null && p.recorderDisplayName!.isNotEmpty)
          'by ${p.recorderDisplayName}',
      ];
      return parts.where((s) => s.isNotEmpty).join(' · ');
    }).toList();

    _writeSection(buf, 'Care plan', lines);
  }

  void _writeAlertsSection(StringBuffer buf, List<AdmissionAlertModel> alerts) {
    final todayAlerts = alerts.where((a) {
      if (a.isResolved) return false;
      return _isToday(a.createdAt);
    }).toList();

    final lines = todayAlerts.map((a) {
      final parts = <String>[
        if (a.createdAt != null) DateFormatter.dateTime(a.createdAt!),
        if (a.severity != null && a.severity!.isNotEmpty) a.severity!,
        a.title ?? 'Alert',
        if (a.message != null && a.message!.isNotEmpty) a.message!,
      ];
      return parts.where((s) => s.isNotEmpty).join(' · ');
    }).toList();

    _writeSection(buf, 'Active alerts', lines);
  }
}
