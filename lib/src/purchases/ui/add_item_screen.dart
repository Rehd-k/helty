import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../pharma../../pharmacy/inputs/morden.form.inpts.dart';
import '../models/purchases_model.dart';
import '../services/purchases_service.dart';

@RoutePage()
class PurchasesAddItemScreen extends StatefulWidget {
  const PurchasesAddItemScreen({
    super.key,
    this.existingItem,
    this.service,
    this.onSaved,
  });

  final PurchaseItem? existingItem;
  final PurchasesApiService? service;
  final VoidCallback? onSaved;

  @override
  State<PurchasesAddItemScreen> createState() => _PurchasesAddItemScreenState();
}

class _PurchasesAddItemScreenState extends State<PurchasesAddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final PurchasesApiService _apiService;
  bool _isLoading = false;

  late final TextEditingController _itemNameCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _reorderLevelCtrl;
  late final TextEditingController _reorderQtyCtrl;

  List<PurchasesManufacturer> _manufacturers = [];
  String? _selectedManufacturerId;

  @override
  void initState() {
    super.initState();
    _apiService = widget.service ?? PurchasesApiService();
    final item = widget.existingItem;
    _itemNameCtrl = TextEditingController(text: item?.itemName ?? '');
    _skuCtrl = TextEditingController(text: item?.sku ?? '');
    _categoryCtrl = TextEditingController(text: item?.category ?? '');
    _descriptionCtrl = TextEditingController(text: item?.description ?? '');
    _unitCtrl = TextEditingController(
      text: item?.unitOfMeasure ?? item?.unit ?? '',
    );
    _reorderLevelCtrl = TextEditingController(
      text: item?.reorderLevel.toString() ?? '0',
    );
    _reorderQtyCtrl = TextEditingController(
      text: item?.reorderQuantity.toString() ?? '0',
    );
    _selectedManufacturerId = item?.manufacturerId;
    _loadManufacturers();
  }

  Future<void> _loadManufacturers() async {
    try {
      final page = await _apiService.getManufacturers(
        const PurchasesQueryParams(pageSize: 100, sortBy: 'name'),
      );
      if (!mounted) return;
      setState(() => _manufacturers = page.items);
    } catch (_) {}
  }

  @override
  void dispose() {
    _itemNameCtrl.dispose();
    _skuCtrl.dispose();
    _categoryCtrl.dispose();
    _descriptionCtrl.dispose();
    _unitCtrl.dispose();
    _reorderLevelCtrl.dispose();
    _reorderQtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final item = PurchaseItem(
        id: widget.existingItem?.id,
        itemName: _itemNameCtrl.text.trim(),
        sku: _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim(),
        category: _categoryCtrl.text.trim().isEmpty
            ? null
            : _categoryCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        unitOfMeasure: _unitCtrl.text.trim().isEmpty
            ? null
            : _unitCtrl.text.trim(),
        manufacturerId: _selectedManufacturerId,
        reorderLevel: int.tryParse(_reorderLevelCtrl.text) ?? 0,
        reorderQuantity: int.tryParse(_reorderQtyCtrl.text) ?? 0,
      );

      if (widget.existingItem != null) {
        await _apiService.updateItem(item);
      } else {
        await _apiService.createItem(item);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingItem != null
                ? 'Item updated successfully!'
                : 'Item added successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      widget.onSaved?.call();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.existingItem != null ? 'Edit Item' : 'Add New Item',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                ModernTextField(
                  label: 'Item Name',
                  hint: 'e.g., Surgical Masks (Box of 50)',
                  controller: _itemNameCtrl,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: ModernTextField(
                        label: 'SKU',
                        hint: 'Optional stock keeping unit',
                        controller: _skuCtrl,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ModernTextField(
                        label: 'Category',
                        hint: 'e.g., Medical Supplies',
                        controller: _categoryCtrl,
                      ),
                    ),
                  ],
                ),
                ModernTextField(
                  label: 'Description',
                  hint: 'Optional item description',
                  controller: _descriptionCtrl,
                ),
                ModernTextField(
                  label: 'Unit of Measure',
                  hint: 'e.g., box, piece, pack',
                  controller: _unitCtrl,
                ),
                if (_manufacturers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedManufacturerId,
                      decoration: const InputDecoration(
                        labelText: 'PurchasesManufacturer',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('None'),
                        ),
                        ..._manufacturers.map(
                          (m) => DropdownMenuItem<String>(
                            value: m.id,
                            child: Text(m.name),
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _selectedManufacturerId = v),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: ModernTextField(
                        label: 'Reorder Level',
                        hint: 'Minimum stock threshold',
                        controller: _reorderLevelCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ModernTextField(
                        label: 'Reorder Quantity',
                        hint: 'Default reorder amount',
                        controller: _reorderQtyCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.existingItem != null
                              ? 'Update Item'
                              : 'Save Item',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
