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
}) async {
  final initial = (defaultPercent ?? 100).clamp(0, 100).toDouble();
  final controller = TextEditingController(
    text: initial == initial.roundToDouble()
        ? initial.toStringAsFixed(0)
        : initial.toStringAsFixed(2),
  );
  final result = await showDialog<double>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Apply HMO coverage'),
        content: TextField(
          controller: controller,
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              if (parsed == null || parsed < 0 || parsed > 100) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a percent between 0 and 100.'),
                  ),
                );
                return;
              }
              Navigator.pop(ctx, parsed);
            },
            child: const Text('Apply'),
          ),
        ],
      );
    },
  );
  controller.dispose();
  return result;
}

/// `null` means the user cancelled. An empty [reason] is still a confirm.
class UncoverHmoResult {
  const UncoverHmoResult({this.reason});

  final String? reason;
}

Future<UncoverHmoResult?> showUncoverHmoDialog(BuildContext context) async {
  final reasonCtrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Uncover HMO'),
      content: TextField(
        controller: reasonCtrl,
        decoration: const InputDecoration(
          labelText: 'Reason (optional)',
          helperText:
              'You can re-apply at a different percent within 24 hours.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Uncover'),
        ),
      ],
    ),
  );
  final reason = reasonCtrl.text.trim();
  reasonCtrl.dispose();
  if (ok != true) return null;
  return UncoverHmoResult(reason: reason.isEmpty ? null : reason);
}
