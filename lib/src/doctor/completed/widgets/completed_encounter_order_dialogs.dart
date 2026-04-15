import 'package:flutter/material.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/lab_order_model.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';

/// Read-only lab result dialog for completed encounter review.
void showCompletedEncounterLabDialog(
  BuildContext context,
  LabOrderModel order,
) {
  final theme = Theme.of(context);
  final lines = order.resultLines;
  final hasLegacyMap =
      order.resultValues != null && order.resultValues!.isNotEmpty;

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(order.testType),
      content: SizedBox(
        width: 400,
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
              _kv(theme, 'Status', order.status),
              _kv(theme, 'Priority', order.priority ?? 'Routine'),
              if (order.clinicalNotes != null && order.clinicalNotes!.isNotEmpty)
                _kv(theme, 'Notes', order.clinicalNotes!),
              const SizedBox(height: 16),
              Text(
                'Results',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (lines != null && lines.isNotEmpty)
                ...lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            line.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            line.valueWithUnit,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            line.referenceRange != null &&
                                    line.referenceRange!.isNotEmpty
                                ? 'Ref: ${line.referenceRange}'
                                : '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (hasLegacyMap)
                ...order.resultValues!.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(
                            e.key,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            e.value,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Text(
                  'No results yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
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
