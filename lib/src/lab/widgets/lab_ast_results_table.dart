import 'package:flutter/material.dart';
import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/ui/widgets/lab_clinical_ui.dart';
import 'package:helty/src/lab/utils/lab_ast_display.dart';
import 'package:helty/src/widgets/helty_surface.dart';

Color labAstInterpretationColor(LabAstInterpretation interpretation) {
  return switch (interpretation) {
    LabAstInterpretation.sensitive => LabClinicalUi.iconGreen,
    LabAstInterpretation.resistant => LabClinicalUi.iconPink,
    LabAstInterpretation.intermediate => LabClinicalUi.iconAmber,
    LabAstInterpretation.other => LabClinicalUi.iconTeal,
  };
}

Color labAstResultColor(LabAstResultOption option) {
  return labAstInterpretationColor(classifyLabAstResult(option));
}

Color labAstTokenColor(String token) {
  return labAstInterpretationColor(classifyAstToken(token));
}

/// Read-only antibiotic susceptibility table used on result review and reports.
class LabAstResultsTable extends StatelessWidget {
  const LabAstResultsTable({
    super.key,
    required this.results,
    this.pending = false,
  });

  final List<LabAstResult> results;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = sortedLabAstResults(results);
    final caption = rows.isEmpty
        ? 'Awaiting susceptibility'
        : '${rows.length} antibiotic${rows.length == 1 ? '' : 's'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const HeltySolidIcon(
              icon: Icons.biotech_outlined,
              color: LabClinicalUi.iconTeal,
              size: 28,
              iconSize: 15,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Antibiotic susceptibility',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    caption,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: rows.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: Text(
                      pending ? 'AST pending' : 'No AST results recorded',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      const _AstHeader(),
                      for (var i = 0; i < rows.length; i++)
                        _AstRow(result: rows[i], index: i, theme: theme),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _AstHeader extends StatelessWidget {
  const _AstHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(flex: 5, child: _AstHeaderLabel('Antibiotic')),
            SizedBox(width: 20),
            Expanded(flex: 2, child: _AstHeaderLabel('Code')),
            SizedBox(width: 20),
            Expanded(flex: 4, child: _AstHeaderLabel('Result')),
          ],
        ),
      ),
    );
  }
}

class _AstHeaderLabel extends StatelessWidget {
  const _AstHeaderLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _AstRow extends StatelessWidget {
  const _AstRow({
    required this.result,
    required this.index,
    required this.theme,
  });

  final LabAstResult result;
  final int index;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return ColoredBox(
      color: LabClinicalUi.zebraFill(cs, index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: HeltyEllipsisText(
                text: labAstAntibioticName(result.antibiotic),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: HeltyEllipsisText(
                text: labAstAntibioticCode(result.antibiotic),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 4,
              child: HeltyEllipsisChip(
                label: labAstResultText(result.resultOption),
                color: labAstResultColor(result.resultOption),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Culture note plus the antibiotic table parsed from a pasted result value.
class LabEmbeddedAstBlock extends StatelessWidget {
  const LabEmbeddedAstBlock({
    super.key,
    required this.report,
    this.label,
    this.hiddenFromReport = false,
  });

  final EmbeddedAstReport report;
  final String? label;
  final bool hiddenFromReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = label?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title.isNotEmpty)
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        if (hiddenFromReport) ...[
          const SizedBox(height: 4),
          Text(
            'Hidden from report',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (report.narrative.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(report.narrative, style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            const HeltySolidIcon(
              icon: Icons.biotech_outlined,
              color: LabClinicalUi.iconTeal,
              size: 28,
              iconSize: 15,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Antibiotic susceptibility',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${report.rows.length} antibiotic${report.rows.length == 1 ? '' : 's'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DecoratedBox(
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
                const _PlainAstHeader(),
                for (var i = 0; i < report.rows.length; i++)
                  _PlainAstRow(row: report.rows[i], index: i, theme: theme),
              ],
            ),
          ),
        ),
        if (report.legend.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              for (final item in report.legend)
                Text(
                  '${item.code} = ${item.meaning}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PlainAstHeader extends StatelessWidget {
  const _PlainAstHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(flex: 5, child: _AstHeaderLabel('Antibiotic')),
            SizedBox(width: 20),
            Expanded(flex: 3, child: _AstHeaderLabel('Result')),
          ],
        ),
      ),
    );
  }
}

class _PlainAstRow extends StatelessWidget {
  const _PlainAstRow({
    required this.row,
    required this.index,
    required this.theme,
  });

  final EmbeddedAstRow row;
  final int index;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: LabClinicalUi.zebraFill(theme.colorScheme, index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: HeltyEllipsisText(
                text: row.antibiotic,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 3,
              child: HeltyEllipsisChip(
                label: row.result,
                color: labAstTokenColor(row.result),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
