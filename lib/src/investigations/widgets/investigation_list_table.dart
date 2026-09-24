import 'dart:math' as math;

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../../core/extensions/number.extention.dart';
import '../../core/widgets/patient_avatar.dart';
import '../../helper/date.formatter.dart';
import '../../lab/ui/widgets/lab_clinical_ui.dart';
import '../../widgets/helty_surface.dart';
import '../models/investigation_models.dart';

class InvestigationListTable extends StatelessWidget {
  const InvestigationListTable({
    super.key,
    required this.rows,
    this.showSampleColumn = false,
    this.showPriorityColumn = false,
    this.fillHeight = false,
    this.useCards = false,
    this.loading = false,
    this.skip = 0,
    this.pageSize = 20,
    this.total,
    this.hasMore = false,
    this.onPrev,
    this.onNext,
    this.trailing,
  });

  final List<InvestigationListRow> rows;
  final bool showSampleColumn;
  final bool showPriorityColumn;
  final bool fillHeight;
  final bool useCards;
  final bool loading;
  final int skip;
  final int pageSize;
  final int? total;
  final bool hasMore;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    if (fillHeight) return _buildFilled(context);
    return _buildLegacy(context);
  }

  Widget _buildFilled(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final footer = LabPaginationFooter(
      skip: skip,
      pageSize: pageSize,
      shown: rows.length,
      total: total ?? rows.length,
      hasMore: hasMore,
      onPrev: onPrev ?? () {},
      onNext: onNext ?? () {},
      noun: 'investigations',
    );

    Widget titleBar() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
        child: Row(
          children: [
            const HeltySolidIcon(
              icon: Icons.science_outlined,
              color: LabClinicalUi.iconIndigo,
              size: 26,
              iconSize: 14,
              radius: 7,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Line items',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      );
    }

    if (loading) {
      return HeltySurfaceCard(
        child: Column(
          children: [
            titleBar(),
            const Expanded(child: Center(child: CircularProgressIndicator())),
            footer,
          ],
        ),
      );
    }

    if (rows.isEmpty) {
      return HeltySurfaceCard(
        child: Column(
          children: [
            titleBar(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No investigations match the filter.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            footer,
          ],
        ),
      );
    }

    if (useCards) {
      return Column(
        children: [
          titleBar(),
          Expanded(
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _InvestigationLineCard(
                  row: rows[index],
                  showSample: showSampleColumn,
                  showPriority: showPriorityColumn,
                );
              },
            ),
          ),
          footer,
        ],
      );
    }

    return HeltySurfaceCard(
      child: Column(
        children: [
          titleBar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const minW = 1080.0;
                final w = math.max(constraints.maxWidth, minW);
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: w,
                    height: constraints.maxHeight,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 16, 8),
                          child: _InvestigationHeaderRow(
                            showSample: showSampleColumn,
                            showPriority: showPriorityColumn,
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: rows.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              color: cs.outline.withValues(alpha: 0.08),
                            ),
                            itemBuilder: (context, index) {
                              return ColoredBox(
                                color: LabClinicalUi.zebraFill(cs, index),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: _InvestigationDataRow(
                                    row: rows[index],
                                    indexLabel: '${skip + index + 1}',
                                    showSample: showSampleColumn,
                                    showPriority: showPriorityColumn,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          footer,
        ],
      ),
    );
  }

  Widget _buildLegacy(BuildContext context) {
    final theme = Theme.of(context);
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No investigations match the filter.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final columns = <DataColumn2>[
      const DataColumn2(label: Text('Patient'), size: ColumnSize.L),
      const DataColumn2(label: Text('Test'), size: ColumnSize.L),
      const DataColumn2(label: Text('Status'), size: ColumnSize.S),
      const DataColumn2(label: Text('Amount'), size: ColumnSize.S),
      const DataColumn2(label: Text('Department'), size: ColumnSize.S),
      const DataColumn2(label: Text('Invoice'), size: ColumnSize.S),
      if (showSampleColumn)
        const DataColumn2(label: Text('Sample'), size: ColumnSize.S),
      if (showPriorityColumn)
        const DataColumn2(label: Text('Priority'), size: ColumnSize.S),
      const DataColumn2(label: Text('Created'), size: ColumnSize.S),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          height: (rows.length.clamp(1, 12) * 52 + 56).toDouble(),
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 8,
            minWidth: 900,
            columns: columns,
            rows: [
              for (final row in rows)
                DataRow2(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          PatientAvatar(
                            avatarUrl: row.patient?.avatarUrl,
                            firstName: row.patient?.firstName,
                            surname: row.patient?.surname,
                            displayName: row.resolvedPatientName,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              row.resolvedPatientName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(row.testName)),
                    DataCell(Text(row.status)),
                    DataCell(Text(row.amount.toFinancial(isMoney: true))),
                    DataCell(Text(row.department?.name ?? '—')),
                    DataCell(Text(row.invoice?.status ?? '—')),
                    if (showSampleColumn)
                      DataCell(
                        Text(
                          row.sampleCollected == true
                              ? 'Collected'
                              : row.sampleCollected == false
                              ? 'Pending'
                              : '—',
                        ),
                      ),
                    if (showPriorityColumn) DataCell(Text(row.priority ?? '—')),
                    DataCell(
                      Text(
                        row.createdAt != null
                            ? DateFormatter.dateTime(row.createdAt!)
                            : '—',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

const _invColGap = 20.0;

class _InvestigationHeaderRow extends StatelessWidget {
  const _InvestigationHeaderRow({
    required this.showSample,
    required this.showPriority,
  });

  final bool showSample;
  final bool showPriority;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget head(String label, {int flex = 1, bool alignEnd = false}) {
      return Expanded(
        flex: flex,
        child: Text(
          label,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    }

    return Row(
      children: [
        const SizedBox(width: 4),
        head('#', flex: 1),
        const SizedBox(width: _invColGap),
        head('PATIENT', flex: 5),
        const SizedBox(width: _invColGap),
        head('TEST', flex: 4),
        const SizedBox(width: _invColGap),
        head('STATUS', flex: 2),
        const SizedBox(width: _invColGap),
        head('AMOUNT', flex: 2, alignEnd: true),
        const SizedBox(width: _invColGap),
        head('DEPT', flex: 3),
        if (showSample) ...[
          const SizedBox(width: _invColGap),
          head('SAMPLE', flex: 2),
        ],
        if (showPriority) ...[
          const SizedBox(width: _invColGap),
          head('PRIORITY', flex: 2),
        ],
        const SizedBox(width: _invColGap),
        head('CREATED', flex: 3),
      ],
    );
  }
}

class _InvestigationDataRow extends StatelessWidget {
  const _InvestigationDataRow({
    required this.row,
    required this.indexLabel,
    required this.showSample,
    required this.showPriority,
  });

  final InvestigationListRow row;
  final String indexLabel;
  final bool showSample;
  final bool showPriority;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusLabel = _investigationStatusLabel(row.status);
    final statusColor = _investigationStatusColor(row.status);

    Widget cell(Widget child, {int flex = 1}) {
      return Expanded(flex: flex, child: child);
    }

    return Row(
      children: [
        const SizedBox(width: 4),
        cell(
          HeltyEllipsisText(
            text: indexLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: _invColGap),
        cell(
          Row(
            children: [
              PatientAvatar(
                avatarUrl: row.patient?.avatarUrl,
                firstName: row.patient?.firstName,
                surname: row.patient?.surname,
                displayName: row.resolvedPatientName,
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: HeltyEllipsisText(
                  text: row.resolvedPatientName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          flex: 5,
        ),
        const SizedBox(width: _invColGap),
        cell(HeltyEllipsisText(text: row.testName), flex: 4),
        const SizedBox(width: _invColGap),
        cell(
          HeltyEllipsisChip(label: statusLabel, color: statusColor),
          flex: 2,
        ),
        const SizedBox(width: _invColGap),
        cell(
          HeltyEllipsisText(
            text: row.amount.toFinancial(isMoney: true),
            align: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          flex: 2,
        ),
        const SizedBox(width: _invColGap),
        cell(HeltyEllipsisText(text: row.department?.name ?? '—'), flex: 3),
        if (showSample) ...[
          const SizedBox(width: _invColGap),
          cell(
            HeltyEllipsisText(text: _sampleLabel(row.sampleCollected)),
            flex: 2,
          ),
        ],
        if (showPriority) ...[
          const SizedBox(width: _invColGap),
          cell(HeltyEllipsisText(text: row.priority ?? '—'), flex: 2),
        ],
        const SizedBox(width: _invColGap),
        cell(
          HeltyEllipsisText(
            text: row.createdAt != null
                ? DateFormatter.dateTime(row.createdAt!)
                : '—',
          ),
          flex: 3,
        ),
      ],
    );
  }
}

class _InvestigationLineCard extends StatelessWidget {
  const _InvestigationLineCard({
    required this.row,
    required this.showSample,
    required this.showPriority,
  });

  final InvestigationListRow row;
  final bool showSample;
  final bool showPriority;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusLabel = _investigationStatusLabel(row.status);
    final statusColor = _investigationStatusColor(row.status);

    return HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PatientAvatar(
                avatarUrl: row.patient?.avatarUrl,
                firstName: row.patient?.firstName,
                surname: row.patient?.surname,
                displayName: row.resolvedPatientName,
                size: 32,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeltyEllipsisText(
                      text: row.resolvedPatientName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    HeltyEllipsisText(
                      text: row.testName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 92,
                child: HeltyEllipsisChip(
                  label: statusLabel,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  row.amount.toFinancial(isMoney: true),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (showSample)
                Text(
                  _sampleLabel(row.sampleCollected),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              if (showPriority) ...[
                const SizedBox(width: 8),
                Text(
                  row.priority ?? '—',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          if (row.createdAt != null) ...[
            const SizedBox(height: 4),
            Text(
              DateFormatter.dateTime(row.createdAt!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _sampleLabel(bool? collected) {
  if (collected == true) return 'Collected';
  if (collected == false) return 'Pending';
  return '—';
}

String _investigationStatusLabel(String status) {
  final parts = status
      .trim()
      .replaceAll('_', ' ')
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '—';
  return parts
      .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
      .join(' ');
}

Color _investigationStatusColor(String status) {
  final n = status.trim().toLowerCase().replaceAll('_', ' ');
  return switch (n) {
    'pending' => LabClinicalUi.iconAmber,
    'sample collected' ||
    'samplecollected' ||
    'collected' => LabClinicalUi.iconBlue,
    'processing' => LabClinicalUi.iconIndigo,
    'completed' => LabClinicalUi.iconTeal,
    'verified' => LabClinicalUi.iconGreen,
    _ => const Color(0xFF64748B),
  };
}
