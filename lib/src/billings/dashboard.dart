import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/services/api_service.dart';

import 'patient_invoice.dart';

@RoutePage()
class BillingDashboardScreen extends StatefulWidget {
  const BillingDashboardScreen({super.key});

  @override
  State<BillingDashboardScreen> createState() => _BillingDashboardScreenState();
}

class _BillingDashboardScreenState extends State<BillingDashboardScreen> {
  String _selectedPeriod = 'This Month';
  final TextEditingController _transactionSearchController =
      TextEditingController();
  final ApiService apiService = ApiService();
  final TextEditingController firstName = TextEditingController();
  final TextEditingController surname = TextEditingController();
  final TextEditingController age = TextEditingController();
  final TextEditingController gender = TextEditingController();

  void createNewPatient() async {
    try {
      var res = await apiService.dio.post(
        '/no-id-patient',
        data: {
          'firstName': firstName.text,
          'surname': surname.text,
          'age': age.text,
          'gender': gender.text,
        },
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Patient created successfully')));
      }
      firstName.clear();
      surname.clear();
      age.clear();
      gender.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Mock Data for Transactions
  final List<Map<String, dynamic>> _transactions = [
    {
      'status': 'Paid',
      'id': 'INV-2023-001',
      'name': 'Sarah Connor',
      'initials': 'SC',
      'date': 'Oct 24, 2023',
      'amount': 1250,
      'color': Colors.green,
      'selected': false,
    },
    {
      'status': 'Pending',
      'id': 'INV-2023-002',
      'name': 'John Doe',
      'initials': 'JD',
      'date': 'Oct 24, 2023',
      'amount': 3400,
      'color': Colors.orange,
      'selected': false,
    },
    {
      'status': 'Overdue',
      'id': 'INV-2023-003',
      'name': 'Emma Watson',
      'initials': 'EW',
      'date': 'Sep 15, 2023',
      'amount': 850,
      'color': Colors.red,
      'selected': false,
    },
    {
      'status': 'Paid',
      'id': 'INV-2023-004',
      'name': 'Michael Chen',
      'initials': 'MC',
      'date': 'Oct 23, 2023',
      'amount': 450,
      'color': Colors.green,
      'selected': false,
    },
  ];

  @override
  void dispose() {
    _transactionSearchController.dispose();
    firstName.dispose();
    surname.dispose();
    age.dispose();
    gender.dispose();
    super.dispose();
  }

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
            // --- 1. HEADER ROW ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Billing Overview",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 250,
                      height: 40,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search invoices, patients...",
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 18,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          filled: true,
                          fillColor: colorScheme.onSurface.withValues(
                            alpha: 0.03,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {},
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.onSurface.withValues(
                          alpha: 0.03,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- 2. SUB-HEADER (Last Updated & Actions) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "Last updated: ",
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      "Today, 09:41 AM ",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Icon(Icons.refresh, size: 14, color: colorScheme.primary),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPeriod,
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface,
                          ),
                          items:
                              [
                                    'Today',
                                    'This Week',
                                    'This Month',
                                    'Last Quarter',
                                    'This Year',
                                  ]
                                  .map(
                                    (period) => DropdownMenuItem(
                                      value: period,
                                      child: Text(period),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedPeriod = val!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => showNewPatientInvoiceForm(
                        context,
                        firstName,
                        surname,
                        age,
                        gender,
                        createNewPatient,
                      ),
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "New Patient",
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            colorScheme.primary, // Often Blue in these designs
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- 3. KPI CARDS ---
            Row(
              children: [
                _buildKpiCard(
                  context,
                  "Total Revenue Today",
                  124500.toFinancial(isMoney: true),
                  "+ 12.5%",
                  "vs yesterday",
                  Icons.payments,
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _buildKpiCard(
                  context,
                  "Unpaid Invoices",
                  42.toFinancial(isMoney: false),
                  "+ 5.2%",
                  "increase",
                  Icons.receipt_long,
                  Colors.orange,
                  subtitleExtra: "(\$45.2k)",
                ),
                const SizedBox(width: 16),
                _buildKpiCard(
                  context,
                  "Pending Insurance",
                  18.toFinancial(isMoney: false),
                  "- 2.4%",
                  "decrease",
                  Icons.shield,
                  Colors.blue,
                  isNegativeGood: true,
                ),
                const SizedBox(width: 16),
                // Added Value KPI for Department Head
                _buildKpiCard(
                  context,
                  "Overdue Accounts (>30d)",
                  18400.toFinancial(isMoney: true),
                  "+ 1.2%",
                  "vs last month",
                  Icons.warning_amber_rounded,
                  Colors.red,
                  isNegativeGood: false,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- 4. CHARTS SECTION ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Revenue Trends Line Chart
                Expanded(
                  flex: 5,
                  child: Container(
                    height: 380,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
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
                                  "Revenue Trends",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Last 30 Days",
                                  style: TextStyle(
                                    fontSize: 12,
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
                                  "Revenue",
                                ),
                                const SizedBox(width: 16),
                                _buildLegendIndicator(
                                  colorScheme.onSurface.withValues(alpha: 0.2),
                                  "Projected",
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Expanded(
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 1,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.1,
                                  ),
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
                                    getTitlesWidget: (value, meta) {
                                      const style = TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      );
                                      Widget text;
                                      switch (value.toInt()) {
                                        case 0:
                                          text = const Text(
                                            '1 Nov',
                                            style: style,
                                          );
                                          break;
                                        case 2:
                                          text = const Text(
                                            '7 Nov',
                                            style: style,
                                          );
                                          break;
                                        case 4:
                                          text = const Text(
                                            '14 Nov',
                                            style: style,
                                          );
                                          break;
                                        case 6:
                                          text = const Text(
                                            '21 Nov',
                                            style: style,
                                          );
                                          break;
                                        case 8:
                                          text = const Text(
                                            '28 Nov',
                                            style: style,
                                          );
                                          break;
                                        default:
                                          text = const Text('', style: style);
                                          break;
                                      }
                                      return SideTitleWidget(
                                        meta: meta,
                                        child: text,
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    reservedSize: 42,
                                    getTitlesWidget: (value, meta) {
                                      if (value == 0) {
                                        return const SizedBox.shrink();
                                      }
                                      return Text(
                                        '${(value * 20).toInt()}k',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: 8,
                              minY: 0,
                              maxY: 6,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: const [
                                    FlSpot(0, 1.5),
                                    FlSpot(1, 1.0),
                                    FlSpot(2, 2.5),
                                    FlSpot(3, 2.0),
                                    FlSpot(4, 3.8),
                                    FlSpot(5, 2.8),
                                    FlSpot(6, 4.2),
                                    FlSpot(7, 5.0),
                                    FlSpot(8, 4.5),
                                  ],
                                  isCurved: true,
                                  color: colorScheme.primary,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),

                // Revenue by Dept Pie Chart
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 380,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Revenue by Dept",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Distribution across key units",
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(enabled: true),
                                  borderData: FlBorderData(show: false),
                                  sectionsSpace: 0,
                                  centerSpaceRadius: 60,
                                  sections: [
                                    PieChartSectionData(
                                      color: Colors.blue[600],
                                      value: 40,
                                      title: '',
                                      radius: 35,
                                    ),
                                    PieChartSectionData(
                                      color: Colors.blue[400],
                                      value: 25,
                                      title: '',
                                      radius: 35,
                                    ),
                                    PieChartSectionData(
                                      color: Colors.blue[200],
                                      value: 20,
                                      title: '',
                                      radius: 35,
                                    ),
                                    PieChartSectionData(
                                      color: Colors.grey[300],
                                      value: 15,
                                      title: '',
                                      radius: 35,
                                    ),
                                  ],
                                ),
                              ),
                              // Center Text
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Total",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "850k",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Custom Legend for Pie Chart
                        Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildLegendIndicator(
                              Colors.blue[600]!,
                              "Surgery (40%)",
                            ),
                            _buildLegendIndicator(
                              Colors.blue[400]!,
                              "ICU (25%)",
                            ),
                            _buildLegendIndicator(
                              Colors.blue[200]!,
                              "Gen Ward (20%)",
                            ),
                            _buildLegendIndicator(
                              Colors.grey[300]!,
                              "Other (15%)",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- 5. RECENT TRANSACTIONS TABLE ---
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Table Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Recent Transactions",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(
                          width: 200,
                          height: 36,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Filter transactions...",
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),

                  // Table Column Headers
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    color: colorScheme.onSurface.withValues(alpha: 0.01),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 40,
                          child: Icon(
                            Icons.check_box_outline_blank,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "STATUS",
                            style: _tableHeaderStyle(colorScheme),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "INVOICE ID",
                            style: _tableHeaderStyle(colorScheme),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            "PATIENT NAME",
                            style: _tableHeaderStyle(colorScheme),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "DATE",
                            style: _tableHeaderStyle(colorScheme),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "AMOUNT",
                            style: _tableHeaderStyle(colorScheme),
                          ),
                        ),
                        const SizedBox(
                          width: 40,
                          child: Text(
                            "ACTION",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),

                  // Table Rows
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _transactions.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: colorScheme.outline.withValues(alpha: 0.05),
                    ),
                    itemBuilder: (context, index) {
                      final txn = _transactions[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Checkbox(
                                value: txn['selected'],
                                onChanged: (val) {
                                  setState(() => txn['selected'] = val);
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: txn['color'].withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: txn['color'],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        txn['status'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: txn['color'],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                txn['id'],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    child: Text(
                                      txn['initials'],
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    txn['name'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                txn['date'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                (txn['amount'] as num).toFinancial(
                                  isMoney: true,
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: IconButton(
                                icon: const Icon(Icons.more_vert, size: 18),
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildKpiCard(
    BuildContext context,
    String title,
    String value,
    String percent,
    String vsText,
    IconData icon,
    Color color, {
    String? subtitleExtra,
    bool isNegativeGood = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isIncrease = percent.startsWith('+');
    final trendColor =
        (isIncrease && !isNegativeGood) || (!isIncrease && isNegativeGood)
        ? Colors.green
        : Colors.red;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (subtitleExtra != null) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      subtitleExtra,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Row(
                  children: [
                    Icon(
                      isIncrease ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: trendColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      percent,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Text(
                  vsText,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  TextStyle _tableHeaderStyle(ColorScheme colorScheme) {
    return TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
      color: colorScheme.onSurface.withValues(alpha: 0.5),
    );
  }
}
