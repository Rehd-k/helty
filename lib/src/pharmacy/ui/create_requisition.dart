import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/responsive.dart';

import '../../purchases/models/purchases_model.dart';
import '../../purchases/services/purchases_service.dart';
import '../../providers/auth_provider.dart';
import '../services/pharmacy_service.dart';

class RequisitionItem {
  final String id;
  final String name;
  final int quantity;
  final String priority;
  final String? notes;

  RequisitionItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.priority,
    this.notes,
  });
}

@RoutePage()
class CreateRequisitionScreen extends ConsumerStatefulWidget {
  const CreateRequisitionScreen({super.key});

  @override
  ConsumerState<CreateRequisitionScreen> createState() =>
      _CreateRequisitionScreenState();
}

class _CreateRequisitionScreenState
    extends ConsumerState<CreateRequisitionScreen> {
  final _pharmacyApi = PharmacyApiService();
  final _purchasesApi = PurchasesApiService();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Controllers for the "Add Item" section
  final _quantityCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedItemId;
  String _selectedPriority = 'Normal';

  // The "Cart" of items being requested
  final List<RequisitionItem> _requestedItems = [];

  // Requestable inventory loaded from pharmacy catalog
  List<Map<String, dynamic>> _inventoryItems = [];
  bool _loadingInventory = true;

  final List<String> _priorities = ['Normal', 'Urgent', 'Critical'];

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    try {
      final drugs = await _pharmacyApi.getDrugs(
        const PharmacyQueryParams(pageSize: 200, sortBy: 'brandName'),
      );
      final consumables = await _pharmacyApi.getConsumables(
        const PharmacyQueryParams(pageSize: 200),
      );
      if (!mounted) return;
      setState(() {
        _inventoryItems = [
          ...drugs.items.map(
            (d) => {
              'id': d.id ?? '',
              'name': d.brandName.isNotEmpty ? d.brandName : d.genericName,
              'type': 'Drug',
              'stock': d.displayStock,
            },
          ),
          ...consumables.items.map(
            (c) => {
              'id': c.id ?? '',
              'name': c.name,
              'type': 'Consumable',
              'stock': c.reorderLevel ?? 0,
            },
          ),
        ];
        _loadingInventory = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingInventory = false);
    }
  }

  void _addItemToRequest() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItemId == null) {
      _showSnackBar('Please select an item to request.', isError: true);
      return;
    }

    final item = _inventoryItems.firstWhere((e) => e['id'] == _selectedItemId);
    final qty = int.tryParse(_quantityCtrl.text) ?? 0;

    setState(() {
      _requestedItems.add(
        RequisitionItem(
          id: item['id'],
          name: item['name'],
          quantity: qty,
          priority: _selectedPriority,
          notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
        ),
      );

      // Reset form for next item
      _selectedItemId = null;
      _quantityCtrl.clear();
      _notesCtrl.clear();
      _selectedPriority = 'Normal';
    });
  }

  void _removeItem(int index) {
    setState(() {
      _requestedItems.removeAt(index);
    });
  }

  Future<void> _submitRequisition() async {
    if (_requestedItems.isEmpty) {
      _showSnackBar('Your requisition list is empty.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final staff = ref.read(authProvider).staff;
      final requestedById = staff?.id ?? '';
      if (requestedById.isEmpty) {
        _showSnackBar('Unable to identify requesting staff.', isError: true);
        return;
      }

      await _purchasesApi.createRequisition(
        CreateRequisitionDto(
          requestingDepartment: 'PHARMACY',
          requestedById: requestedById,
          lines: _requestedItems
              .map(
                (line) => RequisitionLine(
                  itemType:
                      _inventoryItems
                          .firstWhere((e) => e['id'] == line.id)['type']
                          ?.toString() ??
                      'Drug',
                  itemId: line.id,
                  itemName: line.name,
                  quantity: line.quantity,
                  priority: line.priority,
                  notes: line.notes,
                ),
              )
              .toList(),
        ),
      );

      if (mounted) {
        _showSnackBar('Requisition order sent to Purchases successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Requisition Order',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            Text(
              'Send stock request to Purchases Department',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) => ResponsiveRowColumn(
          gap: 0,
          firstFlex: 5,
          secondFlex: 4,
          first: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      'Add Item to Request',
                      Icons.add_shopping_cart_outlined,
                    ),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModernDropdown(
                            label: 'Select Product / Consumable',
                            hint: 'Search inventory catalog...',
                            value: _selectedItemId,
                            icon: Icons.search,
                            items: _inventoryItems.map((item) {
                              return DropdownMenuItem(
                                value: item['id'],
                                child: Text(
                                  '${item['name']} (Current Stock: ${item['stock']})',
                                ),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setState(() => _selectedItemId = v as String?),
                          ),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildModernTextField(
                                  label: 'Requested Quantity',
                                  hint: 'e.g., 50',
                                  controller: _quantityCtrl,
                                  icon: Icons.numbers,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Required';
                                    }
                                    if (int.tryParse(v) == null ||
                                        int.parse(v) <= 0) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildModernDropdown(
                                  label: 'Priority Level',
                                  hint: 'Select urgency',
                                  value: _selectedPriority,
                                  icon: Icons.flag_outlined,
                                  items: _priorities
                                      .map(
                                        (p) => DropdownMenuItem(
                                          value: p,
                                          child: Text(p),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(
                                    () => _selectedPriority = v as String,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          _buildModernTextField(
                            label: 'Notes for Purchasing (Optional)',
                            hint:
                                'e.g., Required for upcoming surgical camp next week',
                            controller: _notesCtrl,
                            icon: Icons.notes,
                            maxLines: 2,
                          ),

                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: _addItemToRequest,
                              icon: Icon(
                                Icons.add,
                                color: theme.colorScheme.primary,
                              ),
                              label: Text(
                                'Add to Request List',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
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
            ),
          second: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                left: bp.stackPanels
                    ? BorderSide.none
                    : BorderSide(color: Colors.grey.shade200),
              ),
            ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Requisition Summary',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_requestedItems.length} Items',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _requestedItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No items added yet',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Select items from the left to build your request.',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(24),
                            itemCount: _requestedItems.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _requestedItems[index];
                              return _buildCartItem(item, index, theme);
                            },
                          ),
                  ),

                  // Submit Button Footer
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _requestedItems.isEmpty || _isSubmitting
                          ? null
                          : _submitRequisition,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
                      label: Text(
                        _isSubmitting
                            ? 'Sending to Purchases...'
                            : 'Submit Requisition',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: theme.colorScheme.primary,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildCartItem(RequisitionItem item, int index, ThemeData theme) {
    Color priorityColor;
    Color priorityBg;

    switch (item.priority) {
      case 'Critical':
        priorityColor = Colors.red.shade700;
        priorityBg = Colors.red.shade50;
        break;
      case 'Urgent':
        priorityColor = Colors.orange.shade700;
        priorityBg = Colors.orange.shade50;
        break;
      default:
        priorityColor = Colors.green.shade700;
        priorityBg = Colors.green.shade50;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Qty: ${item.quantity}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: priorityBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.priority,
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.notes != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Note: ${item.notes}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
            onPressed: () => _removeItem(index),
            tooltip: 'Remove Item',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
        ],
      ),
    );
  }

  // Local re-implementations of the modern inputs to keep this file self-contained
  Widget _buildModernTextField({
    required String label,
    required String hint,
    TextEditingController? controller,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: icon != null
                  ? Icon(icon, color: Colors.grey.shade500, size: 20)
                  : null,
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDropdown({
    required String label,
    required String hint,
    required dynamic value,
    required List<DropdownMenuItem<dynamic>> items,
    required void Function(dynamic)? onChanged,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<dynamic>(
            initialValue: value,
            items: items,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: icon != null
                  ? Icon(icon, color: Colors.grey.shade500, size: 20)
                  : null,
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }
}
