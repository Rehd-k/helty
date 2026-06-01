import 'package:flutter/material.dart';

/// Standard discharge outcomes for PATCH `/admissions/:id` on discharge.
const List<String> kDischargeOutcomes = [
  'Duly Discharged',
  'Discharged against Medical Advice',
  'Referred out',
  'Death',
];

/// Values collected from [showDischargeAdmissionDialog].
class DischargeAdmissionPayload {
  const DischargeAdmissionPayload({
    required this.outcome,
    required this.dischargeSummary,
    this.otherImportantNotes,
  });

  final String outcome;
  final String dischargeSummary;
  final String? otherImportantNotes;
}

/// Returns payload when user completes the form, or `null` if cancelled.
Future<DischargeAdmissionPayload?> showDischargeAdmissionDialog(
  BuildContext context,
) {
  return showDialog<DischargeAdmissionPayload>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _DischargeAdmissionDialogBody(),
  );
}

class _DischargeAdmissionDialogBody extends StatefulWidget {
  const _DischargeAdmissionDialogBody();

  @override
  State<_DischargeAdmissionDialogBody> createState() =>
      _DischargeAdmissionDialogBodyState();
}

class _DischargeAdmissionDialogBodyState
    extends State<_DischargeAdmissionDialogBody> {
  final _formKey = GlobalKey<FormState>();
  final _summaryCtrl = TextEditingController();
  final _otherCtrl = TextEditingController();
  String? _outcome;

  @override
  void dispose() {
    _summaryCtrl.dispose();
    _otherCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final o = _outcome;
    if (o == null || o.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select discharge outcome.')),
      );
      return;
    }
    _close(
      DischargeAdmissionPayload(
        outcome: o,
        dischargeSummary: _summaryCtrl.text.trim(),
        otherImportantNotes: _otherCtrl.text.trim().isEmpty
            ? null
            : _otherCtrl.text.trim(),
      ),
    );
  }

  void _close([DischargeAdmissionPayload? payload]) {
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(payload);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Discharge patient'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Unpaid invoices may block discharge.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey(_outcome ?? ''),
                  initialValue: _outcome,
                  decoration: const InputDecoration(
                    labelText: 'Outcome *',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  hint: const Text('Select outcome'),
                  items: kDischargeOutcomes
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e,
                          child: Text(e, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _outcome = v),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _summaryCtrl,
                  maxLines: 5,
                  minLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Discharge summary *',
                    hintText:
                        'Course in hospital, procedures, condition at discharge…',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _otherCtrl,
                  maxLines: 4,
                  minLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Other important information',
                    hintText: 'Follow-up, warnings, referrals, equipment…',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _close(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Discharge')),
      ],
    );
  }
}
