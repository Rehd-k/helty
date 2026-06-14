import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/billings/widgets/catalog_sales_widgets.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/models/invoice.dart';
import 'package:helty/src/models/invoice_billing_models.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/purchases/models/purchases_model.dart';
import 'package:helty/src/purchases/services/purchases_service.dart';
import 'package:helty/src/services/invoice_service.dart';

import '../../paitients/patient_model.dart';
import '../../paitients/patient_providers.dart';

class PurchaseCartItem {
  PurchaseCartItem({
    required this.item,
    required this.quantity,
    required this.maxQuantity,
    required this.unitPrice,
    required this.locationId,
  });

  final PurchaseItem item;
  int quantity;
  final int maxQuantity;
  final double unitPrice;
  final String locationId;
}

@RoutePage()
class PurchaseItemSalesScreen extends ConsumerStatefulWidget {
  const PurchaseItemSalesScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.id,
    this.invoiceId,
    this.staffId,
  });

  final String patientId;
  final String patientName;
  final String id;
  final String? invoiceId;
  final String? staffId;

  @override
  ConsumerState<PurchaseItemSalesScreen> createState() =>
      _PurchaseItemSalesScreenState();
}

class _PurchaseItemSalesScreenState
    extends ConsumerState<PurchaseItemSalesScreen> {
  final PurchasesApiService _purchasesService = PurchasesApiService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<PurchasesLocation> _locations = [];
  PurchasesLocation? _selectedLocation;
  bool _loadingLocations = true;
  String _locationError = '';

  List<PurchaseItem> _items = [];
  bool _loadingItems = true;
  String _itemsError = '';
  static const int _pageSize = 50;

  final Map<String, int> _stockByItemId = {};
  final Set<String> _loadingStockIds = {};

  final List<PurchaseCartItem> _cart = [];
  bool _checkoutBusy = false;

  double get _subtotal =>
      _cart.fold(0, (sum, item) => sum + (item.unitPrice * item.quantity));
  double get _totalAmount => _subtotal;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => _onSearchChanged(_searchController.text),
    );
    _loadLocations();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _loadingLocations = true;
      _locationError = '';
    });
    try {
      final resp = await _purchasesService.getLocations(
        const PurchasesQueryParams(pageSize: 20),
      );
      final active = resp.items.where((l) => l.isActive).toList();
      PurchasesLocation? defaultLoc;
      for (final l in active) {
        if (l.type == PurchasesLocationType.STORE) {
          defaultLoc = l;
          break;
        }
      }
      defaultLoc ??= active.isNotEmpty ? active.first : null;
      if (!mounted) return;
      setState(() {
        _locations = active;
        _selectedLocation = defaultLoc;
        _loadingLocations = false;
      });
      if (defaultLoc != null) {
        await _loadItems();
      } else {
        setState(() {
          _loadingItems = false;
          _itemsError = 'No active purchases locations found.';
        });
      }
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e.message;
        _loadingLocations = false;
        _loadingItems = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e.toString();
        _loadingLocations = false;
        _loadingItems = false;
      });
    }
  }

  SearchPurchaseItemParams _buildSearchParams() {
    final query = _searchController.text.trim();
    return SearchPurchaseItemParams(
      search: query.isEmpty ? null : query,
      inStock: true,
      limit: _pageSize,
      page: 1,
      pageSize: _pageSize,
      sortOrder: 'asc',
    );
  }

  Future<void> _loadItems() async {
    if (_selectedLocation?.id == null) return;
    if (!mounted) return;
    setState(() {
      _loadingItems = true;
      _itemsError = '';
      _stockByItemId.clear();
    });
    try {
      final response = await _purchasesService.searchItems(
        _buildSearchParams(),
      );
      if (!mounted) return;
      setState(() {
        _items = response.items;
        _loadingItems = false;
      });
      await _refreshStockForItems(_items);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _itemsError = e.message;
        _items = [];
        _loadingItems = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _itemsError = e.toString();
        _items = [];
        _loadingItems = false;
      });
    }
  }

  Future<void> _refreshStockForItems(List<PurchaseItem> items) async {
    final locId = _selectedLocation?.id;
    if (locId == null || locId.isEmpty) return;
    final ids = items
        .map((i) => i.id?.trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isEmpty) return;

    setState(() {
      _loadingStockIds.addAll(ids);
    });

    await Future.wait(
      ids.map((itemId) async {
        try {
          final rows = await _purchasesService.getItemLocationQuantities(
            itemId,
            locationId: locId,
          );
          final qty = rows.isEmpty
              ? 0
              : rows.fold<int>(0, (sum, row) => sum + row.quantity);
          if (mounted) {
            setState(() => _stockByItemId[itemId] = qty);
          }
        } catch (_) {
          if (mounted) {
            setState(() => _stockByItemId[itemId] = 0);
          }
        } finally {
          if (mounted) {
            setState(() => _loadingStockIds.remove(itemId));
          }
        }
      }),
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _loadItems);
  }

  void _onLocationChanged(PurchasesLocation? location) {
    if (location?.id == _selectedLocation?.id) return;
    setState(() {
      _selectedLocation = location;
      _cart.clear();
      _stockByItemId.clear();
    });
    _loadItems();
  }

  int _stockForItem(PurchaseItem item) {
    final id = item.id?.trim() ?? '';
    if (id.isEmpty) return 0;
    return _stockByItemId[id] ?? 0;
  }

  double _unitPriceForItem(PurchaseItem item) => item.sellingPrice ?? 0;

  void _addToCart(PurchaseItem item) {
    final itemId = item.id?.trim() ?? '';
    final locId = _selectedLocation?.id?.trim() ?? '';
    if (itemId.isEmpty || locId.isEmpty) return;

    final maxQuantity = _stockForItem(item);
    if (maxQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot add "${item.itemName}" — out of stock at this location.',
          ),
        ),
      );
      return;
    }

    setState(() {
      final existingIndex = _cart.indexWhere(
        (c) => c.item.id == item.id && c.locationId == locId,
      );
      if (existingIndex >= 0) {
        final existing = _cart[existingIndex];
        final nextQty = (existing.quantity + 1).clamp(0, existing.maxQuantity);
        if (nextQty == existing.quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cannot add more than available stock ($maxQuantity).',
              ),
            ),
          );
        } else {
          existing.quantity = nextQty;
        }
      } else {
        _cart.add(
          PurchaseCartItem(
            item: item,
            quantity: 1,
            maxQuantity: maxQuantity,
            unitPrice: _unitPriceForItem(item),
            locationId: locId,
          ),
        );
      }
    });
  }

  void _updateQuantity(PurchaseItem item, int newQuantity) {
    setState(() {
      final index = _cart.indexWhere((c) => c.item.id == item.id);
      if (index < 0) return;
      final cartItem = _cart[index];
      final clamped = newQuantity.clamp(0, cartItem.maxQuantity);
      if (clamped <= 0) {
        _cart.removeAt(index);
      } else {
        cartItem.quantity = clamped;
      }
    });
  }

  void _clearCart() => setState(() => _cart.clear());

  static bool _looksLikeUuid(String s) {
    final trimmed = s.trim();
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(trimmed);
  }

  static String? _resolvePatientUuidForInvoice({
    required Patient? selectedPatient,
    required String fallbackPatientId,
  }) {
    final candidate = selectedPatient?.id?.trim() ?? '';
    if (_looksLikeUuid(candidate)) return candidate;
    final fallback = fallbackPatientId.trim();
    if (_looksLikeUuid(fallback)) return fallback;
    return null;
  }

  Invoice? _pickOpenInvoice(List<Invoice> invoices) {
    if (invoices.isEmpty) return null;
    final openInvoices = invoices.where((invoice) {
      final status = invoice.status.toUpperCase();
      return status != 'PAID' &&
          status != 'FULLY_PAID' &&
          status != 'CANCELLED' &&
          status != 'VOID';
    }).toList();
    if (openInvoices.isEmpty) return null;
    openInvoices.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return openInvoices.first;
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty || _checkoutBusy) return;
    setState(() => _checkoutBusy = true);
    try {
      final svc = InvoiceService();
      final invId = widget.invoiceId?.trim();

      Future<String> resolveInvoiceId() async {
        if (invId != null && invId.isNotEmpty) return invId;
        final staffId = (widget.staffId?.trim().isNotEmpty == true)
            ? widget.staffId!.trim()
            : (ref.read(authProvider).staff?.id ?? '');
        if (staffId.isEmpty) {
          throw Exception('Sign in required to add items to invoice.');
        }
        final selectedPatient = ref.read(patientProvider).selectedPatient;
        final fallbackPatientId = widget.id.trim().isNotEmpty
            ? widget.id
            : widget.patientId;
        final patientUuid = _resolvePatientUuidForInvoice(
          selectedPatient: selectedPatient,
          fallbackPatientId: fallbackPatientId,
        );
        if (patientUuid == null) {
          throw Exception(
            'Cannot add to invoice: patient requires a server UUID.',
          );
        }
        final invoices = await svc.getPatientInvoices(patientUuid);
        final openInvoice = _pickOpenInvoice(invoices);
        return openInvoice?.id ??
            (await svc.createBillingInvoice(
              patientId: patientUuid,
              staffId: staffId,
            )).id;
      }

      final invoiceId = await resolveInvoiceId();

      for (final ci in _cart) {
        final pid = ci.item.id?.trim();
        if (pid == null || pid.isEmpty) {
          throw Exception('Item "${ci.item.itemName}" is missing a server id.');
        }
        await svc.addBillingItem(
          invoiceId: invoiceId,
          payload: AddInvoiceItemPayload(
            purchaseItemId: pid,
            purchasesLocationId: ci.locationId,
            unitPrice: ci.unitPrice,
            quantity: ci.quantity,
          ),
        );
      }

      if (!mounted) return;
      _clearCart();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase items added to invoice')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not add to invoice: $e')));
      }
    } finally {
      if (mounted) setState(() => _checkoutBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientState = ref.watch(patientProvider);
    final selectedPatient = patientState.selectedPatient;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Purchase items')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CatalogSalesLayout(
            leftPanel: _buildLeftPanel(colorScheme),
            middlePanel: _buildMiddlePanel(colorScheme),
            rightPanel: CatalogSalesSummaryPanel(
              colorScheme: colorScheme,
              patientIdLabel: widget.patientId,
              patientName: widget.patientName,
              patientSubtitle: selectedPatient?.wardHmoDisplayLine ?? 'OPD',
              subtotal: _subtotal,
              totalAmount: _totalAmount,
              checkoutBusy: _checkoutBusy,
              checkoutEnabled: _cart.isNotEmpty,
              onCheckout: _checkout,
              checkoutLabel:
                  widget.invoiceId != null &&
                      widget.invoiceId!.trim().isNotEmpty
                  ? 'Add to invoice'
                  : 'Send To Bill',
              checkoutIcon:
                  widget.invoiceId != null &&
                      widget.invoiceId!.trim().isNotEmpty
                  ? Icons.receipt_long_outlined
                  : Icons.send_and_archive_outlined,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loadingLocations)
          const LinearProgressIndicator()
        else if (_locationError.isNotEmpty)
          Text(_locationError, style: TextStyle(color: colorScheme.error))
        else
          DropdownButtonFormField<PurchasesLocation>(
            // ignore: deprecated_member_use
            value: _selectedLocation,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Store location',
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: _locations
                .map(
                  (l) => DropdownMenuItem(
                    value: l,
                    child: Text('${l.name} (${l.type.name})'),
                  ),
                )
                .toList(),
            onChanged: _onLocationChanged,
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search items...',
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
        Expanded(
          child: _loadingItems
              ? Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                )
              : _itemsError.isNotEmpty
              ? Center(
                  child: Text(
                    _itemsError,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.error),
                  ),
                )
              : _items.isEmpty
              ? Center(
                  child: Text(
                    'No items found. Try another search.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 1.35,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final price = _unitPriceForItem(item);
                    final stock = _stockForItem(item);
                    final itemId = item.id?.trim() ?? '';
                    final stockLoading =
                        itemId.isNotEmpty && _loadingStockIds.contains(itemId);
                    return InkWell(
                      onTap: stock > 0 && !stockLoading
                          ? () => _addToCart(item)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              price > 0
                                  ? price.toFinancial(isMoney: true)
                                  : 'Free',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Text(
                                item.itemName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (stockLoading)
                              Text(
                                'Checking stock…',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              )
                            else
                              Text(
                                stock > 0 ? 'In stock: $stock' : 'Out of stock',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: stock > 0
                                      ? Colors.green.shade700
                                      : colorScheme.error,
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

  Widget _buildMiddlePanel(ColorScheme colorScheme) {
    return CatalogSalesCartPanel(
      colorScheme: colorScheme,
      itemColumnLabel: 'ITEM',
      isEmpty: _cart.isEmpty,
      onClear: _clearCart,
      itemCount: _cart.length,
      itemBuilder: (context, index) {
        final cartItem = _cart[index];
        final item = cartItem.item;
        return CatalogSalesCartRow(
          title: item.itemName,
          subtitle: item.sku != null && item.sku!.isNotEmpty
              ? 'SKU: ${item.sku}'
              : null,
          quantity: cartItem.quantity,
          maxQuantity: cartItem.maxQuantity,
          unitPrice: cartItem.unitPrice,
          onDecrement: () => _updateQuantity(item, cartItem.quantity - 1),
          onIncrement: () => _updateQuantity(item, cartItem.quantity + 1),
          onQuantityChanged: (qty) => _updateQuantity(item, qty),
          colorScheme: colorScheme,
        );
      },
    );
  }
}
