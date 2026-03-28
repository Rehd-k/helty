import 'package:auto_route/auto_route.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'cmd_providers.dart';
import 'models/cmd_models.dart';

@RoutePage()
class CMDDashboardScreen extends ConsumerWidget {
  const CMDDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncDash = ref.watch(cmdExecutiveDashboardProvider);

    return asyncDash.when(
      loading: () => Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(title: const Text('CMD Executive Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(title: const Text('CMD Executive Dashboard')),
        body: Center(child: SelectableText('Error: $e')),
      ),
      data: (bundle) => _buildDashboardScaffold(context, bundle),
    );
  }

  Widget _buildDashboardScaffold(BuildContext context, CmdExecutiveDashboardBundle bundle) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CMD Executive Dashboard',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Overview',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Badge(
              child: Icon(
                Icons.notifications_outlined,
                color: theme.colorScheme.onSurface,
              ),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              'CMD',
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine layout mode based on width
            final isDesktop = constraints.maxWidth > 1100;
            final isTablet =
                constraints.maxWidth > 650 && constraints.maxWidth <= 1100;
            final double horizontalPadding = isDesktop ? 32.0 : 16.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Alerts & risk panel'),
                  const SizedBox(height: 16),
                  _buildAlertsSection(context, bundle.alerts),

                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Live activity feed'),
                  const SizedBox(height: 16),
                  _buildActivityFeed(context, bundle.activityFeed),

                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Executive summary'),
                  const SizedBox(height: 16),
                  _buildExecutiveSummary(context, isDesktop, isTablet, bundle.kpis),

                  const SizedBox(height: 32),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildFinancialOverview(context, bundle)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildCapacityManagement(context, bundle.capacity)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildFinancialOverview(context, bundle),
                        const SizedBox(height: 24),
                        _buildCapacityManagement(context, bundle.capacity),
                      ],
                    ),

                  const SizedBox(height: 32),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildClinicalPerformance(context, bundle.clinical)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildStaffOverview(context, bundle.staff)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildClinicalPerformance(context, bundle.clinical),
                        const SizedBox(height: 24),
                        _buildStaffOverview(context, bundle.staff),
                      ],
                    ),

                  const SizedBox(height: 32),
                  _buildPharmacyAndLabSection(context, isDesktop, bundle.pharmacy, bundle.lab),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildActivityFeed(BuildContext context, List<CmdActivityFeedItem> items) {
    final theme = Theme.of(context);
    final fmt = DateFormat('HH:mm');
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              dense: true,
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(items[i].category.substring(0, 1)),
              ),
              title: Text(items[i].message, style: theme.textTheme.bodyMedium),
              subtitle: Text('${fmt.format(items[i].at)} · ${items[i].actorLabel} · ${items[i].category}'),
            ),
            if (i < items.length - 1) Divider(height: 1, color: theme.colorScheme.outlineVariant),
          ],
        ],
      ),
    );
  }

  // 1️⃣ Executive Summary
  Widget _buildExecutiveSummary(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
    List<CmdKpiTile> kpis,
  ) {
    final crossAxisCount = isDesktop ? 5 : (isTablet ? 3 : 2);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, index) {
        return _KPICard(kpi: kpis[index]);
      },
    );
  }

  Widget _buildAlertsSection(BuildContext context, List<CmdAlertChip> alerts) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: alerts.map((alert) {
        final isCrit = alert.level == 'critical';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: (isCrit ? theme.colorScheme.errorContainer : theme.colorScheme.tertiaryContainer).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isCrit ? theme.colorScheme.error : theme.colorScheme.tertiary).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: isCrit ? theme.colorScheme.error : theme.colorScheme.tertiary,
                size: 20,
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  alert.message,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFinancialOverview(BuildContext context, CmdExecutiveDashboardBundle bundle) {
    final theme = Theme.of(context);
    final series = bundle.revenueWeek;
    var maxY = 48.0;
    if (series.isNotEmpty) {
      maxY = series
              .map((e) => e.revenueInpatient > e.revenueOutpatient ? e.revenueInpatient : e.revenueOutpatient)
              .reduce((a, b) => a > b ? a : b) *
          1.08 /
          1000;
      if (maxY < 8) maxY = 8;
    }

    return _DashboardCard(
      title: 'Revenue analytics (dummy, this week · \$k)',
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    final i = value.toInt();
                    if (i >= 0 && i < days.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(days[i], style: theme.textTheme.labelSmall),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (final p in series) FlSpot(p.dayIndex.toDouble(), p.revenueInpatient / 1000),
                ],
                isCurved: true,
                color: theme.colorScheme.primary,
                barWidth: 4,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(
                  show: true,
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
              LineChartBarData(
                spots: [
                  for (final p in series) FlSpot(p.dayIndex.toDouble(), p.revenueOutpatient / 1000),
                ],
                isCurved: true,
                color: theme.colorScheme.tertiary,
                barWidth: 3,
                isStrokeCapRound: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapacityManagement(BuildContext context, CmdCapacitySnapshot cap) {
    final theme = Theme.of(context);
    final avail = cap.totalBeds - cap.occupiedBeds;

    return _DashboardCard(
      title: 'Capacity management',
      child: SizedBox(
        height: 250,
        child: Row(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 50,
                      sections: [
                        PieChartSectionData(
                          color: theme.colorScheme.primary,
                          value: cap.generalWardPercent,
                          title: 'Gen',
                          radius: 20,
                          titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: theme.colorScheme.error,
                          value: cap.icuPercent,
                          title: 'ICU',
                          radius: 25,
                          titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: theme.colorScheme.secondary,
                          value: cap.maternityPercent,
                          title: 'Mat',
                          radius: 20,
                          titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${cap.occupancyPercent.toStringAsFixed(0)}%\nocc.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CapacityIndicator(
                    title: 'Total beds',
                    value: '${cap.totalBeds}',
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(height: 12),
                  _CapacityIndicator(
                    title: 'Available',
                    value: '$avail',
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  _CapacityIndicator(
                    title: 'ICU load',
                    value: '${cap.icuLoadPercent.toStringAsFixed(0)}%',
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  _CapacityIndicator(
                    title: 'ER load',
                    value: cap.erLoadLabel,
                    color: theme.colorScheme.tertiary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalPerformance(BuildContext context, CmdClinicalPerformance c) {
    return _DashboardCard(
      title: 'Clinical performance',
      child: Column(
        children: [
          _PerformanceRow(label: 'Surgery success rate', percentage: c.surgerySuccessRate),
          const SizedBox(height: 16),
          _PerformanceRow(
            label: 'Readmission rate (30d)',
            percentage: c.readmission30d,
            isReversed: true,
          ),
          const SizedBox(height: 16),
          _PerformanceRow(
            label: 'Infection rate',
            percentage: c.infectionRate,
            isReversed: true,
          ),
          const SizedBox(height: 16),
          _PerformanceRow(label: 'Patient satisfaction', percentage: c.patientSatisfaction),
        ],
      ),
    );
  }

  Widget _buildStaffOverview(BuildContext context, CmdStaffDutySnapshot staff) {
    final theme = Theme.of(context);
    return _DashboardCard(
      title: 'Staff overview',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StaffMetricBox(
                title: 'Doctors on duty',
                count: '${staff.doctorsOnDuty}',
                icon: Icons.medical_services_outlined,
              ),
              _StaffMetricBox(
                title: 'Nurses on duty',
                count: '${staff.nursesOnDuty}',
                icon: Icons.local_hospital_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Absenteeism rate', style: theme.textTheme.bodyMedium),
              Text(
                '${staff.absenteeismPercent.toStringAsFixed(1)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Overtime hours (week)', style: theme.textTheme.bodyMedium),
              Text(
                '${staff.overtimeHoursWeek} hrs',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyAndLabSection(
    BuildContext context,
    bool isDesktop,
    CmdPharmacySnapshot pharmacy,
    CmdLabSnapshot lab,
  ) {
    return isDesktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPharmacy(context, pharmacy)),
              const SizedBox(width: 24),
              Expanded(child: _buildLab(context, lab)),
            ],
          )
        : Column(
            children: [
              _buildPharmacy(context, pharmacy),
              const SizedBox(height: 24),
              _buildLab(context, lab),
            ],
          );
  }

  Widget _buildPharmacy(BuildContext context, CmdPharmacySnapshot pharmacy) {
    final theme = Theme.of(context);
    return _DashboardCard(
      title: 'Pharmacy & inventory snapshot',
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.errorContainer,
              child: Icon(Icons.warning, color: theme.colorScheme.error, size: 18),
            ),
            title: const Text('Low stock alerts'),
            trailing: Text(
              '${pharmacy.lowStockCount} items',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.tertiaryContainer,
              child: Icon(Icons.date_range, color: theme.colorScheme.tertiary, size: 18),
            ),
            title: const Text('Expiring within 30 days'),
            trailing: Text(
              '${pharmacy.expiringBatches} batches',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Icon(Icons.trending_up, color: theme.colorScheme.secondary, size: 18),
            ),
            title: const Text('Top dispensed'),
            subtitle: Text(pharmacy.topDispensed.join(', ')),
          ),
        ],
      ),
    );
  }

  Widget _buildLab(BuildContext context, CmdLabSnapshot lab) {
    final theme = Theme.of(context);
    return _DashboardCard(
      title: 'Lab & diagnostics overview',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _LabStat(
                value: '${lab.testsToday}',
                label: 'Tests today',
                color: theme.colorScheme.primary,
              ),
              _LabStat(
                value: '${lab.pendingCount}',
                label: 'Pending',
                color: theme.colorScheme.secondary,
              ),
              _LabStat(
                value: '${lab.avgTurnaroundHours.toStringAsFixed(1)}h',
                label: 'Avg TAT',
                color: theme.colorScheme.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Machine uptime'),
            trailing: Text(
              '${lab.machineUptimePercent.toStringAsFixed(1)}%',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Repeated tests (quality flag)'),
            trailing: Text(
              '${lab.redoRatePercent.toStringAsFixed(1)}%',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _cmdIconFromKey(String key) {
  switch (key) {
    case 'people':
      return Icons.people_outline;
    case 'login':
      return Icons.login;
    case 'bed':
      return Icons.bed_outlined;
    case 'money':
      return Icons.attach_money;
    case 'badge':
      return Icons.badge_outlined;
    case 'science':
      return Icons.science_outlined;
    case 'receipt':
      return Icons.receipt_long_outlined;
    case 'emergency':
      return Icons.local_hospital_outlined;
    default:
      return Icons.analytics_outlined;
  }
}

// --- Helper Widgets ---

class _KPICard extends StatelessWidget {
  final CmdKpiTile kpi;

  const _KPICard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trendColor = switch (kpi.direction) {
      CmdTrendDirection.up => Colors.green,
      CmdTrendDirection.down => theme.colorScheme.error,
      CmdTrendDirection.flat => theme.colorScheme.onSurfaceVariant,
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(_cmdIconFromKey(kpi.iconKey), color: theme.colorScheme.primary, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    kpi.trendLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: trendColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              kpi.value,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              kpi.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _DashboardCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class _CapacityIndicator extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _CapacityIndicator({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  final String label;
  final double percentage;
  final bool isReversed; // If true, lower is better (e.g. infection rate)

  const _PerformanceRow({
    required this.label,
    required this.percentage,
    this.isReversed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isReversed
        ? (percentage > 0.1 ? theme.colorScheme.error : Colors.green)
        : (percentage > 0.8 ? Colors.green : theme.colorScheme.error);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: theme.colorScheme.surfaceBright,
          color: color,
          borderRadius: BorderRadius.circular(4),
          minHeight: 8,
        ),
      ],
    );
  }
}

class _StaffMetricBox extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;

  const _StaffMetricBox({
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              count,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _LabStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
