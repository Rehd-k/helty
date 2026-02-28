import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

@RoutePage()
class WaitingPatientScreen extends StatefulWidget {
  const WaitingPatientScreen({super.key});

  @override
  State<WaitingPatientScreen> createState() => _WaitingPatientScreenState();
}

class _WaitingPatientScreenState extends State<WaitingPatientScreen> {
  // Filter States
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  String _selectedStatus = 'All Statuses';
  String _selectedDepartment = 'All Departments';

  // Details Pane State
  Map<String, dynamic>? _selectedPatient;

  // Mock Data for Waiting Patients
  final List<Map<String, dynamic>> _patients = [
    {
      'id': 'PT-8021',
      'cardNo': 'CRD-9921',
      'txnId': 'TXN-1001',
      'initials': 'JM',
      'name': 'James Miller',
      'age': 45,
      'gender': 'Male',
      'phone': '+1 555-0192',
      'time': '08:45 AM',
      'room': 'Room 101',
      'status': 'Waiting',
      'doctor': 'Dr. Alan Grant',
      'department': 'General',
      'color': Colors.orange,
      'services': [
        {'name': 'General Consultation', 'price': 150.00},
        {'name': 'Complete Blood Count (CBC)', 'price': 85.00},
      ],
    },
    {
      'id': 'PT-8022',
      'cardNo': 'CRD-9922',
      'txnId': 'TXN-1002',
      'initials': 'ER',
      'name': 'Emma Rodriguez',
      'age': 28,
      'gender': 'Female',
      'phone': '+1 555-0144',
      'time': '09:15 AM',
      'room': 'Room 305',
      'status': 'In Triage',
      'doctor': 'Nurse Sarah Lee',
      'department': 'Triage',
      'color': Colors.blue,
      'services': [
        {'name': 'Vitals Check', 'price': 25.00},
      ],
    },
    {
      'id': 'PT-8023',
      'cardNo': 'CRD-9923',
      'txnId': 'TXN-1003',
      'initials': 'DK',
      'name': 'David Kim',
      'age': 62,
      'gender': 'Male',
      'phone': '+1 555-0177',
      'time': '09:30 AM',
      'room': 'Cardio Wing A',
      'status': 'Billed',
      'doctor': 'Dr. James Wilson',
      'department': 'Cardiology',
      'color': Colors.green,
      'services': [
        {'name': 'Cardiology Consult', 'price': 250.00},
        {'name': 'ECG / EKG', 'price': 120.00},
        {'name': 'Echocardiogram', 'price': 350.00},
      ],
    },
    {
      'id': 'PT-8024',
      'cardNo': 'CRD-9924',
      'txnId': 'TXN-1004',
      'initials': 'SJ',
      'name': 'Sarah Jenkins',
      'age': 34,
      'gender': 'Female',
      'phone': '+1 555-0188',
      'time': '10:00 AM',
      'room': 'Room 202',
      'status': 'Waiting',
      'doctor': 'Dr. Emily Stone',
      'department': 'Orthopedics',
      'color': Colors.orange,
      'services': [
        {'name': 'Specialist Consult', 'price': 200.00},
        {'name': 'X-Ray (Left Arm)', 'price': 110.00},
        {'name': 'Pain Relief Medication', 'price': 45.00},
        {'name': 'Cast Application', 'price': 180.00},
      ],
    },
  ];

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange:
          _selectedDateRange ??
          DateTimeRange(start: DateTime.now(), end: DateTime.now()),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: Theme.of(context).colorScheme),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. TOP SECTION: FILTER BAR
            _buildFilterBar(colorScheme),
            const SizedBox(height: 24),

            // 2. BOTTOM SECTION: TABLE (2/3) & DETAILS (1/3)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side: Table (2/3)
                  Expanded(flex: 2, child: _buildPatientTable(colorScheme)),
                  const SizedBox(width: 24),

                  // Right Side: Details Pane (1/3)
                  Expanded(flex: 1, child: _buildDetailsPane(colorScheme)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- FILTER BAR WIDGET ---
  Widget _buildFilterBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Global Search Bar
          SizedBox(
            width: 350,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search ID, Card No, Name, Txn ID, Services...",
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),

          // Date Range Picker
          OutlinedButton.icon(
            onPressed: _pickDateRange,
            icon: Icon(Icons.date_range, size: 18, color: colorScheme.primary),
            label: Text(
              _selectedDateRange == null
                  ? "Select Date Range"
                  : "${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_selectedDateRange!.end)}",
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
          ),

          // Status Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatus,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                items:
                    [
                          'All Statuses',
                          'Waiting',
                          'In Triage',
                          'Billed',
                          'Completed',
                        ]
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                onChanged: (val) => setState(() => _selectedStatus = val!),
              ),
            ),
          ),

          // Department Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDepartment,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                items:
                    [
                          'All Departments',
                          'General',
                          'Cardiology',
                          'Orthopedics',
                          'Triage',
                        ]
                        .map(
                          (dept) =>
                              DropdownMenuItem(value: dept, child: Text(dept)),
                        )
                        .toList(),
                onChanged: (val) => setState(() => _selectedDepartment = val!),
              ),
            ),
          ),

          // Clear Filters Button
          TextButton.icon(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedDateRange = null;
                _selectedStatus = 'All Statuses';
                _selectedDepartment = 'All Departments';
              });
            },
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text("Clear", style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // --- PATIENT TABLE WIDGET (2/3 Width) ---
  Widget _buildPatientTable(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.02),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "Patient Name & ID",
                    style: _headerStyle(colorScheme),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text("Time", style: _headerStyle(colorScheme)),
                ),
                Expanded(
                  flex: 2,
                  child: Text("Doctor", style: _headerStyle(colorScheme)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Assigned Room",
                    style: _headerStyle(colorScheme),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text("Status", style: _headerStyle(colorScheme)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Services",
                    textAlign: TextAlign.center,
                    style: _headerStyle(colorScheme),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),

          // Scrollable Table Rows
          Expanded(
            child: ListView.separated(
              itemCount: _patients.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
              itemBuilder: (context, index) {
                final patient = _patients[index];
                final isSelected = _selectedPatient?['id'] == patient['id'];
                final List servicesList = patient['services'];

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPatient = patient;
                    });
                  },
                  child: Container(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.05)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Name & IDs
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: patient['color'].withOpacity(
                                  0.1,
                                ),
                                child: Text(
                                  patient['initials'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: patient['color'],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      patient['name'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${patient['id']} • ${patient['cardNo']}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Time
                        Expanded(
                          flex: 2,
                          child: Text(
                            patient['time'],
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ),
                        // Doctor
                        Expanded(
                          flex: 2,
                          child: Text(
                            patient['doctor'],
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ),
                        // Room
                        Expanded(
                          flex: 2,
                          child: Text(
                            patient['room'],
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ),
                        // Status
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
                                color: patient['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                patient['status'],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: patient['color'],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Number of Services
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "${servicesList.length} items",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Pagination Footer
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Showing ${_patients.length} results",
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text(
                        "Previous",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text("Next", style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- PATIENT DETAILS PANE WIDGET (1/3 Width) ---
  Widget _buildDetailsPane(ColorScheme colorScheme) {
    if (_selectedPatient == null) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            style: BorderStyle.none,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_search,
                size: 48,
                color: colorScheme.onSurface.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 16),
              Text(
                "Select a patient from the table\nto view their detailed file.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: .5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final patient = _selectedPatient!;
    final List<Map<String, dynamic>> services = List<Map<String, dynamic>>.from(
      patient['services'],
    );
    double totalAmount = services.fold(
      0.0,
      (sum, item) => sum + (item['price'] as double),
    );

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bio
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: patient['color'].withOpacity(0.2),
                  child: Text(
                    patient['initials'],
                    style: TextStyle(
                      fontSize: 20,
                      color: patient['color'],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "ID: ${patient['id']} | Card: ${patient['cardNo']}",
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${patient['age']} yrs • ${patient['gender']} • ${patient['phone']}",
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Visit Info Quick Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildInfoTile(
                  "Department",
                  patient['department'],
                  Icons.business,
                  colorScheme,
                ),
                _buildInfoTile(
                  "Transaction",
                  patient['txnId'],
                  Icons.receipt_long,
                  colorScheme,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),

          // Itemized Services List (Scrollable)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              "Itemized Services (${services.length})",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: services.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.05),
              ),
              itemBuilder: (context, index) {
                final service = services[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          service['name'],
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withValues(alpha: .8),
                          ),
                        ),
                      ),
                      Text(
                        "\$${service['price'].toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Total Calculation Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.02),
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Due",
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      "\$${totalAmount.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Edit Items"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Process Payment",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Utility Widgets
  Widget _buildInfoTile(
    String label,
    String value,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle(ColorScheme colorScheme) {
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface.withValues(alpha: 0.5),
    );
  }
}
