import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/responsive.dart';

import '../../core/errors/app_exception.dart';
import '../../models/staff_model.dart';
import '../../models/super_admin_department_preview.dart';
import '../../providers/auth_provider.dart';
import '../../providers/super_admin_preview_provider.dart';
import '../inputs/morden.form.inpts.dart';
import '../models/pharmacy_model.dart';
import '../services/pharmacy_service.dart';

bool _viewerIsPharmacyHead(Staff? staff, SuperAdminPreviewState preview) {
  if (staffIsSuperAdmin(staff) && preview.isActive) {
    final r = (preview.previewRole ?? '').toLowerCase().trim();
    final at = (preview.previewAccountType ?? '').toLowerCase().trim();
    return r == 'pharmacy_head' || at == 'pharmacy_head';
  }
  final r = staff?.staffRole.toLowerCase().replaceAll('-', '_') ?? '';
  final pr = staff?.pharmacyRole?.toLowerCase().replaceAll('-', '_') ?? '';
  return r == 'pharmacy_head' || pr == 'pharmacy_head';
}

bool _batchEligibleForQuantityCorrection(DrugBatch b) {
  final created = b.createdAt;
  if (created == null) return false;
  return DateTime.now().difference(created) >= const Duration(hours: 24);
}

@RoutePage()
class StockTransferScreen extends ConsumerStatefulWidget {
  const StockTransferScreen({super.key});

  @override
  ConsumerState<StockTransferScreen> createState() =>
      _StockTransferScreenState();
}

class _StockTransferScreenState extends ConsumerState<StockTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = PharmacyApiService();

  // Controllers
  final _quantityCtrl = TextEditingController();
  final _referenceIdCtrl = TextEditingController();
  final _drugSearchCtrl = TextEditingController();

  // Locations
  List<PharmacyLocation> _locations = [];
  bool _isLoadingLocations = false;
  String? _locationsError;

  String? _fromLocationId;
  String? _toLocationId;

  // Drugs (paginated, filterable)
  PaginatedResponse<Drug>? _drugPage;
  bool _isLoadingDrugs = false;
  String? _drugsError;
  int _drugPageIndex = 1;
  static const int _pageSize = 20;

  Drug? _selectedDrug;

  // Batches for selected drug (paginated, latest first)
  PaginatedResponse<DrugBatch>? _batchPage;
  bool _isLoadingBatches = false;
  String? _batchesError;
  int _batchPageIndex = 1;

  DrugBatch? _selectedBatch;

  // Staged transfer lines to be moved together
  final List<_TransferLine> _lines = [];

  bool _isSubmitting = false;

  Timer? _drugSearchDebounce;

  @override
  void initState() {
    super.initState();
    _drugSearchCtrl.addListener(_scheduleDrugSearchReload);
    _loadLocations();
    _loadDrugs();
  }

  @override
  void dispose() {
    _drugSearchDebounce?.cancel();
    _drugSearchCtrl.removeListener(_scheduleDrugSearchReload);
    _quantityCtrl.dispose();
    _referenceIdCtrl.dispose();
    _drugSearchCtrl.dispose();
    super.dispose();
  }

  void _scheduleDrugSearchReload() {
    _drugSearchDebounce?.cancel();
    _drugSearchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _drugPageIndex = 1);
      _loadDrugs();
    });
  }

  void _searchDrugsNow() {
    _drugSearchDebounce?.cancel();
    setState(() => _drugPageIndex = 1);
    _loadDrugs();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoadingLocations = true;
      _locationsError = null;
    });
    try {
      final resp = await _apiService.getPharmacyLocations();
      if (!mounted) return;
      setState(() {
        _locations = resp.items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationsError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocations = false);
      }
    }
  }

  Future<void> _loadDrugs() async {
    setState(() {
      _isLoadingDrugs = true;
      _drugsError = null;
    });
    try {
      final q = PharmacyQueryParams(
        page: _drugPageIndex,
        pageSize: _pageSize,
        search: _drugSearchCtrl.text.trim().isEmpty
            ? null
            : _drugSearchCtrl.text.trim(),
        sortBy: 'genericName',
        sortOrder: SortOrder.asc,
      );
      final resp = await _apiService.getDrugs(q);
      if (!mounted) return;
      setState(() {
        _drugPage = resp;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _drugsError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingDrugs = false);
      }
    }
  }

  Future<void> _loadBatches() async {
    if (_selectedDrug?.id == null) return;
    final fromId = _fromLocationId;
    if (fromId == null || fromId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoadingBatches = false;
        _batchesError = null;
        _batchPage = null;
        _selectedBatch = null;
      });
      return;
    }
    setState(() {
      _isLoadingBatches = true;
      _batchesError = null;
    });
    try {
      final q = PharmacyQueryParams(
        page: _batchPageIndex,
        pageSize: _pageSize,
        sortBy: 'createdAt',
        sortOrder: SortOrder.desc,
        filters: {
          'drugId': _selectedDrug!.id,
          'toLocationId': fromId,
          'doNotAllowempty': true,
        },
      );
      final resp = await _apiService.getDrugBatches(q);
      if (!mounted) return;
      setState(() {
        _batchPage = resp;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _batchesError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingBatches = false);
      }
    }
  }

  int _availableForBatch(DrugBatch batch) {
    final used = _lines
        .where((l) => l.batch.id == batch.id)
        .fold<int>(0, (sum, l) => sum + l.quantity);
    final baseQty = batch.quantityRemaining ?? batch.quantityReceived;
    return (baseQty - used).clamp(0, baseQty);
  }

  Future<void> _addLine() async {
    if (_fromLocationId == null ||
        _toLocationId == null ||
        _selectedDrug == null ||
        _selectedBatch == null) {
      _showError('Please select from, to, drug and batch.');
      return;
    }
    if (_fromLocationId == _toLocationId) {
      _showError('Source and destination locations cannot be the same.');
      return;
    }
    final qty = int.tryParse(_quantityCtrl.text.trim());
    if (qty == null || qty <= 0) {
      _showError('Enter a valid quantity.');
      return;
    }
    final available = _availableForBatch(_selectedBatch!);
    if (qty > available) {
      _showError(
        'Cannot transfer more than available quantity ($available) for this batch.',
      );
      return;
    }

    setState(() {
      _lines.add(
        _TransferLine(
          drug: _selectedDrug!,
          batch: _selectedBatch!,
          quantity: qty,
        ),
      );
      _quantityCtrl.clear();
    });
  }

  Future<void> _submitAll() async {
    if (_lines.isEmpty) {
      _showError('Add at least one item to transfer.');
      return;
    }
    if (_fromLocationId == null || _toLocationId == null) {
      _showError('Select both source and destination locations.');
      return;
    }
    if (_fromLocationId == _toLocationId) {
      _showError('Source and destination locations cannot be the same.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final items = <StockTransferItemDto>[];
      for (final line in _lines) {
        final batchId = line.batch.id;
        if (batchId == null || batchId.isEmpty) {
          _showError(
            'Every line must have a batch id. Remove invalid lines and try again.',
          );
          return;
        }
        items.add(
          StockTransferItemDto(batchId: batchId, quantity: line.quantity),
        );
      }
      final dto = CreateStockTransferDto(
        fromLocationId: _fromLocationId!,
        toLocationId: _toLocationId!,
        items: items,
      );
      await _apiService.createStockTransfer(dto);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock transferred successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _showQuantityCorrectionDialog(DrugBatch batch) async {
    final batchId = batch.id;
    if (batchId == null || batchId.isEmpty) {
      _showError('This batch has no id; quantity cannot be corrected here.');
      return;
    }

    final receivedCtrl = TextEditingController(
      text: '${batch.quantityReceived}',
    );
    final remainingCtrl = TextEditingController(
      text: '${batch.quantityRemaining ?? batch.quantityReceived}',
    );

    var submitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Future<void> submit() async {
              final received = int.tryParse(receivedCtrl.text.trim());
              final remaining = int.tryParse(remainingCtrl.text.trim());
              if (received == null || received < 0) {
                _showError('Enter a valid quantity received (0 or greater).');
                return;
              }
              if (remaining == null || remaining < 0) {
                _showError('Enter a valid quantity remaining (0 or greater).');
                return;
              }
              setLocal(() => submitting = true);
              try {
                final updated = await _apiService.correctDrugBatchQuantity(
                  batchId,
                  CorrectBatchQuantityDto(
                    quantityReceived: received,
                    quantityRemaining: remaining,
                  ),
                );
                if (!mounted) return;
                setState(() {
                  if (_selectedBatch?.id == updated.id) {
                    _selectedBatch = updated;
                  }
                  final nextLines = _lines.map((l) {
                    if (l.batch.id != updated.id) return l;
                    final maxAvail =
                        updated.quantityRemaining ?? updated.quantityReceived;
                    final q = l.quantity.clamp(0, maxAvail);
                    return _TransferLine(
                      drug: l.drug,
                      batch: updated,
                      quantity: q,
                    );
                  }).toList();
                  _lines
                    ..clear()
                    ..addAll(nextLines);
                });
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Batch quantities updated.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await _loadBatches();
                }
              } on AppException catch (e) {
                if (mounted) _showError(e.message);
              } catch (e) {
                if (mounted) _showError(e.toString());
              } finally {
                if (ctx.mounted) {
                  setLocal(() => submitting = false);
                }
              }
            }

            return AlertDialog(
              title: const Text('Correct batch quantities'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batch ${batch.batchNumber ?? batchId}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For wrong data entry only. This uses the restricted '
                      'correction endpoint (pharmacy head; batch must be at '
                      'least 24 hours old — the server will reject otherwise).',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: receivedCtrl,
                      enabled: !submitting,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity received',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: remainingCtrl,
                      enabled: !submitting,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity remaining',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: submitting ? null : submit,
                  child: submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save correction'),
                ),
              ],
            );
          },
        );
      },
    );

    receivedCtrl.dispose();
    remainingCtrl.dispose();
  }

  Widget? _buildBatchQuantityCorrectionButton(ThemeData theme, DrugBatch b) {
    final staff = ref.watch(authProvider).staff;
    final preview = ref.watch(superAdminPreviewProvider);
    if (!_viewerIsPharmacyHead(staff, preview)) return null;

    final eligible = _batchEligibleForQuantityCorrection(b);
    return IconButton(
      tooltip: eligible
          ? 'Correct received & remaining (data entry)'
          : 'Corrections are allowed once the batch is at least 24 hours old',
      onPressed: eligible ? () => _showQuantityCorrectionDialog(b) : null,
      icon: Icon(
        Icons.edit_note_outlined,
        color: eligible ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) => Form(
          key: _formKey,
          child: ResponsiveRowColumn(
            gap: 24,
            firstFlex: 3,
            secondFlex: 2,
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLocationsCard(theme),
                Expanded(child: _buildItemsSelector(theme)),
              ],
            ),
            second: _buildSummaryPanel(theme),
          ),
        ),
      ),
    );
  }

  // --- UI Helpers ---

  // Widget _buildSectionHeader(String title, IconData icon) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
  //     child: Row(
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.all(8),
  //           decoration: BoxDecoration(
  //             color: Colors.blue.shade50,
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: Icon(icon, color: Colors.blue.shade700, size: 20),
  //         ),
  //         const SizedBox(width: 12),
  //         Text(
  //           title,
  //           style: TextStyle(
  //             fontSize: 16,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.blue.shade900,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildModernDropdown({
    required String label,
    required String hint,
    required dynamic value,
    required List<DropdownMenuItem<dynamic>> items,
    required void Function(dynamic)? onChanged,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDisabled = onChanged == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<dynamic>(
            initialValue: value,
            items: items,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              prefixIcon: icon != null
                  ? Icon(icon, size: 20, color: cs.onSurfaceVariant)
                  : null,
              filled: true,
              fillColor: isDisabled
                  ? cs.surfaceContainerHighest
                  : cs.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: cs.primary,
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: isDisabled
                  ? cs.onSurfaceVariant.withValues(alpha: 0.38)
                  : cs.onSurfaceVariant,
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsCard(ThemeData theme) {
    if (_isLoadingLocations) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_locationsError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _locationsError!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildModernDropdown(
                label: 'From (Source)',
                hint: _locations.isEmpty ? 'No locations' : 'Select Origin',
                value: _fromLocationId,
                icon: Icons.store_outlined,
                items: _locations
                    .map(
                      (loc) => DropdownMenuItem(
                        value: loc.id,
                        child: Text(loc.name),
                      ),
                    )
                    .toList(),
                onChanged: _locations.isEmpty
                    ? null
                    : (v) {
                        setState(() {
                          _fromLocationId = v as String?;
                          if (_toLocationId == _fromLocationId) {
                            _toLocationId = null;
                          }
                          _batchPageIndex = 1;
                          _selectedBatch = null;
                        });
                        if (_selectedDrug != null) {
                          _loadBatches();
                        }
                      },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
              ).copyWith(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              child: _buildModernDropdown(
                label: 'To (Destination)',
                hint: _locations.isEmpty
                    ? 'No locations'
                    : 'Select Destination',
                value: _toLocationId,
                icon: Icons.local_pharmacy_outlined,
                items: _locations
                    .where(
                      (loc) =>
                          _fromLocationId == null || loc.id != _fromLocationId,
                    )
                    .map(
                      (loc) => DropdownMenuItem(
                        value: loc.id,
                        child: Text(loc.name),
                      ),
                    )
                    .toList(),
                onChanged: _locations.isEmpty
                    ? null
                    : (v) => setState(() => _toLocationId = v as String?),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSelector(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _drugSearchCtrl,
              decoration: InputDecoration(
                labelText: 'Search drug',
                hintText: 'Type to filter medicines',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (_) => _searchDrugsNow(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available drugs',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Expanded(child: _buildDrugsList(theme)),
                        _buildDrugsPager(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Batches for selected drug',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Expanded(child: _buildBatchList(theme)),
                        _buildBatchesPager(),
                        const SizedBox(height: 12),
                        _buildQuantityRow(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrugsList(ThemeData theme) {
    if (_isLoadingDrugs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_drugsError != null) {
      return Center(
        child: Text(_drugsError!, style: const TextStyle(color: Colors.red)),
      );
    }
    final drugs = _drugPage?.items ?? [];
    if (drugs.isEmpty) {
      return const Center(child: Text('No drugs found.'));
    }

    return ListView.separated(
      itemCount: drugs.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final d = drugs[index];
        final selected = _selectedDrug?.id == d.id;
        return ListTile(
          dense: true,
          selected: selected,
          selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.06),
          title: Text(
            d.brandName.isNotEmpty ? d.brandName : d.genericName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            [
              d.genericName,
              if (d.strength != null && d.strength!.isNotEmpty) d.strength!,
              if (d.dosageForm != null && d.dosageForm!.isNotEmpty)
                d.dosageForm!,
            ].where((s) => s.isNotEmpty).join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            setState(() {
              _selectedDrug = d;
              _batchPageIndex = 1;
              _selectedBatch = null;
            });
            _loadBatches();
          },
        );
      },
    );
  }

  Widget _buildDrugsPager() {
    final page = _drugPage;
    if (page == null || page.totalPages <= 1) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Page ${page.page} of ${page.totalPages}',
          style: const TextStyle(fontSize: 12),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: page.hasPrevious && !_isLoadingDrugs
                  ? () {
                      setState(() => _drugPageIndex = page.page - 1);
                      _loadDrugs();
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: page.hasNext && !_isLoadingDrugs
                  ? () {
                      setState(() => _drugPageIndex = page.page + 1);
                      _loadDrugs();
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBatchList(ThemeData theme) {
    if (_selectedDrug == null) {
      return const Center(child: Text('Select a drug to see its batches.'));
    }
    if (_fromLocationId == null) {
      return const Center(
        child: Text(
          'Select a source (From) location to list batches stocked there.',
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_isLoadingBatches) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_batchesError != null) {
      return Center(
        child: Text(_batchesError!, style: const TextStyle(color: Colors.red)),
      );
    }
    final batches = _batchPage?.items ?? [];
    if (batches.isEmpty) {
      return const Center(child: Text('No batches found for this drug.'));
    }

    return ListView.separated(
      itemCount: batches.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final b = batches[index];
        final selected = _selectedBatch?.id == b.id;
        final available = _availableForBatch(b);
        return ListTile(
          dense: true,
          selected: selected,
          selectedTileColor: theme.colorScheme.secondary.withValues(
            alpha: 0.06,
          ),
          title: Text(
            b.batchNumber ?? 'Batch',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'Qty: ${b.quantityReceived} • Available: $available'
            '${b.expiryDate != null ? ' • Exp: ${b.expiryDate!.toIso8601String().split('T').first}' : ''}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: _buildBatchQuantityCorrectionButton(theme, b),
          onTap: () {
            setState(() {
              _selectedBatch = b;
            });
          },
        );
      },
    );
  }

  Widget _buildBatchesPager() {
    final page = _batchPage;
    if (page == null || page.totalPages <= 1) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Page ${page.page} of ${page.totalPages}',
          style: const TextStyle(fontSize: 12),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: page.hasPrevious && !_isLoadingBatches
                  ? () {
                      setState(() => _batchPageIndex = page.page - 1);
                      _loadBatches();
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: page.hasNext && !_isLoadingBatches
                  ? () {
                      setState(() => _batchPageIndex = page.page + 1);
                      _loadBatches();
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantityRow() {
    final selectedBatch = _selectedBatch;
    final available = selectedBatch != null
        ? _availableForBatch(selectedBatch)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ModernTextField(
                label: 'Quantity to transfer',
                hint: 'e.g., 100',
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                icon: Icons.numbers,
              ),
            ),
          ],
        ),
        SizedBox(
          width: double.infinity,

          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _addLine,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
          ),
        ),
        if (selectedBatch != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
            child: Text(
              'Available from this batch: $available units',
              style: TextStyle(
                fontSize: 12,
                color: available > 0 ? Colors.green.shade700 : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryPanel(ThemeData theme) {
    final totalQty = _lines.fold<int>(0, (sum, l) => sum + l.quantity);
    final distinctDrugs = _lines.map((l) => l.drug.id).toSet().length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transfer Summary',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Review and confirm before moving stock.',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            ModernTextField(
              label: 'Reference / Document ID (optional)',
              hint: 'e.g., REQ-2026-001',
              controller: _referenceIdCtrl,
              icon: Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _lines.isEmpty
                  ? const Center(
                      child: Text(
                        'No items added yet.\nSelect a drug & batch, then add to transfer.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _lines.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final line = _lines[index];
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          title: Text(
                            line.drug.brandName.isNotEmpty
                                ? line.drug.brandName
                                : line.drug.genericName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Batch: ${line.batch.batchNumber ?? '-'} • Qty: ${line.quantity}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () {
                              setState(() {
                                _lines.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            if (_lines.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items: ${_lines.length} • Distinct drugs: $distinctDrugs • Total qty: $totalQty',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitAll,
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
                  _isSubmitting ? 'Moving stock...' : 'Move all items',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferLine {
  const _TransferLine({
    required this.drug,
    required this.batch,
    required this.quantity,
  });

  final Drug drug;
  final DrugBatch batch;
  final int quantity;
}
