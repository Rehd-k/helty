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

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

// -----------------------------------------------------------------------------
// MAIN UI
// -----------------------------------------------------------------------------
@RoutePage()
class PharmacyPOSScreen extends StatefulWidget {
  const PharmacyPOSScreen({super.key});

  @override
  State<PharmacyPOSScreen> createState() => _PharmacyPOSState();
}

class _PharmacyPOSState extends State<PharmacyPOSScreen> {
  // Mock Data
  final List<String> categories = [
    'All',
    'Common Drugs',
    'Antibiotics',
    'Painkillers',
    'Vitamins',
  ];

  final List<Product> allProducts = [
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

  List<CartItem> cart = [];
  String selectedCategory = 'All';
  String searchQuery = '';

  // Getters for filtered products and totals
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
  double get vat => subtotal * 0.12; // Assuming 12% VAT
  double get discount => 0.00; // Placeholder for discount logic
  double get totalAmount => subtotal + vat - discount;

  // Actions
  void addToCart(Product product) {
    setState(() {
      final existingIndex = cart.indexWhere(
        (item) => item.product.id == product.id,
      );
      if (existingIndex >= 0) {
        cart[existingIndex].quantity++;
      } else {
        cart.add(CartItem(product: product));
      }
    });
  }

  void updateQuantity(Product product, int newQuantity) {
    setState(() {
      final index = cart.indexWhere((item) => item.product.id == product.id);
      if (index >= 0) {
        if (newQuantity <= 0) {
          cart.removeAt(index);
        } else {
          cart[index].quantity = newQuantity;
        }
      }
    });
  }

  void clearCart() {
    setState(() {
      cart.clear();
    });
  }

  void makePayment() {
    // Placeholder for your Payment Module
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening Payment Module... (Le module de paiement)'),
      ),
    );
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
              // Responsive check
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
                // For smaller screens (Tablets/Phones), stack them or use a TabBar
                // Kept simple as a scrollable column for responsiveness
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 500,
                        child: _buildLeftPanel(colorScheme),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 400,
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
  // LEFT PANEL: Search, Categories, Products Grid
  // ---------------------------------------------------------------------------
  Widget _buildLeftPanel(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Scan Barcode or Search Medicine...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (val) => setState(() => searchQuery = val),
        ),
        const SizedBox(height: 16),

        // Category Pills
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Products Grid
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

  // ---------------------------------------------------------------------------
  // MIDDLE PANEL: Cart Items
  // ---------------------------------------------------------------------------
  Widget _buildMiddlePanel(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Header
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
                  const Text(
                    'Current Order',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: cart.isEmpty ? null : clearCart,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              ),
            ],
          ),
          const Divider(),

          // Column Headers
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

          // Cart List
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Text(
                      'Le panier est vide\n(Cart is empty)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.separated(
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                              ],
                            ),
                          ),

                          // Quantity Controls (Custom Editable Widget)
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildQtyBtn(
                                  Icons.remove,
                                  () => updateQuantity(
                                    item.product,
                                    item.quantity - 1,
                                  ),
                                  colorScheme,
                                ),
                                const SizedBox(width: 8),
                                QuantityEditor(
                                  quantity: item.quantity,
                                  onChanged: (newQty) =>
                                      updateQuantity(item.product, newQty),
                                ),
                                const SizedBox(width: 8),
                                _buildQtyBtn(
                                  Icons.add,
                                  () => updateQuantity(
                                    item.product,
                                    item.quantity + 1,
                                  ),
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

          // Bottom action buttons
          const SizedBox(height: 16),
          Row(
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
                child: Icon(Icons.person, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CUSTOMER',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Text(
                    'Walk-in Customer',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Add details',
                    style: TextStyle(fontSize: 12, color: colorScheme.primary),
                  ),
                ],
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

                // Total
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

                // Unified Payment Button
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
// Allows tapping the number to type directly
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
      if (!_focusNode.hasFocus) {
        _commitValue(); // Commit when clicking away
      }
    });
  }

  @override
  void didUpdateWidget(covariant QuantityEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity) {
      // Only update text if it's different to prevent cursor jumps
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
      // Revert to old valid value if input is invalid
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
