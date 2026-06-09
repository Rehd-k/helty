import 'package:flutter/material.dart';

import '../models/lab_models.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                'Antibiotic',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Susceptibility',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 24),
        ...sorted.map((abx) {
          final selectedId = selections[abx.id];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        abx.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (abx.code != null && abx.code!.isNotEmpty)
                        Text(
                          abx.code!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('${abx.id}-$selectedId'),
                    initialValue: selectedId != null &&
                            options.any((o) => o.id == selectedId)
                        ? selectedId
                        : null,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
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
                            opt.code != null && opt.code!.isNotEmpty
                                ? '${opt.label} (${opt.code})'
                                : opt.label,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => onChanged(abx.id, v),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
