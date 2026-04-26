import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/patient_vitals_model.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_layout_constants.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/services/waiting_patient_service.dart';

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

  final _formKey = GlobalKey<FormState>();

  final _tempCtrl = TextEditingController();
  final _sysCtrl = TextEditingController();
  final _diaCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  final _respCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();
  final _painCtrl = ValueNotifier<double>(0);
  final _glucoseCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _waitingService = WaitingPatientService();

  bool _submitting = false;

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
    _vitals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  void dispose() {
    _tempCtrl.dispose();
    _sysCtrl.dispose();
    _diaCtrl.dispose();
    _pulseCtrl.dispose();
    _respCtrl.dispose();
    _spo2Ctrl.dispose();
    _painCtrl.dispose();
    _glucoseCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final narrowHeader = c.maxWidth < 560;
              final title = Text(
                'Vitals',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              );
              final button = FilledButton.icon(
                onPressed: _openRecordVitalsDialog,
                icon: const Icon(Icons.add_chart, size: 18),
                label: const Text('Record Vitals'),
              );
              if (narrowHeader) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    title,
                    const SizedBox(height: 12),
                    button,
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  title,
                  button,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Vitals History',
            subtitle: 'Time-stamped vitals recorded for this admission',
            actions: [
              OutlinedButton.icon(
                onPressed: _openTrendGraph,
                icon: const Icon(Icons.show_chart, size: 16),
                label: const Text('Trend graph'),
              ),
            ],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                columns: const [
                  DataColumn(label: Text('Time')),
                  DataColumn(label: Text('Temp')),
                  DataColumn(label: Text('BP')),
                  DataColumn(label: Text('Pulse')),
                  DataColumn(label: Text('Resp')),
                  DataColumn(label: Text('SpO₂')),
                  DataColumn(label: Text('Pain')),
                  DataColumn(label: Text('Glucose')),
                  DataColumn(label: Text('Recorded by')),
                ],
                rows: _vitals
                    .map(
                      (v) => DataRow(
                        cells: [
                          DataCell(Text(DateFormatter.dateTime(v.createdAt))),
                          DataCell(Text(v.temperature?.toString() ?? '—')),
                          DataCell(
                            Text(
                              '${v.systolic?.toString() ?? '—'}/${v.diastolic?.toString() ?? '—'}',
                            ),
                          ),
                          DataCell(Text(v.pulseRate?.toString() ?? '—')),
                          DataCell(Text(v.respRate?.toString() ?? '—')),
                          DataCell(Text(v.spo2?.toString() ?? '—')),
                          DataCell(Text(v.painScore ?? '—')),
                          DataCell(Text(v.bloodGlucose ?? '—')),
                          DataCell(Text(v.recordedBy ?? '—')),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the “Record Vitals” button to add new observations. Historical records are read-only.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRecordVitalsDialog() async {
    _formKey.currentState?.reset();
    _tempCtrl.clear();
    _sysCtrl.clear();
    _diaCtrl.clear();
    _pulseCtrl.clear();
    _respCtrl.clear();
    _spo2Ctrl.clear();
    _glucoseCtrl.clear();
    _notesCtrl.clear();
    _painCtrl.value = 0;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final bodyW = inpatientDialogBodyWidth(dialogContext);
        final narrowForm = bodyW < 520;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Record Vitals'),
          content: SizedBox(
            width: bodyW,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!narrowForm)
                      Row(
                        children: [
                          Expanded(
                            child: _numberField(
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
                                  child: _numberField(
                                    label: 'Systolic',
                                    controller: _sysCtrl,
                                    required: true,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _numberField(
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
                      _numberField(
                        label: 'Temperature (°C)',
                        controller: _tempCtrl,
                        required: true,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _numberField(
                              label: 'Systolic',
                              controller: _sysCtrl,
                              required: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _numberField(
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
                            child: _numberField(
                              label: 'Pulse (bpm)',
                              controller: _pulseCtrl,
                              required: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _numberField(
                              label: 'Resp Rate',
                              controller: _respCtrl,
                              required: true,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _numberField(
                        label: 'Pulse (bpm)',
                        controller: _pulseCtrl,
                        required: true,
                      ),
                      const SizedBox(height: 12),
                      _numberField(
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
                            child: _numberField(
                              label: 'SpO₂ (%)',
                              controller: _spo2Ctrl,
                              required: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _numberField(
                              label: 'Glucose',
                              controller: _glucoseCtrl,
                              required: false,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _numberField(
                        label: 'SpO₂ (%)',
                        controller: _spo2Ctrl,
                        required: true,
                      ),
                      const SizedBox(height: 12),
                      _numberField(
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
              onPressed: _submitting
                  ? null
                  : () {
                      Navigator.of(dialogContext).pop();
                    },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _submitting ? null : _handleSubmitVitals,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  TextFormField _numberField({
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

  Future<void> _handleSubmitVitals() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final created = await _waitingService.createPatientVitals(
        CreatePatientVitalsDto(
          waitingPatientId: '',
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
        ),
      );

      if (!mounted) return;
      setState(() {
        _vitals.insert(0, created);
        _sortVitals();
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vitals recorded successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to record vitals: $e')));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
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
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final series = <({DateTime t, double y})>[];
    DateTime? firstT;
    for (final v in sorted) {
      final y = _metricValue(v, _metric);
      if (y == null) continue;
      firstT ??= v.createdAt;
      series.add((t: v.createdAt, y: y));
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
                              color: scheme.onSurface.withValues(alpha: 0.7),
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
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
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
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
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
