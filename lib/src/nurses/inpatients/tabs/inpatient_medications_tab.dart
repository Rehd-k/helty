import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';

@RoutePage()
class InpatientMedicationsScreen extends StatefulWidget {
  const InpatientMedicationsScreen({super.key});

  @override
  State<InpatientMedicationsScreen> createState() =>
      _InpatientMedicationsScreenState();
}

class _InpatientMedicationsScreenState
    extends State<InpatientMedicationsScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SectionCard(
              title: 'Active Medication Orders',
              subtitle: 'Standing and PRN orders for this inpatient stay',
              child: _buildActiveOrdersTable(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SectionCard(
              title: 'Medication Administration History',
              subtitle: 'Chronological record of administered doses',
              child: _buildHistoryTable(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersTable(BuildContext context) {
    final columns = [
      'Drug',
      'Dose',
      'Route',
      'Next Due',
      'Administer',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns
            .map(
              (c) => DataColumn(
                label: Text(
                  c,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            )
            .toList(),
        rows: [
          DataRow(
            cells: [
              const DataCell(Text('Paracetamol')),
              const DataCell(Text('1g 8 hourly')),
              const DataCell(Text('PO')),
              const DataCell(Text('14:00')),
              DataCell(
                TextButton(
                  onPressed: () => _openAdministerDialog(context),
                  child: const Text('Administer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTable(BuildContext context) {
    final columns = [
      'Time',
      'Drug',
      'Dose',
      'Route',
      'Status',
      'Nurse',
      'Reason',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns
            .map(
              (c) => DataColumn(
                label: Text(
                  c,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            )
            .toList(),
        rows: const [],
      ),
    );
  }

  Future<void> _openAdministerDialog(BuildContext context) async {
    final statusNotifier = ValueNotifier<String>('Given');
    final timeCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final signatureCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Administer Medication'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Confirm patient and order',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Patient: [Name] • Hosp No: [Number]\nDrug: Paracetamol 1g PO 8 hourly',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: timeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Actual administration time',
                    hintText: 'e.g. 13:45',
                  ),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<String>(
                  valueListenable: statusNotifier,
                  builder: (context, status, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Given',
                              child: Text('Given'),
                            ),
                            DropdownMenuItem(
                              value: 'Missed',
                              child: Text('Missed'),
                            ),
                            DropdownMenuItem(
                              value: 'Refused',
                              child: Text('Refused'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) statusNotifier.value = val;
                          },
                        ),
                        const SizedBox(height: 12),
                        if (status != 'Given')
                          TextFormField(
                            controller: reasonCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Reason (if not given)',
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: signatureCtrl,
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

