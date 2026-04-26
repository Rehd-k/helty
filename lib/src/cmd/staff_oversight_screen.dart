import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cmd_breakpoints.dart';
import 'cmd_providers.dart';
import 'models/cmd_models.dart';
import 'widgets/cmd_async_scaffold.dart';
import 'widgets/cmd_data_table_box.dart';

@RoutePage()
class CMDStaffOversightScreen extends ConsumerWidget {
  const CMDStaffOversightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmdStaffOversightProvider);
    return CmdAsyncScaffold<CmdStaffOversight>(
      title: 'Staff oversight',
      subtitle: 'Attendance, staffing levels, and performance (aggregate)',
      asyncValue: async,
      builder: (context, data) {
        final a = data.attendance;
        return LayoutBuilder(
          builder: (context, c) {
            final bp = CmdBreakpoints.fromWidth(c.maxWidth);
            final chipW = bp.isMobile
                ? ((c.maxWidth - 16) / 2).clamp(120.0, 200.0)
                : 160.0;
            return SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _StatChip(
                        label: 'On duty',
                        value: '${a.onDuty}',
                        icon: Icons.badge_outlined,
                        width: chipW,
                      ),
                      _StatChip(
                        label: 'Scheduled',
                        value: '${a.scheduled}',
                        icon: Icons.calendar_today_outlined,
                        width: chipW,
                      ),
                      _StatChip(
                        label: 'Late',
                        value: '${a.late}',
                        icon: Icons.schedule_outlined,
                        width: chipW,
                      ),
                      _StatChip(
                        label: 'Absent',
                        value: '${a.absent}',
                        icon: Icons.person_off_outlined,
                        width: chipW,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (data.alerts.isNotEmpty) ...[
                    Text(
                      'Staffing alerts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...data.alerts.map(
                      (e) => Card(
                        color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.35),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.warning_amber_rounded),
                          title: Text(e.message),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    'Department staffing',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _StaffingTable(rows: data.byDepartment),
                  const SizedBox(height: 28),
                  Text(
                    'Performance (sample teams)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _PerfTable(rows: data.performance),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.width,
  });

  final String label;
  final String value;
  final IconData icon;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffingTable extends StatelessWidget {
  const _StaffingTable({required this.rows});

  final List<CmdDepartmentStaffing> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: CmdDataTableBox(
        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 560,
          columns: const [
            DataColumn2(label: Text('Department'), size: ColumnSize.L),
            DataColumn2(label: Text('Required'), numeric: true),
            DataColumn2(label: Text('Present'), numeric: true),
            DataColumn2(label: Text('Gap'), numeric: true),
          ],
          rows: [
            for (final r in rows)
              DataRow2(
                cells: [
                  DataCell(Text(r.department)),
                  DataCell(Text('${r.requiredHeadcount}')),
                  DataCell(Text('${r.present}')),
                  DataCell(
                    Text(
                      '${r.gap}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: r.gap > 0 ? theme.colorScheme.error : Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PerfTable extends StatelessWidget {
  const _PerfTable({required this.rows});

  final List<CmdStaffPerformanceRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: CmdDataTableBox(
        heightFactor: 0.34,
        minHeight: 220,
        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 560,
          columns: const [
            DataColumn2(label: Text('Role'), size: ColumnSize.S),
            DataColumn2(label: Text('Team / pool'), size: ColumnSize.L),
            DataColumn2(label: Text('Patients'), numeric: true),
            DataColumn2(label: Text('Efficiency'), numeric: true),
          ],
          rows: [
            for (final r in rows)
              DataRow2(
                cells: [
                  DataCell(Text(r.role)),
                  DataCell(Text(r.nameOrTeam)),
                  DataCell(Text('${r.patientsHandled}')),
                  DataCell(Text(r.efficiencyScore.toStringAsFixed(2))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
