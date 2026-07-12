import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_exception.dart';
import '../../pharmacy/inputs/morden.form.inpts.dart';
import '../../shared/batch_receive_conversion.dart';
import '../models/purchases_model.dart';
import '../services/purchases_service.dart';

/// Local model for a batch line before saving (form → list).
class PendingBatchEntry {
  final PurchaseItem item;
  final String? batchNumber;
  final String? supplierId;
  final String? supplierName;
  final String? locationId;
  final String? locationName;
  final DateTime? mfgDate;
  final DateTime? expiryDate;
  final int quantity;
  final double costPrice;
  final BatchReceiveUnit receiveUnit;
  final int enteredQuantity;
  final double enteredCostPrice;
  final int? unitsPerPack;
  final int? packsPerCarton;

  /// Normalized per-unit selling price; null = inherit catalog at save time.
  final double? sellingPricePerUnit;
  final double? enteredSellingPrice;

  PendingBatchEntry({
    required this.item,
    this.batchNumber,
    this.supplierId,
    this.supplierName,
    this.locationId,
    this.locationName,
    this.mfgDate,
    this.expiryDate,
    required this.quantity,
    required this.costPrice,
    this.receiveUnit = BatchReceiveUnit.unit,
    required this.enteredQuantity,
    required this.enteredCostPrice,
    this.unitsPerPack,
    this.packsPerCarton,
    this.sellingPricePerUnit,
    this.enteredSellingPrice,
  });

  double get lineTotal => quantity * costPrice;

  String get receiveSummary {
    switch (receiveUnit) {
      case BatchReceiveUnit.unit:
        return '$quantity units';
      case BatchReceiveUnit.pack:
        return '$enteredQuantity packs × $unitsPerPack = $quantity units';
      case BatchReceiveUnit.carton:
        return '$enteredQuantity cartons × $packsPerCarton packs × $unitsPerPack = $quantity units';
    }
  }
}

@RoutePage()
class PurchasesAddPurchaseScreen extends StatefulWidget {
  const PurchasesAddPurchaseScreen({super.key});

  @override
  State<PurchasesAddPurchaseScreen> createState() =>
      _PurchasesAddPurchaseScreenState();
}

class _PurchasesAddPurchaseScreenState
    extends State<PurchasesAddPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = PurchasesApiService();

  final _batchNumberCtrl = TextEditingController();
  final _costPriceCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _unitsPerPackCtrl = TextEditingController();
  final _packsPerCartonCtrl = TextEditingController();
  final _sellingPriceCtrl = TextEditingController();
  final _drugSearchCtrl = TextEditingController();

  final FocusNode _drugSearchFocus = FocusNode();

  bool _isLoading = false;
  PurchaseItem? _selectedDrug;
  String? _selectedSupplierId;
  PurchasesLocation? _selectedLocation;
  BatchReceiveUnit _receiveUnit = BatchReceiveUnit.unit;

  DateTime? _mfgDate;
  DateTime? _expiryDate;

  List<PurchaseItem> _drugSearchResults = [];
  bool _drugSearchLoading = false;
  bool _showDrugDropdown = false;
  Timer? _searchDebounce;
  List<PurchasesLocation> _locations = [];
  List<PurchasesSupplier> _suppliers = [];

  /// Pending entries (left form adds here; right side shows list + summary).
  final List<PendingBatchEntry> _pendingEntries = [];

  /// When non-null, form is in "edit" mode for this index.
  int? _editingIndex;

  static const int _drugSearchLimit = 10;

  @override
  void initState() {
    super.initState();
    _loadLocationsAndSuppliers();
    _drugSearchCtrl.addListener(_onDrugSearchChanged);
    _drugSearchFocus.addListener(_onDrugSearchFocusChanged);
    _quantityCtrl.addListener(_onReceiveFieldChanged);
    _costPriceCtrl.addListener(_onReceiveFieldChanged);
    _unitsPerPackCtrl.addListener(_onReceiveFieldChanged);
    _packsPerCartonCtrl.addListener(_onReceiveFieldChanged);
    _sellingPriceCtrl.addListener(_onReceiveFieldChanged);
  }

  void _onReceiveFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _batchNumberCtrl.dispose();
    _costPriceCtrl.dispose();
    _quantityCtrl.dispose();
    _unitsPerPackCtrl.dispose();
    _packsPerCartonCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _drugSearchCtrl.dispose();
    _drugSearchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadLocationsAndSuppliers() async {
    try {
      final locResp = await _apiService.getLocations(
        const PurchasesQueryParams(pageSize: 100),
      );
      final suppliers = await _fetchAllSuppliers();
      if (mounted) {
        setState(() {
          _locations = locResp.items;
          _suppliers = suppliers;
          if (_selectedLocation == null && _locations.isNotEmpty) {
            _selectedLocation = _locations.first;
          }
          if (_selectedSupplierId != null &&
              !_suppliers.any((s) => s.id == _selectedSupplierId)) {
            _selectedSupplierId = null;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  Future<List<PurchasesSupplier>> _fetchAllSuppliers() async {
    const pageSize = 100;
    var page = 1;
    final all = <PurchasesSupplier>[];

    while (true) {
      final response = await _apiService.getSuppliers(
        PurchasesQueryParams(page: page, pageSize: pageSize),
      );
      if (response.items.isEmpty) break;
      all.addAll(response.items);
      if (!response.hasNext || all.length >= response.total) break;
      page += 1;
    }

    final suppliersById = <String, PurchasesSupplier>{};
    for (final PurchasesSupplier in all) {
      final id = PurchasesSupplier.id?.trim();
      if (id == null || id.isEmpty) continue;
      suppliersById[id] = PurchasesSupplier;
    }

    final suppliers = suppliersById.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return suppliers;
  }

  void _onDrugSearchFocusChanged() {
    // On desktop/web, clicking a dropdown item first blurs the text field.
    // If we hide immediately on blur, the tap callback may never fire.
    if (!_drugSearchFocus.hasFocus) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        if (_drugSearchFocus.hasFocus) return;
        setState(() {
          _showDrugDropdown = false;
        });
      });
      return;
    }

    setState(() {
      _showDrugDropdown =
          _drugSearchCtrl.text.trim().isNotEmpty && _selectedDrug == null;
    });
  }

  void _onDrugSearchChanged() {
    _searchDebounce?.cancel();
    final query = _drugSearchCtrl.text.trim();
    if (query.isEmpty) {
      setState(() {
        _drugSearchResults = [];
        _showDrugDropdown = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchItems(query);
    });
  }

  Future<void> _searchItems(String query) async {
    setState(() => _drugSearchLoading = true);
    try {
      final resp = await _apiService.getItems(
        PurchasesQueryParams(
          search: query,
          pageSize: _drugSearchLimit,
          page: 1,
        ),
      );
      if (mounted) {
        setState(() {
          _drugSearchResults = resp.items;
          _drugSearchLoading = false;
          _showDrugDropdown =
              _drugSearchFocus.hasFocus && _selectedDrug == null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _drugSearchResults = [];
          _drugSearchLoading = false;
        });
      }
    }
  }

  void _selectDrug(PurchaseItem selectedItem) {
    setState(() {
      _selectedDrug = selectedItem;
      _drugSearchCtrl.clear();
      _drugSearchResults = [];
      _showDrugDropdown = false;
      _drugSearchFocus.unfocus();
    });
  }

  void _clearSelectedDrug() {
    setState(() => _selectedDrug = null);
  }

  void _clearForm() {
    setState(() {
      _editingIndex = null;
      _selectedDrug = null;
      _selectedSupplierId = null;
      _receiveUnit = BatchReceiveUnit.unit;
      _batchNumberCtrl.clear();
      _costPriceCtrl.clear();
      _quantityCtrl.clear();
      _unitsPerPackCtrl.clear();
      _packsPerCartonCtrl.clear();
      _sellingPriceCtrl.clear();
      _drugSearchCtrl.clear();
      _mfgDate = null;
      _expiryDate = null;
      if (_locations.isNotEmpty && _selectedLocation != _locations.first) {
        _selectedLocation = _locations.first;
      }
    });
  }

  void _fillFormFromEntry(PendingBatchEntry entry) {
    _selectedDrug = entry.item;
    _selectedSupplierId = entry.supplierId;
    _receiveUnit = entry.receiveUnit;
    _batchNumberCtrl.text = entry.batchNumber ?? '';
    _costPriceCtrl.text = entry.enteredCostPrice.toString();
    _quantityCtrl.text = entry.enteredQuantity.toString();
    _unitsPerPackCtrl.text = entry.unitsPerPack?.toString() ?? '';
    _packsPerCartonCtrl.text = entry.packsPerCarton?.toString() ?? '';
    _sellingPriceCtrl.text = entry.enteredSellingPrice?.toString() ?? '';
    _mfgDate = entry.mfgDate;
    _expiryDate = entry.expiryDate;
    if (entry.locationId != null) {
      try {
        _selectedLocation = _locations.firstWhere(
          (l) => l.id == entry.locationId,
        );
      } catch (_) {
        _selectedLocation = _locations.isNotEmpty ? _locations.first : null;
      }
    }
  }

  BatchReceiveConversion? _tryComputeFromForm({
    void Function(String)? onError,
  }) {
    final enteredQty = int.tryParse(_quantityCtrl.text.trim());
    final enteredPrice = double.tryParse(
      _costPriceCtrl.text.replaceAll(',', '.'),
    );
    if (enteredQty == null || enteredPrice == null) return null;

    final unitsPerPack = _receiveUnit == BatchReceiveUnit.unit
        ? null
        : int.tryParse(_unitsPerPackCtrl.text.trim());
    final packsPerCarton = _receiveUnit == BatchReceiveUnit.carton
        ? int.tryParse(_packsPerCartonCtrl.text.trim())
        : null;

    return BatchReceiveConversion.compute(
      receiveUnit: _receiveUnit,
      enteredQuantity: enteredQty,
      enteredCostPrice: enteredPrice,
      unitsPerPack: unitsPerPack,
      packsPerCarton: packsPerCarton,
      onError: onError,
    );
  }

  String get _quantityLabel {
    switch (_receiveUnit) {
      case BatchReceiveUnit.unit:
        return 'Quantity (units) *';
      case BatchReceiveUnit.pack:
        return 'Number of packs *';
      case BatchReceiveUnit.carton:
        return 'Number of cartons *';
    }
  }

  String get _costPriceLabel {
    switch (_receiveUnit) {
      case BatchReceiveUnit.unit:
        return 'Cost price (per unit) *';
      case BatchReceiveUnit.pack:
        return 'Cost price (per pack) *';
      case BatchReceiveUnit.carton:
        return 'Cost price (per carton) *';
    }
  }

  String get _sellingPriceLabel {
    switch (_receiveUnit) {
      case BatchReceiveUnit.unit:
        return 'Selling price override (per unit)';
      case BatchReceiveUnit.pack:
        return 'Selling price override (per pack)';
      case BatchReceiveUnit.carton:
        return 'Selling price override (per carton)';
    }
  }

  double? _resolveSellingPricePerUnit({void Function(String)? onError}) {
    final text = _sellingPriceCtrl.text.trim();
    if (text.isEmpty) return null;

    final entered = double.tryParse(text.replaceAll(',', '.'));
    if (entered == null) {
      onError?.call('Enter a valid selling price.');
      return null;
    }
    if (entered < 0) {
      onError?.call('Selling price must not be negative.');
      return null;
    }

    final unitsPerPack = _receiveUnit == BatchReceiveUnit.unit
        ? null
        : int.tryParse(_unitsPerPackCtrl.text.trim());
    final packsPerCarton = _receiveUnit == BatchReceiveUnit.carton
        ? int.tryParse(_packsPerCartonCtrl.text.trim())
        : null;

    final unitPrice = BatchReceiveConversion.convertEnteredPriceToUnitPrice(
      receiveUnit: _receiveUnit,
      enteredPrice: entered,
      unitsPerPack: unitsPerPack,
      packsPerCarton: packsPerCarton,
    );
    if (unitPrice == null) {
      onError?.call(
        'Complete pack/carton fields before setting selling price.',
      );
    }
    return unitPrice;
  }

  void _addOrUpdateEntry() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDrug == null) {
      _showError('Please search and select an item.');
      return;
    }
    if (_locations.isNotEmpty && _selectedLocation?.id == null) {
      _showError('Please select a storage location.');
      return;
    }
    if (_mfgDate != null &&
        _expiryDate != null &&
        _expiryDate!.isBefore(_mfgDate!)) {
      _showError('Expiry date cannot be before manufacturing date.');
      return;
    }

    String? conversionError;
    final conversion = _tryComputeFromForm(
      onError: (msg) => conversionError = msg,
    );
    if (conversion == null) {
      _showError(conversionError ?? 'Enter valid quantity and pricing.');
      return;
    }

    String? sellingError;
    final sellingPricePerUnit = _resolveSellingPricePerUnit(
      onError: (msg) => sellingError = msg,
    );
    if (sellingError != null) {
      _showError(sellingError!);
      return;
    }

    final enteredQty = int.parse(_quantityCtrl.text.trim());
    final enteredPrice = double.parse(_costPriceCtrl.text.replaceAll(',', '.'));
    final unitsPerPack = _receiveUnit == BatchReceiveUnit.unit
        ? null
        : int.tryParse(_unitsPerPackCtrl.text.trim());
    final packsPerCarton = _receiveUnit == BatchReceiveUnit.carton
        ? int.tryParse(_packsPerCartonCtrl.text.trim())
        : null;
    final enteredSellingText = _sellingPriceCtrl.text.trim();
    final enteredSellingPrice = enteredSellingText.isEmpty
        ? null
        : double.tryParse(enteredSellingText.replaceAll(',', '.'));

    final entry = PendingBatchEntry(
      item: _selectedDrug!,
      batchNumber: _batchNumberCtrl.text.trim().isEmpty
          ? null
          : _batchNumberCtrl.text.trim(),
      supplierId: _selectedSupplierId,
      supplierName: () {
        final match = _suppliers.where((s) => s.id == _selectedSupplierId);
        return match.isEmpty ? null : match.first.name;
      }(),
      locationId: _selectedLocation?.id,
      locationName: _selectedLocation?.name,
      mfgDate: _mfgDate,
      expiryDate: _expiryDate,
      quantity: conversion.quantityInUnits,
      costPrice: conversion.costPricePerUnit,
      receiveUnit: _receiveUnit,
      enteredQuantity: enteredQty,
      enteredCostPrice: enteredPrice,
      unitsPerPack: unitsPerPack,
      packsPerCarton: packsPerCarton,
      sellingPricePerUnit: sellingPricePerUnit,
      enteredSellingPrice: enteredSellingPrice,
    );

    setState(() {
      if (_editingIndex != null) {
        _pendingEntries[_editingIndex!] = entry;
        _editingIndex = null;
      } else {
        _pendingEntries.add(entry);
      }
      _clearForm();
    });
  }

  void _editEntry(int index) {
    if (index < 0 || index >= _pendingEntries.length) return;
    setState(() {
      _editingIndex = index;
      _fillFormFromEntry(_pendingEntries[index]);
    });
  }

  void _removeEntry(int index) {
    setState(() {
      _pendingEntries.removeAt(index);
      if (_editingIndex == index) {
        _clearForm();
      } else if (_editingIndex != null && _editingIndex! > index) {
        _editingIndex = _editingIndex! - 1;
      }
    });
  }

  Future<void> _saveAllBatches() async {
    if (_pendingEntries.isEmpty) {
      _showError('Add at least one batch entry before saving.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      for (final entry in _pendingEntries) {
        final batch = PurchaseItemBatch(
          itemId: entry.item.id!,
          batchNumber: entry.batchNumber,
          expiryDate: entry.expiryDate,
          quantityReceived: entry.quantity,
          manufacturingDate: entry.mfgDate,
          costPrice: entry.costPrice,
          sellingPrice: entry.sellingPricePerUnit,
          supplierId: entry.supplierId,
          toLocationId: entry.locationId,
        );
        await _apiService.createItemBatch(batch);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All batches saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } on AppException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isMfg) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isMfg
          ? (_mfgDate ?? DateTime.now())
          : (_expiryDate ?? DateTime.now().add(const Duration(days: 365))),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isMfg) {
          _mfgDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectableSuppliers = _suppliers
        .where((s) => (s.id?.trim().isNotEmpty ?? false))
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Add Purchase Batch',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
          first: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                        _buildSectionHeader(
                          'Product & Location',
                          Icons.inventory_2_outlined,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Medicine',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_selectedDrug != null)
                              _buildSelectedDrugPill(theme, _selectedDrug!)
                            else
                              _buildDrugSearchField(theme),
                            if (_showDrugDropdown)
                              _buildDrugDropdownList(theme),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_locations.isNotEmpty) ...[
                          _buildModernDropdown<String?>(
                            label: 'Storage Location',
                            hint: 'Select location',
                            value: _selectedLocation?.id,
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('— Select location —'),
                              ),
                              ..._locations.map(
                                (loc) => DropdownMenuItem<String?>(
                                  value: loc.id,
                                  child: Text(loc.name),
                                ),
                              ),
                            ],
                            onChanged: (v) => setState(() {
                              if (v == null) {
                                _selectedLocation = null;
                              } else {
                                try {
                                  _selectedLocation = _locations.firstWhere(
                                    (l) => l.id == v,
                                  );
                                } catch (_) {
                                  _selectedLocation = null;
                                }
                              }
                            }),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildSectionHeader(
                          'Batch Details',
                          Icons.qr_code_outlined,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ModernTextField(
                                label: 'Batch Number / Lot ID *',
                                hint: 'e.g., LOT-2023-XYZ',
                                controller: _batchNumberCtrl,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildModernDropdown<String?>(
                                label: 'Supplier (Optional)',
                                hint: selectableSuppliers.isEmpty
                                    ? 'No suppliers available'
                                    : 'Select origin Supplier',
                                value:
                                    selectableSuppliers.any(
                                      (s) => s.id == _selectedSupplierId,
                                    )
                                    ? _selectedSupplierId
                                    : null,
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('— None —'),
                                  ),
                                  ...selectableSuppliers.map(
                                    (s) => DropdownMenuItem<String?>(
                                      value: s.id!,
                                      child: Text(
                                        s.name,
                                        style: TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (selectableSuppliers.isEmpty) return;
                                  setState(() => _selectedSupplierId = v);
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernDatePicker(
                                label: 'Manufacturing Date',
                                date: _mfgDate,
                                onTap: () => _selectDate(context, true),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildModernDatePicker(
                                label: 'Expiry Date',
                                date: _expiryDate,
                                onTap: () => _selectDate(context, false),
                                isDanger:
                                    _expiryDate != null &&
                                    _expiryDate!
                                            .difference(DateTime.now())
                                            .inDays <
                                        90,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionHeader(
                          'Quantities & Pricing',
                          Icons.attach_money_outlined,
                        ),
                        const Text(
                          'Receive as',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<BatchReceiveUnit>(
                          segments: const [
                            ButtonSegment(
                              value: BatchReceiveUnit.unit,
                              label: Text('Unit'),
                              icon: Icon(Icons.medication_outlined, size: 16),
                            ),
                            ButtonSegment(
                              value: BatchReceiveUnit.pack,
                              label: Text('Pack'),
                              icon: Icon(Icons.inventory_outlined, size: 16),
                            ),
                            ButtonSegment(
                              value: BatchReceiveUnit.carton,
                              label: Text('Carton'),
                              icon: Icon(Icons.all_inbox_outlined, size: 16),
                            ),
                          ],
                          selected: {_receiveUnit},
                          onSelectionChanged: (selection) {
                            setState(() {
                              _receiveUnit = selection.first;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        if (_receiveUnit != BatchReceiveUnit.unit) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ModernTextField(
                                  label: 'Units in one pack *',
                                  hint: 'e.g., 10',
                                  controller: _unitsPerPackCtrl,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (_receiveUnit == BatchReceiveUnit.unit) {
                                      return null;
                                    }
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final n = int.tryParse(v.trim());
                                    if (n == null || n < 1) return 'Invalid';
                                    return null;
                                  },
                                ),
                              ),
                              if (_receiveUnit == BatchReceiveUnit.carton) ...[
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ModernTextField(
                                    label: 'Packs in one carton *',
                                    hint: 'e.g., 12',
                                    controller: _packsPerCartonCtrl,
                                    keyboardType: TextInputType.number,
                                    validator: (v) {
                                      if (_receiveUnit !=
                                          BatchReceiveUnit.carton) {
                                        return null;
                                      }
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      final n = int.tryParse(v.trim());
                                      if (n == null || n < 1) return 'Invalid';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: ModernTextField(
                                label: _quantityLabel,
                                hint: 'e.g., 500',
                                controller: _quantityCtrl,
                                keyboardType: TextInputType.number,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ModernTextField(
                                label: _costPriceLabel,
                                hint: '0.00',
                                icon: Icons.money_off_csred_outlined,
                                controller: _costPriceCtrl,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : double.tryParse(v.replaceAll(',', '.')) ==
                                          null
                                    ? 'Invalid'
                                    : null,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        ModernTextField(
                          label: _sellingPriceLabel,
                          hint: _selectedDrug?.sellingPrice != null
                              ? 'Catalog: ${_selectedDrug!.sellingPrice!.toFinancial(isMoney: true)} — leave blank to inherit'
                              : 'Leave blank to inherit catalog price',
                          icon: Icons.sell_outlined,
                          controller: _sellingPriceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final n = double.tryParse(v.replaceAll(',', '.'));
                            if (n == null) return 'Invalid';
                            if (n < 0) return 'Must not be negative';
                            return null;
                          },
                        ),
                        _buildReceivePreview(theme),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            if (_editingIndex != null) ...[
                              OutlinedButton(
                                onPressed: _clearForm,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Cancel edit'),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: SizedBox(
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _addOrUpdateEntry,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    _editingIndex != null
                                        ? 'Update entry'
                                        : 'Add to list',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
          second: _buildRightPanel(theme),
        ),
      ),
    );
  }

  Widget _buildRightPanel(ThemeData theme) {
    final totalValue = _pendingEntries.fold<double>(
      0,
      (sum, e) => sum + e.lineTotal,
    );
    final totalQty = _pendingEntries.fold<int>(0, (sum, e) => sum + e.quantity);
    final uniqueDrugs = _pendingEntries.map((e) => e.item.id).toSet().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSummaryCard(theme, totalValue, totalQty, uniqueDrugs),
        const SizedBox(height: 16),
        Expanded(child: _buildEntriesList(theme)),
        const SizedBox(height: 16),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: (_isLoading || _pendingEntries.isEmpty)
                ? null
                : _saveAllBatches,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Save all batches (${_pendingEntries.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    double totalValue,
    int totalQty,
    int uniqueDrugs,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _summaryRow('Line items', '${_pendingEntries.length}'),
          _summaryRow('Unique drugs', '$uniqueDrugs'),
          _summaryRow('Total quantity', totalQty.toFinancial(isMoney: false)),
          _summaryRow(
            'Total value',
            totalValue.toFinancial(isMoney: true),
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? Colors.green.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList(ThemeData theme) {
    if (_pendingEntries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'No batches added yet',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                'Use the form on the left to add entries.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'Added batches',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _pendingEntries.length,
              itemBuilder: (context, index) {
                return _buildEntryTile(theme, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTile(ThemeData theme, int index) {
    final entry = _pendingEntries[index];
    final isEditing = _editingIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEditing
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEditing
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.item.itemName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (entry.item.sku != null && entry.item.sku!.isNotEmpty)
                      Text(
                        entry.item.sku!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 0,
                      runSpacing: 4,
                      children: [
                        if (entry.batchNumber != null &&
                            entry.batchNumber!.isNotEmpty)
                          _chip('Batch: ${entry.batchNumber}'),
                        _chip(entry.receiveSummary),
                        _chip(
                          'Unit cost: ${entry.costPrice.toFinancial(isMoney: true)}',
                        ),
                        if (entry.sellingPricePerUnit != null)
                          _chip(
                            'Sell: ${entry.sellingPricePerUnit!.toFinancial(isMoney: true)}/unit',
                          )
                        else
                          _chip('Sell: catalog'),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () => _editEntry(index),
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    onPressed: () => _removeEntry(index),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red.shade400,
                    ),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Line total: ${entry.lineTotal.toFinancial(isMoney: true)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildReceivePreview(ThemeData theme) {
    final conversion = _tryComputeFromForm();
    if (conversion == null) {
      return const SizedBox(height: 4);
    }

    final sellingPerUnit = _resolveSellingPricePerUnit();
    final sellingLine = sellingPerUnit != null
        ? ' · Sell ${sellingPerUnit.toFinancial(isMoney: true)}/unit'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '→ ${conversion.quantityInUnits.toFinancial(isMoney: false)} units @ '
            '${conversion.costPricePerUnit.toFinancial(isMoney: true)}/unit$sellingLine',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Line total: ${conversion.lineTotal.toFinancial(isMoney: true)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDrugPill(ThemeData theme, PurchaseItem selectedItem) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.medication, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedItem.itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (selectedItem.sku != null && selectedItem.sku!.isNotEmpty)
                  Text(
                    selectedItem.sku!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                if (selectedItem.sellingPrice != null)
                  Text(
                    selectedItem.sellingPrice! > 0
                        ? 'Catalog sell: ${selectedItem.sellingPrice!.toFinancial(isMoney: true)}'
                        : 'Catalog sell: Free',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20, color: Colors.grey.shade700),
            onPressed: _clearSelectedDrug,
            style: IconButton.styleFrom(
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrugSearchField(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _drugSearchCtrl,
        focusNode: _drugSearchFocus,
        decoration: InputDecoration(
          hintText: 'Search medicine by name...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          suffixIcon: _drugSearchLoading
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
        ),
        onTap: () {
          if (_drugSearchCtrl.text.trim().isNotEmpty &&
              _drugSearchResults.isNotEmpty) {
            setState(() => _showDrugDropdown = true);
          }
        },
      ),
    );
  }

  Widget _buildDrugDropdownList(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 320),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: _drugSearchResults.isEmpty && !_drugSearchLoading
            ? 1
            : _drugSearchResults.length,
        itemBuilder: (context, index) {
          if (_drugSearchResults.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'No medicines found. Keep typing to search.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            );
          }
          final pickedItem = _drugSearchResults[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.inventory_2,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
            title: Text(
              pickedItem.itemName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle:
                pickedItem.category != null && pickedItem.category!.isNotEmpty
                ? Text(
                    pickedItem.category!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  )
                : null,
            onTap: () {
              _selectDrug(pickedItem);
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
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

  Widget _buildModernDropdown<T>({
    required String label,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final theme = Theme.of(context);
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
          DropdownButtonFormField<T>(
            initialValue: value,
            items: items,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: Colors.white,
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
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDatePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final theme = Theme.of(context);
    final dateString = date != null
        ? DateFormat('MMM dd, yyyy').format(date)
        : 'Select Date';
    final textColor = date != null
        ? (isDanger ? theme.colorScheme.error : Colors.black87)
        : Colors.grey.shade400;

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
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDanger
                      ? theme.colorScheme.error.withValues(alpha: 0.5)
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateString,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: date != null
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_outlined,
                    color: isDanger
                        ? theme.colorScheme.error
                        : Colors.grey.shade500,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
