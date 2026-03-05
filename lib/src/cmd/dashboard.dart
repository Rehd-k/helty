import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

@RoutePage()
class CMDDashboardScreen extends StatelessWidget {
  const CMDDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  _buildSectionTitle(context, 'Alerts & Risk Panel'),
                  const SizedBox(height: 16),
                  _buildAlertsSection(context),

                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Executive Summary'),
                  const SizedBox(height: 16),
                  _buildExecutiveSummary(context, isDesktop, isTablet),

                  const SizedBox(height: 32),
                  // Charts Row
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildFinancialOverview(context)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildCapacityManagement(context)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildFinancialOverview(context),
                        const SizedBox(height: 24),
                        _buildCapacityManagement(context),
                      ],
                    ),

                  const SizedBox(height: 32),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildClinicalPerformance(context)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildStaffOverview(context)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildClinicalPerformance(context),
                        const SizedBox(height: 24),
                        _buildStaffOverview(context),
                      ],
                    ),

                  const SizedBox(height: 32),
                  _buildPharmacyAndLabSection(context, isDesktop),
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

  // 1️⃣ Executive Summary
  Widget _buildExecutiveSummary(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
  ) {
    int crossAxisCount = isDesktop ? 5 : (isTablet ? 3 : 2);

    final kpis = [
      {
        'title': 'Patients Today',
        'value': '1,240',
        'icon': Icons.people_outline,
        'trend': '+5%',
      },
      {
        'title': 'Admissions',
        'value': '85',
        'icon': Icons.login,
        'trend': '+2%',
      },
      {
        'title': 'Bed Occupancy',
        'value': '78%',
        'icon': Icons.bed_outlined,
        'trend': '-1%',
      },
      {
        'title': 'Revenue Today',
        'value': '\$42.5k',
        'icon': Icons.attach_money,
        'trend': '+12%',
      },
      {
        'title': 'Emergencies',
        'value': '142',
        'icon': Icons.warning_amber_rounded,
        'trend': '+8%',
      },
      {
        'title': 'Avg Length Stay',
        'value': '4.2 d',
        'icon': Icons.timer_outlined,
        'trend': '-0.5 d',
      },
      {
        'title': 'Mortality (Mo)',
        'value': '1.2%',
        'icon': Icons.monitor_heart_outlined,
        'trend': '0%',
      },
      {
        'title': 'Outstanding',
        'value': '\$120k',
        'icon': Icons.receipt_long_outlined,
        'trend': '-2%',
      },
    ];

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
        final kpi = kpis[index];
        return _KPICard(
          title: kpi['title'] as String,
          value: kpi['value'] as String,
          icon: kpi['icon'] as IconData,
          trend: kpi['trend'] as String,
        );
      },
    );
  }

  // 6️⃣ Alerts & Risk Panel
  Widget _buildAlertsSection(BuildContext context) {
    final theme = Theme.of(context);
    final alerts = [
      '🔴 ICU at 95% capacity',
      '🔴 Paracetamol stock critically low',
      '🔴 High surgical infection rate (Ward B)',
      '🔴 MRI Machine under maintenance',
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: alerts.map((alert) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.error.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                alert.replaceAll('🔴 ', ''),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 3️⃣ Financial Overview (Line Chart)
  Widget _buildFinancialOverview(BuildContext context) {
    final theme = Theme.of(context);

    return _DashboardCard(
      title: 'Revenue Analytics (This Week)',
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
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
                    const days = [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
                    ];
                    if (value.toInt() >= 0 && value.toInt() < days.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          days[value.toInt()],
                          style: theme.textTheme.labelSmall,
                        ),
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
                spots: const [
                  FlSpot(0, 30),
                  FlSpot(1, 45),
                  FlSpot(2, 35),
                  FlSpot(3, 50),
                  FlSpot(4, 40),
                  FlSpot(5, 60),
                  FlSpot(6, 55),
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
                spots: const [
                  FlSpot(0, 20),
                  FlSpot(1, 25),
                  FlSpot(2, 22),
                  FlSpot(3, 28),
                  FlSpot(4, 25),
                  FlSpot(5, 30),
                  FlSpot(6, 28),
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

  // 2️⃣ Patient & Capacity Management (Pie Chart / Progress)
  Widget _buildCapacityManagement(BuildContext context) {
    final theme = Theme.of(context);

    return _DashboardCard(
      title: 'Capacity Management',
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
                          value: 65,
                          title: 'Gen Ward',
                          radius: 20,
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: theme.colorScheme.error,
                          value: 20,
                          title: 'ICU',
                          radius: 25, // Pop out ICU
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: theme.colorScheme.secondary,
                          value: 15,
                          title: 'Maternity',
                          radius: 20,
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '78%\nFull',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                    title: 'Total Beds',
                    value: '500',
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(height: 12),
                  _CapacityIndicator(
                    title: 'Available',
                    value: '110',
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  _CapacityIndicator(
                    title: 'ICU Load',
                    value: '95%',
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  _CapacityIndicator(
                    title: 'ER Load',
                    value: 'High',
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

  // 4️⃣ Clinical Performance Metrics
  Widget _buildClinicalPerformance(BuildContext context) {
    return _DashboardCard(
      title: 'Clinical Performance',
      child: Column(
        children: [
          _PerformanceRow(label: 'Surgery Success Rate', percentage: 0.98),
          const SizedBox(height: 16),
          _PerformanceRow(
            label: 'Readmission Rate (30d)',
            percentage: 0.12,
            isReversed: true,
          ),
          const SizedBox(height: 16),
          _PerformanceRow(
            label: 'Infection Rate',
            percentage: 0.04,
            isReversed: true,
          ),
          const SizedBox(height: 16),
          _PerformanceRow(label: 'Patient Satisfaction', percentage: 0.88),
        ],
      ),
    );
  }

  // 5️⃣ Staff Overview
  Widget _buildStaffOverview(BuildContext context) {
    final theme = Theme.of(context);
    return _DashboardCard(
      title: 'Staff Overview',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StaffMetricBox(
                title: 'Doctors On Duty',
                count: '42',
                icon: Icons.medical_services_outlined,
              ),
              _StaffMetricBox(
                title: 'Nurses On Duty',
                count: '128',
                icon: Icons.local_hospital_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Absenteeism Rate', style: theme.textTheme.bodyMedium),
              Text(
                '3.2%',
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
              Text('Overtime Hours (Week)', style: theme.textTheme.bodyMedium),
              Text(
                '450 hrs',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 7 & 8 ️⃣ Pharmacy & Lab
  Widget _buildPharmacyAndLabSection(BuildContext context, bool isDesktop) {
    return isDesktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPharmacy(context)),
              const SizedBox(width: 24),
              Expanded(child: _buildLab(context)),
            ],
          )
        : Column(
            children: [
              _buildPharmacy(context),
              const SizedBox(height: 24),
              _buildLab(context),
            ],
          );
  }

  Widget _buildPharmacy(BuildContext context) {
    final theme = Theme.of(context);
    return _DashboardCard(
      title: 'Pharmacy & Inventory Snapshot',
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.errorContainer,
              child: Icon(
                Icons.warning,
                color: theme.colorScheme.error,
                size: 18,
              ),
            ),
            title: const Text('Low Stock Alerts'),
            trailing: const Text(
              '14 Items',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.tertiaryContainer,
              child: Icon(
                Icons.date_range,
                color: theme.colorScheme.tertiary,
                size: 18,
              ),
            ),
            title: const Text('Expiring within 30 days'),
            trailing: const Text(
              '5 Batches',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Icon(
                Icons.trending_up,
                color: theme.colorScheme.secondary,
                size: 18,
              ),
            ),
            title: const Text('Top Dispensed'),
            subtitle: const Text('Amoxicillin, Paracetamol, Metformin'),
          ),
        ],
      ),
    );
  }

  Widget _buildLab(BuildContext context) {
    final theme = Theme.of(context);
    return _DashboardCard(
      title: 'Lab & Diagnostics Overview',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _LabStat(
                value: '1,420',
                label: 'Tests Today',
                color: theme.colorScheme.primary,
              ),
              _LabStat(
                value: '85',
                label: 'Pending',
                color: theme.colorScheme.secondary,
              ),
              _LabStat(
                value: '2.5h',
                label: 'Avg TAT',
                color: theme.colorScheme.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Machine Uptime'),
            trailing: Text(
              '99.2%',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Repeated Tests (Quality flag)'),
            trailing: Text(
              '1.8%',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Helper Widgets ---

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String trend;

  const _KPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = trend.startsWith('+');
    final isNeutral = trend == '0%';
    final trendColor = isNeutral
        ? theme.colorScheme.onSurfaceVariant
        : (isPositive ? Colors.green : theme.colorScheme.error);

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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trend,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: trendColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
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
