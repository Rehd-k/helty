import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helper/date.formatter.dart';
import '../models/patient_vitals_model.dart';
import '../models/waiting_patient_model.dart';
import '../providers/module_request_flow_provider.dart';
import '../services/api_service.dart';
import '../services/waiting_patient_service.dart';
import 'patient_model.dart';
import '../../app_router.gr.dart';

@RoutePage()
class NewPatientScreen extends ConsumerStatefulWidget {
  const NewPatientScreen({
    super.key,
    this.use = 'For Register',
    this.categoryQueries = const ['Laboratory', 'Laboratory Tests'],
  });

  /// Defines how this screen should fetch and present data.
  final String use;

  /// Categories forwarded by parent when [use] is not "For Register".
  final List<String> categoryQueries;

  @override
  ConsumerState<NewPatientScreen> createState() => _WaitingPatientScreenState();
}

class _WaitingPatientScreenState extends ConsumerState<NewPatientScreen> {
  // Filter States
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  // Networking
  final Dio _dio = ApiService().dio;
  final WaitingPatientService _waitingService = WaitingPatientService();

  // Data + UI state
  List<_UnregisteredPatientTxn> _patients = [];
  _UnregisteredPatientTxn? _selectedPatient;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isRegisterUse => widget.use.trim().toLowerCase() == 'for register';
  bool get _isNursingQueueUse =>
      widget.use.trim().toLowerCase() == 'nursingqueue';

  String get _endpoint => _isRegisterUse
      ? '/invoices/unregistered-patients'
      : _isNursingQueueUse
      ? '/waiting-patients'
      : '/invoices/by-service-categories';

  String get _primaryButtonLabel => _isRegisterUse
      ? 'Register Patient'
      : _isNursingQueueUse
      ? 'Send to Consulting Room'
      : 'Open Patient';

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
      final range = _selectedDateRange;
      final now = DateTime.now();
      final from = range?.start ?? DateTime(now.year, now.month, now.day);
      final to =
          range?.end ?? DateTime(now.year, now.month, now.day, 23, 59, 59);

      if (search.isNotEmpty) {
        // Invoice API: bill number, internal id, or patient name.
        query['transactionId'] = search;
        query['patientName'] = search;
        query['invoiceId'] = search;
        query['invoiceID'] = search;
      }

      if (_isNursingQueueUse) {
        final queue = await _waitingService.fetchWaitingPatients(
          WaitingPatientQuery(skip: 0, take: 100, fromDate: from, toDate: to),
        );
        if (!mounted) return;
        final patients = queue.data
            .map(_UnregisteredPatientTxn.fromWaitingQueue)
            .toList();
        setState(() {
          _patients = patients;
          _selectedPatient = patients.isNotEmpty ? patients.first : null;
        });
        return;
      }

      if (!_isRegisterUse) {
        final categories = widget.categoryQueries
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (categories.isNotEmpty) {
          // Dio serializes list values as repeated query params by default.
          query['category'] = categories;
        }
        // Do not force status here: backend shapes vary; unpaid rows should still
        // appear so staff can see the queue. "Open Patient" stays gated by [isPaid].
      }

      query['fromDate'] = from.toUtc().toIso8601String();
      query['toDate'] = to.toUtc().toIso8601String();
      // if (!_isNursingQueueUse) {
      //   query['status'] = 'PAID';
      // }

      final resp = await _dio.get(_endpoint, queryParameters: query);

      if (!mounted) return;

      final raw = resp.data;
      final list = _extractUnregisteredList(
        raw is Map ? Map<String, dynamic>.from(raw) : raw,
      );
      var patients = <_UnregisteredPatientTxn>[];
      for (final e in list) {
        if (e is! Map) continue;
        try {
          patients.add(
            _UnregisteredPatientTxn.fromJson(Map<String, dynamic>.from(e)),
          );
        } catch (_) {
          // Skip malformed rows; keep the rest of the table usable.
        }
      }
      setState(() {
        _patients = patients;
        _selectedPatient = patients.isNotEmpty ? patients.first : null;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = _dioErrorMessage(e);
      setState(() {
        _errorMessage = msg;
        _patients = [];
        _selectedPatient = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load unregistered patients: $e';
        _patients = [];
        _selectedPatient = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  static List<dynamic> _extractUnregisteredList(dynamic data) {
    if (data is List<dynamic>) return data;
    if (data is Map<String, dynamic>) {
      const keys = [
        'data',
        'items',
        'invoices',
        'results',
        'rows',
        'unregisteredPatients',
        'patients',
      ];
      for (final k in keys) {
        final v = data[k];
        if (v is List<dynamic>) return v;
      }
    }
    return const [];
  }

  static String _dioErrorMessage(DioException e) {
    final payload = e.response?.data;
    if (payload is Map) {
      final msg = payload['message'];
      if (msg != null) return msg.toString();
      final err = payload['error'];
      if (err != null) return err.toString();
    } else if (payload is String && payload.trim().isNotEmpty) {
      return payload;
    }
    return e.message ?? 'Failed to load unregistered patients';
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
                hintText: "Search bill #, invoice id, or patient name...",
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
                  child: Text("Bill #", style: _headerStyle(colorScheme)),
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
                : RefreshIndicator(
                    onRefresh: _fetchPatients,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _patients.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: colorScheme.outline.withValues(alpha: 0.1),
                      ),
                      itemBuilder: (context, index) {
                        final patient = _patients[index];
                        final isSelected =
                            _selectedPatient?.rowKey == patient.rowKey;

                        return InkWell(
                          key: ValueKey<String>(patient.rowKey),
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
                                // Name (matches header column 1)
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
                                        child: Text(
                                          patient.fullName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Transaction / bill id (column 2)
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    patient.billLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
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
                                    patient.age != null
                                        ? '${patient.age}'
                                        : '-',
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
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.7),
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
                  "Bill",
                  patient.billLabel,
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
                    onPressed:
                        (_isNursingQueueUse &&
                            (!patient.isPaid || !patient.hasPatientId))
                        ? null
                        : () => _goToRegister(patient),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _primaryButtonLabel,
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
    if (_isNursingQueueUse) {
      _openSendToRoomDialog(patient);
      return;
    }

    if (!_isRegisterUse) {
      final resolvedPatientId = patient.patientId?.trim() ?? '';
      // if (resolvedPatientId.isEmpty) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('Cannot open patient because patient ID is missing.'),
      //     ),
      //   );
      //   return;
      // }
      final use = widget.use.trim().toLowerCase();
      final moduleType = use == 'radiology'
          ? ModuleRequestFlowType.radiology
          : ModuleRequestFlowType.laboratory;
      final paidContext = PaidModuleRequestContext(
        moduleType: moduleType,
        patientId: resolvedPatientId,
        invoiceId: patient.transactionId,
        invoiceDisplayId: patient.billLabel,
        serviceLines: patient.serviceLines,
        invoiceStaffId: patient.invoiceStaffId,
      );
      ref.read(paidModuleRequestContextProvider.notifier).state = paidContext;

      if (moduleType == ModuleRequestFlowType.radiology) {
        context.router.push(
          RadiologyPatientHistoryRoute(patientId: patient.patientId ?? ''),
        );
      } else {
        context.router.push(const LabCreateOrderRoute());
      }
      return;
    }

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

  Future<void> _openSendToRoomDialog(_UnregisteredPatientTxn patient) async {
    if (!patient.hasPatientId || patient.invoiceUuid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient or invoice is missing for queue action.'),
        ),
      );
      return;
    }

    final rooms = await _waitingService.fetchConsultingRooms();
    if (!mounted) return;
    if (rooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No consulting rooms configured.')),
      );
      return;
    }
    String selectedRoomId = rooms.first.id;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Send to consulting room'),
          content: StatefulBuilder(
            builder: (context, setModalState) {
              return DropdownButtonFormField<String>(
                initialValue: selectedRoomId,
                items: rooms
                    .map(
                      (r) => DropdownMenuItem<String>(
                        value: r.id,
                        child: Text(r.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setModalState(() => selectedRoomId = v);
                },
                decoration: const InputDecoration(
                  labelText: 'Consulting room',
                  border: OutlineInputBorder(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
    if (submitted != true) return;

    // Link vitals to invoice first if missing.
    if (!patient.hasVitals) {
      await _waitingService.createPatientVitals(
        CreatePatientVitalsDto(
          invoiceId: patient.invoiceUuid,
          patientId: patient.patientId,
        ),
      );
    }
    await _waitingService.sendInvoiceToRoom(
      invoiceId: patient.invoiceUuid,
      consultingRoomId: selectedRoomId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Patient sent to consulting room.')),
    );
    _fetchPatients();
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

/// Row from `GET /invoices/unregistered-patients` (invoice-led billing).
///
/// [transactionId] is the invoice identifier (UUID or human `invoiceId` code).
/// [patientId] is the server patient UUID when present on the row (walk-in / placeholder).
/// [invoiceDisplayId] is the human-facing bill number when the API sends it.
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
    this.invoiceDisplayId,
    this.patientNameAsPrinted,
    this.invoiceStatus,
    this.serviceLines = const [],
    this.rowAppearsPaid = false,
    this.invoiceUuid = '',
    this.hasVitals = false,
    this.invoiceStaffId,
  });

  /// Invoice id (UUID or bill code) — also sent as [Patient.unregisteredTransactionId] for linkage.
  final String transactionId;

  /// Human-facing bill code (`invoiceID`), when present.
  final String? invoiceDisplayId;

  /// Full name exactly as returned by the API (`patientName`), when present.
  final String? patientNameAsPrinted;
  final String? invoiceStatus;
  final List<PaidInvoiceServiceLine> serviceLines;

  /// True when status/amounts/lines indicate the invoice is paid enough to open.
  final bool rowAppearsPaid;
  final String invoiceUuid;
  final bool hasVitals;
  /// Invoice requesting / billing staff id when returned by the API.
  final String? invoiceStaffId;
  final String surname;
  final String firstName;
  final String? phoneNumber;
  final int? age;
  final List<String> services;
  final DateTime dateTime;

  /// Patient UUID from the API row (`patientId`) — prefer over nested `patient.id`.
  final String? patientId;
  bool get hasPatientId => (patientId ?? '').trim().isNotEmpty;

  String get rowKey {
    final pid = patientId?.trim();
    if (pid != null && pid.isNotEmpty) return pid;
    if (transactionId.isNotEmpty) return transactionId;
    final d = invoiceDisplayId?.trim();
    if (d != null && d.isNotEmpty) return d;
    return '${fullName}_${dateTime.millisecondsSinceEpoch}';
  }

  String get billLabel {
    final human = invoiceDisplayId?.trim();
    if (human != null && human.isNotEmpty) return human;
    final id = transactionId.trim();
    if (id.length <= 12) return id.isEmpty ? '—' : id;
    return '${id.substring(0, 8)}…';
  }

  String get fullName {
    final printed = patientNameAsPrinted?.trim();
    if (printed != null && printed.isNotEmpty) return printed;
    final combined = '$surname $firstName'.trim();
    if (combined.isNotEmpty) return combined;
    return '—';
  }

  String get initials {
    final printed = patientNameAsPrinted?.trim();
    if (printed != null && printed.isNotEmpty) {
      final parts = printed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
      final list = parts.toList();
      if (list.isEmpty) return '?';
      if (list.length == 1) {
        final c = list[0][0].toUpperCase();
        return c;
      }
      return '${list[0][0]}${list[1][0]}'.toUpperCase();
    }
    final buffer = StringBuffer();
    if (firstName.isNotEmpty) buffer.write(firstName[0].toUpperCase());
    if (surname.isNotEmpty) buffer.write(surname[0].toUpperCase());
    return buffer.isEmpty ? '?' : buffer.toString();
  }

  bool get isPaid => rowAppearsPaid;

  factory _UnregisteredPatientTxn.fromWaitingQueue(WaitingPatientModel row) {
    final patient = row.patient;
    return _UnregisteredPatientTxn(
      transactionId: row.invoiceId,
      invoiceDisplayId: row.invoiceDisplayId,
      patientNameAsPrinted: patient == null
          ? null
          : '${patient.firstName} ${patient.surname}'.trim(),
      invoiceStatus: row.seen ? 'SEEN' : 'PAID',
      rowAppearsPaid: true,
      surname: patient?.surname ?? '',
      firstName: patient?.firstName ?? '',
      phoneNumber: patient?.phoneNumber,
      age: null,
      services: row.consultationNames,
      dateTime: row.createdAt,
      patientId: row.patientId,
      invoiceUuid: row.invoiceId,
      hasVitals: row.patientVitals?.id.isNotEmpty == true,
      serviceLines: const [],
      invoiceStaffId: null,
    );
  }

  /// Splits a single `patientName` string into given / family for the registration form.
  static (String firstName, String surname) _namesFromPatientName(String? raw) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return ('', '');
    final parts = s.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return (parts[0], '');
    final surname = parts.last;
    final firstName = parts.sublist(0, parts.length - 1).join(' ');
    return (firstName, surname);
  }

  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  /// Row-level `patientId` wins over nested `patient.id` (invoice payloads may nest partial patient).
  static String? _firstNonEmptyId(dynamic a, dynamic b, dynamic c) {
    for (final v in [a, b, c]) {
      final t = v?.toString().trim() ?? '';
      if (t.isNotEmpty) return t;
    }
    return null;
  }

  static double? _parseMoney(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim());
  }

  /// Backend list payloads often omit top-level `status`; infer from amounts / lines.
  static bool _computeAppearsPaid(
    Map<String, dynamic> root,
    Map<String, dynamic> json,
    List<dynamic> rawServices,
  ) {
    final status =
        (root['status'] ??
                json['status'] ??
                root['invoiceStatus'] ??
                json['invoiceStatus'] ??
                root['paymentStatus'] ??
                json['paymentStatus'])
            ?.toString()
            .trim()
            .toUpperCase() ??
        '';
    if (status == 'PAID' || status == 'FULLY_PAID') return true;
    if (json['isPaid'] == true || root['isPaid'] == true) return true;
    if (json['fullyPaid'] == true || root['fullyPaid'] == true) return true;

    final due = _parseMoney(
      root['amountDue'] ??
          json['amountDue'] ??
          root['netAmountDue'] ??
          json['netAmountDue'] ??
          root['balanceDue'] ??
          json['balanceDue'],
    );
    if (due != null && due <= 0) return true;

    if (rawServices.isEmpty) return false;
    for (final e in rawServices) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final unit = _parseMoney(m['unitPrice']) ?? 0;
      final qtyRaw = m['quantity'];
      final qty = qtyRaw is num
          ? qtyRaw.toDouble()
          : (_parseMoney(qtyRaw) ?? 1.0);
      final lineTotal = unit * qty;
      final paid = _parseMoney(m['amountPaid']) ?? 0;
      if (lineTotal > 0 && paid + 1e-6 < lineTotal) return false;
    }
    return rawServices.isNotEmpty;
  }

  static String? _parseInvoiceStaffId(
    Map<String, dynamic> root,
    Map<String, dynamic> json,
  ) {
    final staff = _asMap(root['staff']) ?? _asMap(json['staff']);
    final fromNested = staff?['id']?.toString().trim();
    if (fromNested != null && fromNested.isNotEmpty) return fromNested;
    for (final key in ['staffId', 'createdById', 'createdByStaffId']) {
      final v = root[key] ?? json[key];
      final s = v?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return null;
  }

  static String? _serviceLineName(Map<String, dynamic> item) {
    final custom = item['customDescription']?.toString().trim();
    if (custom != null && custom.isNotEmpty) return custom;
    final svc = _asMap(item['service']);
    final name = (svc?['name'] ?? item['name'] ?? item['serviceName'])
        ?.toString()
        .trim();
    if (name != null && name.isNotEmpty) return name;
    return null;
  }

  factory _UnregisteredPatientTxn.fromJson(Map<String, dynamic> json) {
    final invoice = _asMap(json['invoice']);
    final root = invoice ?? json;

    final patient = _asMap(json['patient']) ?? _asMap(root['patient']);

    final patientNameSingle =
        json['patientName']?.toString() ?? root['patientName']?.toString();
    final printed = patientNameSingle?.trim();
    final (
      String splitFirst,
      String splitSurname,
    ) = printed != null && printed.isNotEmpty
        ? _namesFromPatientName(printed)
        : ('', '');

    final rawServices =
        (root['invoiceItems'] as List?) ??
        (root['services'] as List?) ??
        (json['services'] as List?) ??
        (json['items'] as List?) ??
        (json['invoiceItems'] as List?) ??
        const [];

    final names = <String>[];
    final lines = <PaidInvoiceServiceLine>[];
    for (final e in rawServices) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final n = _serviceLineName(m);
      if (n != null) names.add(n);
      final service = _asMap(m['service']);
      final itemId = (m['invoiceItemId'] ?? m['id'] ?? '').toString().trim();
      final serviceIdRaw = (m['serviceId'] ?? service?['id'] ?? '')
          .toString()
          .trim();
      final serviceId = serviceIdRaw.isEmpty ? null : serviceIdRaw;
      final serviceName =
          (service?['name'] ?? m['serviceName'] ?? m['name'] ?? '')
              .toString()
              .trim();
      String categoryName = '';
      final cat = m['category'];
      if (cat is String) {
        categoryName = cat.trim();
      } else if (service != null && service['category'] is Map) {
        final c = Map<String, dynamic>.from(service['category'] as Map);
        categoryName = (c['name'] ?? '').toString().trim();
      } else {
        categoryName = (m['categoryName'] ?? service?['categoryName'] ?? '')
            .toString()
            .trim();
      }
      if (itemId.isNotEmpty && serviceName.isNotEmpty) {
        lines.add(
          PaidInvoiceServiceLine(
            invoiceItemId: itemId,
            serviceId: serviceId,
            serviceName: serviceName,
            categoryName: categoryName,
          ),
        );
      }
    }

    final String? dtString =
        json['date']?.toString() ??
        root['date']?.toString() ??
        root['createdAt']?.toString() ??
        root['updatedAt']?.toString() ??
        json['createdAt']?.toString() ??
        json['datetime']?.toString();

    final invoiceUuid = root['id']?.toString().trim() ?? '';
    final legacyTxn =
        json['transactionID']?.toString() ?? json['transactionId']?.toString();
    final topInvoiceId =
        json['invoiceId']?.toString().trim() ??
        root['invoiceId']?.toString().trim() ??
        '';

    final resolvedId = invoiceUuid.isNotEmpty
        ? invoiceUuid
        : (legacyTxn != null && legacyTxn.toString().trim().isNotEmpty
              ? legacyTxn.toString().trim()
              : topInvoiceId);

    final displayBill =
        root['invoiceID']?.toString() ??
        root['invoiceId']?.toString() ??
        json['invoiceID']?.toString() ??
        json['invoiceId']?.toString();

    final displayTrimmed = displayBill?.toString().trim();
    final displayResolved =
        (displayTrimmed != null && displayTrimmed.isNotEmpty)
        ? displayTrimmed
        : (topInvoiceId.isNotEmpty ? topInvoiceId : null);

    final sn =
        (patient?['surname'] ?? root['surname'] ?? json['surname'])
            ?.toString() ??
        '';
    final fn =
        (patient?['firstName'] ??
                patient?['firstname'] ??
                root['firstName'] ??
                root['firstname'] ??
                json['firstname'] ??
                json['firstName'])
            ?.toString() ??
        '';

    final surname = sn.isNotEmpty ? sn : splitSurname;
    final firstName = fn.isNotEmpty ? fn : splitFirst;

    final appearsPaid = _computeAppearsPaid(root, json, rawServices);

    final invoiceStaffId = _parseInvoiceStaffId(root, json);

    return _UnregisteredPatientTxn(
      transactionId: resolvedId,
      invoiceDisplayId: displayResolved,
      patientNameAsPrinted: printed != null && printed.isNotEmpty
          ? printed
          : null,
      invoiceStatus: (root['status'] ?? json['status'])?.toString(),
      rowAppearsPaid: appearsPaid,
      surname: surname,
      firstName: firstName,
      phoneNumber:
          (patient?['phoneNumber'] ??
                  root['phoneNumber'] ??
                  json['phoneNumber'])
              ?.toString(),
      age: (patient?['age'] ?? json['age']) is num
          ? ((patient?['age'] ?? json['age']) as num).toInt()
          : int.tryParse((patient?['age'] ?? json['age'])?.toString() ?? ''),
      services: names,
      dateTime: dtString != null
          ? DateTime.tryParse(dtString) ?? DateTime.now()
          : DateTime.now(),
      patientId: _firstNonEmptyId(
        json['patientId'],
        root['patientId'],
        patient?['id'],
      ),
      serviceLines: lines,
      invoiceUuid: invoiceUuid,
      hasVitals: root['vitalsId'] != null || root['vitals'] != null,
      invoiceStaffId: invoiceStaffId,
    );
  }
}
