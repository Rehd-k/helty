import 'package:flutter/material.dart';
import 'package:helty/src/models/invoice_billing_models.dart';

const hmoCoverageReverseWindow = Duration(hours: 24);

bool isActiveHmoCoverage(InvoiceCoverage c) {
  if (c.kind.trim().toUpperCase() != 'HMO') return false;
  final s = c.status.trim().toUpperCase();
  return s != 'REVERSED' && s != 'CANCELLED' && s != 'VOIDED';
}

InvoiceCoverage? activeHmoInvoiceCoverage(Iterable<InvoiceCoverage> coverages) {
  for (final c in coverages) {
    if (!isActiveHmoCoverage(c)) continue;
    if (c.scope.trim().toUpperCase() != 'INVOICE') continue;
    return c;
  }
  return null;
}

bool isHmoCoverageReversibleWithin24h(InvoiceCoverage c, {DateTime? now}) {
  if (!isActiveHmoCoverage(c)) return false;
  if (c.status.trim().toUpperCase() == 'SETTLED') return false;
  final created = c.createdAt;
  if (created == null) return true;
  final clock = now ?? DateTime.now();
  return !clock.isAfter(created.add(hmoCoverageReverseWindow));
}

Duration? remainingHmoReverseWindow(InvoiceCoverage c, {DateTime? now}) {
  final created = c.createdAt;
  if (created == null) return null;
  final end = created.add(hmoCoverageReverseWindow);
  final left = end.difference(now ?? DateTime.now());
  if (left.isNegative) return Duration.zero;
  return left;
}

String formatHmoReverseWindowLabel(InvoiceCoverage c, {DateTime? now}) {
  if (!isActiveHmoCoverage(c)) return '';
  if (c.status.trim().toUpperCase() == 'SETTLED') {
    return 'Settled — cannot reverse';
  }
  if (!isHmoCoverageReversibleWithin24h(c, now: now)) {
    return 'Cannot reverse after 24 hours';
  }
  final left = remainingHmoReverseWindow(c, now: now);
  if (left == null) return 'Can reverse within 24 hours of apply';
  final h = left.inHours;
  final m = left.inMinutes.remainder(60);
  if (h > 0) return '${h}h ${m}m left to reverse';
  if (m > 0) return '${m}m left to reverse';
  return 'Less than a minute left to reverse';
}

Future<double?> showApplyHmoPercentDialog(
  BuildContext context, {
  double? defaultPercent,
}) {
  final initial = (defaultPercent ?? 100).clamp(0, 100).toDouble();
  return showDialog<double>(
    context: context,
    builder: (ctx) => _ApplyHmoPercentDialog(initial: initial),
  );
}

class _ApplyHmoPercentDialog extends StatefulWidget {
  const _ApplyHmoPercentDialog({required this.initial});

  final double initial;

  @override
  State<_ApplyHmoPercentDialog> createState() => _ApplyHmoPercentDialogState();
}

class _ApplyHmoPercentDialogState extends State<_ApplyHmoPercentDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _controller = TextEditingController(
      text: initial == initial.roundToDouble()
          ? initial.toStringAsFixed(0)
          : initial.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Apply HMO coverage'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Coverage percent',
          suffixText: '%',
          helperText:
              '0–100. Change this if this patient is covered at a different rate.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final parsed = double.tryParse(_controller.text.trim());
            if (parsed == null || parsed < 0 || parsed > 100) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Enter a percent between 0 and 100.'),
                ),
              );
              return;
            }
            Navigator.pop(context, parsed);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

/// `null` means the user cancelled. An empty [reason] is still a confirm.
class UncoverHmoResult {
  const UncoverHmoResult({this.reason});

  final String? reason;
}

Future<UncoverHmoResult?> showUncoverHmoDialog(BuildContext context) {
  return showDialog<UncoverHmoResult>(
    context: context,
    builder: (ctx) => const _UncoverHmoDialog(),
  );
}

class _UncoverHmoDialog extends StatefulWidget {
  const _UncoverHmoDialog();

  @override
  State<_UncoverHmoDialog> createState() => _UncoverHmoDialogState();
}

class _UncoverHmoDialogState extends State<_UncoverHmoDialog> {
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Uncover HMO'),
      content: TextField(
        controller: _reasonCtrl,
        decoration: const InputDecoration(
          labelText: 'Reason (optional)',
          helperText:
              'You can re-apply at a different percent within 24 hours.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final reason = _reasonCtrl.text.trim();
            Navigator.pop(
              context,
              UncoverHmoResult(reason: reason.isEmpty ? null : reason),
            );
          },
          child: const Text('Uncover'),
        ),
      ],
    );
  }
}
