import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';

@RoutePage()
class InpatientProceduresScreen extends StatefulWidget {
  const InpatientProceduresScreen({super.key});

  @override
  State<InpatientProceduresScreen> createState() =>
      _InpatientProceduresScreenState();
}

class _InpatientProceduresScreenState
    extends State<InpatientProceduresScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Procedures',
        subtitle: 'Bedside and theatre procedures for this admission',
        actions: [
          FilledButton.icon(
            onPressed: () => _openAddProcedureDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Procedure'),
          ),
        ],
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              'Date/Time',
              'Type',
              'Clinician',
              'Site',
              'Outcome',
            ]
                .map(
                  (c) => DataColumn(
                    label: Text(
                      c,
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                )
                .toList(),
            rows: const [],
          ),
        ),
      ),
    );
  }

  Future<void> _openAddProcedureDialog(BuildContext context) async {
    final typeCtrl = TextEditingController();
    final clinicianCtrl = TextEditingController();
    final siteCtrl = TextEditingController();
    final outcomeCtrl = TextEditingController();
    final complicationsCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Procedure'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: typeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Procedure type',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: clinicianCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Performing clinician',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: siteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Site',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: outcomeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Outcome',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: complicationsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Complications',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Wound images (optional)',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Upload wound image'),
                  ),
                ],
              ),
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

