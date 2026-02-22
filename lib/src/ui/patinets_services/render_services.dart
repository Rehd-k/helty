import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/models/service_model.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_providers.dart';

import '../../billings/pay.bill.dart';
import '../../enlist_services/selected.user.dart';

@RoutePage()
class RenderServiceScreen extends ConsumerStatefulWidget {
  const RenderServiceScreen({super.key});

  @override
  ConsumerState<RenderServiceScreen> createState() =>
      _BillingServicesViewState();
}

class _BillingServicesViewState extends ConsumerState<RenderServiceScreen> {
  // Mock Data from Backend for available services

  void _openPaymentModal(
    BuildContext context,
    Patient patient,
    List<ServiceModel> selectedItems,
    double _totalDue,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // We handle the dimming inside PayBill
      builder: (context) => PayBill(
        patient: patient,
        selectedItems: selectedItems,
        total: _totalDue,
      ),
    );
  }

  final List<ServiceModel> _allServices = [
    ServiceModel(
      serviceId: '99213',
      name: 'General Consultation',
      description: 'Outpatient Visit Level 3',
      categoryId: 'OPD',
      cost: 150.00,
      id: '232',
    ),
    ServiceModel(
      serviceId: '85025',
      name: 'CBC (Hemogram)',
      description: 'Complete Blood Count',
      categoryId: 'Lab',
      cost: 45.00,
      id: 'w232',
    ),
    ServiceModel(
      serviceId: 'J0123',
      name: 'Amoxicillin 500mg',
      description: 'Oral Capsule',
      categoryId: 'Pharmacy',
      cost: 12.50,
      id: 'fh',
    ),
    ServiceModel(
      serviceId: '85025',
      name: 'CBC (Hemogram)',
      description: 'Complete Blood Count',
      categoryId: 'Lab',
      cost: 45.00,
      id: 'w232',
    ),

    ServiceModel(
      serviceId: '71045',
      name: 'Chest X-Ray',
      description: 'Single View',
      categoryId: 'Radiology',
      cost: 85.00,
      id: 'w233',
    ),

    ServiceModel(
      serviceId: '90935',
      name: 'Hemodialysis',
      description: 'Single Session',
      categoryId: 'Dialysis',
      cost: 300.00,
      id: 'w234',
    ),

    ServiceModel(
      serviceId: '99214',
      name: 'Specialist Consultation',
      description: 'Outpatient Visit Level 4',
      categoryId: 'OPD',
      cost: 250.00,
      id: 'w235',
    ),

    ServiceModel(
      serviceId: '80053',
      name: 'Comprehensive Metabolic Panel',
      description: 'Blood Test',
      categoryId: 'Lab',
      cost: 60.00,
      id: 'w236',
    ),

    // 🔥 10 More Entries
    ServiceModel(
      serviceId: '93000',
      name: 'Electrocardiogram (ECG)',
      description: 'Routine ECG with Interpretation',
      categoryId: 'Cardiology',
      cost: 120.00,
      id: 'w237',
    ),

    ServiceModel(
      serviceId: '70450',
      name: 'CT Scan - Head',
      description: 'Without Contrast',
      categoryId: 'Radiology',
      cost: 450.00,
      id: 'w238',
    ),

    ServiceModel(
      serviceId: '81002',
      name: 'Urinalysis',
      description: 'Non-automated, Without Microscopy',
      categoryId: 'Lab',
      cost: 35.00,
      id: 'w239',
    ),

    ServiceModel(
      serviceId: '90658',
      name: 'Influenza Vaccine',
      description: 'Seasonal Flu Shot',
      categoryId: 'Immunization',
      cost: 40.00,
      id: 'w240',
    ),

    ServiceModel(
      serviceId: '36415',
      name: 'Venipuncture',
      description: 'Collection of Blood Specimen',
      categoryId: 'Lab',
      cost: 20.00,
      id: 'w241',
    ),

    ServiceModel(
      serviceId: '76700',
      name: 'Abdominal Ultrasound',
      description: 'Complete Study',
      categoryId: 'Radiology',
      cost: 200.00,
      id: 'w242',
    ),

    ServiceModel(
      serviceId: '94010',
      name: 'Spirometry',
      description: 'Pulmonary Function Test',
      categoryId: 'Respiratory',
      cost: 110.00,
      id: 'w243',
    ),

    ServiceModel(
      serviceId: '85018',
      name: 'Hemoglobin Test',
      description: 'Blood Test',
      categoryId: 'Lab',
      cost: 25.00,
      id: 'w244',
    ),

    ServiceModel(
      serviceId: '12001',
      name: 'Simple Wound Repair',
      description: 'Small Laceration',
      categoryId: 'Emergency',
      cost: 150.00,
      id: 'w245',
    ),

    ServiceModel(
      serviceId: '96372',
      name: 'Therapeutic Injection',
      description: 'Intramuscular Injection',
      categoryId: 'Treatment',
      cost: 75.00,
      id: 'w246',
    ),
  ];

  final List<String> _hospitalUnits = [
    'All Services',
    'Pharmacy',
    'Lab',
    'Dialysis',
    'Radiology',
    'OPD',
    'Procedures',
  ];

  final List<String> _filterCategories = [
    'Consultation',
    'Blood Test',
    'Imaging',
    'Medication',
    'Consumables',
  ];

  String _selectedUnit = 'All Services';
  String _searchQuery = '';

  // Mock Selected Items (The Cart)
  final List<ServiceModel> _selectedItems = [];

  // Filter Logic
  List<ServiceModel> get _filteredServices {
    return _allServices.where((s) {
      final matchesSearch =
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesUnit =
          _selectedUnit == 'All Services' ||
          s.categoryId?.toLowerCase() == _selectedUnit.toLowerCase();
      return matchesSearch && matchesUnit;
    }).toList();
  }

  // Calculate Total
  double get _totalDue =>
      _selectedItems.fold(0.0, (sum, item) => sum + item.cost);

  void _addToSelected(ServiceModel item) {
    setState(() {
      final existingIndex = _selectedItems.indexWhere(
        (s) => s.serviceId == item.serviceId,
      );
      if (existingIndex >= 0) {
        // If it already exists, silently increase the multiplier (qty)
        _selectedItems[existingIndex].qty =
            (_selectedItems[existingIndex].qty ?? 0) + 1;
      } else {
        // Add a fresh copy to the selected list
        _selectedItems.add(
          ServiceModel(
            serviceId: item.serviceId,
            name: item.name,
            description: item.description,
            categoryId: item.categoryId,
            cost: item.cost,
            qty: 1,
            id: 'uhi',
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
  Widget build(BuildContext context) {
    final selectedPatient = ref.watch(patientProvider).selectedPatient;
    return Scaffold(
      appBar: AppBar(),
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
                ],
              ),
            ),

            const SizedBox(width: 16),

            // ==========================================
            // RIGHT PANE: SELECTED SERVICES TABLE
            // ==========================================
            Expanded(
              flex: 4,
              child: _buildSelectedServicesPanel(selectedPatient!),
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
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: "Search services, meds, or CPT...",
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filters Row
          Row(
            children: [
              // Horizontal Scrollable Chips
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _hospitalUnits.map((unit) {
                      final isSelected = _selectedUnit == unit;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedUnit = unit;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue.shade600
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue.shade600
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (unit == 'All Services') ...[
                                  Icon(
                                    Icons.grid_view,
                                    size: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  unit,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade800,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Funnel Dropdown (Categories)
              Container(
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.filter_list, color: Colors.grey.shade700),
                  tooltip: 'Filter by Category',
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) {
                    return _filterCategories.map((category) {
                      return PopupMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList();
                  },
                  onSelected: (value) {
                    debugPrint("Selected category filter: $value");
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableServicesList() {
    final items = _filteredServices;

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
      child: items.isEmpty
          ? Center(
              child: Text(
                "No services found.",
                style: TextStyle(color: Colors.grey.shade500),
              ),
            )
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  onTap: () => _addToSelected(item),
                  hoverColor: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Details
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
                                  _buildCategoryBadge(item.categoryId ?? ''),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Price & Action
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
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

  // =========================================================================
  // RIGHT PANE COMPONENTS
  // =========================================================================
  Widget _buildSelectedServicesPanel(Patient selectedPatient) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200), // Highlighted border
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
          SelectedPatientCard(),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Services',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
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
                _headerCell('UNIT PRICE', flex: 2),
                _headerCell('AMOUNT', flex: 2),
                _headerCell('', flex: 1), // Delete Icon
              ],
            ),
          ),

          // Table Body (The Selected Items List)
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
                            // Description
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
                                      // Indicator if amount is multiplied
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

                            // Unit Price
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

                            // Total Amount (UnitPrice * Hidden Qty)
                            Expanded(
                              flex: 2,
                              child: Text(
                                item.cost.toFinancial(isMoney: true),
                                style: TextStyle(
                                  color: Colors.grey.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                            // Remove Icon
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
                Text(
                  _totalDue.toFinancial(isMoney: true),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _openPaymentModal(
                      context,
                      selectedPatient,
                      _selectedItems,
                      _totalDue,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40), // fully rounded
                    ),
                  ),
                  child: const Text(
                    "Make Payment",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
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
