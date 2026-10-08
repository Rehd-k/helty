import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/app_timezone.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/pharmacy/widgets/pharmacy_page_chrome.dart';
import 'package:helty/src/shared/department_colors.dart';
import 'package:helty/src/widgets/date.filter.dart';
import 'package:helty/src/widgets/helty_surface.dart';

import '../../core/errors/app_exception.dart';
import '../../core/extensions/number.extention.dart';
import '../models/pharmacy_model.dart';
import '../services/pharmacy_service.dart';

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

  final DrugBatch batch;
  final int quantity;
  final double totalCost;
  final String status;
  final DateTime? receiveDate;
  final String? supplierName;
  final String? category;
}

class _DrugPickResult {
  const _DrugPickResult.clear() : drug = null, explicitClear = true;
  _DrugPickResult.selected(this.drug) : explicitClear = false;

  final Drug? drug;
  final bool explicitClear;
}

String _drugDisplayLabel(Drug d) {
  final g = d.genericName.trim();
  final b = d.brandName.trim();
  if (g.isEmpty) return b.isEmpty ? 'Unnamed drug' : b;
  if (b.isEmpty || b.toLowerCase() == g.toLowerCase()) return g;
  return '$g · $b';
}

Widget? _subtitleForDrugPicker(Drug d) {
  final parts = <String>[];
  final form = d.dosageForm?.trim();
  final str = d.strength?.trim();
  if (form != null && form.isNotEmpty) parts.add(form);
  if (str != null && str.isNotEmpty) parts.add(str);
  if (parts.isEmpty) return null;
  return Text(parts.join(' · '));
}

@RoutePage()
class SupplyHistoryScreen extends StatefulWidget {
  const SupplyHistoryScreen({super.key});

  @override
  State<SupplyHistoryScreen> createState() => _SupplyHistoryScreenState();
}

class _SupplyHistoryScreenState extends State<SupplyHistoryScreen> {
  final PharmacyApiService _api = PharmacyApiService();

  // Data + pagination
  List<_SupplyHistoryRow> _rows = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentPage = 1;
  int _pageSize = 25;
  int _totalItems = 0;
  int _fetchGen = 0;

  // Receive date is the only sort. Newest receipts first until the column is toggled.
  static const int _receiveDateColumn = 2;
  int? _sortColumnIndex = _receiveDateColumn;
  bool _isAscending = false;
  String _sortBy = 'createdAt';

  // Filters
  late DateTime _fromDate;
  late DateTime _toDate;
  String? _selectedSupplierId;
  String _selectedCategory = 'All';
  Drug? _selectedDrug;

  // Supplier dropdown options
  List<Supplier> _suppliers = [];
  bool _isLoadingSuppliers = false;

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _toDate = DateTime(today.year, today.month, today.day, 23, 59, 59, 999);
    _fromDate = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 29));
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
      final List<Supplier> all = [];
      const pageSize = 100;
      int page = 1;
      while (true) {
        final resp = await _api.getSuppliers(
          PharmacyQueryParams(
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

    // Supplier filter (backend: supplierId)
    if (_selectedSupplierId != null && _selectedSupplierId!.trim().isNotEmpty) {
      filters['supplierId'] = _selectedSupplierId!.trim();
    }

    // Category: backend may not support therapeuticClass on batch search; send anyway for future use
    if (_selectedCategory != 'All' && _selectedCategory.trim().isNotEmpty) {
      filters['therapeuticClass'] = _selectedCategory.trim();
    }

    final drugId = _selectedDrug?.id?.trim();
    if (drugId != null && drugId.isNotEmpty) {
      filters['drugId'] = drugId;
    }

    filters['fromDate'] = AppTimezone.toBackendIso(_fromDate);
    filters['toDate'] = AppTimezone.toBackendIso(_toDate);

    return filters;
  }

  Future<void> _fetchHistory() async {
    final gen = ++_fetchGen;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _api.getDrugBatches(
        PharmacyQueryParams(
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
        final category = batch.drug?.therapeuticClass ?? batch.drug?.brandName;

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

      if (!mounted || gen != _fetchGen) return;
      setState(() {
        _rows = rows;
        _totalItems = response.total;
      });
    } on AppException catch (e) {
      if (!mounted || gen != _fetchGen) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted || gen != _fetchGen) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted && gen == _fetchGen) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onReceiveDateSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
      _sortBy = 'createdAt';
      _currentPage = 1;
    });
    _fetchHistory();
  }

  void _onDateRangeChanged(DateTime? from, DateTime? to) {
    if (from == null || to == null) return;
    setState(() {
      _fromDate = from;
      _toDate = to;
      _currentPage = 1;
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
    return DateFormatter.shortDate(date);
  }

  String _formatQuantity(_SupplyHistoryRow row) {
    final unit = row.batch.drug?.displayUnit ?? 'units';
    return '${row.quantity} $unit';
  }

  String _formatTotalCost(_SupplyHistoryRow row) {
    return row.totalCost.toFinancial(isMoney: true);
  }

  String _drugNameForRow(_SupplyHistoryRow row) {
    final d = row.batch.drug;
    if (d != null) return _drugDisplayLabel(d);
    if (row.batch.drugId.isNotEmpty) return row.batch.drugId;
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
    if (result.drug != null) {
      setState(() {
        _selectedDrug = result.drug;
        _currentPage = 1;
      });
      _fetchHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ready = !_isLoading || _rows.isNotEmpty;
    final pageUnits = _rows.fold<int>(0, (sum, r) => sum + r.quantity);
    final pageValue = _rows.fold<num>(0, (sum, r) => sum + r.totalCost);
    final scopeSubtitle = _selectedDrug != null
        ? 'Inbound batches for ${_drugDisplayLabel(_selectedDrug!)}'
        : 'Track receipts, costs, and batch status across suppliers';

    return Scaffold(
      backgroundColor: cs.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final width = bp.maxWidth > 0
              ? bp.maxWidth
              : MediaQuery.sizeOf(context).width;
          final compact = width < PharmacyAccent.cardBreakpoint;
          final showRail = width >= PharmacyAccent.railBreakpoint;

          final main = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PharmacyPageHeader(
                title: 'Supply History',
                subtitle: scopeSubtitle,
                icon: Icons.inventory_2_outlined,
                iconColor: DepartmentColors.pharmacy,
                onRefresh: _isLoading ? null : _fetchHistory,
              ),
              const SizedBox(height: 10),
              PharmacyKpiStrip(
                items: [
                  PharmacyKpiItem(
                    label: 'Batches',
                    value: ready ? '$_totalItems' : '—',
                    caption: 'Matching receipts',
                    icon: Icons.assignment_turned_in_outlined,
                    accent: PharmacyAccent.blue,
                  ),
                  PharmacyKpiItem(
                    label: 'On this page',
                    value: ready ? '${_rows.length}' : '—',
                    caption: 'Loaded rows',
                    icon: Icons.list_alt_outlined,
                    accent: PharmacyAccent.teal,
                  ),
                  PharmacyKpiItem(
                    label: 'Units',
                    value: ready ? '$pageUnits' : '—',
                    caption: 'On this page',
                    icon: Icons.move_to_inbox_outlined,
                    accent: PharmacyAccent.amber,
                  ),
                  PharmacyKpiItem(
                    label: 'Page value',
                    value: ready ? pageValue.toFinancial(isMoney: true) : '—',
                    caption: 'Received cost',
                    icon: Icons.payments_outlined,
                    accent: PharmacyAccent.green,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildFilterToolbar(compact),
              const SizedBox(height: 10),
              Expanded(
                child: HeltySurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _isLoading && _rows.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : _errorMessage.isNotEmpty && _rows.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _errorMessage,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: cs.error),
                                      ),
                                      const SizedBox(height: 8),
                                      FilledButton(
                                        onPressed: _fetchHistory,
                                        child: const Text('Retry'),
                                      ),
                                    ],
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
            ],
          );

          final rail = _SupplyRail(
            dateLabel:
                '${DateFormatter.shortDate(_fromDate)} – ${DateFormatter.shortDate(_toDate)}',
            onRefresh: _isLoading ? null : _fetchHistory,
            onClearDrug: _selectedDrug == null
                ? null
                : () {
                    setState(() {
                      _selectedDrug = null;
                      _currentPage = 1;
                    });
                    _fetchHistory();
                  },
          );

          if (showRail) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 9, child: main),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: rail),
              ],
            );
          }
          return Column(
            children: [
              Expanded(child: main),
              const SizedBox(height: 10),
              rail,
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterToolbar(bool compact) {
    final cs = Theme.of(context).colorScheme;
    final drug = OutlinedButton.icon(
      onPressed: _showDrugPicker,
      icon: const Icon(Icons.medication_outlined, size: 18),
      label: HeltyEllipsisText(
        text: _selectedDrug != null
            ? _drugDisplayLabel(_selectedDrug!)
            : 'All drugs',
      ),
    );
    final supplier = DropdownButtonFormField<String?>(
      key: ValueKey('supplier-${_selectedSupplierId ?? 'all'}'),
      initialValue: _selectedSupplierId,
      isExpanded: true,
      style: TextStyle(fontSize: 12, color: cs.onSurface),
      decoration: pharmacyFieldDecoration(
        context,
        label: 'Supplier',
        icon: Icons.local_shipping_outlined,
        iconColor: PharmacyAccent.pink,
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All suppliers'),
        ),
        ..._suppliers.map(
          (s) => DropdownMenuItem<String?>(
            value: s.id,
            child: Text(s.name, overflow: TextOverflow.ellipsis),
          ),
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
    );

    return Row(
      children: [
        Expanded(flex: 3, child: drug),
        if (!compact) ...[
          const SizedBox(width: 8),
          Expanded(flex: 2, child: supplier),
        ],
        const SizedBox(width: 8),
        PharmacyFilterButton(onPressed: () => _openSupplyFilters(compact)),
      ],
    );
  }

  Future<void> _openSupplyFilters(bool compact) {
    return showPharmacyFilterDialog(
      context: context,
      body: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (compact) ...[
            _buildSupplierFilterDropdown(),
            const SizedBox(height: 8),
          ],
          Text(
            'Date range',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          FromToDateFilter(
            doRefresh: () {},
            dateFilter: true,
            labelStyle: DateFilterLabelStyle.shortUs,
            initialFrom: _fromDate,
            initialTo: _toDate,
            notifyOnInit: false,
            onFilterChanged: (query, category, from, to) {
              _onDateRangeChanged(from, to);
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Category',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          _buildCategoryFilterDropdown(),
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
              'Supplier: All',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF495057),
              ),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Supplier: All'),
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
                    child: Text('Drug Category: $c'),
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
    final cs = theme.colorScheme;
    if (_rows.isEmpty) {
      final msg = _selectedDrug != null
          ? 'No batches found for this drug in the selected period.\nTry widening the date range or clearing other filters.'
          : 'No supply history matches these filters.\nPick a drug to see only its inbound batches, or adjust date and supplier.';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ResponsiveDataTable(
      minWidth: 1640,
      horizontalScrollController: _horizontalScrollController,
      child: Scrollbar(
        controller: _verticalScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _verticalScrollController,
          scrollDirection: Axis.vertical,
          child: DataTable(
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _isAscending,
            headingRowColor: WidgetStatePropertyAll(
              Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            ),
            dataRowMinHeight: 56,
            dataRowMaxHeight: 88,
            horizontalMargin: 16,
            columnSpacing: 24,
            dividerThickness: 1,
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF6C757D),
              letterSpacing: 1.2,
            ),
            columns: [
              const DataColumn(
                label: SizedBox(width: 110, child: Text('BATCH\nID')),
              ),
              const DataColumn(
                label: SizedBox(width: 220, child: Text('DRUG')),
              ),
              DataColumn(
                label: const SizedBox(width: 110, child: Text('RECEIVE\nDATE')),
                onSort: _onReceiveDateSort,
              ),
              const DataColumn(
                label: SizedBox(width: 160, child: Text('SUPPLIER')),
              ),
              const DataColumn(
                label: SizedBox(width: 140, child: Text('DRUG\nCATEGORY')),
              ),
              const DataColumn(
                label: SizedBox(width: 180, child: Text('QUANTITY')),
                numeric: true,
              ),
              const DataColumn(
                label: SizedBox(width: 120, child: Text('TOTAL\nCOST')),
                numeric: true,
              ),
              const DataColumn(
                label: SizedBox(width: 110, child: Text('STATUS')),
              ),
            ],
            rows: _rows.map((row) {
              final batch = row.batch;
              final supplierText = row.supplierName ?? '—';
              final categoryText =
                  row.category ?? batch.drug?.therapeuticClass ?? '—';

              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      batch.batchNumber ?? (batch.id ?? '—'),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        _drugNameForRow(row),
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
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 160,
                      child: Text(
                        supplierText,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(_buildCategoryChip(categoryText)),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(
                        _formatQuantity(row),
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      _formatTotalCost(row),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
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
    final cs = Theme.of(context).colorScheme;
    Color bgColor;
    Color textColor;

    if (status.toLowerCase() == 'verified') {
      bgColor = const Color(0xFFE3FCEF);
      textColor = const Color(0xFF00A36C);
    } else if (status.toLowerCase() == 'quarantine') {
      bgColor = const Color(0xFFFFF3CD);
      textColor = const Color(0xFFD39E00);
    } else {
      bgColor = cs.surfaceContainer;
      textColor = cs.onSurfaceVariant;
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
    final cs = theme.colorScheme;
    final totalPages = _pageSize > 0
        ? (_totalItems / _pageSize).ceil().clamp(1, 1 << 30)
        : 1;
    final start = _totalItems == 0 ? 0 : (_currentPage - 1) * _pageSize + 1;
    final end = _totalItems == 0
        ? 0
        : (_currentPage * _pageSize).clamp(0, _totalItems);
    final canGoBack = !_isLoading && _currentPage > 1;
    final canGoForward = !_isLoading && _currentPage < totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 4,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Showing $start–$end of $_totalItems',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(width: 16),
              Text(
                'Per page:',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
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
                onChanged: _isLoading
                    ? null
                    : (v) {
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
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              Text(
                'Page $_currentPage of $totalPages',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: canGoBack
                    ? () => _onPageChanged(_currentPage - 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next page',
                onPressed: canGoForward
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

class _SupplyRail extends StatelessWidget {
  const _SupplyRail({
    required this.dateLabel,
    required this.onRefresh,
    required this.onClearDrug,
  });

  final String dateLabel;
  final VoidCallback? onRefresh;
  final VoidCallback? onClearDrug;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeltySurfaceCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const HeltySolidIcon(
                    icon: Icons.flash_on,
                    color: PharmacyAccent.amber,
                    size: 26,
                    iconSize: 14,
                    radius: 7,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              PharmacyRailButton(
                label: 'Refresh',
                icon: Icons.refresh,
                colors: [
                  PharmacyAccent.green,
                  Color.lerp(PharmacyAccent.green, cs.primary, 0.25)!,
                ],
                onPressed: onRefresh,
              ),
              const SizedBox(height: 8),
              PharmacyRailButton(
                label: 'Clear drug',
                icon: Icons.medication_outlined,
                colors: [
                  PharmacyAccent.teal,
                  Color.lerp(PharmacyAccent.teal, cs.primary, 0.25)!,
                ],
                onPressed: onClearDrug,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        HeltySurfaceCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date range',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SupplyHistoryDrugSheet extends StatefulWidget {
  const _SupplyHistoryDrugSheet({required this.api});

  final PharmacyApiService api;

  @override
  State<_SupplyHistoryDrugSheet> createState() =>
      _SupplyHistoryDrugSheetState();
}

class _SupplyHistoryDrugSheetState extends State<_SupplyHistoryDrugSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<Drug> _items = [];
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
      final resp = await widget.api.getDrugs(
        PharmacyQueryParams(
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
                        'Choose a drug',
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
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
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
