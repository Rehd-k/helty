import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/helper/quill_content_helper.dart';
import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/models/admission_model.dart';
import 'package:helty/src/models/intake_output_record_model.dart';
import 'package:helty/src/models/lab_order_model.dart';
import 'package:helty/src/models/medication_administration_model.dart';
import 'package:helty/src/models/medication_order_model.dart';
import 'package:helty/src/models/nursing_note_model.dart';
import 'package:helty/src/models/patient_vitals_model.dart';
import 'package:helty/src/models/procedure_record_model.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_metrics.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_ui_tabs.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';
import 'package:helty/src/radiology/services/radiology_service.dart';
import 'package:helty/src/services/admission_service.dart';
import 'package:helty/src/services/intake_output_service.dart';
import 'package:helty/src/services/lab_order_service.dart';
import 'package:helty/src/services/medication_administration_service.dart';
import 'package:helty/src/services/nursing_note_service.dart';
import 'package:helty/src/services/procedure_record_service.dart';
import 'package:helty/src/widgets/helty_surface.dart';

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
  final _notesService = NursingNoteService();
  final _labService = LabOrderService();
  final _imagingService = RadiologyService();
  final _procedureService = ProcedureRecordService();
  final _marService = MedicationAdministrationService();

  AdmissionModel? _admission;
  List<IntakeOutputRecordModel> _io = [];
  List<NursingNoteModel> _notes = [];
  List<LabOrderModel> _labs = [];
  List<RadiologyOrder> _imaging = [];
  List<ProcedureRecordModel> _procedures = [];
  List<MedicationAdministrationModel> _mar = [];
  bool _labsOk = false;
  bool _imagingOk = false;
  bool _notesOk = false;
  bool _proceduresOk = false;
  bool _marOk = false;
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
      final patientId = admission.patient.id?.trim() ?? '';
      final results = await Future.wait([
        _ioService
            .list(admissionId)
            .then<Object>((v) => v)
            .catchError((_) => <IntakeOutputRecordModel>[]),
        _notesService
            .list(admissionId)
            .then<Object>((v) => v)
            .catchError((_) => false),
        _labService
            .listForScope(patientId: patientId)
            .then<Object>((v) => v)
            .catchError((_) => false),
        patientId.isEmpty
            ? Future<Object>.value(false)
            : _imagingService
                  .listOrders(patientId: patientId, take: 100)
                  .then<Object>((v) => v)
                  .catchError((_) => false),
        _procedureService
            .list(admissionId)
            .then<Object>((v) => v)
            .catchError((_) => false),
        _marService
            .listByAdmission(admissionId)
            .then<Object>((v) => v)
            .catchError((_) => false),
      ]);

      if (!mounted) return;

      final notesRaw = results[1];
      final labsRaw = results[2];
      final imagingRaw = results[3];
      final procRaw = results[4];
      final marRaw = results[5];

      setState(() {
        _admission = admission;
        _io = results[0] as List<IntakeOutputRecordModel>;
        _notesOk = notesRaw is List<NursingNoteModel>;
        _notes = _notesOk ? notesRaw as List<NursingNoteModel> : [];
        _labsOk = labsRaw is List<LabOrderModel>;
        _labs = _labsOk ? labsRaw as List<LabOrderModel> : [];
        _imagingOk = imagingRaw is RadiologyOrdersListResponse;
        _imaging = _imagingOk
            ? (imagingRaw as RadiologyOrdersListResponse).orders
            : [];
        _proceduresOk = procRaw is List<ProcedureRecordModel>;
        _procedures = _proceduresOk
            ? procRaw as List<ProcedureRecordModel>
            : [];
        _marOk = marRaw is List<MedicationAdministrationModel>;
        _mar = _marOk ? marRaw as List<MedicationAdministrationModel> : [];
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

  PatientVitalsModel? _latestVitals() {
    final list = _admission?.patientVitals ?? [];
    if (list.isEmpty) return null;
    final sorted = List<PatientVitalsModel>.from(list)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.first;
  }

  int _dueMedCount() {
    final orders = _admission?.encounterMedicationOrders ?? [];
    var n = 0;
    for (final o in orders) {
      if (o.administrationStatus != MedicationAdministrationStatus.active) {
        continue;
      }
      if (o.doseSchedule?.scheduleStatus.isDueAttention == true) n++;
    }
    return n;
  }

  bool _labPending(String status) {
    final s = status.toUpperCase().replaceAll(' ', '_');
    return s != 'COMPLETED' && s != 'VERIFIED' && s != 'CANCELLED';
  }

  DateTime? _parseDt(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  List<_ActivityItem> _activity() {
    final items = <_ActivityItem>[];
    for (final n in _notes) {
      final at = n.createdAt;
      if (at == null) continue;
      final preview = plainTextFromStoredContent(n.content);
      items.add(
        _ActivityItem(
          at: at,
          text: preview.isEmpty
              ? 'Nursing note added'
              : 'Nursing note added – $preview',
          icon: Icons.note_alt_outlined,
          color: InpatientMetrics.iconPink,
        ),
      );
    }
    for (final a in _mar) {
      final at = a.actualTime ?? a.scheduledTime;
      if (at == null) continue;
      final st = a.status.toUpperCase();
      if (st != 'GIVEN') continue;
      final drug = (a.drugName ?? '').trim();
      final dose = (a.dose ?? '').trim();
      final label = [
        if (drug.isNotEmpty) drug,
        if (dose.isNotEmpty) dose,
      ].join(' ');
      items.add(
        _ActivityItem(
          at: at,
          text: label.isEmpty
              ? 'Medication given'
              : 'Medication given – $label',
          icon: Icons.medication_outlined,
          color: InpatientMetrics.iconTeal,
        ),
      );
    }
    for (final lab in _labs) {
      final at = _parseDt(lab.createdAt);
      if (at == null) continue;
      final pending = _labPending(lab.status);
      items.add(
        _ActivityItem(
          at: at,
          text: pending
              ? 'Lab ordered – ${lab.testType}'
              : 'Lab result available – ${lab.testType}',
          icon: Icons.science_outlined,
          color: InpatientMetrics.iconTeal,
        ),
      );
    }
    for (final img in _imaging) {
      final at = _parseDt(img.createdAt) ?? _parseDt(img.updatedAt);
      if (at == null) continue;
      final done = img.status == RadiologyOrderStatus.COMPLETED;
      final study = img.items.isNotEmpty
          ? (img.items.first.serviceName ??
                img.items.first.rawScanType ??
                'Imaging')
          : 'Imaging';
      items.add(
        _ActivityItem(
          at: at,
          text: done
              ? 'Imaging result available – $study'
              : 'Imaging ordered – $study',
          icon: Icons.photo_outlined,
          color: InpatientMetrics.iconBlue,
        ),
      );
    }
    for (final p in _procedures) {
      final at = p.recordedAt ?? p.createdAt;
      if (at == null) continue;
      final type = (p.procedureType ?? p.description ?? 'Procedure').trim();
      items.add(
        _ActivityItem(
          at: at,
          text: 'Procedure recorded – $type',
          icon: Icons.healing_outlined,
          color: InpatientMetrics.iconPurple,
        ),
      );
    }
    for (final v in _admission?.patientVitals ?? const <PatientVitalsModel>[]) {
      items.add(
        _ActivityItem(
          at: v.effectiveAt,
          text: 'Vitals recorded',
          icon: Icons.monitor_heart_outlined,
          color: InpatientMetrics.waitRed,
        ),
      );
    }
    items.sort((a, b) => b.at.compareTo(a.at));
    if (items.length > 6) return items.sublist(0, 6);
    return items;
  }

  NursingNoteModel? _latestNote() {
    if (_notes.isEmpty) return null;
    final sorted = List<NursingNoteModel>.from(_notes)
      ..sort((a, b) {
        final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
    return sorted.first;
  }

  void _go(int tab) {
    InpatientViewScope.of(context)?.onSelectTab?.call(tab);
  }

  @override
  Widget build(BuildContext context) {
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

    final latest = _latestVitals();
    final intakeToday = _ioTodaySum('INTAKE');
    final outputToday = _ioTodaySum('OUTPUT');
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tabletMin;

    final vitalsCard = _VitalsCard(latest: latest);
    final ioCard = _IoCard(intake: intakeToday, output: outputToday);
    final shortcuts = _ShortcutRow(
      medsCaption: '${_dueMedCount()} due',
      labsCaption: _labsOk
          ? '${_labs.where((l) => _labPending(l.status)).length} pending'
          : '—',
      imagingCaption: _imagingOk
          ? '${_imaging.where((o) => o.status == RadiologyOrderStatus.PENDING || o.status == RadiologyOrderStatus.ACTIVE).length} pending'
          : '—',
      notesCaption: _notesOk ? '${_notes.length} notes' : '—',
      ordersCaption: _proceduresOk ? '${_procedures.length} recorded' : '—',
      onMeds: () => _go(InpatientUiTabs.medications),
      onLabs: () => _go(InpatientUiTabs.labResults),
      onImaging: () => _go(InpatientUiTabs.imaging),
      onNotes: () => _go(InpatientUiTabs.nursingReport),
      onOrders: () => _go(InpatientUiTabs.procedures),
    );
    final notesCard = _ClinicalNotesCard(
      note: _notesOk ? _latestNote() : null,
      available: _notesOk,
      onViewAll: () => _go(InpatientUiTabs.nursingReport),
    );
    final activityCard = _ActivityCard(
      items: _activity(),
      onViewAll: () => _go(InpatientUiTabs.nursingReport),
    );

    return ResponsiveBody(
      expand: false,
      builder: (context, bp) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: vitalsCard),
                  const SizedBox(width: 12),
                  Expanded(child: ioCard),
                ],
              )
            else ...[
              vitalsCard,
              const SizedBox(height: 12),
              ioCard,
            ],
            const SizedBox(height: 12),
            shortcuts,
            const SizedBox(height: 12),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: notesCard),
                  const SizedBox(width: 12),
                  Expanded(child: activityCard),
                ],
              )
            else ...[
              notesCard,
              const SizedBox(height: 12),
              activityCard,
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.at,
    required this.text,
    required this.icon,
    required this.color,
  });

  final DateTime at;
  final String text;
  final IconData icon;
  final Color color;
}

class _VitalsCard extends StatelessWidget {
  const _VitalsCard({required this.latest});

  final PatientVitalsModel? latest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = latest;
    final bp = v == null ? '—' : '${v.systolic ?? "—"}/${v.diastolic ?? "—"}';
    final temp = v?.temperature == null ? '—' : '${v!.temperature}°C';
    final hr = v?.pulseRate == null ? '—' : '${v!.pulseRate}';
    final spo2 = v?.spo2 == null ? '—' : '${v!.spo2}%';
    final when = v == null ? null : DateFormatter.dateTime(v.effectiveAt);

    return HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const HeltySolidIcon(
                icon: Icons.monitor_heart_outlined,
                color: InpatientMetrics.waitRed,
                size: 26,
                iconSize: 14,
                radius: 7,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latest Vitals',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Most recent bedside observations',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _VitalTile(
                  icon: Icons.thermostat_outlined,
                  color: InpatientMetrics.waitRed,
                  value: temp,
                  label: 'Temp',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VitalTile(
                  icon: Icons.speed_outlined,
                  color: InpatientMetrics.iconIndigo,
                  value: bp,
                  label: 'BP',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VitalTile(
                  icon: Icons.favorite_outline,
                  color: InpatientMetrics.iconPink,
                  value: hr,
                  label: 'HR',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VitalTile(
                  icon: Icons.air,
                  color: InpatientMetrics.iconTeal,
                  value: spo2,
                  label: 'SpO₂',
                ),
              ),
            ],
          ),
          if (when != null) ...[
            const SizedBox(height: 8),
            Text(
              when,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VitalTile extends StatelessWidget {
  const _VitalTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          HeltySolidIcon(
            icon: icon,
            color: color,
            size: 26,
            iconSize: 14,
            radius: 7,
          ),
          const SizedBox(height: 6),
          HeltyEllipsisText(
            text: value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _IoCard extends StatelessWidget {
  const _IoCard({required this.intake, required this.output});

  final double intake;
  final double output;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final net = intake - output;
    final total = intake + output;
    final bar = total <= 0 ? 0.0 : (intake / total).clamp(0.0, 1.0);
    final netColor = net < 0
        ? InpatientMetrics.waitRed
        : InpatientMetrics.waitGreen;

    String ml(double v) => '${v.toStringAsFixed(0)} ml';

    return HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const HeltySolidIcon(
                icon: Icons.water_drop_outlined,
                color: InpatientMetrics.iconBlue,
                size: 26,
                iconSize: 14,
                radius: 7,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Intake / Output",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Fluid balance (local date)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _VitalTile(
                  icon: Icons.arrow_downward,
                  color: InpatientMetrics.iconBlue,
                  value: ml(intake),
                  label: 'Intake',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VitalTile(
                  icon: Icons.arrow_upward,
                  color: InpatientMetrics.iconIndigo,
                  value: ml(output),
                  label: 'Output',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VitalTile(
                  icon: Icons.balance_outlined,
                  color: netColor,
                  value: ml(net),
                  label: 'Net',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: bar,
              minHeight: 8,
              backgroundColor: InpatientMetrics.iconIndigo.withValues(
                alpha: 0.2,
              ),
              color: InpatientMetrics.iconBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({
    required this.medsCaption,
    required this.labsCaption,
    required this.imagingCaption,
    required this.notesCaption,
    required this.ordersCaption,
    required this.onMeds,
    required this.onLabs,
    required this.onImaging,
    required this.onNotes,
    required this.onOrders,
  });

  final String medsCaption;
  final String labsCaption;
  final String imagingCaption;
  final String notesCaption;
  final String ordersCaption;
  final VoidCallback onMeds;
  final VoidCallback onLabs;
  final VoidCallback onImaging;
  final VoidCallback onNotes;
  final VoidCallback onOrders;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _ShortcutTile(
        icon: Icons.medication_outlined,
        color: InpatientMetrics.waitAmber,
        title: 'Medications',
        caption: medsCaption,
        onTap: onMeds,
      ),
      _ShortcutTile(
        icon: Icons.science_outlined,
        color: InpatientMetrics.iconTeal,
        title: 'Lab Results',
        caption: labsCaption,
        onTap: onLabs,
      ),
      _ShortcutTile(
        icon: Icons.photo_outlined,
        color: InpatientMetrics.iconBlue,
        title: 'Radiology',
        caption: imagingCaption,
        onTap: onImaging,
      ),
      _ShortcutTile(
        icon: Icons.note_alt_outlined,
        color: InpatientMetrics.iconPink,
        title: 'Nursing Notes',
        caption: notesCaption,
        onTap: onNotes,
      ),
      _ShortcutTile(
        icon: Icons.assignment_outlined,
        color: InpatientMetrics.iconPurple,
        title: 'Orders',
        caption: ordersCaption,
        onTap: onOrders,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in tiles)
                SizedBox(width: (constraints.maxWidth - 8) / 2, child: t),
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: tiles[i]),
            ],
          ],
        );
      },
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HeltySurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeltySolidIcon(
            icon: icon,
            color: color,
            size: 32,
            iconSize: 16,
            radius: 8,
          ),
          const SizedBox(height: 8),
          HeltyEllipsisText(
            text: title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          HeltyEllipsisText(
            text: caption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalNotesCard extends StatelessWidget {
  const _ClinicalNotesCard({
    required this.note,
    required this.available,
    required this.onViewAll,
  });

  final NursingNoteModel? note;
  final bool available;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final n = note;
    final preview = n == null ? '' : plainTextFromStoredContent(n.content);

    return HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const HeltySolidIcon(
                icon: Icons.notes_outlined,
                color: InpatientMetrics.iconIndigo,
                size: 26,
                iconSize: 14,
                radius: 7,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinical Notes',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Latest notes and observations',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!available)
            Text(
              '—',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            )
          else if (n == null)
            Text(
              'No nursing notes yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: HeltyEllipsisText(
                    text: n.authorName?.trim().isNotEmpty == true
                        ? n.authorName!
                        : 'Nursing note',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (n.createdAt != null)
                  Text(
                    DateFormatter.dateTime(n.createdAt!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if ((n.noteType ?? '').trim().isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: HeltyStatusChip(
                  label: n.noteType!,
                  color: InpatientMetrics.iconIndigo,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              preview.isEmpty ? '—' : preview,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onViewAll,
              child: const Text('View all'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.items, required this.onViewAll});

  final List<_ActivityItem> items;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const HeltySolidIcon(
                icon: Icons.history,
                color: InpatientMetrics.iconTeal,
                size: 26,
                iconSize: 14,
                radius: 7,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recent Activity',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(onPressed: onViewAll, child: const Text('View all')),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              'No recent activity.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            )
          else
            for (final item in items) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeltySolidIcon(
                      icon: item.icon,
                      color: item.color,
                      size: 26,
                      iconSize: 14,
                      radius: 7,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HeltyEllipsisText(
                            text: item.text,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            DateFormatter.dateTime(item.at),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}
