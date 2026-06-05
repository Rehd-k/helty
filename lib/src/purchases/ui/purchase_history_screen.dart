import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_exception.dart';
import '../../core/extensions/number.extention.dart';
import '../models/purchases_model.dart';
import '../services/purchases_service.dart';

class _SupplyHistoryRow {
  _SupplyHistoryRow({
    required this.batch,
    required this.quantity,
    required this.totalCost,
    required this.status,
    required this.receiveDate,
    this.supplierName,
    this.category,
  });

  final PurchaseItemBatch batch;
  final int quantity;
  final double totalCost;
  final String status;
  final DateTime? receiveDate;
  final String? supplierName;
  final String? category;
}

enum _DateFilterOption { last7Days, last30Days, last90Days, allTime }

class _DrugPickResult {
  const _DrugPickResult.clear() : item = null, explicitClear = true;
  _DrugPickResult.selected(this.item) : explicitClear = false;

  final PurchaseItem? item;
  final bool explicitClear;
}

String _drugDisplayLabel(PurchaseItem d) {
  final name = d.itemName.trim();
  return name.isEmpty ? 'Unnamed item' : name;
}

Widget? _subtitleForDrugPicker(PurchaseItem d) {
  final parts = <String>[];
  final cat = d.category?.trim();
  final sku = d.sku?.trim();
  if (cat != null && cat.isNotEmpty) parts.add(cat);
  if (sku != null && sku.isNotEmpty) parts.add(sku);
  if (parts.isEmpty) return null;
  return Text(parts.join(' · '));
}

@RoutePage()
class PurchasesPurchaseHistoryScreen extends StatefulWidget {
  const PurchasesPurchaseHistoryScreen({super.key});

  @override
  State<PurchasesPurchaseHistoryScreen> createState() =>
      _PurchasesPurchaseHistoryScreenState();
}

class _PurchasesPurchaseHistoryScreenState
    extends State<PurchasesPurchaseHistoryScreen> {
  final PurchasesApiService _api = PurchasesApiService();

  // Data + pagination
  List<_SupplyHistoryRow> _rows = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentPage = 1;
  int _pageSize = 25;
  int _totalItems = 0;

  // Sorting
  int? _sortColumnIndex;
  bool _isAscending = false;
  String? _sortBy;

  // Filters
  _DateFilterOption _dateFilter = _DateFilterOption.last30Days;
  String? _selectedSupplierId;
  String _selectedCategory = 'All';
  PurchaseItem? _selectedDrug;

  // PurchasesSupplier dropdown options
  List<PurchasesSupplier> _suppliers = [];
  bool _isLoadingSuppliers = false;

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
    _fetchHistory();
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoadingSuppliers = true);
    try {
      final List<PurchasesSupplier> all = [];
      const pageSize = 100;
      int page = 1;
      while (true) {
        final resp = await _api.getSuppliers(
          PurchasesQueryParams(
            page: page,
            pageSize: pageSize,
            sortBy: 'name',
            sortOrder: SortOrder.asc,
          ),
        );
        if (resp.items.isEmpty) break;
        all.addAll(resp.items);
        if (!resp.hasNext || all.length >= resp.total) break;
        page++;
      }
      if (!mounted) return;
      setState(() {
        _suppliers = all
            .where((s) => s.id != null && s.id!.trim().isNotEmpty)
            .toList();
      });
    } catch (_) {
      if (mounted) setState(() => _suppliers = []);
    } finally {
      if (mounted) {
        setState(() => _isLoadingSuppliers = false);
      }
    }
  }

  Map<String, dynamic> _buildFilters() {
    final filters = <String, dynamic>{};

    // PurchasesSupplier filter (backend: supplierId)
    if (_selectedSupplierId != null && _selectedSupplierId!.trim().isNotEmpty) {
      filters['supplierId'] = _selectedSupplierId!.trim();
    }

    // Category: backend may not support therapeuticClass on batch search; send anyway for future use
    if (_selectedCategory != 'All' && _selectedCategory.trim().isNotEmpty) {
      filters['therapeuticClass'] = _selectedCategory.trim();
    }

    final itemId = _selectedDrug?.id?.trim();
    if (itemId != null && itemId.isNotEmpty) {
      filters['itemId'] = itemId;
    }

    // Date filter: backend uses manufacturingDateFrom / manufacturingDateTo (and expiryDateFrom/To)
    final now = DateTime.now();
    DateTime? from;
    switch (_dateFilter) {
      case _DateFilterOption.last7Days:
        from = now.subtract(const Duration(days: 7));
        break;
      case _DateFilterOption.last30Days:
        from = now.subtract(const Duration(days: 30));
        break;
      case _DateFilterOption.last90Days:
        from = now.subtract(const Duration(days: 90));
        break;
      case _DateFilterOption.allTime:
        from = null;
        break;
    }
    if (from != null) {
      filters['manufacturingDateFrom'] = from.toIso8601String();
      filters['manufacturingDateTo'] = now.toIso8601String();
    }

    return filters;
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _api.getItemBatches(
        PurchasesQueryParams(
          page: _currentPage,
          pageSize: _pageSize,
          sortBy: _sortBy,
          sortOrder: _isAscending ? SortOrder.asc : SortOrder.desc,
          filters: _buildFilters(),
        ),
      );

      final now = DateTime.now();
      final rows = response.items.map((batch) {
        final receivedAt = batch.createdAt;
        final quantity = batch.quantityReceived;
        final costPrice = batch.costPrice ?? 0;
        final totalCost = quantity * costPrice;

        String status = 'Verified';
        if (batch.expiryDate != null && batch.expiryDate!.isBefore(now)) {
          status = 'Quarantine';
        }

        final supplierName = batch.supplierName;
        final category = batch.item?.category ?? batch.item?.itemName;

        return _SupplyHistoryRow(
          batch: batch,
          quantity: quantity,
          totalCost: totalCost,
          status: status,
          receiveDate: receivedAt,
          supplierName: supplierName,
          category: category,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _totalItems = response.total;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSort(int columnIndex, bool ascending, String sortKey) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
      _sortBy = sortKey;
    });
    _fetchHistory();
  }

  void _onPageChanged(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
    _fetchHistory();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatQuantity(_SupplyHistoryRow row) {
    final unit = row.batch.item?.displayUnit ?? 'units';
    return '${row.quantity} $unit';
  }

  String _formatTotalCost(_SupplyHistoryRow row) {
    return row.totalCost.toFinancial(isMoney: true);
  }

  String _itemNameForRow(_SupplyHistoryRow row) {
    final d = row.batch.item;
    if (d != null) return _drugDisplayLabel(d);
    if (row.batch.itemId.isNotEmpty) return row.batch.itemId;
    return '—';
  }

  Future<void> _showDrugPicker() async {
    final result = await showModalBottomSheet<_DrugPickResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _SupplyHistoryDrugSheet(api: _api),
    );
    if (!mounted || result == null) return;
    if (result.explicitClear) {
      setState(() {
        _selectedDrug = null;
        _currentPage = 1;
      });
      _fetchHistory();
      return;
    }
    if (result.item != null) {
      setState(() {
        _selectedDrug = result.item;
        _currentPage = 1;
      });
      _fetchHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const pageBg = Color(0xFFF4F6FA);
    const accent = Color(0xFF0D9488);

    final scopeSubtitle = _selectedDrug != null
        ? 'Inbound batches for ${_drugDisplayLabel(_selectedDrug!)}'
        : 'Track receipts, costs, and batch status across suppliers';

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: pageBg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Purchase history',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 46, top: 4),
              child: Text(
                scopeSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    theme: theme,
                    icon: Icons.payments_outlined,
                    iconColor: const Color(0xFF6366F1),
                    title: 'Page value (received)',
                    value: _rows.isEmpty
                        ? '₦0.00'
                        : _rows
                              .fold<num>(0, (sum, r) => sum + r.totalCost)
                              .toFinancial(isMoney: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    theme: theme,
                    icon: Icons.move_to_inbox_outlined,
                    iconColor: accent,
                    title: 'Units on this page',
                    value:
                        '${_rows.fold<int>(0, (sum, r) => sum + r.quantity)} units',
                    isUnitTextBold: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    theme: theme,
                    icon: Icons.assignment_turned_in_outlined,
                    iconColor: const Color(0xFFEA580C),
                    title: 'Batches listed',
                    value: '${_rows.length}',
                    isUnitTextBold: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildFilterToolbar(theme, accent),

            const SizedBox(height: 16),

            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          children: [
                            Text(
                              'Batch receipts',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const Spacer(),
                            if (_selectedDrug != null)
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedDrug = null;
                                    _currentPage = 1;
                                  });
                                  _fetchHistory();
                                },
                                icon: const Icon(Icons.close, size: 18),
                                label: const Text('Clear Item'),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 24),
                      Expanded(
                        child: _isLoading
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 36,
                                      height: 36,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Loading batches…',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _errorMessage.isNotEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    _errorMessage,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                            : _buildScrollableTable(theme),
                      ),
                      _buildPagination(theme),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Builders ---

  Widget _buildStatCard({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    bool isUnitTextBold = false,
  }) {
    final valueParts = value.split(' ');
    final mainValue = valueParts.isNotEmpty ? valueParts.first : value;
    final suffix = valueParts.length > 1
        ? valueParts.sublist(1).join(' ')
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(text: mainValue),
                if (suffix != null && suffix.isNotEmpty)
                  TextSpan(
                    text: ' $suffix',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: isUnitTextBold
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: const Color(0xFF334155),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar(ThemeData theme, Color accent) {
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.tonalIcon(
              onPressed: _showDrugPicker,
              icon: const Icon(Icons.medication_outlined, size: 20),
              label: Text(
                _selectedDrug != null
                    ? _drugDisplayLabel(_selectedDrug!)
                    : 'Select Item',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                backgroundColor: accent.withValues(alpha: 0.1),
                foregroundColor: const Color(0xFF0F766E),
              ),
            ),
            if (_selectedDrug != null)
              IconButton(
                tooltip: 'Clear Item Filter',
                onPressed: () {
                  setState(() {
                    _selectedDrug = null;
                    _currentPage = 1;
                  });
                  _fetchHistory();
                },
                icon: const Icon(Icons.close_rounded),
              ),
            const SizedBox(width: 4),
            _buildDateFilterDropdown(),
            _buildSupplierFilterDropdown(),
            _buildCategoryFilterDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 20,
            color: Color(0xFF6C757D),
          ),
          const SizedBox(width: 8),
          DropdownButton<_DateFilterOption>(
            value: _dateFilter,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(8),
            items: const [
              DropdownMenuItem(
                value: _DateFilterOption.last7Days,
                child: Text('Date: Last 7 Days'),
              ),
              DropdownMenuItem(
                value: _DateFilterOption.last30Days,
                child: Text('Date: Last 30 Days'),
              ),
              DropdownMenuItem(
                value: _DateFilterOption.last90Days,
                child: Text('Date: Last 90 Days'),
              ),
              DropdownMenuItem(
                value: _DateFilterOption.allTime,
                child: Text('Date: All Time'),
              ),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _dateFilter = v;
                _currentPage = 1;
              });
              _fetchHistory();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            size: 20,
            color: Color(0xFF6C757D),
          ),
          const SizedBox(width: 8),
          DropdownButton<String?>(
            value: _selectedSupplierId,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(8),
            hint: const Text(
              'PurchasesSupplier: All',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF495057),
              ),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('PurchasesSupplier: All'),
              ),
              ..._suppliers.map(
                (s) =>
                    DropdownMenuItem<String?>(value: s.id, child: Text(s.name)),
              ),
            ],
            onChanged: _isLoadingSuppliers
                ? null
                : (v) {
                    setState(() {
                      _selectedSupplierId = v;
                      _currentPage = 1;
                    });
                    _fetchHistory();
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterDropdown() {
    const categories = <String>[
      'All',
      'Antibiotics',
      'Analgesics',
      'Vaccines',
      'Cardiovascular',
      'Oncology',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.category_outlined,
            size: 20,
            color: Color(0xFF6C757D),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedCategory,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(8),
            items: categories
                .map(
                  (c) => DropdownMenuItem<String>(
                    value: c,
                    child: Text('Item Category: $c'),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _selectedCategory = v;
                _currentPage = 1;
              });
              _fetchHistory();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableTable(ThemeData theme) {
    if (_rows.isEmpty) {
      final msg = _selectedDrug != null
          ? 'No batches found for this Item in the selected period.\nTry widening the date range or clearing other filters.'
          : 'No supply history matches these filters.\nPick a Item to see only its inbound batches, or adjust date and PurchasesSupplier.';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scrollbar(
      controller: _verticalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _verticalScrollController,
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _isAscending,
              headingRowColor: WidgetStateProperty.all(Colors.white),
              dataRowMinHeight: 70,
              dataRowMaxHeight: 70,
              horizontalMargin: 24,
              columnSpacing: 48,
              dividerThickness: 1,
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF6C757D),
                letterSpacing: 1.2,
              ),
              columns: [
                DataColumn(
                  label: const Text('BATCH\nID'),
                  onSort: (idx, asc) => _onSort(idx, asc, 'batchNumber'),
                ),
                const DataColumn(label: Text('Item')),
                DataColumn(
                  label: const Text('RECEIVE\nDATE'),
                  onSort: (idx, asc) => _onSort(idx, asc, 'createdAt'),
                ),
                const DataColumn(label: Text('PurchasesSupplier')),
                const DataColumn(label: Text('Item\nCATEGORY')),
                DataColumn(
                  label: const Text('QUANTITY'),
                  numeric: true,
                  onSort: (idx, asc) => _onSort(idx, asc, 'quantityReceived'),
                ),
                DataColumn(
                  label: const Text('TOTAL\nCOST'),
                  numeric: true,
                  onSort: (idx, asc) => _onSort(idx, asc, 'costPrice'),
                ),
                const DataColumn(label: Text('STATUS')),
              ],
              rows: _rows.map((row) {
                final batch = row.batch;
                final supplierText = row.supplierName ?? '—';
                final categoryText =
                    row.category ?? batch.item?.category ?? '—';

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        batch.batchNumber ?? (batch.id ?? '—'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          _itemNameForRow(row),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF334155),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        _formatDate(row.receiveDate),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          supplierText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ),
                    DataCell(_buildCategoryChip(categoryText)),
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          _formatQuantity(row),
                          style: const TextStyle(color: Colors.black54),
                          softWrap: true,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        _formatTotalCost(row),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    DataCell(_buildStatusChip(row.status)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: Color(0xFF6C757D),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;

    if (status.toLowerCase() == 'verified') {
      bgColor = const Color(0xFFE3FCEF);
      textColor = const Color(0xFF00A36C);
    } else if (status.toLowerCase() == 'quarantine') {
      bgColor = const Color(0xFFFFF3CD);
      textColor = const Color(0xFFD39E00);
    } else {
      bgColor = Colors.grey.shade100;
      textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPagination(ThemeData theme) {
    int totalPages = (_totalItems / _pageSize).ceil();
    if (totalPages == 0) totalPages = 1;
    final start = (_currentPage - 1) * _pageSize + 1;
    final end = (_currentPage * _pageSize).clamp(0, _totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Showing ${_totalItems == 0 ? 0 : start}–$end of $_totalItems',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(width: 16),
              Text(
                'Per page:',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _pageSize,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 10, child: Text('10')),
                  DropdownMenuItem(value: 25, child: Text('25')),
                  DropdownMenuItem(value: 50, child: Text('50')),
                  DropdownMenuItem(value: 100, child: Text('100')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _pageSize = v;
                    _currentPage = 1;
                  });
                  _fetchHistory();
                },
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Page $_currentPage of $totalPages',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1
                    ? () => _onPageChanged(_currentPage - 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < totalPages
                    ? () => _onPageChanged(_currentPage + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupplyHistoryDrugSheet extends StatefulWidget {
  const _SupplyHistoryDrugSheet({required this.api});

  final PurchasesApiService api;

  @override
  State<_SupplyHistoryDrugSheet> createState() =>
      _SupplyHistoryDrugSheetState();
}

class _SupplyHistoryDrugSheetState extends State<_SupplyHistoryDrugSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<PurchaseItem> _items = [];
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final resp = await widget.api.getItems(
        PurchasesQueryParams(
          page: 1,
          pageSize: 50,
          search: _searchCtrl.text.trim().isEmpty
              ? null
              : _searchCtrl.text.trim(),
          sortBy: 'genericName',
          sortOrder: SortOrder.asc,
        ),
      );
      if (!mounted) return;
      setState(() {
        _items = resp.items
            .where((d) => d.id != null && d.id!.trim().isNotEmpty)
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _items = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollCtrl) {
        return Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Choose a Item',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, const _DrugPickResult.clear()),
                      child: const Text('All drugs'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SearchBar(
                  controller: _searchCtrl,
                  hintText: 'Search generic or brand name…',
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_searchCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                        },
                      ),
                  ],
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _load(),
                ),
              ),
              const SizedBox(height: 8),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              Expanded(
                child: _loading && _items.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No drugs match this search. Try another name.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollCtrl,
                        padding: EdgeInsets.fromLTRB(8, 0, 8, 12 + bottom),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final d = _items[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xFF0D9488,
                              ).withValues(alpha: 0.12),
                              child: const Icon(
                                Icons.medication_outlined,
                                color: Color(0xFF0F766E),
                                size: 22,
                              ),
                            ),
                            title: Text(
                              _drugDisplayLabel(d),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: _subtitleForDrugPicker(d),
                            onTap: () => Navigator.pop(
                              context,
                              _DrugPickResult.selected(d),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
