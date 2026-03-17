import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../models/pharmacy_model.dart';
import '../services/pharmacy_service.dart';
import '../inputs/morden.form.inpts.dart';

@RoutePage()
class AddSupplierScreen extends StatefulWidget {
  const AddSupplierScreen({super.key});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = PharmacyApiService();
  bool _isLoading = false;

  final _suppliersScrollController = ScrollController();

  final _nameCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _creditTermsCtrl = TextEditingController();
  final _leadTimeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _isBlacklisted = false;

  PaginatedResponse<Supplier>? _suppliersPage;
  bool _isLoadingSuppliers = false;
  String? _suppliersError;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _suppliersScrollController.dispose();
    _nameCtrl.dispose();
    _licenseCtrl.dispose();
    _creditTermsCtrl.dispose();
    _leadTimeCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() {
      _isLoadingSuppliers = true;
      _suppliersError = null;
    });

    try {
      final page = await _apiService.getSuppliers(
        const PharmacyQueryParams(
          pageSize: 20,
          sortBy: 'name',
          sortOrder: SortOrder.asc,
        ),
      );
      if (mounted) {
        setState(() {
          _suppliersPage = page;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suppliersError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSuppliers = false;
        });
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String? _contactField(Supplier supplier, String key) {
    final info = supplier.contactInfo;
    if (info == null) return null;
    final value = info[key];
    return value?.toString();
  }

  void _showSupplierSuppliesDialog(Supplier supplier) {
    showDialog(
      context: context,
      builder: (ctx) {
        if (supplier.id == null || supplier.id!.isEmpty) {
          return AlertDialog(
            title: const Text('Supplies'),
            content: const Text(
              'Supplier id is missing, unable to load supplies.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        }

        return AlertDialog(
          title: Text('Supplies from ${supplier.name}'),
          content: SizedBox(
            width: 800,
            height: 400,
            child: FutureBuilder<PaginatedResponse<DrugBatch>>(
              future: _apiService.getDrugBatches(
                PharmacyQueryParams(filters: {'supplierId': supplier.id}),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                final data = snapshot.data;
                final batches = data?.items ?? [];
                if (batches.isEmpty) {
                  return const Center(
                    child: Text('No supplies found for this supplier.'),
                  );
                }

                return SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Drug')),
                        DataColumn(label: Text('Batch')),
                        DataColumn(label: Text('Qty')),
                        DataColumn(label: Text('Unit Cost')),
                        DataColumn(label: Text('Expiry')),
                        DataColumn(label: Text('Received At')),
                      ],
                      rows: batches.map((b) {
                        final drug = b.drug;
                        final drugName = (drug?.brandName.isNotEmpty == true)
                            ? drug!.brandName
                            : (drug?.genericName ?? '');
                        return DataRow(
                          cells: [
                            DataCell(Text(drugName.isEmpty ? '-' : drugName)),
                            DataCell(Text(b.batchNumber ?? '-')),
                            DataCell(Text(b.quantityReceived.toString())),
                            DataCell(
                              Text(
                                b.costPrice != null
                                    ? b.costPrice!.toStringAsFixed(2)
                                    : '-',
                              ),
                            ),
                            DataCell(Text(_formatDate(b.expiryDate))),
                            DataCell(Text(_formatDate(b.createdAt))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSupplierForm(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ModernTextField(
                  label: 'Supplier Name',
                  hint: 'e.g., Global Pharma Distributors',
                  controller: _nameCtrl,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                ModernTextField(
                  label: 'License Number',
                  hint: 'Operating license ID',
                  controller: _licenseCtrl,
                ),
                const Divider(height: 32),
                ModernTextField(
                  label: 'Email Address',
                  hint: 'contact@supplier.com',
                  controller: _emailCtrl,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                ModernTextField(
                  label: 'Phone Number',
                  hint: '+1 234 567 890',
                  controller: _phoneCtrl,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ModernTextField(
                        label: 'Credit Terms',
                        hint: 'e.g., Net 30',
                        controller: _creditTermsCtrl,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ModernTextField(
                        label: 'Lead Time (Days)',
                        hint: 'e.g., 5',
                        controller: _leadTimeCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                ModernSwitchCard(
                  title: 'Blacklist Supplier',
                  subtitle:
                      'Prevent future purchase orders from being issued to this supplier.',
                  value: _isBlacklisted,
                  onChanged: (v) => setState(() => _isBlacklisted = v),
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
                      ? const CircularProgressIndicator()
                      : const Text('Save Supplier'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuppliersTableSection(BuildContext context) {
    if (_isLoadingSuppliers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_suppliersError != null) {
      return Center(
        child: Text(
          _suppliersError!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final suppliers = _suppliersPage?.items ?? [];

    if (suppliers.isEmpty) {
      return const Center(child: Text('No suppliers found.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const cardMinWidth = 260.0;
        final crossAxisCount = (constraints.maxWidth / (cardMinWidth + 16))
            .floor()
            .clamp(1, 4);

        final gridWidth =
            (cardMinWidth + 16) * crossAxisCount.toDouble() + 16.0;

        return Scrollbar(
          controller: _suppliersScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _suppliersScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: gridWidth.clamp(constraints.maxWidth, double.infinity),
              child: GridView.builder(
                padding: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 3.4,
                ),
                itemCount: suppliers.length,
                itemBuilder: (context, index) {
                  final s = suppliers[index];
                  final phone = _contactField(s, 'phone') ?? '-';
                  final email = _contactField(s, 'email') ?? '-';
                  final isBlacklisted = s.isBlacklisted;

                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: s.id == null || s.id!.isEmpty
                          ? null
                          : () => _showSupplierSuppliesDialog(s),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    s.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isBlacklisted
                                        ? Colors.red.withValues(alpha: 0.1)
                                        : Colors.green.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    isBlacklisted ? 'Blacklisted' : 'Active',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isBlacklisted
                                          ? Colors.red[700]
                                          : Colors.green[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    phone,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.email_outlined, size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s.creditTerms?.isNotEmpty == true
                                        ? s.creditTerms!
                                        : 'No credit terms',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      s.leadTimeDays != null
                                          ? '${s.leadTimeDays}d'
                                          : '--',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: s.id == null || s.id!.isEmpty
                                    ? null
                                    : () => _showSupplierSuppliesDialog(s),
                                icon: const Icon(
                                  Icons.list_alt_outlined,
                                  size: 16,
                                ),
                                label: const Text('View supplies'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final supplier = Supplier(
        name: _nameCtrl.text,
        licenseNumber: _licenseCtrl.text,
        creditTerms: _creditTermsCtrl.text,
        leadTimeDays: int.tryParse(_leadTimeCtrl.text),
        isBlacklisted: _isBlacklisted,
        contactInfo: {'phone': _phoneCtrl.text, 'email': _emailCtrl.text},
      );

      await _apiService.createSupplier(supplier);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supplier added successfully!')),
        );
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 900;

          final formSection = _buildSupplierForm(context, theme);
          final tableSection = Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Suppliers',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh suppliers',
                        onPressed: _isLoadingSuppliers ? null : _loadSuppliers,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: _buildSuppliersTableSection(context)),
                ],
              ),
            ),
          );

          if (isNarrow) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  formSection,
                  const SizedBox(height: 16),
                  SizedBox(height: 400, child: tableSection),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: formSection),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: constraints.maxHeight - 32,
                    child: tableSection,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
