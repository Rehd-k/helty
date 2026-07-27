import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/core/widgets/patient_avatar.dart';
import 'package:helty/src/doctor/widgets/start_encounter_dialog.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/consultation_credit_model.dart';
import 'package:helty/src/models/consultation_credit_utils.dart';
import 'package:helty/src/models/invoice_by_service_category_row.dart';
import 'package:helty/src/models/service_category_model.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/encounter_service.dart';
import 'package:helty/src/services/invoice_service.dart';
import 'package:helty/src/services/service_category_service.dart';
import 'package:helty/src/widgets/date.filter.dart';

@RoutePage()
class DoctorWaitingPatientsScreen extends ConsumerStatefulWidget {
  const DoctorWaitingPatientsScreen({super.key});

  @override
  ConsumerState<DoctorWaitingPatientsScreen> createState() =>
      _DoctorWaitingPatientsScreenState();
}

class _DoctorWaitingPatientsScreenState
    extends ConsumerState<DoctorWaitingPatientsScreen> {
  final _invoiceService = InvoiceService();
  final _encounterService = EncounterService();
  final _categoryService = ServiceCategoryService();
  final _searchCtrl = TextEditingController();

  List<ServiceCategory> _categories = [];
  List<InvoiceByServiceCategoryRow> _patients = [];
  ServiceCategory? _selectedCategory;
  bool _loading = false;
  bool _loadingCategories = false;
  String? _categoriesError;
  String _searchQuery = '';
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (q != _searchQuery) {
        _searchQuery = q;
        _loadPatients();
      }
    });
    _loadCategories();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _categoriesError = null;
    });
    try {
      final categories = await _categoryService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loadingCategories = false;
        _selectedCategory = categories.isNotEmpty ? categories.first : null;
      });
      await _loadPatients();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCategories = false;
        _categoriesError = e.toString();
      });
    }
  }

  Future<void> _onCategoryChanged(ServiceCategory? category) async {
    setState(() => _selectedCategory = category);
    await _loadPatients();
  }

  Future<void> _loadPatients() async {
    final category = _selectedCategory?.name.trim() ?? '';
    if (category.isEmpty) {
      setState(() {
        _patients = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final rows = await _invoiceService.fetchByServiceCategories(
        category: category,
        fromDate: DateTime(_fromDate.year, _fromDate.month, _fromDate.day),
        toDate: DateTime(
          _toDate.year,
          _toDate.month,
          _toDate.day,
          23,
          59,
          59,
          999,
        ),
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _patients = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _patients = [];
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load waiting patients: $e')),
      );
    }
  }

  void _onPatientTap(InvoiceByServiceCategoryRow row) {
    if (!row.isPaid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This bill is not paid yet. Open the patient after payment is complete.',
          ),
        ),
      );
      return;
    }
    final patientId = row.patientId?.trim() ?? '';
    if (patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot open encounter — patient ID is missing.'),
        ),
      );
      return;
    }
    final staff = ref.read(authProvider).staff;
    final doctorId = staff?.id ?? staff?.staffId ?? '';
    if (doctorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to start an encounter.')),
      );
      return;
    }
    _showStartEncounterDialog(row, doctorId, patientId);
  }

  Future<void> _showStartEncounterDialog(
    InvoiceByServiceCategoryRow row,
    String doctorId,
    String patientId,
  ) async {
    ConsultationServiceLine? fifoCredit;
    try {
      final invoices = await _invoiceService.fetchPaidWithoutEncounter(
        patientId: patientId,
      );
      if (invoices.isNotEmpty) {
        fifoCredit = invoices.first.primaryConsultationCredit;
      }
    } catch (_) {
      fifoCredit = row.primaryConsultationCredit;
    }

    if (!mounted) return;

    final result = await showDialog<_StartEncounterResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StartEncounterDialog(
        patientName: row.patientName,
        consultationCredit: fifoCredit ?? row.primaryConsultationCredit,
        onOpen: () async {
          try {
            final encounter = await _encounterService.startOutpatient(
              patientId: patientId,
              doctorId: doctorId,
              visitType: 'Walk-in',
            );
            if (!ctx.mounted) return;
            Navigator.of(ctx).pop(
              _StartEncounterResult(
                encounterId: encounter.id,
                patientId: patientId,
              ),
            );
          } on OutpatientStartException catch (e) {
            if (!ctx.mounted) return;
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(mapOutpatientStartError(e.message))),
            );
          } catch (e) {
            if (!ctx.mounted) return;
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text('Failed to start encounter: $e')),
            );
          }
        },
      ),
    );

    if (result != null && mounted) {
      context.router.push(
        DoctorEncounterViewRoute(
          encounterId: result.encounterId,
          patientId: result.patientId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResponsiveToolbar(
              leading: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waiting Patients',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select a service category. Tap a paid patient to open their encounter.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_empty_outlined,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_patients.length} in queue',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by patient name or bill number…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_loadingCategories)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              )
            else if (_categoriesError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Failed to load categories: $_categoriesError',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadCategories,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Service category',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.4,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ServiceCategory>(
                    isExpanded: true,
                    value:
                        _selectedCategory != null &&
                            _categories.any(
                              (c) => c.id == _selectedCategory!.id,
                            )
                        ? _categories.firstWhere(
                            (c) => c.id == _selectedCategory!.id,
                          )
                        : null,
                    hint: const Text('Select category'),
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem<ServiceCategory>(
                            value: c,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (c) => _onCategoryChanged(c),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            FromToDateFilter(
              doRefresh: _loadPatients,
              dateFilter: true,
              onFilterChanged:
                  (
                    String query,
                    String category,
                    DateTime? from,
                    DateTime? to,
                  ) {
                    setState(() {
                      _fromDate = from ?? DateTime.now();
                      _toDate = to ?? DateTime.now();
                    });
                    _loadPatients();
                  },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ResponsiveDataTable(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!bp.isMobile)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withValues(alpha: 0.04),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                'PATIENT',
                                style: _headerStyle(colorScheme),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'SERVICES',
                                style: _headerStyle(colorScheme),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'BILL',
                                style: _headerStyle(colorScheme),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'TIME',
                                style: _headerStyle(colorScheme),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'STATUS',
                                style: _headerStyle(colorScheme),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Divider(
                      height: 1,
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),
                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _selectedCategory == null
                          ? Center(
                              child: Text(
                                'Select a service category to see waiting patients.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : _patients.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.hourglass_empty_outlined,
                                    size: 64,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No waiting patients for this category.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _patients.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: colorScheme.outline.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                              itemBuilder: (context, index) {
                                final row = _patients[index];
                                final time = DateFormatter.dateTime(
                                  row.dateTime.toLocal(),
                                );
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: row.isPaid
                                        ? () => _onPatientTap(row)
                                        : null,
                                    child: bp.isMobile
                                        ? _buildMobileRow(
                                            colorScheme,
                                            row,
                                            time,
                                          )
                                        : _buildDesktopRow(
                                            colorScheme,
                                            row,
                                            time,
                                          ),
                                  ),
                                );
                              },
                            ),
                    ),
                    if (_patients.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Text(
                          'Showing ${_patients.length} • Tap a paid patient to open encounter',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
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
    );
  }

  TextStyle _headerStyle(ColorScheme colorScheme) {
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
      color: colorScheme.onSurfaceVariant,
    );
  }

  Widget _paidBadge(bool isPaid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPaid ? 'Paid' : 'Unpaid',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isPaid ? Colors.green.shade800 : Colors.orange.shade800,
        ),
      ),
    );
  }

  Widget _buildDesktopRow(
    ColorScheme colorScheme,
    InvoiceByServiceCategoryRow row,
    String time,
  ) {
    final muted = !row.isPaid;
    return Opacity(
      opacity: muted ? 0.65 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  PatientAvatar(
                    firstName: row.firstName.isNotEmpty
                        ? row.firstName
                        : row.patientName,
                    surname: row.surname,
                    avatarUrl: row.avatarUrl,
                    size: 36,
                    backgroundColor: colorScheme.primary.withValues(
                      alpha: 0.12,
                    ),
                    foregroundColor: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      row.patientName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                row.servicesLabel,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                row.billLabel,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(flex: 1, child: _paidBadge(row.isPaid)),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileRow(
    ColorScheme colorScheme,
    InvoiceByServiceCategoryRow row,
    String time,
  ) {
    return Opacity(
      opacity: row.isPaid ? 1 : 0.65,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PatientAvatar(
                  firstName: row.firstName.isNotEmpty
                      ? row.firstName
                      : row.patientName,
                  surname: row.surname,
                  avatarUrl: row.avatarUrl,
                  size: 36,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                  foregroundColor: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    row.patientName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                _paidBadge(row.isPaid),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              row.servicesLabel,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${row.billLabel} • $time',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (!row.isPaid) ...[
              const SizedBox(height: 4),
              Text(
                'Bill not paid',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StartEncounterResult {
  const _StartEncounterResult({
    required this.encounterId,
    required this.patientId,
  });

  final String encounterId;
  final String patientId;
}
