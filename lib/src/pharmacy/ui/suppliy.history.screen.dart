import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

enum _DateFilterOption { last7Days, last30Days, last90Days, allTime }

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

  // Sorting
  int? _sortColumnIndex;
  bool _isAscending = false;
  String? _sortBy;

  // Filters
  _DateFilterOption _dateFilter = _DateFilterOption.last30Days;
  String? _selectedSupplierId;
  String _selectedCategory = 'All';

  // Supplier dropdown options
  List<Supplier> _suppliers = [];
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
      final page = await _api.getSuppliers(
        const PharmacyQueryParams(
          pageSize: 500,
          sortBy: 'name',
          sortOrder: SortOrder.asc,
        ),
      );
      if (!mounted) return;
      setState(() {
        _suppliers = page.items;
      });
    } catch (_) {
      // ignore, dropdown will just show "All"
    } finally {
      if (mounted) {
        setState(() => _isLoadingSuppliers = false);
      }
    }
  }

  Map<String, dynamic> _buildFilters() {
    final filters = <String, dynamic>{};

    if (_selectedSupplierId != null && _selectedSupplierId!.isNotEmpty) {
      filters['supplierId'] = _selectedSupplierId;
    }

    if (_selectedCategory != 'All') {
      // Backend already uses `therapeuticClass` filter for medicines.
      filters['therapeuticClass'] = _selectedCategory;
    }

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
      filters['createdAtFrom'] = from.toIso8601String();
    }

    return filters;
  }

  Future<void> _fetchHistory() async {
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
        final unitCost = batch.unitCost ?? 0;
        final totalCost = quantity * unitCost;

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
    final unit = row.batch.drug?.displayUnit ?? 'units';
    return '${row.quantity} $unit';
  }

  String _formatTotalCost(_SupplyHistoryRow row) {
    return row.totalCost.toFinancial(isMoney: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Supply History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Inventory Value',
                    value: _rows.isEmpty
                        ? '₦0.00'
                        : _rows
                              .fold<num>(0, (sum, r) => sum + r.totalCost)
                              .toFinancial(isMoney: true),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildStatCard(
                    title: 'Items Received This Page',
                    value:
                        '${_rows.fold<int>(0, (sum, r) => sum + r.quantity)} units',
                    isUnitTextBold: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Filters Row
            Row(
              children: [
                _buildDateFilterDropdown(),
                const SizedBox(width: 16),
                _buildSupplierFilterDropdown(),
                const SizedBox(width: 16),
                _buildCategoryFilterDropdown(),
              ],
            ),
            const SizedBox(height: 24),

            // Data Table + pagination (only table scrolls)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _errorMessage.isNotEmpty
                          ? Center(
                              child: Text(
                                _errorMessage,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontSize: 14,
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
        ),
      ),
    );
  }

  // --- UI Builders ---

  Widget _buildStatCard({
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6C757D),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: mainValue,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF212529),
                    fontFamily: 'Serif',
                  ),
                ),
                if (suffix != null && suffix.isNotEmpty)
                  TextSpan(
                    text: ' $suffix',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: isUnitTextBold
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: const Color(0xFF212529),
                      fontFamily: 'Serif',
                    ),
                  ),
              ],
            ),
          ),
        ],
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
    if (_rows.isEmpty) {
      return const Center(
        child: Text(
          'No supply history found for the selected filters.',
          style: TextStyle(color: Colors.black54),
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
                DataColumn(
                  label: const Text('RECEIVE\nDATE'),
                  onSort: (idx, asc) => _onSort(idx, asc, 'createdAt'),
                ),
                const DataColumn(label: Text('SUPPLIER')),
                const DataColumn(label: Text('DRUG\nCATEGORY')),
                DataColumn(
                  label: const Text('QUANTITY'),
                  numeric: true,
                  onSort: (idx, asc) => _onSort(idx, asc, 'quantityReceived'),
                ),
                DataColumn(
                  label: const Text('TOTAL\nCOST'),
                  numeric: true,
                  onSort: (idx, asc) => _onSort(idx, asc, 'unitCost'),
                ),
                const DataColumn(label: Text('STATUS')),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
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
