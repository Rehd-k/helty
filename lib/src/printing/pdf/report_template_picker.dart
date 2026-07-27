import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'report_template_preference.dart';
import 'report_templates/report_pdf_theme.dart';

/// Opens a dialog to pick the default lab/diagnostic PDF report template.
///
/// Selection is persisted via [reportTemplateProvider] and reused on every
/// print until changed again.
Future<void> showReportTemplatePicker(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => const _ReportTemplatePickerDialog(),
  );
}

/// Compact AppBar action that opens [showReportTemplatePicker].
class ReportTemplatePickerButton extends ConsumerWidget {
  const ReportTemplatePickerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(reportTemplateProvider);
    return IconButton(
      tooltip: 'Report template: ${selected.displayName}',
      icon: const Icon(Icons.article_outlined),
      onPressed: () => showReportTemplatePicker(context, ref),
    );
  }
}

class _ReportTemplatePickerDialog extends ConsumerWidget {
  const _ReportTemplatePickerDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(reportTemplateProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Report template'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a layout for lab and diagnostic prints. '
              'This becomes the default until you change it again.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            for (final id in ReportPdfTemplateId.all) ...[
              _TemplateOptionTile(
                id: id,
                selected: selected == id,
                onTap: () async {
                  await ref
                      .read(reportTemplateProvider.notifier)
                      .setTemplate(id);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
              if (id != ReportPdfTemplateId.all.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _TemplateOptionTile extends StatelessWidget {
  const _TemplateOptionTile({
    required this.id,
    required this.selected,
    required this.onTap,
  });

  final ReportPdfTemplateId id;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      id.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      id.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
