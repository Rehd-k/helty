import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

@RoutePage()
class NursesDashboardScreen extends StatefulWidget {
  const NursesDashboardScreen({super.key});

  @override
  State<NursesDashboardScreen> createState() => _NursesDashboardScreenState();
}

class _NursesDashboardScreenState extends State<NursesDashboardScreen> {
  String _timeRange = 'Today';

  // Mock Data for Staff on Duty
  final List<Map<String, dynamic>> _activeStaff = [
    {
      'name': 'Dr. Alan Grant',
      'role': 'Head of Cardiology',
      'status': 'In Surgery',
      'color': Colors.red,
    },
    {
      'name': 'Dr. Emily Stone',
      'role': 'Orthopedics',
      'status': 'Consulting',
      'color': Colors.green,
    },
    {
      'name': 'Sarah Jenkins',
      'role': 'Front Desk Lead',
      'status': 'Active',
      'color': Colors.green,
    },
    {
      'name': 'Nurse Michael',
      'role': 'ICU Ward',
      'status': 'On Break',
      'color': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hospital Overview",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Welcome back, Admin. Here's what's happening today.",
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _timeRange,
                          icon: Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          items:
                              [
                                    'Today',
                                    'Last 7 Days',
                                    'This Month',
                                    'This Year',
                                  ]
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 8.0,
                                        ),
                                        child: Text(e),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) => setState(() => _timeRange = val!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      child: Icon(Icons.person, color: colorScheme.primary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- 2. KPI CARDS ---
            Row(
              children: [
                _buildMetricCard(
                  "Total Patients",
                  "1,248",
                  "+12%",
                  Icons.people_alt,
                  Colors.blue,
                  colorScheme,
                ),
                const SizedBox(width: 16),
                _buildMetricCard(
                  "Bed Occupancy",
                  "84%",
                  "+2%",
                  Icons.bed,
                  Colors.orange,
                  colorScheme,
                  isProgress: true,
                  progressValue: 0.84,
                ),
                const SizedBox(width: 16),
                _buildMetricCard(
                  "Active Staff",
                  "142",
                  "Optimal",
                  Icons.medical_information,
                  Colors.green,
                  colorScheme,
                  isTextStatus: true,
                ),
                const SizedBox(width: 16),
                _buildMetricCard(
                  "Avg. Wait Time",
                  "18m",
                  "-4m",
                  Icons.timer,
                  Colors.purple,
                  colorScheme,
                  isGoodNegative: true,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- 3. MAIN DASHBOARD CONTENT ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column (Charts - Flex 2)
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      // Line Chart: Patient Influx
                      Container(
                        height: 400,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Patient Admissions vs Discharges",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      "Les admissions",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    _buildLegendIndicator(
                                      colorScheme.primary,
                                      "Admissions",
                                    ),
                                    const SizedBox(width: 16),
                                    _buildLegendIndicator(
                                      Colors.orange,
                                      "Discharges",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Expanded(
                              child: _buildPatientInfluxChart(colorScheme),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Bar Chart: Department Load
                      Container(
                        height: 300,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Department Load (Patients)",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: _buildDepartmentBarChart(colorScheme),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Right Column (Side Panel - Flex 1)
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Active Staff Widget
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Staff on Duty",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  "View All",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),
                            ..._activeStaff.map(
                              (staff) => Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: colorScheme.primary
                                          .withValues(alpha: 0.1),
                                      child: Text(
                                        staff['name'].substring(0, 1),
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            staff['name'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          Text(
                                            staff['role'],
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: staff['color'].withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        staff['status'],
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: staff['color'],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.assignment_ind,
                                  size: 16,
                                ),
                                label: const Text("Manage Roster"),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Critical Alerts Widget
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_rounded,
                                  color: Colors.red[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Critical Alerts",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildAlertItem(
                              "ICU Ward",
                              "Approaching max capacity (92%)",
                              "10m ago",
                              Colors.red,
                            ),
                            const Divider(height: 24),
                            _buildAlertItem(
                              "Pharmacy",
                              "Low stock on Amoxicillin",
                              "1h ago",
                              Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- REUSABLE COMPONENTS ---

  Widget _buildMetricCard(
    String title,
    String value,
    String change,
    IconData icon,
    Color color,
    ColorScheme colorScheme, {
    bool isProgress = false,
    double progressValue = 0,
    bool isTextStatus = false,
    bool isGoodNegative = false,
  }) {
    final bool isPositive = change.startsWith('+') || change == 'Optimal';
    final Color trendColor =
        (isPositive && !isGoodNegative) || (!isPositive && isGoodNegative)
        ? Colors.green
        : (isTextStatus && isPositive ? Colors.green : Colors.red);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (isProgress)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: progressValue,
                          backgroundColor: colorScheme.outline.withValues(
                            alpha: 0.1,
                          ),
                          color: color,
                          strokeWidth: 4,
                        ),
                        Center(
                          child: Text(
                            "${(progressValue * 100).toInt()}%",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: trendColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        if (!isTextStatus)
                          Icon(
                            isPositive
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 12,
                            color: trendColor,
                          ),
                        if (!isTextStatus) const SizedBox(width: 4),
                        Text(
                          change,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: trendColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendIndicator(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertItem(
    String location,
    String message,
    String time,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red[700]?.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[700]?.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- CHARTS ---

  Widget _buildPatientInfluxChart(ColorScheme colorScheme) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outline.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                const style = TextStyle(color: Colors.grey, fontSize: 11);
                Widget text;
                switch (value.toInt()) {
                  case 0:
                    text = const Text('Mon', style: style);
                    break;
                  case 1:
                    text = const Text('Tue', style: style);
                    break;
                  case 2:
                    text = const Text('Wed', style: style);
                    break;
                  case 3:
                    text = const Text('Thu', style: style);
                    break;
                  case 4:
                    text = const Text('Fri', style: style);
                    break;
                  case 5:
                    text = const Text('Sat', style: style);
                    break;
                  case 6:
                    text = const Text('Sun', style: style);
                    break;
                  default:
                    text = const Text('', style: style);
                    break;
                }
                return SideTitleWidget(meta: meta, child: text);
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          // Admissions
          LineChartBarData(
            spots: const [
              FlSpot(0, 40),
              FlSpot(1, 60),
              FlSpot(2, 50),
              FlSpot(3, 80),
              FlSpot(4, 75),
              FlSpot(5, 45),
              FlSpot(6, 50),
            ],
            isCurved: true,
            color: colorScheme.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          // Discharges
          LineChartBarData(
            spots: const [
              FlSpot(0, 30),
              FlSpot(1, 45),
              FlSpot(2, 60),
              FlSpot(3, 50),
              FlSpot(4, 65),
              FlSpot(5, 55),
              FlSpot(6, 40),
            ],
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentBarChart(ColorScheme colorScheme) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                const style = TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                );
                String text = '';
                switch (value.toInt()) {
                  case 0:
                    text = 'Cardio';
                    break;
                  case 1:
                    text = 'Ortho';
                    break;
                  case 2:
                    text = 'ICU';
                    break;
                  case 3:
                    text = 'Gen';
                    break;
                  case 4:
                    text = 'Pediatrics';
                    break;
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(text, style: style),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          _makeBarGroup(0, 85, colorScheme.primary),
          _makeBarGroup(1, 45, colorScheme.secondary),
          _makeBarGroup(2, 95, Colors.red[400]!),
          _makeBarGroup(3, 60, Colors.blue[300]!),
          _makeBarGroup(4, 30, Colors.orange[300]!),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: color.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }
}
