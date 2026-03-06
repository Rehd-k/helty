import 'package:auto_route/auto_route.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/models/patient_vitals_model.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/services/waiting_patient_service.dart';

@RoutePage()
class InpatientVitalsScreen extends StatefulWidget {
  const InpatientVitalsScreen({super.key});

  @override
  State<InpatientVitalsScreen> createState() => _InpatientVitalsScreenState();
}

class _InpatientVitalsScreenState extends State<InpatientVitalsScreen> {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vitals',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              FilledButton.icon(
                onPressed: _openRecordVitalsDialog,
                icon: const Icon(Icons.add_chart, size: 18),
                label: const Text('Record Vitals'),
              ),
            ],
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
            child: SizedBox(
              width: double.infinity,
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
                rows: const [],
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
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Record Vitals'),
          content: SizedBox(
            width: 520,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    ),
                    const SizedBox(height: 12),
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
                    ),
                    const SizedBox(height: 12),
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
                    ),
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
                      Navigator.of(context).pop();
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
      await _waitingService.createPatientVitals(
        CreatePatientVitalsDto(
          waitingPatientId: '',
          systolic: int.tryParse(_sysCtrl.text),
          diastolic: int.tryParse(_diaCtrl.text),
          temperature: double.tryParse(_tempCtrl.text),
          pulseRate: int.tryParse(_pulseCtrl.text),
          spo2: double.tryParse(_spo2Ctrl.text),
        ),
      );

      if (!mounted) return;
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
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Vitals Trend'),
          content: SizedBox(
            width: 520,
            height: 260,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: scheme.outline.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 36.6),
                      FlSpot(1, 37.0),
                      FlSpot(2, 37.4),
                      FlSpot(3, 37.1),
                      FlSpot(4, 36.9),
                    ],
                    isCurved: true,
                    color: scheme.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: scheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
