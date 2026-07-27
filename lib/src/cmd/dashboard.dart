import 'package:auto_route/auto_route.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/cmac/cmac_palette.dart';
import 'package:helty/src/cmac/widgets/cmac_vibrant_backdrop.dart';

import 'cmd_breakpoints.dart';
import 'cmd_money_format.dart';
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
        body: CmacVibrantBackdrop(
          colors: CmacPalette.operations,
          child: Column(
            children: [
              AppBar(
                title: const Text('CMD Executive Dashboard'),
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
              ),
              const Expanded(child: Center(child: _PulseLoader())),
            ],
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        body: CmacVibrantBackdrop(
          colors: CmacPalette.operations,
          child: Column(
            children: [
              AppBar(
                title: const Text('CMD Executive Dashboard'),
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SelectableText(
                      'Error: $e',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (bundle) => _buildDashboardScaffold(context, bundle),
    );
  }

  Widget _buildDashboardScaffold(
    BuildContext context,
    CmdExecutiveDashboardBundle bundle,
  ) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    final cs = theme.colorScheme;

    return Scaffold(
      body: CmacVibrantBackdrop(
        colors: CmacPalette.operations,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              stretch: true,
              automaticallyImplyLeading: false,
              expandedHeight: 108,
              backgroundColor: cs.surface,
              surfaceTintColor: cs.surfaceTint,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Command Center',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      'Executive overview · live',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                background: ColoredBox(color: cs.surface),
              ),
              actions: [
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: cs.primaryContainer.withValues(
                      alpha: dark ? 0.55 : 0.9,
                    ),
                  ),
                  onPressed: () {},
                  icon: Badge(
                    backgroundColor: cs.secondary,
                    smallSize: 7,
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: cs.secondary,
                    child: Text(
                      'C',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: cs.onSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bp = CmdBreakpoints.fromWidth(constraints.maxWidth);
                  final isDesktop = bp.isDesktop;
                  final double horizontalPadding = isDesktop ? 32.0 : 16.0;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      8,
                      horizontalPadding,
                      40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroStrip(context, narrow: bp.isMobile),
                        const SizedBox(height: 24),
                        _buildSectionTitle(
                          context,
                          'Alerts & risk panel',
                          Icons.shield_moon_rounded,
                          CmacPalette.quality.first,
                        ),
                        const SizedBox(height: 16),
                        _buildAlertsSection(context, bundle.alerts),
                        const SizedBox(height: 24),
                        _buildSectionTitle(
                          context,
                          'Live activity feed',
                          Icons.bolt_rounded,
                          CmacPalette.overview.first,
                        ),
                        const SizedBox(height: 16),
                        _buildActivityFeed(context, bundle.activityFeed),
                        const SizedBox(height: 24),
                        _buildSectionTitle(
                          context,
                          'Executive summary',
                          Icons.insights_rounded,
                          CmacPalette.insights.first,
                        ),
                        const SizedBox(height: 16),
                        _buildExecutiveSummary(
                          context,
                          bp,
                          bundle.kpis,
                        ),
                        const SizedBox(height: 24),
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildFinancialOverview(context, bundle),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildCapacityManagement(
                                  context,
                                  bundle.capacity,
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _buildFinancialOverview(context, bundle),
                              const SizedBox(height: 20),
                              _buildCapacityManagement(
                                context,
                                bundle.capacity,
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildClinicalPerformance(
                                  context,
                                  bundle.clinical,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildStaffOverview(
                                  context,
                                  bundle.staff,
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _buildClinicalPerformance(
                                context,
                                bundle.clinical,
                              ),
                              const SizedBox(height: 20),
                              _buildStaffOverview(context, bundle.staff),
                            ],
                          ),
                        const SizedBox(height: 24),
                        _buildPharmacyAndLabSection(
                          context,
                          isDesktop,
                          bundle.pharmacy,
                          bundle.lab,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStrip(BuildContext context, {required bool narrow}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final now = DateFormatter.medicalDate(DateTime.now());
    final dateChip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: cs.onSecondary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.onSecondary.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            narrow ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Icon(
            Icons.calendar_month_rounded,
            color: cs.onSecondary,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            now,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hospital pulse',
          style: theme.textTheme.labelLarge?.copyWith(
            color: cs.onPrimary.withValues(alpha: 0.92),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'One glance at operations, capacity, and clinical signal.',
          style: theme.textTheme.titleMedium?.copyWith(
            color: cs.onPrimary,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
      ],
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cs.primary, cs.secondary],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    copy,
                    const SizedBox(height: 14),
                    dateChip,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: copy),
                    const SizedBox(width: 12),
                    dateChip,
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    IconData icon,
    Color accent,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                height: 3,
                width: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.3)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityFeed(
    BuildContext context,
    List<CmdActivityFeedItem> items,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: i.isEven ? cs.primary : cs.secondary,
                child: Text(
                  items[i].category.isNotEmpty
                      ? items[i].category.substring(0, 1).toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: i.isEven ? cs.onPrimary : cs.onSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              title: Text(
                items[i].message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FeedChip(
                      icon: Icons.schedule_rounded,
                      label: DateFormatter.timeOnly(items[i].at),
                      color: cs.primary,
                    ),
                    _FeedChip(
                      icon: Icons.person_outline_rounded,
                      label: items[i].actorLabel,
                      color: cs.secondary,
                    ),
                    _FeedChip(
                      icon: Icons.label_outline_rounded,
                      label: items[i].category,
                      color: cs.primary,
                    ),
                  ],
                ),
              ),
            ),
            if (i < items.length - 1)
              Divider(
                height: 1,
                indent: 72,
                color: cs.outlineVariant.withValues(alpha: 0.45),
              ),
          ],
        ],
      ),
    );
  }

  // 1️⃣ Executive Summary
  Widget _buildExecutiveSummary(
    BuildContext context,
    CmdBreakpoints bp,
    List<CmdKpiTile> kpis,
  ) {
    final crossAxisCount = bp.kpiCrossAxisCount();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: bp.kpiChildAspectRatio(),
      ),
      itemCount: kpis.length,
      itemBuilder: (context, index) {
        return _KPICard(kpi: kpis[index], index: index);
      },
    );
  }

  Widget _buildAlertsSection(BuildContext context, List<CmdAlertChip> alerts) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: alerts.map((alert) {
        final isCrit = alert.level == 'critical';
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            color: isCrit
                ? cs.errorContainer.withValues(alpha: 0.45)
                : cs.surfaceContainer,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isCrit
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline_rounded,
                    color: isCrit ? cs.error : cs.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      alert.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: isCrit ? cs.onErrorContainer : cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFinancialOverview(
    BuildContext context,
    CmdExecutiveDashboardBundle bundle,
  ) {
    final theme = Theme.of(context);
    final series = bundle.revenueWeek;
    var maxY = 48.0;
    if (series.isNotEmpty) {
      maxY =
          series
              .map(
                (e) => e.revenueInpatient > e.revenueOutpatient
                    ? e.revenueInpatient
                    : e.revenueOutpatient,
              )
              .reduce((a, b) => a > b ? a : b) *
          1.08 /
          1000;
      if (maxY < 8) maxY = 8;
    }

    final nairaCompact = cmdNairaCompactFormat();
    return _DashboardCard(
      title: 'Revenue analytics (this week · ₦ thousands)',
      accent: theme.colorScheme.primary,
      icon: Icons.show_chart_rounded,
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
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  getTitlesWidget: (value, meta) {
                    final major = value * 1000;
                    final label = nairaCompact.format(major);
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        label,
                        style: theme.textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
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
                  for (final p in series)
                    FlSpot(p.dayIndex.toDouble(), p.revenueInpatient / 1000),
                ],
                isCurved: true,
                color: theme.colorScheme.primary,
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.32),
                      theme.colorScheme.primary.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
              LineChartBarData(
                spots: [
                  for (final p in series)
                    FlSpot(p.dayIndex.toDouble(), p.revenueOutpatient / 1000),
                ],
                isCurved: true,
                color: theme.colorScheme.secondary,
                barWidth: 3.5,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.secondary.withValues(alpha: 0.26),
                      theme.colorScheme.secondary.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapacityManagement(
    BuildContext context,
    CmdCapacitySnapshot cap,
  ) {
    final theme = Theme.of(context);
    final avail = cap.totalBeds - cap.occupiedBeds;

    return _DashboardCard(
      title: 'Capacity management',
      accent: theme.colorScheme.secondary,
      icon: Icons.pie_chart_outline_rounded,
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
                          radius: 22,
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: theme.colorScheme.secondary,
                          value: cap.icuPercent,
                          title: 'ICU',
                          radius: 26,
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: Color.lerp(
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                            0.5,
                          )!,
                          value: cap.maternityPercent,
                          title: 'Mat',
                          radius: 22,
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${cap.occupancyPercent.toStringAsFixed(0)}%\nocc.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
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
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 12),
                  _CapacityIndicator(
                    title: 'ER load',
                    value: cap.erLoadLabel,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalPerformance(
    BuildContext context,
    CmdClinicalPerformance c,
  ) {
    return _DashboardCard(
      title: 'Clinical performance',
      accent: Theme.of(context).colorScheme.primary,
      icon: Icons.favorite_outline_rounded,
      child: Column(
        children: [
          _PerformanceRow(
            label: 'Surgery success rate',
            percentage: c.surgerySuccessRate,
          ),
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
          _PerformanceRow(
            label: 'Patient satisfaction',
            percentage: c.patientSatisfaction,
          ),
        ],
      ),
    );
  }

  Widget _buildStaffOverview(BuildContext context, CmdStaffDutySnapshot staff) {
    final theme = Theme.of(context);
    return _DashboardCard(
      title: 'Staff overview',
      accent: theme.colorScheme.secondary,
      icon: Icons.groups_2_rounded,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StaffMetricBox(
                title: 'Doctors on duty',
                count: '${staff.doctorsOnDuty}',
                icon: Icons.medical_services_rounded,
                a: theme.colorScheme.primary,
                b: theme.colorScheme.secondary,
              ),
              _StaffMetricBox(
                title: 'Nurses on duty',
                count: '${staff.nursesOnDuty}',
                icon: Icons.local_hospital_rounded,
                a: theme.colorScheme.secondary,
                b: theme.colorScheme.primary,
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
                  color: theme.colorScheme.secondary,
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
      accent: theme.colorScheme.primary,
      icon: Icons.medication_liquid_rounded,
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
            title: const Text('Low stock alerts'),
            trailing: Text(
              '${pharmacy.lowStockCount} items',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Icon(
                Icons.date_range,
                color: theme.colorScheme.secondary,
                size: 18,
              ),
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
              child: Icon(
                Icons.trending_up,
                color: theme.colorScheme.secondary,
                size: 18,
              ),
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
      accent: theme.colorScheme.secondary,
      icon: Icons.biotech_rounded,
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
                color: Color.lerp(
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                  0.5,
                )!,
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
  final int index;

  const _KPICard({required this.kpi, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final trendColor = switch (kpi.direction) {
      CmdTrendDirection.up => CmacPalette.trendColor(isPositive: true),
      CmdTrendDirection.down => CmacPalette.trendColor(isPositive: false),
      CmdTrendDirection.flat => cs.onSurfaceVariant,
    };
    final accent = index.isEven ? cs.primary : cs.secondary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(color: accent, child: const SizedBox(width: 4)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          _cmdIconFromKey(kpi.iconKey),
                          color: accent,
                          size: 24,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: trendColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            kpi.trendLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: trendColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      kpi.value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      kpi.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
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
  final Color accent;
  final IconData icon;

  const _DashboardCard({
    required this.title,
    required this.child,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: accent,
            child: const SizedBox(height: 4, width: double.infinity),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(icon, color: accent, size: 22),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                child,
              ],
            ),
          ),
        ],
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
    final cs = theme.colorScheme;
    final ok = isReversed ? percentage <= 0.1 : percentage > 0.8;
    final Color a = ok ? cs.primary : cs.secondary;
    final Color b = ok ? cs.secondary : cs.primary;
    final v = percentage.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: a,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.85),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: v,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [a, b]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StaffMetricBox extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color a;
  final Color b;

  const _StaffMetricBox({
    required this.title,
    required this.count,
    required this.icon,
    required this.a,
    required this.b,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: b, size: 26),
              const SizedBox(height: 16),
              Text(
                count,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Text(
                value,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseLoader extends StatefulWidget {
  const _PulseLoader();

  @override
  State<_PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<_PulseLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Transform.scale(
                  scale: 0.65 + ((_c.value + i * 0.15) % 1.0) * 0.55,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i.isEven ? cs.primary : cs.secondary,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.25),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FeedChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeedChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
