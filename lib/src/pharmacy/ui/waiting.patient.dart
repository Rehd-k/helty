import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/extensions/number.extention.dart';

// -----------------------------------------------------------------------------
// MODELS
// -----------------------------------------------------------------------------
class Product {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String sku;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.sku,
    required this.category,
  });
}

class PrescriptionItem {
  final Product product;
  final int quantity;
  final String dosage;
  final String frequency;
  final String notes;

  PrescriptionItem({
    required this.product,
    required this.quantity,
    required this.dosage,
    required this.frequency,
    required this.notes,
  });
}

class Prescription {
  final String id;
  final String patientName;
  final String doctorName;
  final List<String> allergies;
  final List<String> interactions;
  final List<PrescriptionItem> items;
  final DateTime timestamp;

  Prescription({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.allergies,
    required this.interactions,
    required this.items,
    required this.timestamp,
  });
}

class CartItem {
  final Product product;
  int quantity;
  // Optional prescription details
  final String? dosage;
  final String? frequency;
  final String? notes;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.dosage,
    this.frequency,
    this.notes,
  });
}

enum ViewMode { pos, rxQueue }

// -----------------------------------------------------------------------------
// MAIN UI
// -----------------------------------------------------------------------------
@RoutePage()
class PharmacyWaitingPatientScreen extends StatefulWidget {
  const PharmacyWaitingPatientScreen({super.key});

  @override
  State<PharmacyWaitingPatientScreen> createState() =>
      _PharmacyWaitingPatientState();
}

class _PharmacyWaitingPatientState extends State<PharmacyWaitingPatientScreen> {
  // Mock Data
  final List<String> categories = [
    'All',
    'Common Drugs',
    'Antibiotics',
    'Painkillers',
    'Vitamins',
  ];

  late final List<Product> allProducts;
  late final List<Prescription> rxQueue;

  @override
  void initState() {
    super.initState();
    allProducts = [
      Product(
        id: '1',
        name: 'Amoxicillin 500mg',
        price: 12.50,
        stock: 42,
        sku: 'AM-500-12',
        category: 'Antibiotics',
      ),
      Product(
        id: '2',
        name: 'Ibuprofen 200mg',
        price: 8.00,
        stock: 120,
        sku: 'IB-200-P',
        category: 'Painkillers',
      ),
      Product(
        id: '3',
        name: 'Paracetamol 500mg',
        price: 5.25,
        stock: 88,
        sku: 'PA-500-T',
        category: 'Painkillers',
      ),
      Product(
        id: '4',
        name: 'Azithromycin 250mg',
        price: 18.90,
        stock: 15,
        sku: 'AZ-250-M',
        category: 'Antibiotics',
      ),
      Product(
        id: '5',
        name: 'Lantus Solostar',
        price: 45.00,
        stock: 8,
        sku: 'LA-SOL-8',
        category: 'Common Drugs',
      ),
      Product(
        id: '6',
        name: 'Metformin 850mg',
        price: 22.00,
        stock: 65,
        sku: 'ME-850-D',
        category: 'Common Drugs',
      ),
      Product(
        id: '7',
        name: 'Cough Syrup (EX)',
        price: 15.40,
        stock: 24,
        sku: 'CS-EX-24',
        category: 'Common Drugs',
      ),
      Product(
        id: '8',
        name: 'Saline Nasal Mist',
        price: 7.50,
        stock: 30,
        sku: 'SN-MST-30',
        category: 'Common Drugs',
      ),
    ];

    rxQueue = [
      Prescription(
        id: 'RX-8842',
        patientName: 'Alice Johnson',
        doctorName: 'Dr. Sarah Smith',
        allergies: [
          'Penicillin',
        ], // Triggers safety alert (Amoxicillin is a penicillin)
        interactions: [],
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        items: [
          PrescriptionItem(
            product: allProducts[0],
            quantity: 2,
            dosage: '500mg',
            frequency: 'Twice daily',
            notes: 'Take after meals',
          ),
          PrescriptionItem(
            product: allProducts[2],
            quantity: 1,
            dosage: '500mg',
            frequency: 'As needed',
            notes: 'For fever',
          ),
        ],
      ),
      Prescription(
        id: 'RX-8843',
        patientName: 'Robert Chase',
        doctorName: 'Dr. Gregory House',
        allergies: [],
        interactions: ['Metformin + Cough Syrup'],
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
        items: [
          PrescriptionItem(
            product: allProducts[5],
            quantity: 2,
            dosage: '850mg',
            frequency: 'Once daily',
            notes: 'With evening meal',
          ),
          PrescriptionItem(
            product: allProducts[4],
            quantity: 10,
            dosage: '100 units',
            frequency: 'Daily',
            notes: 'Keep refrigerated',
          ), // Triggers stock alert (requires 10, stock is 8)
        ],
      ),
    ];
  }

  // State
  ViewMode currentView = ViewMode.pos;
  List<CartItem> cart = [];
  String selectedCategory = 'All';
  String searchQuery = '';
  Prescription? selectedPrescription;

  // Getters
  List<Product> get filteredProducts {
    return allProducts.where((p) {
      final matchesCategory =
          selectedCategory == 'All' || p.category == selectedCategory;
      final matchesSearch =
          p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.sku.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  double get subtotal =>
      cart.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  double get vat => subtotal * 0.12;
  double get discount => 0.00;
  double get totalAmount => subtotal + vat - discount;

  // Actions
  void addToCart(Product product) {
    setState(() {
      final existingIndex = cart.indexWhere(
        (item) => item.product.id == product.id && item.dosage == null,
      ); // Don't merge with Rx items
      if (existingIndex >= 0) {
        cart[existingIndex].quantity++;
      } else {
        cart.add(CartItem(product: product));
      }
    });
  }

  void updateQuantity(CartItem item, int newQuantity) {
    setState(() {
      final index = cart.indexOf(item);
      if (index >= 0) {
        if (newQuantity <= 0) {
          cart.removeAt(index);
          if (cart.isEmpty) {
            selectedPrescription = null; // Clear Rx context if cart is emptied
          }
        } else {
          cart[index].quantity = newQuantity;
        }
      }
    });
  }

  void clearCart() {
    setState(() {
      cart.clear();
      selectedPrescription = null;
    });
  }

  void loadPrescription(Prescription rx) {
    setState(() {
      selectedPrescription = rx;
      currentView = ViewMode.pos; // Switch back to POS view to process
      cart = rx.items
          .map(
            (item) => CartItem(
              product: item.product,
              quantity: item.quantity,
              dosage: item.dosage,
              frequency: item.frequency,
              notes: item.notes,
            ),
          )
          .toList();
    });
  }

  void makePayment() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening Payment Module...')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _buildLeftPanel(colorScheme)),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: _buildMiddlePanel(colorScheme)),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: _buildRightPanel(colorScheme, theme),
                    ),
                  ],
                );
              } else {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 500,
                        child: _buildLeftPanel(colorScheme),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 500,
                        child: _buildMiddlePanel(colorScheme),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 400,
                        child: _buildRightPanel(colorScheme, theme),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LEFT PANEL: View Switcher (POS / Rx Queue)
  // ---------------------------------------------------------------------------
  Widget _buildLeftPanel(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // View Toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildToggleBtn(
                  title: 'Store Products',
                  icon: Icons.storefront,
                  isActive: currentView == ViewMode.pos,
                  onTap: () => setState(() => currentView = ViewMode.pos),
                  colorScheme: colorScheme,
                ),
              ),
              Expanded(
                child: _buildToggleBtn(
                  title: 'Dispensing Queue',
                  icon: Icons.receipt_long,
                  isActive: currentView == ViewMode.rxQueue,
                  onTap: () => setState(() => currentView = ViewMode.rxQueue),
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: currentView == ViewMode.pos
              ? _buildStoreProducts(colorScheme)
              : _buildRxQueue(colorScheme),
        ),
      ],
    );
  }

  Widget _buildToggleBtn({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreProducts(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Scan Barcode or Search Medicine...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (val) => setState(() => searchQuery = val),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final isSelected = selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => selectedCategory = cat);
                  },
                  selectedColor: colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 1.4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return InkWell(
                onTap: () => addToCart(product),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.price.toFinancial(isMoney: true),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        'Stock: ${product.stock} Units',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRxQueue(ColorScheme colorScheme) {
    if (rxQueue.isEmpty) {
      return const Center(child: Text("No prescriptions in queue."));
    }
    return ListView.separated(
      itemCount: rxQueue.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final rx = rxQueue[index];
        final timeAgo = DateTime.now().difference(rx.timestamp).inMinutes;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rx.id,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    '$timeAgo mins ago',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Patient: ${rx.patientName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Prescriber: ${rx.doctorName}',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              if (rx.allergies.isNotEmpty || rx.interactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Alerts: ${[...rx.allergies, ...rx.interactions].join(', ')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${rx.items.length} items',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  ElevatedButton(
                    onPressed: () => loadPrescription(rx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      elevation: 0,
                    ),
                    child: const Text('Process Rx'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // MIDDLE PANEL: Cart Items & Rx Details
  // ---------------------------------------------------------------------------
  Widget _buildMiddlePanel(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Rx Safety Alerts Header
          if (selectedPrescription != null &&
              (selectedPrescription!.allergies.isNotEmpty ||
                  selectedPrescription!.interactions.isNotEmpty))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.gpp_bad,
                        color: colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PATIENT SAFETY ALERT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                  if (selectedPrescription!.allergies.isNotEmpty)
                    Text(
                      'Allergies: ${selectedPrescription!.allergies.join(", ")}',
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  if (selectedPrescription!.interactions.isNotEmpty)
                    Text(
                      'Interactions: ${selectedPrescription!.interactions.join(", ")}',
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedPrescription != null
                              ? 'Rx Order: ${selectedPrescription!.id}'
                              : 'Current Order',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: cart.isEmpty ? null : clearCart,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Clear All'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'MEDICINE',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            'QUANTITY',
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'PRICE',
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cart List
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Text(
                      'Cart is empty',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      final bool isStockLow =
                          item.quantity > item.product.stock;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Medicine Info
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'SKU: ${item.product.sku}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),

                                // Electronic Prescription Details
                                if (item.dosage != null) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sig: ${item.dosage} | ${item.frequency}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        if (item.notes != null)
                                          Text(
                                            'Note: ${item.notes}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],

                                // Real-time Stock Indicator
                                if (isStockLow)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      '⚠️ Insufficient Stock (${item.product.stock} available)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      '✓ In Stock',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Quantity Controls
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildQtyBtn(
                                  Icons.remove,
                                  () => updateQuantity(item, item.quantity - 1),
                                  colorScheme,
                                ),
                                const SizedBox(width: 8),
                                QuantityEditor(
                                  quantity: item.quantity,
                                  onChanged: (newQty) =>
                                      updateQuantity(item, newQty),
                                ),
                                const SizedBox(width: 8),
                                _buildQtyBtn(
                                  Icons.add,
                                  () => updateQuantity(item, item.quantity + 1),
                                  colorScheme,
                                ),
                              ],
                            ),
                          ),

                          // Price
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                (item.product.price * item.quantity)
                                    .toFinancial(isMoney: true),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    Icons.health_and_safety,
                    'HMO SPLIT',
                    colorScheme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    Icons.sync_alt,
                    'GENERIC ALT',
                    colorScheme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    Icons.percent,
                    '% DISCOUNT',
                    colorScheme,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(
    IconData icon,
    VoidCallback onTap,
    ColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: colorScheme.onSurface),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    ColorScheme colorScheme,
  ) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RIGHT PANEL: Summary & Payment
  // ---------------------------------------------------------------------------
  Widget _buildRightPanel(ColorScheme colorScheme, ThemeData theme) {
    final customerName = selectedPrescription != null
        ? selectedPrescription!.patientName
        : 'Walk-in Customer';
    final customerSubtitle = selectedPrescription != null
        ? 'Prescriber: ${selectedPrescription!.doctorName}'
        : 'Add details';

    return Column(
      children: [
        // Customer Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                child: Icon(
                  selectedPrescription != null ? Icons.sick : Icons.person,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedPrescription != null ? 'PATIENT' : 'CUSTOMER',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      customerName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      customerSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Summary Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                _buildSummaryRow(
                  'Subtotal',
                  subtotal.toFinancial(isMoney: true),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('VAT (12%)', vat.toFinancial(isMoney: true)),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  'Discount',
                  '-${discount.toFinancial(isMoney: true)}',
                  color: colorScheme.error,
                ),

                const Spacer(),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'TOTAL AMOUNT',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      totalAmount.toFinancial(isMoney: true),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: cart.isEmpty ? null : makePayment,
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text(
                    'Make Payment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// CUSTOM QUANTITY EDITOR
// -----------------------------------------------------------------------------
class QuantityEditor extends StatefulWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const QuantityEditor({
    super.key,
    required this.quantity,
    required this.onChanged,
  });

  @override
  State<QuantityEditor> createState() => _QuantityEditorState();
}

class _QuantityEditorState extends State<QuantityEditor> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.quantity.toString());
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _commitValue();
    });
  }

  @override
  void didUpdateWidget(covariant QuantityEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity) {
      if (_controller.text != widget.quantity.toString()) {
        _controller.text = widget.quantity.toString();
      }
    }
  }

  void _commitValue() {
    final parsed = int.tryParse(_controller.text);
    if (parsed != null && parsed >= 0) {
      widget.onChanged(parsed);
    } else {
      _controller.text = widget.quantity.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 4),
          border: InputBorder.none,
        ),
        onSubmitted: (_) => _commitValue(),
      ),
    );
  }
}
