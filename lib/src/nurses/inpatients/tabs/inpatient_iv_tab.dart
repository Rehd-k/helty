import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';

@RoutePage()
class InpatientIVScreen extends StatefulWidget {
  const InpatientIVScreen({super.key});

  @override
  State<InpatientIVScreen> createState() => _InpatientIVScreenState();
}

class _InpatientIVScreenState extends State<InpatientIVScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Active IV Lines',
        subtitle: 'Fluids running for this inpatient stay',
        actions: [
          OutlinedButton.icon(
            onPressed: () => _openUpdateDialog(context),
            icon: const Icon(Icons.edit_note, size: 18),
            label: const Text('Update IV'),
          ),
        ],
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns:
                [
                      'Fluid',
                      'Volume',
                      'Rate',
                      'Start Time',
                      'Time Remaining',
                      'Site',
                    ]
                    .map(
                      (c) => DataColumn(
                        label: Text(
                          c,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
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

  Future<void> _openUpdateDialog(BuildContext context) async {
    final siteCondition = ValueNotifier<String>('Good');
    final swelling = ValueNotifier<bool>(false);
    final stopIV = ValueNotifier<bool>(false);
    final remarksCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Update IV'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: siteCondition,
                  builder: (context, value, _) {
                    return DropdownButtonFormField<String>(
                      initialValue: value,
                      decoration: const InputDecoration(
                        labelText: 'Current site condition',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Good', child: Text('Good')),
                        DropdownMenuItem(
                          value: 'Redness',
                          child: Text('Redness'),
                        ),
                        DropdownMenuItem(value: 'Pain', child: Text('Pain')),
                        DropdownMenuItem(
                          value: 'Infiltration',
                          child: Text('Infiltration'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) siteCondition.value = val;
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<bool>(
                  valueListenable: swelling,
                  builder: (context, value, _) {
                    return SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: value,
                      title: const Text('Any swelling?'),
                      onChanged: (v) => swelling.value = v,
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: stopIV,
                  builder: (context, value, _) {
                    return SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: value,
                      title: const Text('Stop IV?'),
                      onChanged: (v) => stopIV.value = v,
                    );
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: remarksCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Remarks',
                    alignLabelWithHint: true,
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
