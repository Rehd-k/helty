import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/models/invoice.dart';
import 'package:helty/src/models/invoice_billing_models.dart';
import 'package:helty/src/models/service_model.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/models/ward_models.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_providers.dart';
import 'package:helty/src/paitients/patient.state.dart';
import 'package:helty/src/paitients/patient_service.dart';

import '../../billings/pay.bill.dart';
import '../../enlist_services/selected.user.dart';
import '../../models/service_category_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/module_request_flow_provider.dart';
import '../../services/hmo_service.dart';
import '../../services/department_service.dart';
import '../../services/invoice_service.dart';
import '../../services/service_category_service.dart';
import '../../services/service_service.dart';
import '../../services/ward_service.dart';
import '../../widgets/receipt_escpos_service.dart';
import '../../widgets/receipt_printer_picker_sheet.dart';

@RoutePage()
class RenderServiceScreen extends ConsumerStatefulWidget {
  const RenderServiceScreen({super.key});

  @override
  ConsumerState<RenderServiceScreen> createState() =>
      _BillingServicesViewState();
}

class _BillingServicesViewState extends ConsumerState<RenderServiceScreen> {
  final _deptSvc = DepartmentService();
  final _catSvc = ServiceCategoryService();
  final _srvSvc = ServiceService();

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── list data ─────────────────────────────────────────────────────────────
  List<Department> _departments = [];
  List<ServiceCategory> _categories = [];
  List<ServiceModel> _services = [];
  bool _loading = false;

  // ── filter & pagination state ─────────────────────────────────────────────
  String _searchQuery = '';
  String? _selectedCategoryId; // null = all categories
  String? _selectedDepartmentId; // null = all departments
  int _skip = 0;
  static const int _take = 10;
  bool _hasMore = true; // becomes false when API returns fewer than _take
  ModuleRequestFlowConfig _flowConfig = ModuleRequestFlowConfig.defaultBilling;

  // Debounce timer for the search bar
  Timer? _debounce;

  // ── API calls ─────────────────────────────────────────────────────────────

  /// Loads departments and categories once on init.
  Future<void> _loadMeta() async {
    try {
      final results = await Future.wait([
        _deptSvc.fetchDepartments(),
        _catSvc.fetchCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _departments = results[0] as List<Department>;
        _categories = results[1] as List<ServiceCategory>;
        if (_flowConfig.forcedCategoryNames.isNotEmpty) {
          final forcedIds = _categories
              .where(
                (c) => _flowConfig.forcedCategoryNames
                    .map((e) => e.toLowerCase())
                    .contains(c.name.toLowerCase()),
              )
              .map((e) => e.id)
              .toSet();
          if (forcedIds.length == 1) {
            _selectedCategoryId = forcedIds.first;
          }
        }
      });
    } catch (e) {
      _snack('Failed to load filters: $e');
    }
  }

  /// Fetches services using the current filter + pagination state.
  Future<void> _loadServices({bool resetPage = false}) async {
    if (resetPage) {
      _skip = 0;
      _hasMore = true;
    }
    setState(() => _loading = true);
    try {
      final results = await _srvSvc.fetchServices(
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoryId: _selectedCategoryId,
        departmentId: _selectedDepartmentId,
        skip: _flowConfig.isModuleFlow ? 0 : _skip,
        take: _flowConfig.isModuleFlow ? 200 : _take,
      );
      if (!mounted) return;
      var filteredResults = results;
      if (_flowConfig.forcedCategoryNames.isNotEmpty) {
        final allowed = _flowConfig.forcedCategoryNames
            .map((e) => e.toLowerCase())
            .toSet();
        filteredResults = results
            .where(
              (s) => allowed.contains((s.categoryName ?? '').toLowerCase()),
            )
            .toList();
      }
      setState(() {
        _services = filteredResults;
        _hasMore = _flowConfig.isModuleFlow
            ? false
            : filteredResults.length >= _take;
      });
    } catch (e) {
      _snack('Failed to load services: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── lifecycle ─────────────────────────────────────────────────────────────

  bool _payAtPosBusy = false;
  bool _depositBusy = false;

  /// When HMO desk + patient has [Patient.hmoId], map catalog service id → patient co-pay.
  Map<String, double> _hmoPatientPaysByServiceId = {};
  String? _hmoPricesLoadedFor;

  bool get _useHmoPatientPricing {
    final staff = ref.read(authProvider).staff;
    final flow = ref.read(moduleRequestFlowProvider);
    final patient = ref.read(patientProvider).selectedPatient;
    final hid = patient?.hmoId?.trim();
    if (hid == null || hid.isEmpty) return false;
    return staff?.accountType == AccountType.hmo ||
        flow.type == ModuleRequestFlowType.hmo;
  }

  double _effectiveUnitPrice(ServiceModel item) {
    final sid = item.id.trim().isNotEmpty ? item.id.trim() : item.serviceId.trim();
    if (sid.isNotEmpty) {
      final p = _hmoPatientPaysByServiceId[sid];
      if (p != null) return p;
    }
    return item.cost;
  }

  Future<void> _refreshHmoPricingIfNeeded() async {
    if (!_useHmoPatientPricing) {
      if (_hmoPatientPaysByServiceId.isNotEmpty || _hmoPricesLoadedFor != null) {
        if (mounted) {
          setState(() {
            _hmoPatientPaysByServiceId = {};
            _hmoPricesLoadedFor = null;
          });
        }
      }
      return;
    }
    final patient = ref.read(patientProvider).selectedPatient;
    final hid = patient?.hmoId?.trim() ?? '';
    if (hid.isEmpty) return;
    if (_hmoPricesLoadedFor == hid && _hmoPatientPaysByServiceId.isNotEmpty) {
      return;
    }
    try {
      final detail = await HmoService().getById(hid);
      final map = <String, double>{};
      for (final row in detail.servicePrices) {
        final sid = row.serviceId.trim();
        if (sid.isNotEmpty) map[sid] = row.patientPays;
        final nested = row.service?.id.trim() ?? '';
        if (nested.isNotEmpty) map[nested] = row.patientPays;
      }
      if (!mounted) return;
      setState(() {
        _hmoPatientPaysByServiceId = map;
        _hmoPricesLoadedFor = hid;
        final previous = List<ServiceModel>.from(_selectedItems);
        _selectedItems
          ..clear()
          ..addAll(
            previous.map((line) {
              final sid = line.id.trim().isNotEmpty ? line.id : line.serviceId;
              final p = map[sid];
              if (p == null) return line;
              return ServiceModel(
                id: line.id,
                serviceId: line.serviceId,
                name: line.name,
                description: line.description,
                categoryId: line.categoryId,
                categoryName: line.categoryName,
                departmentId: line.departmentId,
                departmentName: line.departmentName,
                cost: p,
                qty: line.qty,
                isRecurringDaily: line.isRecurringDaily,
              );
            }),
          );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hmoPatientPaysByServiceId = {};
        _hmoPricesLoadedFor = null;
      });
    }
  }

  /// Creates an invoice with cart lines, then opens [PayBill] with [invoiceId] for invoice-led payment.
  Future<void> _openPayAtPosWithInvoice(
    Patient? patient,
    List<ServiceModel> selectedItems,
    double totalDue,
    String staffId,
  ) async {
    if (patient == null) {
      _snack('Please select a patient before making a payment.');
      return;
    }
    if (totalDue <= 0) {
      _snack('No items selected or total amount is zero.');
      return;
    }
    final patientUuid = _resolvePatientUuidForInvoice(selectedPatient: patient);
    if (patientUuid == null) {
      _snack(
        'Cannot pay: patient needs a server id (UUID). '
        'Use a registered patient.',
      );
      return;
    }

    final validLines = <ServiceModel>[];
    for (final line in selectedItems) {
      final sid = line.id.trim().isNotEmpty ? line.id : line.serviceId;
      if (sid.isEmpty) continue;
      validLines.add(line);
    }
    if (validLines.isEmpty) {
      _snack('No valid service lines to invoice.');
      return;
    }

    try {
      final svc = InvoiceService();
      final created = await svc.createBillingInvoice(
        patientId: patientUuid,
        staffId: staffId,
      );
      for (final line in validLines) {
        final sid = line.id.trim().isNotEmpty ? line.id : line.serviceId;
        if (sid.isEmpty) continue;
        await svc.addBillingItem(
          invoiceId: created.id,
          payload: AddInvoiceItemPayload(
            serviceId: sid,
            unitPrice: line.cost,
            quantity: line.qty ?? 1,
            isRecurringDaily: line.isRecurringDaily,
          ),
        );
      }
      final invoice = await svc.getBillingInvoice(created.id);
      final outstanding = invoice.netAmountDue > 0
          ? invoice.netAmountDue
          : (invoice.amountDue > 0
                ? invoice.amountDue
                : (invoice.totalAmount - invoice.amountPaid));
      if (outstanding <= 0) {
        _snack(
          'Invoice created but no billable balance found. Please refresh and try again.',
        );
        return;
      }
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierColor: Colors.transparent,
        builder: (ctx) => PayBill(
          patientId: patient.patientId,
          firstName: patient.firstName,
          lastName: patient.surname,
          selectedItems: selectedItems,
          total: outstanding,
          staffId: staffId,
          onPaymentComplete: _emptySelection,
          isInvoice: true,
          invoiceId: invoice.id,
        ),
      );
    } catch (e) {
      _snack('Failed to create invoice: $e');
    }
  }

  // Mock Selected Items (The Cart)
  final List<ServiceModel> _selectedItems = [];

  // Calculate Total (unit cost × quantity)
  double get _totalDue => _selectedItems.fold(
    0.0,
    (sum, item) => sum + item.cost * (item.qty ?? 1),
  );

  void _addToSelected(ServiceModel item) {
    setState(() {
      final existingIndex = _selectedItems.indexWhere(
        (s) => s.serviceId == item.serviceId,
      );
      if (existingIndex >= 0) {
        _selectedItems[existingIndex].qty =
            (_selectedItems[existingIndex].qty ?? 0) + 1;
      } else {
        _selectedItems.add(
          ServiceModel(
            id: item.id,
            serviceId: item.serviceId,
            name: item.name,
            description: item.description,
            categoryId: item.categoryId,
            categoryName: item.categoryName,
            departmentId: item.departmentId,
            departmentName: item.departmentName,
            cost: _effectiveUnitPrice(item),
            qty: 1,
          ),
        );
      }
    });
  }

  void _removeSelected(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
  }

  void _emptySelection() {
    setState(() {
      _selectedItems.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _flowConfig = ref.read(moduleRequestFlowProvider);
    _loadMeta();
    _loadServices();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshHmoPricingIfNeeded();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // ── pagination helpers ────────────────────────────────────────────────────

  void _nextPage() {
    if (!_hasMore) return;
    _skip += _take;
    _loadServices();
  }

  void _prevPage() {
    if (_skip == 0) return;
    _skip = (_skip - _take).clamp(0, double.maxFinite.toInt());
    _loadServices();
  }

  int get _currentPage => (_skip ~/ _take) + 1;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final patientState = ref.watch(patientProvider);
    final selectedPatient = patientState.selectedPatient;
    ref.listen<PatientState>(patientProvider, (prev, next) {
      final a = prev?.selectedPatient?.id;
      final b = next.selectedPatient?.id;
      if (a != b) {
        Future.microtask(_refreshHmoPricingIfNeeded);
      }
    });
    final accountType = auth.staff?.accountType?.name.toLowerCase() ?? '';
    final role = auth.staff?.role.toLowerCase() ?? '';
    final isBillingUser =
        accountType == 'billing' ||
        accountType == 'bills' ||
        accountType == 'hmo' ||
        role == 'billing_head' ||
        role == 'billing_staff' ||
        role == 'billing' ||
        role == 'hmo_staff';
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (selectedPatient != null) ...[
            IconButton(
              tooltip: 'Take deposit',
              onPressed: _depositBusy
                  ? null
                  : () => _openDepositDialog(
                      selectedPatient: selectedPatient,
                      auth: auth,
                      printReceiptForBilling: isBillingUser,
                    ),
              icon: const Icon(Icons.account_balance_wallet_outlined),
            ),
            IconButton(
              tooltip: 'Change patient status',
              onPressed: () => _openStatusDialog(
                selectedPatient,
                requireWardWhenAdmitted: isBillingUser,
              ),
              icon: const Icon(Icons.manage_accounts_outlined),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // LEFT PANE: SEARCH & AVAILABLE SERVICES
            // ==========================================
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchAndFilterCard(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildAvailableServicesList()),
                  const SizedBox(height: 8),
                  _buildPagination(),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // ==========================================
            // RIGHT PANE: SELECTED SERVICES TABLE
            // ==========================================
            Expanded(
              flex: 4,
              child: _buildSelectedServicesPanel(selectedPatient, auth),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // LEFT PANE COMPONENTS
  // =========================================================================
  Widget _buildSearchAndFilterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              onChanged: (val) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  setState(() => _searchQuery = val);
                  _loadServices(resetPage: true);
                });
              },
              decoration: InputDecoration(
                hintText: "Search services, meds, or CPT...",
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                suffixIcon: _loading
                    ? Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue.shade400,
                          ),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filters Row
          Row(
            children: [
              // Horizontal Scrollable Department Chips
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // "All" chip
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildDeptChip(
                          label: 'All Services',
                          isSelected: _selectedDepartmentId == '',
                          onTap: () {
                            setState(() => _selectedDepartmentId = '');
                            _loadServices(resetPage: true);
                          },
                          showGridIcon: true,
                        ),
                      ),
                      ..._departments.map((unit) {
                        final isSelected = _selectedDepartmentId == unit.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _buildDeptChip(
                            label: unit.name,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedDepartmentId = isSelected
                                    ? null
                                    : unit.id;
                              });
                              _loadServices(resetPage: true);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Category Dropdown
              if (!_flowConfig.isModuleFlow)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: _selectedCategoryId == ''
                        ? Colors.blue.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: _selectedCategoryId == ''
                        ? Border.all(color: Colors.blue.shade300)
                        : null,
                  ),
                  child: PopupMenuButton<String?>(
                    icon: Icon(
                      Icons.filter_list,
                      color: _selectedCategoryId == ""
                          ? Colors.blue.shade700
                          : Colors.grey.shade700,
                    ),
                    tooltip: 'Filter by Category',
                    offset: const Offset(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => [
                      // "All Categories" clear option
                      const PopupMenuItem<String?>(
                        value: "",
                        child: Row(
                          children: [
                            Icon(Icons.clear, size: 16),
                            SizedBox(width: 8),
                            Text('All Categories'),
                          ],
                        ),
                      ),
                      ..._categories.map((category) {
                        final isCurrent = _selectedCategoryId == category.id;
                        return PopupMenuItem<String?>(
                          value: category.id,
                          child: Row(
                            children: [
                              if (isCurrent)
                                Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.blue.shade600,
                                )
                              else
                                const SizedBox(width: 16),
                              const SizedBox(width: 8),
                              Text(category.name),
                            ],
                          ),
                        );
                      }),
                    ],
                    onSelected: (value) {
                      setState(() => _selectedCategoryId = value);
                      _loadServices(resetPage: true);
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeptChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool showGridIcon = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue.shade600 : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            if (showGridIcon) ...[
              Icon(
                Icons.grid_view,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade800,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableServicesList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
          ? Center(
              child: Text(
                "No services found.",
                style: TextStyle(color: Colors.grey.shade500),
              ),
            )
          : ListView.separated(
              itemCount: _services.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final item = _services[index];
                return InkWell(
                  onTap: () => _addToSelected(item),
                  hoverColor: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    item.serviceId,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildCategoryBadge(
                                    item.departmentName ?? '',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!_flowConfig.hideServicePrices)
                              Text(
                                item.cost.toFinancial(isMoney: true),
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'Click to Add',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ── Pagination bar ────────────────────────────────────────────────────────
  Widget _buildPagination() {
    if (_flowConfig.isModuleFlow) {
      return const SizedBox.shrink();
    }
    final canGoBack = _skip > 0;
    final canGoNext = _hasMore;
    // Show how many items are on the current page and a "more" indicator
    final showing = _services.length;
    final from = _skip + 1;
    final to = _skip + showing;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Item range label (left)
          if (showing > 0)
            Text(
              showing == 0 ? '' : '$from–$to${_hasMore ? '+' : ''}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: canGoBack ? _prevPage : null,
            color: canGoBack ? Colors.blue.shade600 : Colors.grey.shade300,
            tooltip: 'Previous page',
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Page $_currentPage',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: canGoNext ? _nextPage : null,
            color: canGoNext ? Colors.blue.shade600 : Colors.grey.shade300,
            tooltip: 'Next page',
          ),
          const Spacer(),
          // "more" badge on the right
          AnimatedOpacity(
            opacity: _hasMore ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                'More pages ›',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // RIGHT PANE COMPONENTS
  // =========================================================================
  Widget _buildSelectedServicesPanel(Patient? selectedPatient, AuthState auth) {
    final hasPatient = selectedPatient != null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasPatient)
            const SelectedPatientCard()
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.person_search_outlined,
                    color: Colors.orange.shade400,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Please select a patient to continue.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Selected Services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                if (_selectedItems.isNotEmpty)
                  TextButton.icon(
                    onPressed: _emptySelection,
                    icon: const Icon(
                      Icons.delete_sweep,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                    label: const Text(
                      'Empty Selection',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                _headerCell('DESCRIPTION', flex: 4),
                if (!_flowConfig.hideServicePrices) ...[
                  _headerCell('UNIT PRICE', flex: 2),
                  _headerCell('AMOUNT', flex: 2),
                ],
                _headerCell('', flex: 1),
              ],
            ),
          ),

          // Table Body
          Expanded(
            child: _selectedItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No services selected yet.\nClick on a service from the left to add it.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _selectedItems.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final item = _selectedItems[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (item.qty! > 1)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 6,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: Colors.orange.shade200,
                                            ),
                                          ),
                                          child: Text(
                                            'x${item.qty}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange.shade800,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (!_flowConfig.hideServicePrices) ...[
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.cost.toFinancial(isMoney: true),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  (item.cost * (item.qty ?? 1)).toFinancial(
                                    isMoney: true,
                                  ),
                                  style: TextStyle(
                                    color: Colors.grey.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () => _removeSelected(index),
                                  tooltip: 'Remove',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Total Amount Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AMOUNT DUE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    letterSpacing: 1,
                  ),
                ),
                if (!_flowConfig.hideServicePrices)
                  Text(
                    _totalDue.toFinancial(isMoney: true),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                _footerCheckoutButton(
                  auth: auth,
                  selectedPatient: selectedPatient,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SHARED HELPERS
  // =========================================================================
  Widget _footerCheckoutButton({
    required AuthState auth,
    required Patient? selectedPatient,
  }) {
    final staff = auth.staff;
    if (staff == null) {
      return const SizedBox.shrink();
    }
    final admitted =
        selectedPatient != null &&
        patientStatusIsAdmitted(selectedPatient.status);
    // Module-only flows always send items to invoice without Card payment.
    final usePayAtPos = !_flowConfig.sendToBillOnly && !admitted;

    if (usePayAtPos) {
      return ElevatedButton(
        onPressed: (_selectedItems.isEmpty || _payAtPosBusy)
            ? null
            : () async {
                setState(() => _payAtPosBusy = true);
                try {
                  await _openPayAtPosWithInvoice(
                    selectedPatient,
                    _selectedItems,
                    _totalDue,
                    staff.id,
                  );
                } finally {
                  if (mounted) setState(() => _payAtPosBusy = false);
                }
              },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        child: _payAtPosBusy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Pay',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      );
    }

    return ElevatedButton(
      onPressed: _selectedItems.isEmpty
          ? null
          : () => _handleSendToBill(selectedPatient: selectedPatient),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      ),
      child: Text(
        _flowConfig.isModuleFlow ? 'Send To Bill' : 'Send To Bills',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Backend `/invoices` routes expect the patient's internal UUID, not the display `patientId`.
  static bool _looksLikeUuid(String s) {
    final t = s.trim();
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(t);
  }

  static String? _resolvePatientUuidForInvoice({
    required Patient? selectedPatient,
  }) {
    final id = selectedPatient?.id?.trim() ?? '';
    return _looksLikeUuid(id) ? id : null;
  }

  /// Prefer a non-terminal invoice; do not attach lines to paid/cancelled bills from this flow.
  static Invoice? _pickOpenInvoice(List<Invoice> list) {
    if (list.isEmpty) return null;
    bool isOpen(Invoice i) {
      final s = i.status.toUpperCase();
      return s != 'PAID' &&
          s != 'FULLY_PAID' &&
          s != 'CANCELLED' &&
          s != 'VOID';
    }

    final open = list.where(isOpen).toList();
    if (open.isEmpty) return null;
    open.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return open.first;
  }

  Future<void> _handleSendToBill({required Patient? selectedPatient}) async {
    if (_selectedItems.isEmpty) return;
    final patientUuid = _resolvePatientUuidForInvoice(
      selectedPatient: selectedPatient,
    );
    if (patientUuid == null) {
      _snack(
        'Cannot add to bill: patient needs a server id (UUID). '
        'Use a registered patient, or open billing from Inpatient Bills.',
      );
      return;
    }
    try {
      final svc = InvoiceService();
      final list = await svc.getPatientInvoices(patientUuid);
      String? invoiceId = _pickOpenInvoice(list)?.id;
      if (invoiceId == null) {
        if (_flowConfig.sendToBillOnly) {
          final staffId = ref.read(authProvider).staff?.id ?? '';
          if (staffId.isEmpty) {
            _snack('Unable to send to bill: missing logged-in staff.');
            return;
          }
          final created = await svc.createBillingInvoice(
            patientId: patientUuid,
            staffId: staffId,
          );
          invoiceId = created.id;
        } else {
          _snack(
            'No open invoice for this patient (only paid or closed bills). '
            'Use Inpatient Bills if a new admission invoice is needed.',
          );
          return;
        }
      }
      for (final line in _selectedItems) {
        final sid = line.id.trim().isNotEmpty ? line.id : line.serviceId;
        if (sid.isEmpty) continue;
        await svc.addBillingItem(
          invoiceId: invoiceId,
          payload: AddInvoiceItemPayload(
            serviceId: sid,
            unitPrice: line.cost,
            quantity: line.qty ?? 1,
          ),
        );
      }
      if (!mounted) return;
      _emptySelection();
      _snack(
        _flowConfig.sendToBillOnly
            ? 'Services sent to bill successfully.'
            : 'Services added to patient invoice.',
      );
    } catch (e) {
      _snack('Failed to add to bill: $e');
    }
  }

  Future<void> _openDepositDialog({
    required Patient selectedPatient,
    required AuthState auth,
    required bool printReceiptForBilling,
  }) async {
    final amountController = TextEditingController();
    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Take Deposit'),
            content: TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Deposit amount',
                hintText: 'Enter amount',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: _depositBusy
                    ? null
                    : () async {
                        final amount = double.tryParse(
                          amountController.text.trim(),
                        );
                        if (amount == null || amount <= 0) {
                          _snack('Enter a valid deposit amount.');
                          return;
                        }
                        final patientUuid = _resolvePatientUuidForInvoice(
                          selectedPatient: selectedPatient,
                        );
                        if (patientUuid == null) {
                          _snack(
                            'Cannot deposit: patient needs a server id (UUID).',
                          );
                          return;
                        }
                        setState(() => _depositBusy = true);
                        try {
                          await InvoiceService().depositToWallet(
                            patientId: patientUuid,
                            payload: WalletDepositPayload(
                              amount: amount,
                              reference: 'deposit',
                              staffId: auth.staff?.id,
                            ),
                          );
                          if (!mounted) return;
                          Navigator.of(ctx).pop();
                          _snack('Deposit recorded successfully.');
                          if (printReceiptForBilling && mounted) {
                            final data = ReceiptEscposService.fromPayBillSnapshot(
                              patientName:
                                  '${selectedPatient.firstName} ${selectedPatient.surname}'
                                      .trim(),
                              patientId: selectedPatient.patientId,
                              cashierFirst: auth.staff?.firstName ?? '',
                              cashierLast: auth.staff?.lastName ?? '',
                              itemSnapshots: [
                                {
                                  'description': 'Wallet deposit',
                                  'quantity': 1,
                                  'total': amount.toStringAsFixed(2),
                                },
                              ],
                              totalAmount: amount,
                              discountAmount: 0,
                              amountPaid: amount,
                            );
                            await showReceiptPrinterPickerSheet(
                              context,
                              data: data,
                            );
                          }
                        } catch (e) {
                          _snack('Failed to record deposit: $e');
                        } finally {
                          if (mounted) setState(() => _depositBusy = false);
                        }
                      },
                child: _depositBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Deposit'),
              ),
            ],
          );
        },
      );
    } finally {
      amountController.dispose();
    }
  }

  Future<void> _openStatusDialog(
    Patient selectedPatient, {
    required bool requireWardWhenAdmitted,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _PatientStatusDialog(
        patient: selectedPatient,
        requireWardWhenAdmitted: requireWardWhenAdmitted,
        patientService: ref.read(patientServiceProvider),
        onSuccess: (updated) {
          ref.read(patientProvider.notifier).selectPatient(updated);
          _snack('Patient status updated to ${updated.status}.');
        },
      ),
    );
  }

  Widget _headerCell(String title, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    Color bgColor;
    Color textColor;

    switch (category.toLowerCase()) {
      case 'opd':
      case 'clinic':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        break;
      case 'lab':
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        break;
      case 'pharmacy':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'radiology':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PatientStatusDialog extends StatefulWidget {
  const _PatientStatusDialog({
    required this.patient,
    required this.requireWardWhenAdmitted,
    required this.patientService,
    required this.onSuccess,
  });

  final Patient patient;
  final bool requireWardWhenAdmitted;
  final PatientService patientService;
  final void Function(Patient updated) onSuccess;

  @override
  State<_PatientStatusDialog> createState() => _PatientStatusDialogState();
}

class _PatientStatusDialogState extends State<_PatientStatusDialog> {
  static const List<String> _statuses = ['ADMITED', 'DECEASED', 'OUTPATIENT'];

  final WardService _wardService = WardService();

  late String _selected;
  List<Ward> _wards = const [];
  Ward? _selectedWard;
  List<Bed> _beds = const [];
  Bed? _selectedBed;
  bool _loadingWards = false;
  bool _loadingBeds = false;
  String? _wardLoadError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.patient.status ?? 'OUTPATIENT';
    if (!_statuses.contains(_selected)) {
      _selected = patientStatusIsAdmitted(widget.patient.status)
          ? 'ADMITED'
          : 'OUTPATIENT';
    }
    if (widget.requireWardWhenAdmitted && _selected == 'ADMITED') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadWards());
    }
  }

  Future<void> _onStatusRadioChanged(String? value) async {
    if (value == null) return;
    setState(() {
      _selected = value;
      if (value != 'ADMITED') {
        _wards = const [];
        _selectedWard = null;
        _beds = const [];
        _selectedBed = null;
        _wardLoadError = null;
      }
    });
    if (value == 'ADMITED' && widget.requireWardWhenAdmitted) {
      await _loadWards();
    }
  }

  Future<void> _loadWards() async {
    setState(() {
      _loadingWards = true;
      _wardLoadError = null;
    });
    try {
      final list = await _wardService.fetchWards();
      if (!mounted) return;
      setState(() {
        _wards = list;
        _loadingWards = false;
        _selectedWard = list.isNotEmpty ? list.first : null;
        _beds = const [];
        _selectedBed = null;
      });
      if (_selectedWard != null) {
        await _loadBedsForWard(_selectedWard!.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingWards = false;
        _wardLoadError = e.toString();
      });
    }
  }

  Future<void> _loadBedsForWard(String wardId) async {
    setState(() {
      _loadingBeds = true;
      _selectedBed = null;
      _beds = const [];
    });
    try {
      final beds = await _wardService.fetchBedsForWard(wardId);
      if (!mounted) return;
      final free = beds
          .where((b) => b.status != BedStatus.occupied)
          .toList(growable: false);
      setState(() {
        _beds = free;
        _selectedBed = free.isNotEmpty ? free.first : null;
        _loadingBeds = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingBeds = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load beds: $e')));
    }
  }

  Future<void> _submit() async {
    if (widget.patient.id == null || widget.patient.id!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot update status: missing patient id.'),
        ),
      );
      return;
    }
    if (_selected == 'ADMITED' && widget.requireWardWhenAdmitted) {
      if (_selectedWard == null || _selectedBed == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Select a ward and an available bed before admitting.',
            ),
          ),
        );
        return;
      }
    }
    setState(() => _submitting = true);
    try {
      final Patient draft;
      if (_selected == 'ADMITED' && widget.requireWardWhenAdmitted) {
        draft = widget.patient.withStatusWardBed(
          'ADMITED',
          ward: _selectedWard!.name,
          wardId: _selectedWard!.id,
          bedNumber: _selectedBed!.bedNumber,
          bedId: _selectedBed!.id,
          admissionDate: DateTime.now(),
        );
      } else {
        draft = widget.patient.withStatus(_selected);
      }
      final updated = await widget.patientService.updatePatient(
        draft,
        widget.patient.id,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSuccess(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showWardBed =
        widget.requireWardWhenAdmitted && _selected == 'ADMITED';

    return AlertDialog(
      title: const Text('Change Patient Status'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._statuses.map(
                (status) => RadioListTile<String>(
                  value: status,
                  groupValue: _selected,
                  title: Text(status),
                  onChanged: _submitting ? null : _onStatusRadioChanged,
                ),
              ),
              if (showWardBed) ...[
                const Divider(height: 24),
                Text(
                  'Ward & bed (billing admission)',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (_loadingWards)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_wardLoadError != null)
                  Text(
                    _wardLoadError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
                  )
                else ...[
                  DropdownButtonFormField<Ward>(
                    initialValue: _selectedWard,
                    decoration: const InputDecoration(
                      labelText: 'Ward',
                      border: OutlineInputBorder(),
                    ),
                    items: _wards
                        .map(
                          (w) =>
                              DropdownMenuItem(value: w, child: Text(w.name)),
                        )
                        .toList(),
                    onChanged: _submitting || _wards.isEmpty
                        ? null
                        : (w) {
                            if (w == null) return;
                            setState(() => _selectedWard = w);
                            _loadBedsForWard(w.id);
                          },
                  ),
                  const SizedBox(height: 12),
                  if (_loadingBeds)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else
                    DropdownButtonFormField<Bed>(
                      initialValue: _selectedBed,
                      decoration: const InputDecoration(
                        labelText: 'Bed',
                        border: OutlineInputBorder(),
                      ),
                      items: _beds
                          .map(
                            (b) => DropdownMenuItem(
                              value: b,
                              child: Text(b.bedNumber),
                            ),
                          )
                          .toList(),
                      onChanged: _submitting || _beds.isEmpty
                          ? null
                          : (b) => setState(() => _selectedBed = b),
                    ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}
