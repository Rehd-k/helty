import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/app_timezone.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/patient_vitals_model.dart';
import 'package:helty/src/models/staff_attribution.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_chart_table.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_layout_constants.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_metrics.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/services/waiting_patient_service.dart';
import 'package:helty/src/widgets/helty_surface.dart';

enum _VitalsTrendMetric {
  temperature,
  pulse,
  spo2,
  respRate,
  map,
  pain,
  glucose,
}

@RoutePage()
class InpatientVitalsScreen extends StatefulWidget {
  final List<PatientVitalsModel> vitals;
  final String admissionId;
  const InpatientVitalsScreen({
    super.key,
    required this.vitals,
    required this.admissionId,
  });

  @override
  State<InpatientVitalsScreen> createState() => _InpatientVitalsScreenState();
}

class _InpatientVitalsScreenState extends State<InpatientVitalsScreen> {
  late List<PatientVitalsModel> _vitals;

  final _waitingService = WaitingPatientService();

  @override
  void initState() {
    super.initState();
    _vitals = List<PatientVitalsModel>.from(widget.vitals);
    _sortVitals();
  }

  @override
  void didUpdateWidget(covariant InpatientVitalsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.vitals, widget.vitals)) {
      _vitals = List<PatientVitalsModel>.from(widget.vitals);
      _sortVitals();
    }
  }

  void _sortVitals() {
    _vitals.sort((a, b) => b.effectiveAt.compareTo(a.effectiveAt));
  }

  @override
  Widget build(BuildContext context) {
    final scope = InpatientViewScope.of(context);
    final canRecord = scope?.isAdmissionActive == true && scope?.isNurse == true;
    final staffId = scope?.staffId?.trim();
    final latest = _vitals.isEmpty ? null : _vitals.first;
    final when = latest == null
        ? null
        : DateFormatter.dateTime(latest.effectiveAt);

    return ResponsiveBody(
      expand: false,
      builder: (context, bp) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InpatientTabToolbar(
              icon: Icons.monitor_heart_outlined,
              iconColor: InpatientMetrics.waitRed,
              title: 'Vitals',
              subtitle: 'Time-stamped bedside observations',
              actions: [
                OutlinedButton.icon(
                  onPressed: _openTrendGraph,
                  style: inpatientCompactOutline(),
                  icon: const Icon(Icons.show_chart, size: 16),
                  label: const Text('Trend'),
                ),
                FilledButton.icon(
                  onPressed: canRecord ? _openRecordVitalsDialog : null,
                  style: inpatientCompactFill(),
                  icon: const Icon(Icons.add_chart, size: 16),
                  label: const Text('Record Vitals'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _VitalsKpiStrip(latest: latest, recordedAt: when),
            const SizedBox(height: 10),
            SectionCard(
              title: 'Vitals history',
              subtitle: 'Newest first',
              icon: Icons.table_chart_outlined,
              iconColor: InpatientMetrics.iconIndigo,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: InpatientChartTable(
                columns: const [
                  InpatientChartColumn('TIME', flex: 3),
                  InpatientChartColumn('TEMP'),
                  InpatientChartColumn('BP'),
                  InpatientChartColumn('PULSE'),
                  InpatientChartColumn('RESP'),
                  InpatientChartColumn('SPO₂'),
                  InpatientChartColumn('PAIN'),
                  InpatientChartColumn('GLUCOSE'),
                  InpatientChartColumn('RECORDED BY', flex: 3),
                  InpatientChartColumn('ACTIONS', flex: 2, alignEnd: true),
                ],
                rowCount: _vitals.length,
                emptyMessage: 'No vitals recorded yet.',
                footerLabel: _vitals.length == 1
                    ? '1 observation'
                    : '${_vitals.length} observations',
                minWidth: 960,
                cellBuilder: (context, index) {
                  final v = _vitals[index];
                  final canEdit = canRecord &&
                      staffId != null &&
                      staffId.isNotEmpty &&
                      (v.recordedByNurseId == null ||
                          v.recordedByNurseId!.isEmpty ||
                          v.recordedByNurseId == staffId);
                  return [
                    HeltyEllipsisText(
                      text: DateFormatter.dateTime(v.effectiveAt),
                    ),
                    HeltyEllipsisText(text: v.temperature?.toString() ?? '—'),
                    HeltyEllipsisText(
                      text:
                          '${v.systolic?.toString() ?? '—'}/${v.diastolic?.toString() ?? '—'}',
                    ),
                    HeltyEllipsisText(text: v.pulseRate?.toString() ?? '—'),
                    HeltyEllipsisText(text: v.respRate?.toString() ?? '—'),
                    HeltyEllipsisText(text: v.spo2?.toString() ?? '—'),
                    HeltyEllipsisText(text: v.painScore ?? '—'),
                    HeltyEllipsisText(text: v.bloodGlucose ?? '—'),
                    HeltyEllipsisText(text: v.recordedBy ?? '—'),
                    canEdit
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: OutlinedButton(
                              onPressed: () => _openEditVitalsDialog(v),
                              style: inpatientCompactOutline(),
                              child: const Text('Edit'),
                            ),
                          )
                        : const HeltyEllipsisText(text: '—'),
                  ];
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRecordVitalsDialog() async {
    final nurseId = requireNurseIdFromScope(context);
    if (nurseId == null) return;

    final created = await showDialog<PatientVitalsModel>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RecordVitalsDialog(
        admissionId: widget.admissionId,
        nurseId: nurseId,
        waitingService: _waitingService,
      ),
    );

    if (created != null && mounted) {
      setState(() {
        _vitals.insert(0, created);
        _sortVitals();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vitals recorded successfully.')),
      );
    }
  }

  Future<void> _openEditVitalsDialog(PatientVitalsModel existing) async {
    final nurseId = requireNurseIdFromScope(context);
    if (nurseId == null) return;

    final updated = await showDialog<PatientVitalsModel>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RecordVitalsDialog(
        admissionId: widget.admissionId,
        nurseId: nurseId,
        waitingService: _waitingService,
        existing: existing,
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        final idx = _vitals.indexWhere((v) => v.id == updated.id);
        if (idx >= 0) {
          _vitals[idx] = updated;
        }
        _sortVitals();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vitals updated.')),
      );
    }
  }

  Future<void> _openTrendGraph() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _VitalsTrendDialog(vitals: List<PatientVitalsModel>.from(_vitals));
      },
    );
  }
}

class _VitalsKpiStrip extends StatelessWidget {
  const _VitalsKpiStrip({required this.latest, required this.recordedAt});

  final PatientVitalsModel? latest;
  final String? recordedAt;

  @override
  Widget build(BuildContext context) {
    final v = latest;
    final caption = recordedAt ?? 'No observations';
    final items = [
      InpatientKpiTile(
        icon: Icons.thermostat_outlined,
        color: InpatientMetrics.waitRed,
        label: 'Temp',
        value: v?.temperature == null ? '—' : '${v!.temperature}°C',
        caption: caption,
      ),
      InpatientKpiTile(
        icon: Icons.speed_outlined,
        color: InpatientMetrics.iconIndigo,
        label: 'BP',
        value: v == null
            ? '—'
            : '${v.systolic ?? '—'}/${v.diastolic ?? '—'}',
        caption: caption,
      ),
      InpatientKpiTile(
        icon: Icons.favorite_outline,
        color: InpatientMetrics.iconPink,
        label: 'HR',
        value: v?.pulseRate?.toString() ?? '—',
        caption: caption,
      ),
      InpatientKpiTile(
        icon: Icons.air,
        color: InpatientMetrics.iconTeal,
        label: 'SpO₂',
        value: v?.spo2 == null ? '—' : '${v!.spo2}%',
        caption: caption,
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

TextFormField _vitalsNumberField({
  required String label,
  required TextEditingController controller,
  required bool required,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      if (!required) return null;
      if (value == null || value.trim().isEmpty) {
        return 'Required';
      }
      return null;
    },
  );
}

/// Owns vitals form controllers so disposal matches the dialog route lifecycle.
class _RecordVitalsDialog extends StatefulWidget {
  const _RecordVitalsDialog({
    required this.admissionId,
    required this.nurseId,
    required this.waitingService,
    this.existing,
  });

  final String admissionId;
  final String nurseId;
  final WaitingPatientService waitingService;
  final PatientVitalsModel? existing;

  @override
  State<_RecordVitalsDialog> createState() => _RecordVitalsDialogState();
}

class _RecordVitalsDialogState extends State<_RecordVitalsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _timeCtrl;
  final _tempCtrl = TextEditingController();
  final _sysCtrl = TextEditingController();
  final _diaCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  final _respCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();
  final _glucoseCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _painCtrl = ValueNotifier<double>(0);

  bool _saving = false;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final at = existing?.effectiveAt ?? AppTimezone.now();
    _timeCtrl = TextEditingController(
      text: DateFormatter.timeOnly(at),
    );
    if (existing != null) {
      _tempCtrl.text = existing.temperature?.toString() ?? '';
      _sysCtrl.text = existing.systolic?.toString() ?? '';
      _diaCtrl.text = existing.diastolic?.toString() ?? '';
      _pulseCtrl.text = existing.pulseRate?.toString() ?? '';
      _respCtrl.text = existing.respRate?.toString() ?? '';
      _spo2Ctrl.text = existing.spo2?.toString() ?? '';
      _glucoseCtrl.text = existing.bloodGlucose ?? '';
      _notesCtrl.text = existing.notes ?? '';
      final pain = double.tryParse(existing.painScore ?? '');
      if (pain != null) _painCtrl.value = pain.clamp(0, 10);
    }
  }

  @override
  void dispose() {
    _timeCtrl.dispose();
    _tempCtrl.dispose();
    _sysCtrl.dispose();
    _diaCtrl.dispose();
    _pulseCtrl.dispose();
    _respCtrl.dispose();
    _spo2Ctrl.dispose();
    _glucoseCtrl.dispose();
    _notesCtrl.dispose();
    _painCtrl.dispose();
    super.dispose();
  }

  void _close([PatientVitalsModel? result]) {
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final baseDate = widget.existing != null
        ? AppTimezone.toLocal(widget.existing!.effectiveAt)
        : AppTimezone.now();
    final parsedTime = AppTimezone.parseTimeOnDate(
      _timeCtrl.text,
      baseDate,
    );
    if (parsedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid time (e.g. 2:30 PM).')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final PatientVitalsModel result;
      if (_isEdit) {
        result = await widget.waitingService.updatePatientVitals(
          widget.existing!.id,
          UpdatePatientVitalsDto(
            systolic: int.tryParse(_sysCtrl.text),
            diastolic: int.tryParse(_diaCtrl.text),
            temperature: double.tryParse(_tempCtrl.text),
            pulseRate: int.tryParse(_pulseCtrl.text),
            respRate: int.tryParse(_respCtrl.text),
            spo2: double.tryParse(_spo2Ctrl.text),
            notes: _notesCtrl.text,
            bloodGlucose: _glucoseCtrl.text,
            painScore: _painCtrl.value.toInt().toString(),
            recordedAt: parsedTime,
          ),
        );
      } else {
        result = await widget.waitingService.createPatientVitals(
          CreatePatientVitalsDto(
            admissionId: widget.admissionId,
            systolic: int.tryParse(_sysCtrl.text),
            diastolic: int.tryParse(_diaCtrl.text),
            temperature: double.tryParse(_tempCtrl.text),
            pulseRate: int.tryParse(_pulseCtrl.text),
            respRate: int.tryParse(_respCtrl.text),
            spo2: double.tryParse(_spo2Ctrl.text),
            notes: _notesCtrl.text,
            bloodGlucose: _glucoseCtrl.text,
            painScore: _painCtrl.value.toInt().toString(),
            recordedByNurseId: widget.nurseId,
            recordedAt: parsedTime,
          ),
        );
      }
      if (!mounted) return;
      _close(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Failed to update vitals: $e' : 'Failed to record vitals: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodyW = inpatientDialogBodyWidth(context);
    final narrowForm = bodyW < 520;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(_isEdit ? 'Edit Vitals' : 'Record Vitals'),
      content: SizedBox(
        width: bodyW,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _timeCtrl,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Recorded time',
                    hintText: 'e.g. 2:30 PM',
                    helperText: 'Enter time as hh:mm AM or PM',
                  ),
                ),
                const SizedBox(height: 12),
                if (!narrowForm)
                  Row(
                    children: [
                      Expanded(
                        child: _vitalsNumberField(
                          label: 'Temperature (°C)',
                          controller: _tempCtrl,
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _vitalsNumberField(
                                label: 'Systolic',
                                controller: _sysCtrl,
                                required: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _vitalsNumberField(
                                label: 'Diastolic',
                                controller: _diaCtrl,
                                required: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _vitalsNumberField(
                    label: 'Temperature (°C)',
                    controller: _tempCtrl,
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _vitalsNumberField(
                          label: 'Systolic',
                          controller: _sysCtrl,
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _vitalsNumberField(
                          label: 'Diastolic',
                          controller: _diaCtrl,
                          required: true,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                if (!narrowForm)
                  Row(
                    children: [
                      Expanded(
                        child: _vitalsNumberField(
                          label: 'Pulse (bpm)',
                          controller: _pulseCtrl,
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _vitalsNumberField(
                          label: 'Resp Rate',
                          controller: _respCtrl,
                          required: true,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _vitalsNumberField(
                    label: 'Pulse (bpm)',
                    controller: _pulseCtrl,
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  _vitalsNumberField(
                    label: 'Resp Rate',
                    controller: _respCtrl,
                    required: true,
                  ),
                ],
                const SizedBox(height: 12),
                if (!narrowForm)
                  Row(
                    children: [
                      Expanded(
                        child: _vitalsNumberField(
                          label: 'SpO₂ (%)',
                          controller: _spo2Ctrl,
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _vitalsNumberField(
                          label: 'Glucose',
                          controller: _glucoseCtrl,
                          required: false,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _vitalsNumberField(
                    label: 'SpO₂ (%)',
                    controller: _spo2Ctrl,
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  _vitalsNumberField(
                    label: 'Glucose',
                    controller: _glucoseCtrl,
                    required: false,
                  ),
                ],
                const SizedBox(height: 16),
                ValueListenableBuilder<double>(
                  valueListenable: _painCtrl,
                  builder: (context, value, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Pain Score'),
                            Text(value.toInt().toString()),
                          ],
                        ),
                        Slider(
                          value: value,
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: value.toInt().toString(),
                          onChanged: (v) => _painCtrl.value = v,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => _close(),
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
              : Text(_isEdit ? 'Save' : 'Submit'),
        ),
      ],
    );
  }
}

double? _metricValue(PatientVitalsModel v, _VitalsTrendMetric m) {
  switch (m) {
    case _VitalsTrendMetric.temperature:
      return v.temperature;
    case _VitalsTrendMetric.pulse:
      return v.pulseRate?.toDouble();
    case _VitalsTrendMetric.spo2:
      return v.spo2;
    case _VitalsTrendMetric.respRate:
      return v.respRate?.toDouble();
    case _VitalsTrendMetric.map:
      final sys = v.systolic;
      final dia = v.diastolic;
      if (sys == null || dia == null) return null;
      return dia + (sys - dia) / 3.0;
    case _VitalsTrendMetric.pain:
      if (v.painScore == null || v.painScore!.trim().isEmpty) return null;
      return double.tryParse(v.painScore!.trim());
    case _VitalsTrendMetric.glucose:
      if (v.bloodGlucose == null || v.bloodGlucose!.trim().isEmpty) {
        return null;
      }
      return double.tryParse(v.bloodGlucose!.trim());
  }
}

String _metricLabel(_VitalsTrendMetric m) {
  switch (m) {
    case _VitalsTrendMetric.temperature:
      return 'Temp (°C)';
    case _VitalsTrendMetric.pulse:
      return 'Pulse (bpm)';
    case _VitalsTrendMetric.spo2:
      return 'SpO₂ (%)';
    case _VitalsTrendMetric.respRate:
      return 'Resp rate';
    case _VitalsTrendMetric.map:
      return 'MAP (mmHg)';
    case _VitalsTrendMetric.pain:
      return 'Pain (0–10)';
    case _VitalsTrendMetric.glucose:
      return 'Glucose';
  }
}

class _VitalsTrendDialog extends StatefulWidget {
  const _VitalsTrendDialog({required this.vitals});

  final List<PatientVitalsModel> vitals;

  @override
  State<_VitalsTrendDialog> createState() => _VitalsTrendDialogState();
}

class _VitalsTrendDialogState extends State<_VitalsTrendDialog> {
  _VitalsTrendMetric _metric = _VitalsTrendMetric.temperature;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sorted = List<PatientVitalsModel>.from(widget.vitals)
      ..sort((a, b) => a.effectiveAt.compareTo(b.effectiveAt));

    final series = <({DateTime t, double y})>[];
    DateTime? firstT;
    for (final v in sorted) {
      final y = _metricValue(v, _metric);
      if (y == null) continue;
      firstT ??= v.effectiveAt;
      series.add((t: v.effectiveAt, y: y));
    }

    final dialogW = inpatientDialogBodyWidth(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Vitals Trend'),
      content: SizedBox(
        width: dialogW,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<_VitalsTrendMetric>(
              key: ValueKey(_metric),
              initialValue: _metric,
              decoration: const InputDecoration(labelText: 'Metric'),
              items: _VitalsTrendMetric.values
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(_metricLabel(e)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _metric = v);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: series.isEmpty || firstT == null
                  ? Center(
                      child: Text(
                        sorted.isEmpty
                            ? 'No vitals recorded yet.'
                            : 'No data points for ${_metricLabel(_metric)} in this history.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    )
                  : _TrendChart(
                      series: series,
                      firstT: firstT,
                      colorScheme: scheme,
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.series,
    required this.firstT,
    required this.colorScheme,
  });

  final List<({DateTime t, double y})> series;
  final DateTime firstT;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final ys = series.map((e) => e.y).toList();
    var minY = ys.reduce(math.min);
    var maxY = ys.reduce(math.max);
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    } else {
      final pad = (maxY - minY) * 0.08;
      minY -= pad;
      maxY += pad;
    }

    final lastT = series.last.t;
    final spanH = math.max(
      lastT.difference(firstT).inMilliseconds / 3.6e6,
      1e-6,
    );

    final spots = <FlSpot>[];
    for (var i = 0; i < series.length; i++) {
      final h = series[i].t.difference(firstT).inMilliseconds / 3.6e6;
      spots.add(FlSpot(h, series[i].y));
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: spanH,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outline.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: spanH > 24 ? spanH / 4 : (spanH > 6 ? 6 : 1),
              getTitlesWidget: (value, meta) {
                final h = value;
                if (h < -0.01 || h > spanH + 0.01) {
                  return const SizedBox.shrink();
                }
                final t = firstT.add(Duration(
                  milliseconds: (h * 3.6e6).round(),
                ));
                final label =
                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(
                  value.abs() >= 100 ? 0 : (value.abs() >= 10 ? 1 : 2),
                ),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: colorScheme.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: series.length < 40,
              getDotPainter: (spot, percent, bar, i) =>
                  FlDotCirclePainter(radius: 3, color: colorScheme.primary),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
