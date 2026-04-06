import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../models/ward_models.dart';
import '../../services/ward_service.dart';
import '../models/pharmacy_model.dart';
import '../services/pharmacy_service.dart';
import '../inputs/morden.form.inpts.dart';

@RoutePage()
class AddDrugScreen extends StatefulWidget {
  const AddDrugScreen({
    super.key,
    this.existingDrug,
    this.service,
    this.onSaved,
  });

  /// When provided, the form will be prefilled and submitting will update
  /// the existing drug instead of creating a new one.
  final Drug? existingDrug;

  /// Optional service to use; falls back to a new [PharmacyApiService].
  final PharmacyApiService? service;

  /// Optional callback invoked after a successful save (create or update).
  final VoidCallback? onSaved;

  @override
  State<AddDrugScreen> createState() => _AddDrugScreenState();
}

class _AddDrugScreenState extends State<AddDrugScreen> {
  final _formKey = GlobalKey<FormState>();
  late final PharmacyApiService _apiService;
  bool _isLoading = false;

  // Controllers
  late final TextEditingController _genericNameCtrl;
  late final TextEditingController _brandNameCtrl;
  late final TextEditingController _strengthCtrl;
  late final TextEditingController _dosageFormCtrl;
  late final TextEditingController _routeCtrl;
  late final TextEditingController _therapeuticClassCtrl;
  late final TextEditingController _atcCodeCtrl;
  late final TextEditingController _maxDailyDoseCtrl;
  late final TextEditingController _reorderLevelCtrl;
  late final TextEditingController _reorderQtyCtrl;

  // Booleans
  bool _isControlled = false;
  bool _isRefrigerated = false;
  bool _isHighAlert = false;

  final _wardService = WardService();
  final _wardPriceController = TextEditingController();
  List<Ward> _availableWards = [];
  List<DrugPrice> _priceRows = [];
  String? _selectedWardId;

  @override
  void initState() {
    super.initState();
    _apiService = widget.service ?? PharmacyApiService();

    final d = widget.existingDrug;
    _genericNameCtrl = TextEditingController(text: d?.genericName ?? '');
    _brandNameCtrl = TextEditingController(text: d?.brandName ?? '');
    _strengthCtrl = TextEditingController(text: d?.strength ?? '');
    _dosageFormCtrl = TextEditingController(text: d?.dosageForm ?? '');
    _routeCtrl = TextEditingController(text: d?.route ?? '');
    _therapeuticClassCtrl = TextEditingController(
      text: d?.therapeuticClass ?? '',
    );
    _atcCodeCtrl = TextEditingController(text: d?.atcCode ?? '');
    _maxDailyDoseCtrl = TextEditingController(
      text: d?.maxDailyDose != null ? d!.maxDailyDose.toString() : '',
    );
    _reorderLevelCtrl = TextEditingController(
      text: d?.reorderLevel != null ? d!.reorderLevel.toString() : '0',
    );
    _reorderQtyCtrl = TextEditingController(
      text: d?.reorderQuantity != null ? d!.reorderQuantity.toString() : '0',
    );
    _isControlled = d?.isControlled ?? false;
    _isRefrigerated = d?.isRefrigerated ?? false;
    _isHighAlert = d?.isHighAlert ?? false;
    _loadWards();
    if (d?.prices != null) {
      _priceRows = List.from(d!.prices!);
    }
  }

  @override
  void dispose() {
    _genericNameCtrl.dispose();
    _brandNameCtrl.dispose();
    _strengthCtrl.dispose();
    _dosageFormCtrl.dispose();
    _routeCtrl.dispose();
    _therapeuticClassCtrl.dispose();
    _atcCodeCtrl.dispose();
    _maxDailyDoseCtrl.dispose();
    _reorderLevelCtrl.dispose();
    _reorderQtyCtrl.dispose();
    _wardPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadWards() async {
    try {
      final wards = await _wardService.fetchWards();
      if (!mounted) return;
      final existingWardIds = _priceRows.map((e) => e.wardId).toSet();
      setState(() {
        _availableWards = wards
            .where((w) => !existingWardIds.contains(w.id))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load wards: $e')));
    }
  }

  void _addWardPrice() {
    final selectedWardId = _selectedWardId;
    if (selectedWardId == null || selectedWardId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a ward.')));
      return;
    }

    final priceText = _wardPriceController.text.trim();
    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price.')),
      );
      return;
    }

    final ward = _availableWards.firstWhere((w) => w.id == selectedWardId);
    final row = DrugPrice(wardId: ward.id, wardName: ward.name, price: price);

    setState(() {
      _priceRows.add(row);
      _availableWards.removeWhere((w) => w.id == ward.id);
      _selectedWardId = null;
      _wardPriceController.clear();
    });
  }

  void _removeWardPrice(DrugPrice row) {
    setState(() {
      _priceRows.remove(row);
    });
    _loadWards();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final drug = Drug(
        id: widget.existingDrug?.id,
        genericName: _genericNameCtrl.text.trim(),
        brandName: _brandNameCtrl.text.trim(),
        strength: _strengthCtrl.text.trim().isEmpty
            ? null
            : _strengthCtrl.text.trim(),
        dosageForm: _dosageFormCtrl.text.trim().isEmpty
            ? null
            : _dosageFormCtrl.text.trim(),
        route: _routeCtrl.text.trim().isEmpty ? null : _routeCtrl.text.trim(),
        therapeuticClass: _therapeuticClassCtrl.text.trim().isEmpty
            ? null
            : _therapeuticClassCtrl.text.trim(),
        atcCode: _atcCodeCtrl.text.trim().isEmpty
            ? null
            : _atcCodeCtrl.text.trim(),
        isControlled: _isControlled,
        isRefrigerated: _isRefrigerated,
        isHighAlert: _isHighAlert,
        maxDailyDose: double.tryParse(_maxDailyDoseCtrl.text),
        reorderLevel: int.tryParse(_reorderLevelCtrl.text) ?? 0,
        reorderQuantity: int.tryParse(_reorderQtyCtrl.text) ?? 0,
        prices: _priceRows,
        // Manufacturer ID can be wired when manufacturer selector is added.
        manufacturerId: widget.existingDrug?.manufacturerId,
      );

      if (widget.existingDrug != null) {
        await _apiService.updateDrug(drug);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Drug updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _apiService.createDrug(drug);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Drug added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        widget.onSaved?.call();
        Navigator.pop(context);
      }
    } catch (e) {
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
        title: const Text(
          'Add New Drug',
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                _buildSectionHeader('Basic Information', Icons.info_outline),
                Row(
                  children: [
                    Expanded(
                      child: ModernTextField(
                        label: 'Brand Name',
                        hint: 'e.g., Tylenol',
                        controller: _brandNameCtrl,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ModernTextField(
                        label: 'Generic Name',
                        hint: 'e.g., Paracetamol',
                        controller: _genericNameCtrl,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: ModernTextField(
                        label: 'Strength',
                        hint: 'e.g., 500mg',
                        controller: _strengthCtrl,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ModernTextField(
                        label: 'Dosage Form',
                        hint: 'e.g., Tablet, Syrup',
                        controller: _dosageFormCtrl,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                _buildSectionHeader(
                  'Clinical Details',
                  Icons.medical_services_outlined,
                ),
                Row(
                  children: [
                    Expanded(
                      child: ModernTextField(
                        label: 'Route of Admin.',
                        hint: 'e.g., Oral, IV',
                        controller: _routeCtrl,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ModernTextField(
                        label: 'Therapeutic Class',
                        hint: 'e.g., Analgesic',
                        controller: _therapeuticClassCtrl,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ModernTextField(
                        label: 'ATC Code',
                        hint: 'e.g., N02BE01',
                        controller: _atcCodeCtrl,
                      ),
                    ),
                  ],
                ),
                ModernTextField(
                  label: 'Max Daily Dose',
                  hint: 'Maximum allowed units per day',
                  controller: _maxDailyDoseCtrl,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),
                _buildSectionHeader(
                  'Stock & Rules',
                  Icons.inventory_2_outlined,
                ),
                Row(
                  children: [
                    Expanded(
                      child: ModernTextField(
                        label: 'Reorder Level',
                        hint: 'Trigger alert below this stock',
                        controller: _reorderLevelCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ModernTextField(
                        label: 'Reorder Quantity',
                        hint: 'Default restock amount',
                        controller: _reorderQtyCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                _buildSectionHeader('Ward Pricing', Icons.price_change),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedWardId,
                        hint: const Text('Select Ward'),
                        onChanged: (value) =>
                            setState(() => _selectedWardId = value),
                        items: _availableWards
                            .map(
                              (ward) => DropdownMenuItem<String>(
                                value: ward.id,
                                child: Text(ward.name),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ModernTextField(
                        label: 'Price',
                        hint: 'Ward-specific price',
                        controller: _wardPriceController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _addWardPrice,
                      child: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_priceRows.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ward Prices',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ..._priceRows.map(
                            (row) => ListTile(
                              dense: true,
                              title: Text(row.wardName ?? row.wardId),
                              subtitle: Text(
                                'NGN ${row.price.toStringAsFixed(2)}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => _removeWardPrice(row),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                _buildSectionHeader('Special Flags', Icons.flag_outlined),
                ModernSwitchCard(
                  title: 'Controlled Substance',
                  subtitle:
                      'Requires special dispensation approvals and auditing.',
                  value: _isControlled,
                  onChanged: (v) => setState(() => _isControlled = v),
                ),
                ModernSwitchCard(
                  title: 'Requires Refrigeration',
                  subtitle: 'Must be stored in cold chain facilities.',
                  value: _isRefrigerated,
                  onChanged: (v) => setState(() => _isRefrigerated = v),
                ),
                ModernSwitchCard(
                  title: 'High Alert Medication',
                  subtitle:
                      'Drugs that bear a heightened risk of causing significant patient harm.',
                  value: _isHighAlert,
                  onChanged: (v) => setState(() => _isHighAlert = v),
                ),

                const SizedBox(height: 32),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save Drug details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
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
}
