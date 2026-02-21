import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

// --- MOCK DATA MODELS ---
class ServiceItem {
  final String code;
  final String title;
  final String subtitle;
  final String category;
  final double unitPrice;
  int qty;

  ServiceItem({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.unitPrice,
    this.qty = 1,
  });

  // Since there is no quantity column, the total amount simply multiples the unit price
  // internally based on how many times the user clicks the service.
  double get amount => unitPrice * qty;
}

@RoutePage()
class RenderServiceScreen extends StatefulWidget {
  const RenderServiceScreen({super.key});

  @override
  State<RenderServiceScreen> createState() => _BillingServicesViewState();
}

class _BillingServicesViewState extends State<RenderServiceScreen> {
  // Mock Data from Backend for available services
  final List<ServiceItem> _allServices = [
    ServiceItem(
      code: '99213',
      title: 'General Consultation',
      subtitle: 'Outpatient Visit Level 3',
      category: 'OPD',
      unitPrice: 150.00,
    ),
    ServiceItem(
      code: '85025',
      title: 'CBC (Hemogram)',
      subtitle: 'Complete Blood Count',
      category: 'Lab',
      unitPrice: 45.00,
    ),
    ServiceItem(
      code: 'J0123',
      title: 'Amoxicillin 500mg',
      subtitle: 'Oral Capsule',
      category: 'Pharmacy',
      unitPrice: 12.50,
    ),
    ServiceItem(
      code: '71045',
      title: 'Chest X-Ray',
      subtitle: 'Single View',
      category: 'Radiology',
      unitPrice: 85.00,
    ),
    ServiceItem(
      code: '90935',
      title: 'Hemodialysis',
      subtitle: 'Single Session',
      category: 'Dialysis',
      unitPrice: 300.00,
    ),
    ServiceItem(
      code: '99214',
      title: 'Specialist Consultation',
      subtitle: 'Outpatient Visit Level 4',
      category: 'OPD',
      unitPrice: 250.00,
    ),
    ServiceItem(
      code: '80053',
      title: 'Comprehensive Metabolic Panel',
      subtitle: 'Blood Test',
      category: 'Lab',
      unitPrice: 60.00,
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
  final List<ServiceItem> _selectedItems = [];

  // Filter Logic
  List<ServiceItem> get _filteredServices {
    return _allServices.where((s) {
      final matchesSearch =
          s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.code.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesUnit =
          _selectedUnit == 'All Services' ||
          s.category.toLowerCase() == _selectedUnit.toLowerCase();
      return matchesSearch && matchesUnit;
    }).toList();
  }

  // Calculate Total
  double get _totalDue =>
      _selectedItems.fold(0.0, (sum, item) => sum + item.amount);

  void _addToSelected(ServiceItem item) {
    setState(() {
      final existingIndex = _selectedItems.indexWhere(
        (s) => s.code == item.code,
      );
      if (existingIndex >= 0) {
        // If it already exists, silently increase the multiplier (qty)
        _selectedItems[existingIndex].qty += 1;
      } else {
        // Add a fresh copy to the selected list
        _selectedItems.add(
          ServiceItem(
            code: item.code,
            title: item.title,
            subtitle: item.subtitle,
            category: item.category,
            unitPrice: item.unitPrice,
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
  Widget build(BuildContext context) {
    // NOTE: For this Row to work properly with Expanded children containing ListViews,
    // this Widget should be placed inside a container with bounded height (like an Expanded
    // in your main screen layout, or a SizedBox with a fixed height).
    return Row(
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
        Expanded(flex: 4, child: _buildSelectedServicesPanel()),
      ],
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
            color: Colors.black.withOpacity(0.02),
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
            color: Colors.black.withOpacity(0.02),
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
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    item.code,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildCategoryBadge(item.category),
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
                              '\$${item.unitPrice.toStringAsFixed(2)}',
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
  Widget _buildSelectedServicesPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200), // Highlighted border
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                                          item.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Indicator if amount is multiplied
                                      if (item.qty > 1)
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
                                '\$${item.unitPrice.toStringAsFixed(2)}',
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
                                '\$${item.amount.toStringAsFixed(2)}',
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
                  '\$${_totalDue.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).primaryColor,
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
