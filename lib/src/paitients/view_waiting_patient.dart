import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../helper/date.formatter.dart';
import '../services/api_service.dart';
import 'patient_model.dart';
import '../../app_router.gr.dart';

@RoutePage()
class NewPatientScreen extends StatefulWidget {
  const NewPatientScreen({super.key});

  @override
  State<NewPatientScreen> createState() => _WaitingPatientScreenState();
}

class _WaitingPatientScreenState extends State<NewPatientScreen> {
  // Filter States
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  // Networking
  final Dio _dio = ApiService().dio;

  // Data + UI state
  List<_UnregisteredPatientTxn> _patients = [];
  _UnregisteredPatientTxn? _selectedPatient;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
    _fetchPatients();
  }

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
      await _fetchPatients();
    }
  }

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final query = <String, dynamic>{};
      final search = _searchController.text.trim();

      if (search.isNotEmpty) {
        // Backend accepts both transactionId and patientName – we use same text.
        query['transactionId'] = search;
        query['patientName'] = search;
      }

      final range = _selectedDateRange;
      final now = DateTime.now();
      final from = range?.start ?? DateTime(now.year, now.month, now.day);
      final to =
          range?.end ?? DateTime(now.year, now.month, now.day, 23, 59, 59);

      query['fromDate'] = from.toIso8601String();
      query['toDate'] = to.toIso8601String();

      final resp = await _dio.get(
        '/transaction/unregistered-patients',
        queryParameters: query,
      );

      final data = resp.data;
      final List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic> && data['data'] is List) {
        list = data['data'] as List;
      } else {
        list = const [];
      }

      final patients = list
          .map(
            (e) => _UnregisteredPatientTxn.fromJson(
              Map<String, dynamic>.from(e as Map<String, dynamic>),
            ),
          )
          .toList();

      setState(() {
        _patients = patients;
        _selectedPatient = patients.isNotEmpty ? patients.first : null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load unregistered patients';
      });
    } finally {
      setState(() {
        _isLoading = false;
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
              onSubmitted: (_) => _fetchPatients(),
              decoration: InputDecoration(
                hintText: "Search Transaction ID or Patient Name...",
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
                  : DateFormatter.dateTime(_selectedDateRange!.start),
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

          // Clear Filters Button
          TextButton.icon(
            onPressed: () {
              setState(() {
                _searchController.clear();
              });
              _fetchPatients();
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
                  child: Text("Patient Name", style: _headerStyle(colorScheme)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Transaction ID",
                    style: _headerStyle(colorScheme),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text("Phone", style: _headerStyle(colorScheme)),
                ),
                Expanded(
                  flex: 1,
                  child: Text("Age", style: _headerStyle(colorScheme)),
                ),
                Expanded(
                  flex: 3,
                  child: Text("Date/Time", style: _headerStyle(colorScheme)),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: colorScheme.error, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    itemCount: _patients.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),
                    itemBuilder: (context, index) {
                      final patient = _patients[index];
                      final isSelected =
                          _selectedPatient?.transactionId ==
                          patient.transactionId;

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
                              // Name
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: colorScheme.primary
                                          .withValues(alpha: 0.08),
                                      child: Text(
                                        patient.initials,
                                        style: TextStyle(
                                          fontSize: 12,
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
                                            patient.fullName,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            patient.transactionId,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Phone
                              Expanded(
                                flex: 2,
                                child: Text(
                                  patient.phoneNumber ?? '-',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ),
                              // Age
                              Expanded(
                                flex: 1,
                                child: Text(
                                  patient.age != null ? '${patient.age}' : '-',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ),
                              // Date/time
                              Expanded(
                                flex: 3,
                                child: Text(
                                  DateFormatter.dateTime(patient.dateTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.7,
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
                                      "${patient.services.length} items",
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
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    patient.initials,
                    style: TextStyle(
                      fontSize: 20,
                      color: colorScheme.primary,
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
                        patient.fullName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (patient.age != null) "${patient.age} yrs",
                          if (patient.phoneNumber != null) patient.phoneNumber!,
                        ].join(" • "),
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
                  "Transaction",
                  patient.transactionId,
                  Icons.receipt_long,
                  colorScheme,
                ),
                _buildInfoTile(
                  "Date/Time",
                  DateFormatter.dateTime(patient.dateTime),
                  Icons.receipt_long,
                  colorScheme,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),

          // Services List (Scrollable – no prices)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              "Services (${patient.services.length})",
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
              itemCount: patient.services.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.05),
              ),
              itemBuilder: (context, index) {
                final serviceName = patient.services[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          serviceName,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withValues(alpha: .8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Footer Actions
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
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedPatient = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Close"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _goToRegister(patient),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Register Patient",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goToRegister(_UnregisteredPatientTxn patient) {
    // Build a minimal Patient model to seed the registration form.
    final String fallbackId = patient.patientId ?? patient.transactionId;

    final seededPatient = Patient(
      id: fallbackId,
      patientId: fallbackId,
      cardNo: '',
      title: '',
      surname: patient.surname,
      firstName: patient.firstName,
      otherName: null,
      dob: DateTime.now(),
      gender: '',
      maritalStatus: '',
      nationality: '',
      stateOfOrigin: '',
      lga: '',
      town: '',
      permanentAddress: '',
      religion: null,
      email: null,
      preferredLanguage: null,
      phoneNumber: patient.phoneNumber,
      addressOfResidence: null,
      profession: null,
      nextOfKinName: null,
      nextOfKinPhone: null,
      nextOfKinAddress: null,
      nextOfKinRelationship: null,
      hmo: null,
      fingerprintData: null,
      createdAt: null,
      updatedAt: null,
      createdBy: null,
      updatedBy: null,
      lockNames: true,
      fromUnregisteredFlow: true,
      unregisteredTransactionId: patient.transactionId,
    );

    context.router.push(PatientFormRoute(patient: seededPatient));
  }

  // Utility Widgets

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

/// Model for "newly paid but unregistered" patients coming from
/// GET /transaction/unregistered-patients.
class _UnregisteredPatientTxn {
  _UnregisteredPatientTxn({
    required this.transactionId,
    required this.surname,
    required this.firstName,
    required this.services,
    required this.dateTime,
    this.phoneNumber,
    this.age,
    this.patientId,
  });

  final String transactionId;
  final String surname;
  final String firstName;
  final String? phoneNumber;
  final int? age;
  final List<String> services;
  final DateTime dateTime;

  /// Optional backend patient identifier (if one already exists).
  final String? patientId;

  String get fullName => "$surname $firstName".trim();

  String get initials {
    final buffer = StringBuffer();
    if (surname.isNotEmpty) buffer.write(surname[0].toUpperCase());
    if (firstName.isNotEmpty) buffer.write(firstName[0].toUpperCase());
    return buffer.isEmpty ? '?' : buffer.toString();
  }

  factory _UnregisteredPatientTxn.fromJson(Map<String, dynamic> json) {
    // patient is now nested
    final patient = json['patient'] as Map<String, dynamic>?;

    // Try to get services from multiple possible shapes
    final rawServices =
        (json['services'] as List?) ??
        (json['items'] as List?) ?? // if backend later returns items[]
        const [];

    final names = rawServices
        .map(
          (e) =>
              (e is Map<String, dynamic>
                      ? (e['name'] ?? e['serviceName'])
                      : null)
                  ?.toString(),
        )
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();

    // Prefer createdAt; fall back to old datetime field
    final String? dtString =
        json['createdAt']?.toString() ?? json['datetime']?.toString();

    return _UnregisteredPatientTxn(
      transactionId:
          json['transactionID']?.toString() ??
          json['transactionId']?.toString() ??
          '',
      surname: (patient?['surname'] ?? json['surname'])?.toString() ?? '',
      firstName:
          (patient?['firstName'] ??
                  patient?['firstname'] ??
                  json['firstname'] ??
                  json['firstName'])
              ?.toString() ??
          '',
      phoneNumber: (patient?['phoneNumber'] ?? json['phoneNumber'])?.toString(),
      age: (json['age'] as num?)
          ?.toInt(), // will be null with your current payload
      services: names,
      dateTime: dtString != null
          ? DateTime.tryParse(dtString) ?? DateTime.now()
          : DateTime.now(),
      // prefer explicit patientId, else nested patient.id, else top-level id
      patientId: patient?['id']?.toString() ?? json['id']?.toString(),
    );
  }
}
