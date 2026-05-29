import 'package:flutter/material.dart';

/// Confirms opening a patient file before creating an encounter.
class StartEncounterDialog extends StatefulWidget {
  const StartEncounterDialog({
    super.key,
    required this.patientName,
    required this.onOpen,
  });

  final String patientName;
  final Future<void> Function() onOpen;

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
