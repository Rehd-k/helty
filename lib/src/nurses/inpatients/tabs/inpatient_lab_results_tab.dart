import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';

@RoutePage()
class InpatientLabResultsScreen extends StatelessWidget {
  const InpatientLabResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final columns = [
      'Date/Time',
      'Test',
      'Result',
      'Units',
      'Reference Range',
      'Status',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Lab Results',
        subtitle: 'Read-only view of investigations',
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: columns
                .map(
                  (c) => DataColumn(
                    label: Text(
                      c,
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                )
                .toList(),
            rows: [
              _row(
                context,
                time: 'Today 10:32',
                test: 'FBC',
                result: 'Normal',
                units: '-',
                range: '-',
                status: 'Normal',
                abnormal: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _row(
    BuildContext context, {
    required String time,
    required String test,
    required String result,
    required String units,
    required String range,
    required String status,
    required bool abnormal,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final statusStyle = TextStyle(
      color: abnormal ? scheme.error : scheme.primary,
      fontWeight: FontWeight.w600,
    );

    return DataRow(
      cells: [
        DataCell(Text(time)),
        DataCell(Text(test)),
        DataCell(
          Text(
            result,
            style: abnormal ? TextStyle(color: scheme.error) : null,
          ),
        ),
        DataCell(Text(units)),
        DataCell(Text(range)),
        DataCell(
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: abnormal
                  ? scheme.error.withValues(alpha: 0.1)
                  : scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.merge(statusStyle),
            ),
          ),
        ),
      ],
    );
  }
}

