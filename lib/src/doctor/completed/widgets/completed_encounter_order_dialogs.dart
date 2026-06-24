import 'package:flutter/material.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/lab/widgets/lab_order_results_dialog.dart';
import 'package:helty/src/models/lab_order_model.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';

/// Read-only lab result dialog for completed encounter review.
void showCompletedEncounterLabDialog(
  BuildContext context,
  LabOrderModel order,
) {
  showLabOrderResultsDialog(
    context,
    order: order,
    showEncounterId: false,
  );
}

Widget _kv(ThemeData theme, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    ),
  );
}

/// Read-only radiology summary including report text when present.
void showCompletedEncounterRadiologyDialog(
  BuildContext context,
  RadiologyOrder order,
) {
  final theme = Theme.of(context);
  final firstItem = order.items.isNotEmpty ? order.items.first : null;

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Order ${order.id.length > 8 ? order.id.substring(0, 8) : order.id}'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _kv(
                theme,
                'Ordered',
                DateFormatter.formatFromBackend(
                  order.createdAt,
                  DateFormatter.dateTime,
                ),
              ),
              _kv(theme, 'Status', order.status.name),
              _kv(theme, 'Items', '${order.items.length}'),
              if (firstItem != null) ...[
                _kv(
                  theme,
                  'Modality',
                  firstItem.scanType.displayLabel,
                ),
                if (firstItem.bodyPart != null &&
                    firstItem.bodyPart!.trim().isNotEmpty)
                  _kv(theme, 'Area', firstItem.bodyPart!),
                if (firstItem.contrast != null)
                  _kv(
                    theme,
                    'Contrast',
                    firstItem.contrast! ? 'Yes' : 'No',
                  ),
              ],
              const SizedBox(height: 16),
              Text(
                'Report',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...order.items.map((item) {
                final r = item.report;
                if (r == null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${item.scanType.displayLabel}: No signed report yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        item.scanType.displayLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (r.findings != null && r.findings!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Findings', style: theme.textTheme.labelMedium),
                        Text(r.findings!, style: theme.textTheme.bodyMedium),
                      ],
                      if (r.impression != null &&
                          r.impression!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Impression', style: theme.textTheme.labelMedium),
                        Text(r.impression!, style: theme.textTheme.bodyMedium),
                      ],
                      if (r.recommendations != null &&
                          r.recommendations!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Recommendations',
                          style: theme.textTheme.labelMedium,
                        ),
                        Text(
                          r.recommendations!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
