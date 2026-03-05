import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';

@RoutePage()
class InpatientIOScreen extends StatefulWidget {
  const InpatientIOScreen({super.key});

  @override
  State<InpatientIOScreen> createState() => _InpatientIOScreenState();
}

class _InpatientIOScreenState extends State<InpatientIOScreen> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SectionCard(
              title: 'Intake',
              subtitle: 'Fluids and intake for this admission',
              actions: [
                FilledButton.icon(
                  onPressed: () => _openAddRecordDialog(context, true),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Record'),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTable(context, isIntake: true),
                  const SizedBox(height: 12),
                  Text(
                    'Daily total: 0 ml',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SectionCard(
              title: 'Output',
              subtitle: 'Urine, drains and other output',
              actions: [
                FilledButton.icon(
                  onPressed: () => _openAddRecordDialog(context, false),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Record'),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTable(context, isIntake: false),
                  const SizedBox(height: 12),
                  Text(
                    'Daily total: 0 ml',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.error,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, {required bool isIntake}) {
    final columns = [
      'Time',
      'Type',
      'Category',
      'Amount (ml)',
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

  Future<void> _openAddRecordDialog(
    BuildContext context,
    bool isIntake,
  ) async {
    final typeCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final timeCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isIntake ? 'Add Intake' : 'Add Output'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: typeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    hintText: 'e.g. Oral, IV, Urine, Drain',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'e.g. Normal saline, NG output',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (ml)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: timeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    hintText: 'e.g. 09:30',
                  ),
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

