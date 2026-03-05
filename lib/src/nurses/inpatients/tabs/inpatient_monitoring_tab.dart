import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';

@RoutePage()
class InpatientMonitoringScreen extends StatefulWidget {
  const InpatientMonitoringScreen({super.key});

  @override
  State<InpatientMonitoringScreen> createState() =>
      _InpatientMonitoringScreenState();
}

class _InpatientMonitoringScreenState extends State<InpatientMonitoringScreen> {
  String _chartType = 'Respiratory Chart';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Monitoring',
        subtitle: 'Structured charts and dynamic forms',
        actions: [
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              initialValue: _chartType,
              decoration: const InputDecoration(labelText: 'Chart type'),
              items: const [
                DropdownMenuItem(
                  value: 'Respiratory Chart',
                  child: Text('Respiratory Chart'),
                ),
                DropdownMenuItem(
                  value: 'Neurological Chart',
                  child: Text('Neurological Chart'),
                ),
                DropdownMenuItem(
                  value: 'Fluid Balance',
                  child: Text('Fluid Balance'),
                ),
              ],
              onChanged: (val) {
                if (val == null) return;
                setState(() => _chartType = val);
              },
            ),
          ),
        ],
        child: _buildDynamicForm(context),
      ),
    );
  }

  Widget _buildDynamicForm(BuildContext context) {
    switch (_chartType) {
      case 'Neurological Chart':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _FieldRow(label: 'GCS'),
            _FieldRow(label: 'Pupil size / reaction'),
            _FieldRow(label: 'Motor response'),
          ],
        );
      case 'Fluid Balance':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _FieldRow(label: 'Total intake (ml)'),
            _FieldRow(label: 'Total output (ml)'),
            _FieldRow(label: 'Net balance (ml)'),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _FieldRow(label: 'Resp rate'),
            _FieldRow(label: 'SpO₂'),
            _FieldRow(label: 'Oxygen delivery'),
          ],
        );
    }
  }
}

class _FieldRow extends StatelessWidget {
  final String label;

  const _FieldRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 200, child: Text(label)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(decoration: InputDecoration(labelText: label)),
          ),
        ],
      ),
    );
  }
}
