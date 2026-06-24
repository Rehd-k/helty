import 'package:flutter/material.dart';

import '../../models/consultation_credit_model.dart';
import '../../widgets/consultation_credit_chip.dart';

/// Confirms opening a patient file before creating an encounter.
class StartEncounterDialog extends StatefulWidget {
  const StartEncounterDialog({
    super.key,
    required this.patientName,
    required this.onOpen,
    this.consultationCredit,
  });

  final String patientName;
  final Future<void> Function() onOpen;

  /// FIFO consumable credit from `GET /invoices/paid-without-encounter?patientId=`.
  final ConsultationServiceLine? consultationCredit;

  @override
  State<StartEncounterDialog> createState() => _StartEncounterDialogState();
}

class _StartEncounterDialogState extends State<StartEncounterDialog> {
  bool _saving = false;

  Future<void> _open() async {
    setState(() => _saving = true);
    await widget.onOpen();
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final credit = widget.consultationCredit;
    final hasConsumableCredit = credit != null && credit.consumable;

    return AlertDialog(
      title: const Text('Open Patient File'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.patientName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Open this patient\'s file to start the encounter?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            if (hasConsumableCredit) ...[
              const SizedBox(height: 16),
              ConsultationCreditChip.fromLine(line: credit),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'No consumable consultation credit on file. '
                  'Starting may fail — send the patient to billing if needed.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _saving ? null : _open,
          child: Text(_saving ? 'Opening…' : 'Open'),
        ),
      ],
    );
  }
}
