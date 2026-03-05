import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';

@RoutePage()
class InpatientHandoverScreen extends StatefulWidget {
  const InpatientHandoverScreen({super.key});

  @override
  State<InpatientHandoverScreen> createState() =>
      _InpatientHandoverScreenState();
}

class _InpatientHandoverScreenState extends State<InpatientHandoverScreen> {
  final _summaryCtrl = TextEditingController();
  bool _locked = false;

  @override
  void dispose() {
    _summaryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Shift Handover',
        subtitle:
            'Summarise this patient\'s status for the next nurse on duty',
        actions: [
          if (!_locked)
            FilledButton.icon(
              onPressed: _generateSummary,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Generate Shift Summary'),
            ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _summaryCtrl,
              maxLines: 10,
              readOnly: _locked,
              decoration: const InputDecoration(
                hintText:
                    'Vitals trend, meds given and pending, critical notes...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: _locked
                  ? Text(
                      'Handover submitted and locked.',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    )
                  : FilledButton(
                      onPressed: _submit,
                      child: const Text('Submit & Lock'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _generateSummary() {
    _summaryCtrl.text =
        '''Vitals: Stable over the last 8 hours.\nMeds: All scheduled medications given; next doses due at 14:00.\nOutstanding: Awaiting lab results for FBC and U&E.\nCritical notes: Monitor SpO₂ closely, on 2L oxygen via nasal prongs.''';
  }

  void _submit() {
    setState(() {
      _locked = true;
    });
  }
}

