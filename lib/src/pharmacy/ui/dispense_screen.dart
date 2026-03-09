import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/pharmacy/models/pharmacy_model.dart';
import 'package:helty/src/pharmacy/services/pharmacy_service.dart';

// -----------------------------------------------------------------------------
// CART MODEL (uses Drug from pharmacy_model)
// -----------------------------------------------------------------------------
class CartItem {
  final Drug drug;
  int quantity;

  CartItem({required this.drug, this.quantity = 1});
}

// -----------------------------------------------------------------------------
// MAIN UI
// -----------------------------------------------------------------------------
@RoutePage()
class DispenseScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String id;
  const DispenseScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.id,
  });

  @override
  State<DispenseScreen> createState() => _DispenseScreenState();
}

class _DispenseScreenState extends State<DispenseScreen> {
  String patientId = '';
  String patientName = '';
  String id = '';

  final PharmacyApiService _drugService = PharmacyApiService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  /// Categories map to API therapeuticClass. "All" = no filter.
  static const List<String> categories = [
    'All',
    'Antibiotic',
    'Analgesic',
    'Antiviral',
    'Vitamin',
  ];

  List<Drug> _drugs = [];
  bool _loading = true;
  String _errorMessage = '';
  static const int _pageSize = 50;

  List<CartItem> cart = [];
  String selectedCategory = 'All';

  double get subtotal => cart.fold(
        0,
        (sum, item) =>
            sum + ((item.drug.price ?? 0) * item.quantity),
      );
  double get vat => subtotal * 0.12;
  double get discount => 0.00;
  double get totalAmount => subtotal + vat - discount;

  SearchDrugParams _buildSearchParams() {
    final query = _searchController.text.trim();
    return SearchDrugParams(
      search: query.isEmpty ? null : query,
      therapeuticClass:
          selectedCategory == 'All' ? null : selectedCategory,
      page: 1,
      pageSize: _pageSize,
      limit: _pageSize,
      sortOrder: 'asc',
    );
  }

  Future<void> _loadDrugs() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = '';
    });
    try {
      final response = await _drugService.searchDrugs(_buildSearchParams());
      if (mounted) {
        setState(() {
          _drugs = response.items;
          _loading = false;
        });
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _drugs = [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _drugs = [];
          _loading = false;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadDrugs();
    });
  }

  void addToCart(Drug drug) {
    setState(() {
      final existingIndex =
          cart.indexWhere((item) => item.drug.id == drug.id);
      if (existingIndex >= 0) {
        cart[existingIndex].quantity++;
      } else {
        cart.add(CartItem(drug: drug));
      }
    });
  }

  void updateQuantity(Drug drug, int newQuantity) {
    setState(() {
      final index = cart.indexWhere((item) => item.drug.id == drug.id);
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
    setState(() => cart.clear());
  }

  @override
  void initState() {
    super.initState();
    patientId = widget.patientId;
    patientName = widget.patientName;
    id = widget.id;
    _searchController.addListener(() => _onSearchChanged(_searchController.text));
    _loadDrugs();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
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
              final isWide = constraints.maxWidth > 900;
              final maxH = constraints.maxHeight;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildLeftPanel(colorScheme),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: _buildMiddlePanel(colorScheme),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: _buildRightPanel(colorScheme, theme),
                    ),
                  ],
                );
              }

              // Stacked layout: scrollable column with constrained heights to avoid overflow
              final leftH = (maxH * 0.45).clamp(320.0, 500.0);
              final midH = (maxH * 0.35).clamp(280.0, 400.0);
              final rightH = (maxH * 0.35).clamp(280.0, 400.0);
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: leftH,
                      child: _buildLeftPanel(colorScheme),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: midH,
                      child: _buildMiddlePanel(colorScheme),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: rightH,
                      child: _buildRightPanel(colorScheme, theme),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LEFT PANEL: Search, Categories, Drugs Grid
  // ---------------------------------------------------------------------------
  Widget _buildLeftPanel(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search Bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Scan barcode or search medicine...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Category Pills (filter via API therapeuticClass)
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => selectedCategory = cat);
                    _loadDrugs();
                  }
                },
                selectedColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Drugs Grid (scrollable, takes remaining space)
        Expanded(
          child: _loading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Loading drugs...',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : _errorMessage.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _loadDrugs,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _drugs.isEmpty
                      ? Center(
                          child: Text(
                            'No drugs found. Try another search or category.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.only(bottom: 8),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            childAspectRatio: 1.35,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _drugs.length,
                          itemBuilder: (context, index) {
                            final drug = _drugs[index];
                            final price = drug.price ?? 0;
                            return InkWell(
                              onTap: () => addToCart(drug),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      price > 0
                                          ? price.toFinancial(isMoney: true)
                                          : '—',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      drug.brandName.isNotEmpty
                                          ? drug.brandName
                                          : drug.genericName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Stock: ${drug.displayStock} ${drug.displayUnit}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
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
                      final drug = item.drug;
                      final lineTotal = (drug.price ?? 0) * item.quantity;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  drug.brandName.isNotEmpty
                                      ? drug.brandName
                                      : drug.genericName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (drug.id != null && drug.id!.isNotEmpty)
                                  Text(
                                    'ID: ${drug.id}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildQtyBtn(
                                  Icons.remove,
                                  () => updateQuantity(
                                    drug,
                                    item.quantity - 1,
                                  ),
                                  colorScheme,
                                ),
                                const SizedBox(width: 8),
                                QuantityEditor(
                                  quantity: item.quantity,
                                  onChanged: (newQty) =>
                                      updateQuantity(drug, newQty),
                                ),
                                const SizedBox(width: 8),
                                _buildQtyBtn(
                                  Icons.add,
                                  () => updateQuantity(
                                    drug,
                                    item.quantity + 1,
                                  ),
                                  colorScheme,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                lineTotal.toFinancial(isMoney: true),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
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
                    patientId,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    patientName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '',
                    style: TextStyle(fontSize: 12, color: colorScheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Summary Card (scrollable to avoid overflow on small panels)
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
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
                  _buildSummaryRow(
                    'VAT (12%)',
                    vat.toFinancial(isMoney: true),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Discount',
                    '-${discount.toFinancial(isMoney: true)}',
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 24),
                  // Total (FittedBox to prevent overflow on small width)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TOTAL AMOUNT',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          totalAmount.toFinancial(isMoney: true),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: cart.isEmpty ? null : makePayment,
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text(
                      'Send To Bill',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
