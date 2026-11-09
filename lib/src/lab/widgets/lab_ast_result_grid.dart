import 'package:flutter/material.dart';
import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/ui/widgets/lab_clinical_ui.dart';
import 'package:helty/src/widgets/helty_surface.dart';

/// Susceptibility grid: one dropdown per antibiotic row.
class LabAstResultGrid extends StatelessWidget {
  const LabAstResultGrid({
    super.key,
    required this.antibiotics,
    required this.resultOptions,
    required this.selections,
    required this.onChanged,
  });

  final List<LabAntibiotic> antibiotics;
  final List<LabAstResultOption> resultOptions;
  final Map<String, String> selections;
  final void Function(String antibioticId, String? resultOptionId) onChanged;

  List<LabAntibiotic> get _sortedAntibiotics {
    final list = List<LabAntibiotic>.from(antibiotics)
      ..sort((a, b) {
        final pc = a.position.compareTo(b.position);
        return pc != 0 ? pc : a.name.compareTo(b.name);
      });
    return list;
  }

  List<LabAstResultOption> get _sortedOptions {
    final list = List<LabAstResultOption>.from(resultOptions)
      ..sort((a, b) {
        final pc = a.position.compareTo(b.position);
        return pc != 0 ? pc : a.label.compareTo(b.label);
      });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = _sortedAntibiotics;
    final options = _sortedOptions;

    if (sorted.isEmpty) {
      return Text(
        'No antibiotics configured. Add them under Lab → Config → Antibiotics.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    if (options.isEmpty) {
      return Text(
        'No AST result options configured. Add them under Lab → Config → AST options.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Column(
          children: [
            ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.55,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text('Antibiotic', style: headerStyle),
                    ),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: Text('Code', style: headerStyle)),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 4,
                      child: Text('Result', style: headerStyle),
                    ),
                  ],
                ),
              ),
            ),
            for (var i = 0; i < sorted.length; i++)
              _AstEntryRow(
                antibiotic: sorted[i],
                index: i,
                options: options,
                selectedId: selections[sorted[i].id],
                onChanged: onChanged,
              ),
          ],
        ),
      ),
    );
  }
}

class _AstEntryRow extends StatelessWidget {
  const _AstEntryRow({
    required this.antibiotic,
    required this.index,
    required this.options,
    required this.selectedId,
    required this.onChanged,
  });

  final LabAntibiotic antibiotic;
  final int index;
  final List<LabAstResultOption> options;
  final String? selectedId;
  final void Function(String antibioticId, String? resultOptionId) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final code = antibiotic.code?.trim() ?? '';
    final value = selectedId != null && options.any((o) => o.id == selectedId)
        ? selectedId
        : null;

    return ColoredBox(
      color: LabClinicalUi.zebraFill(cs, index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: HeltyEllipsisText(
                text: antibiotic.name.trim().isEmpty ? '-' : antibiotic.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: HeltyEllipsisText(
                text: code.isEmpty ? '-' : code,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 4,
              child: DropdownButtonFormField<String>(
                key: ValueKey('${antibiotic.id}-$value'),
                initialValue: value,
                isExpanded: true,
                isDense: true,
                decoration: InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
                hint: const Text('—'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('—'),
                  ),
                  ...options.map(
                    (opt) => DropdownMenuItem<String>(
                      value: opt.id,
                      child: Text(
                        opt.code != null && opt.code!.trim().isNotEmpty
                            ? '${opt.label} (${opt.code})'
                            : opt.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (next) => onChanged(antibiotic.id, next),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
