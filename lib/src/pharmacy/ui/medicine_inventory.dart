import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_exception.dart';
import '../models/pharmacy_model.dart';
import '../services/pharmacy_service.dart';
import 'add_drug_screen.dart';
import 'medicine_filters_panel.dart';

/// Search field type for the search bar dropdown.
enum SearchFieldType { genericName, brandName }

/// Filter pill type for status/category filtering.
enum FilterPillType { all, lowStock, expiringSoon, antibiotics, painkillers }

@RoutePage()
class MedicineInventoryScreen extends StatefulWidget {
  const MedicineInventoryScreen({super.key});

  @override
  State<MedicineInventoryScreen> createState() =>
      _MedicineInventoryScreenState();
}

class _MedicineInventoryScreenState extends State<MedicineInventoryScreen> {
  final PharmacyApiService _drugService = PharmacyApiService();

  List<Drug> _drugs = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Pagination & Sorting State
  int _currentPage = 1;
  int _pageSize = 25;
  int _totalItems = 0;
  int? _sortColumnIndex;
  bool _isAscending = true;
  String? _sortBy;

  Drug? _selectedDrug;
  bool _isFiltersOpen = false;
  final TextEditingController _searchController = TextEditingController();
  SearchFieldType _searchFieldType = SearchFieldType.brandName;
  FilterPillType _filterPill = FilterPillType.all;

  // Additional filters
  String? _manufacturerId;
  String? _supplierId;
  bool? _isControlledFilter; // null = all, true = yes, false = no
  DateTime? _manufacturingDateFrom;
  DateTime? _manufacturingDateTo;
  DateTime? _expiryDateFrom;
  DateTime? _expiryDateTo;

  List<Manufacturer> _manufacturers = [];
  List<Supplier> _suppliers = [];
  bool _filtersLoaded = false;
  final Map<String, List<DrugLocationQuantity>> _drugLocationQuantities = {};
  final Set<String> _loadingDrugLocationIds = {};
  final Map<String, String> _drugLocationErrors = {};

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadFilterOptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFilterOptions() async {
    if (_filtersLoaded) return;
    try {
      final manu = await _drugService.getManufacturers(
        const PharmacyQueryParams(pageSize: 500),
      );
      final supp = await _drugService.getSuppliers(
        const PharmacyQueryParams(pageSize: 500),
      );
      if (mounted) {
        setState(() {
          _manufacturers = manu.items;
          _suppliers = supp.items;
          _filtersLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _filtersLoaded = true);
    }
  }

  SearchDrugParams _buildSearchParams() {
    final query = _searchController.text.trim();
    String? therapeuticClass;
    bool? lowStock;
    bool? expiringSoon;
    switch (_filterPill) {
      case FilterPillType.lowStock:
        lowStock = true;
        break;
      case FilterPillType.expiringSoon:
        expiringSoon = true;
        break;
      case FilterPillType.antibiotics:
        therapeuticClass = 'Antibiotic';
        break;
      case FilterPillType.painkillers:
        therapeuticClass = 'Analgesic';
        break;
      case FilterPillType.all:
        break;
    }
    return SearchDrugParams(
      search: query.isEmpty ? null : query,
      genericName:
          _searchFieldType == SearchFieldType.genericName && query.isNotEmpty
          ? query
          : null,
      brandName:
          _searchFieldType == SearchFieldType.brandName && query.isNotEmpty
          ? query
          : null,
      manufacturerId: _manufacturerId,
      supplierId: _supplierId,
      isControlled: _isControlledFilter,
      manufacturingDateFrom: _manufacturingDateFrom,
      manufacturingDateTo: _manufacturingDateTo,
      expiryDateFrom: _expiryDateFrom,
      expiryDateTo: _expiryDateTo,
      therapeuticClass: therapeuticClass,
      lowStock: lowStock,
      expiringSoon: expiringSoon,
      limit: _pageSize,
      page: _currentPage,
      pageSize: _pageSize,
      sortBy: _sortBy,
      sortOrder: _isAscending ? 'asc' : 'desc',
    );
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _drugService.searchDrugs(_buildSearchParams());

      setState(() {
        _drugs = response.items;
        _totalItems = response.total;
        if (_drugs.isNotEmpty && _selectedDrug == null) {
          _selectedDrug = _drugs.first;
        }
      });
      if (_selectedDrug?.id != null) {
        await _fetchDrugLocationQuantities(_selectedDrug!.id!);
      }
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSort(int columnIndex, bool ascending, String sortKey) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
      _sortBy = sortKey;
    });
    _fetchData();
  }

  void _onPageChanged(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
    _fetchData();
  }

  Future<void> _fetchDrugLocationQuantities(String drugId) async {
    if (drugId.trim().isEmpty) return;
    if (_loadingDrugLocationIds.contains(drugId)) return;

    setState(() {
      _loadingDrugLocationIds.add(drugId);
      _drugLocationErrors.remove(drugId);
    });

    try {
      final locations = await _drugService.getDrugLocationQuantities(drugId);
      if (!mounted) return;
      setState(() {
        _drugLocationQuantities[drugId] = locations;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _drugLocationErrors[drugId] = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _drugLocationErrors[drugId] = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingDrugLocationIds.remove(drugId);
        });
      }
    }
  }

  void _selectDrug(Drug drug) {
    setState(() {
      _selectedDrug = drug;
      if (_isFiltersOpen) _isFiltersOpen = false;
    });
    final id = drug.id;
    if (id != null && id.isNotEmpty) {
      _fetchDrugLocationQuantities(id);
    }
  }

  bool _hasSellableStock(Drug drug) => (drug.stock ?? 0) > 0;

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  Future<void> _hideDrug(Drug drug) async {
    final id = drug.id;
    if (id == null || id.isEmpty) return;

    if (_hasSellableStock(drug)) {
      _showSnack(
        'Deplete or transfer stock before hiding this drug.',
        isError: true,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hide drug from catalog?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hide ${drug.brandName} (${drug.genericName}) from the pharmacy catalog?',
            ),
            const SizedBox(height: 12),
            const Text(
              '• The drug will no longer appear in searches or new orders.',
            ),
            const Text('• Past prescriptions and invoices are not affected.'),
            const Text(
              '• You cannot hide a drug while sellable stock remains.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hide drug'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await _drugService.deleteDrug(id);
      if (!mounted) return;
      _showSnack('Drug hidden from catalog.');
      setState(() {
        _drugs.removeWhere((d) => d.id == id);
        if (_totalItems > 0) _totalItems--;
        if (_selectedDrug?.id == id) {
          _selectedDrug = _drugs.isNotEmpty ? _drugs.first : null;
        }
        _drugLocationQuantities.remove(id);
        _drugLocationErrors.remove(id);
        _loadingDrugLocationIds.remove(id);
      });
      final selectedId = _selectedDrug?.id;
      if (selectedId != null && selectedId.isNotEmpty) {
        _fetchDrugLocationQuantities(selectedId);
      }
    } on AppException catch (e) {
      if (mounted) _showSnack(e.message, isError: true);
    } catch (e) {
      if (mounted) _showSnack(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Main Section
              Expanded(
                flex: 7,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: 24),

                      // Main Table Area with Horizontal and Vertical Scrolling
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : _errorMessage.isNotEmpty
                                    ? Center(
                                        child: Text(
                                          _errorMessage,
                                          style: TextStyle(
                                            color: theme.colorScheme.error,
                                          ),
                                        ),
                                      )
                                    : _buildTable(theme),
                              ),
                              _buildPagination(theme),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right Side Panel (Details)
              Container(
                width: 380,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(
                    left: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: _selectedDrug == null
                    ? const Center(
                        child: Text("Select a medicine to view details"),
                      )
                    : _buildDetailsPanel(theme, _selectedDrug!),
              ),
            ],
          ),

          if (_isFiltersOpen)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: Material(
                elevation: 8,
                child: Container(
                  width: 360,
                  color: theme.scaffoldBackgroundColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Filters',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: 'Close filters',
                              onPressed: () =>
                                  setState(() => _isFiltersOpen = false),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: MedicineFiltersPanel(
                          theme: theme,
                          searchController: _searchController,
                          searchFieldType: _searchFieldType,
                          onSearchFieldTypeChanged: (v) {
                            setState(() => _searchFieldType = v);
                          },
                          onPerformSearch: () {
                            setState(() => _currentPage = 1);
                            _fetchData();
                          },
                          filterPill: _filterPill,
                          onFilterPillChanged: (pill) {
                            setState(() {
                              _filterPill = pill;
                              _currentPage = 1;
                            });
                            _fetchData();
                          },
                          manufacturers: _manufacturers,
                          suppliers: _suppliers,
                          selectedManufacturerId: _manufacturerId,
                          onManufacturerChanged: (v) {
                            setState(() {
                              _manufacturerId = v;
                              _currentPage = 1;
                            });
                            _fetchData();
                          },
                          selectedSupplierId: _supplierId,
                          onSupplierChanged: (v) {
                            setState(() {
                              _supplierId = v;
                              _currentPage = 1;
                            });
                            _fetchData();
                          },
                          isControlledFilter: _isControlledFilter,
                          onControlledFilterChanged: (v) {
                            setState(() {
                              _isControlledFilter = v;
                              _currentPage = 1;
                            });
                            _fetchData();
                          },
                          manufacturingDateFrom: _manufacturingDateFrom,
                          manufacturingDateTo: _manufacturingDateTo,
                          onManufacturingDateFromChanged: (d) {
                            setState(() {
                              _manufacturingDateFrom = d;
                              _currentPage = 1;
                            });
                            _fetchData();
                          },
                          onManufacturingDateToChanged: (d) {
                            setState(() {
                              _manufacturingDateTo = d;
                              _currentPage = 1;
                            });
                            _fetchData();
                          },
                          expiryDateFrom: _expiryDateFrom,
                          expiryDateTo: _expiryDateTo,
                          onExpiryDateFromChanged: (d) {
                            setState(() {
                              _expiryDateFrom = d;
                              _currentPage = 1;
                            });
                            _fetchData();
                          },
                          onExpiryDateToChanged: (d) {
                            setState(() {
                              _expiryDateTo = d;
                              _currentPage = 1;
                            });
                            _fetchData();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medicine Inventory',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage stock, track expiries, and update details',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _isFiltersOpen = true);
              },
              icon: const Icon(Icons.filter_list, size: 18),
              label: const Text('Filters'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                side: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showAddMedicineModal(context, theme),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Medicine'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTable(ThemeData theme) {
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
              headingRowColor: WidgetStateProperty.all(
                theme.colorScheme.surface,
              ),
              dataRowMinHeight: 70,
              dataRowMaxHeight: 70,
              showCheckboxColumn:
                  false, // Hide default checkboxes to match design
              columns: [
                DataColumn(
                  label: const Text(
                    'MEDICINE NAME',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  onSort: (idx, asc) => _onSort(idx, asc, 'brandName'),
                ),
                DataColumn(
                  label: const Text(
                    'COMPOSITION',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  onSort: (idx, asc) => _onSort(idx, asc, 'genericName'),
                ),
                DataColumn(
                  label: const Text(
                    'STOCK',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  onSort: (idx, asc) => _onSort(idx, asc, 'stock'),
                ),
                DataColumn(
                  label: const Text(
                    'EXPIRY',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  onSort: (idx, asc) => _onSort(idx, asc, 'expiryDate'),
                ),
                const DataColumn(
                  label: Text(
                    'STATUS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'ACTIONS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
              rows: _drugs.map((drug) {
                final isSelected = _selectedDrug?.id == drug.id;
                return DataRow(
                  selected: isSelected,
                  onSelectChanged: (selected) {
                    if (selected != null && selected) {
                      _selectDrug(drug);
                    }
                  },
                  color: WidgetStateProperty.resolveWith<Color?>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return theme.colorScheme.primary.withValues(alpha: 0.05);
                    }
                    return null; // Use default
                  }),
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          if (isSelected)
                            Container(
                              width: 4,
                              height: 40,
                              color: theme.colorScheme.primary,
                              margin: const EdgeInsets.only(right: 8),
                            ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.medication,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                drug.brandName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'ID: ${drug.id ?? '—'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        drug.genericName,
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                    ),
                    DataCell(
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium,
                          children: [
                            TextSpan(
                              text: '${drug.displayStock} ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: drug.displayUnit,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (drug.displayStatus == 'Expiring Soon')
                            const Padding(
                              padding: EdgeInsets.only(right: 4.0),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 16,
                              ),
                            ),
                          Text(
                            drug.expiryDate != null
                                ? DateFormat(
                                    'MMM yyyy',
                                  ).format(drug.expiryDate!)
                                : '—',
                            style: TextStyle(
                              color: drug.displayStatus == 'Expiring Soon'
                                  ? Colors.orange[800]
                                  : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(_buildStatusChip(drug.displayStatus)),
                    DataCell(
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        tooltip: 'Actions',
                        onSelected: (value) {
                          if (value == 'hide') _hideDrug(drug);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'hide',
                            enabled: !_hasSellableStock(drug),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.visibility_off_outlined,
                                  size: 18,
                                  color: _hasSellableStock(drug)
                                      ? Colors.grey
                                      : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Hide from catalog',
                                  style: TextStyle(
                                    color: _hasSellableStock(drug)
                                        ? Colors.grey
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    Color bgColor;

    switch (status) {
      case 'In Stock':
        color = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.1);
        break;
      case 'Low Stock':
        color = Colors.orange;
        bgColor = Colors.orange.withValues(alpha: 0.1);
        break;
      case 'Expiring Soon':
        color = Colors.orange[800]!;
        bgColor = Colors.orange.withValues(alpha: 0.1);
        break;
      case 'Out of Stock':
        color = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.1);
        break;
      default:
        color = Colors.grey;
        bgColor = Colors.grey.withValues(alpha: 0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPagination(ThemeData theme) {
    int totalPages = (_totalItems / _pageSize).ceil();
    if (totalPages == 0) totalPages = 1;
    final start = (_currentPage - 1) * _pageSize + 1;
    final end = (_currentPage * _pageSize).clamp(0, _totalItems);

    return Padding(
      padding: const EdgeInsets.all(16.0),
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
                  if (v != null) {
                    setState(() {
                      _pageSize = v;
                      _currentPage = 1;
                    });
                    _fetchData();
                  }
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

  // --- Right Panel Details ---

  Widget _buildDetailsPanel(ThemeData theme, Drug drug) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medication,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey),
                    onPressed: () =>
                        _showEditMedicineModal(context, theme, drug),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sell_outlined, color: Colors.grey),
                    tooltip: 'Batch & ward pricing preview',
                    onPressed: drug.id == null || drug.id!.trim().isEmpty
                        ? null
                        : () => context.router.push(
                            BatchesPreviewWardPricingRoute(id: drug.id!),
                          ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.visibility_off_outlined,
                      color: _hasSellableStock(drug) ||
                              drug.id == null ||
                              drug.id!.trim().isEmpty
                          ? Colors.grey.withValues(alpha: 0.4)
                          : Colors.red,
                    ),
                    tooltip: 'Hide drug from catalog',
                    onPressed: _hasSellableStock(drug) ||
                            drug.id == null ||
                            drug.id!.trim().isEmpty
                        ? null
                        : () => _hideDrug(drug),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            drug.brandName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${drug.therapeuticClass ?? '—'} • ID: ${drug.id ?? '—'}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatusChip(drug.displayStatus),
              const SizedBox(width: 8),
              if (drug.displayStatus == 'Expiring Soon' &&
                  drug.expiryDate != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Expires in ${drug.expiryDate!.difference(DateTime.now()).inDays} days',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_hasSellableStock(drug)) ...[
            const SizedBox(height: 12),
            Text(
              'Deplete or transfer stock before hiding.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Total Stock',
                  '${drug.displayStock}',
                  drug.displayUnit,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildPricesCard(theme, drug.prices)),
            ],
          ),
          const SizedBox(height: 16),

          // Composition Card
          _buildInfoCard(theme, 'Drug Composition', Icons.science_outlined, [
            _buildInfoRow('Generic Name', drug.genericName, isFullWidth: true),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow('Strength', drug.strength ?? '—'),
                ),
                Expanded(
                  child: _buildInfoRow('Dosage Form', drug.dosageForm ?? '—'),
                ),
              ],
            ),
            _buildInfoRow(
              'Manufacturer',
              drug.manufacturerName ?? drug.manufacturerId ?? '—',
              isFullWidth: true,
            ),
          ]),
          const SizedBox(height: 16),

          // Locations Card
          _buildInfoCard(theme, 'Stock Locations', Icons.storefront_outlined, [
            ..._buildStockLocationChildren(theme, drug),
          ]),
          const SizedBox(height: 24),
          // Order button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showOrderModal(context, theme, drug),
              icon: const Icon(Icons.shopping_cart_outlined, size: 20),
              label: Text('Order ${drug.brandName}'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String title,
    String value,
    String suffix,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              children: [
                TextSpan(text: value),
                TextSpan(
                  text: ' $suffix',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricesCard(ThemeData theme, List<DrugPrice>? prices) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selling Prices',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (prices == null || prices.isEmpty)
            Text(
              '—',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: prices.map((price) {
                final wardName = price.wardName ?? 'Unknown Ward';
                final priceText = price.price.toFinancial(isMoney: true);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '$wardName: $priceText/unit',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    ThemeData theme,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isFullWidth = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isFullWidth ? 12.0 : 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLocationRow(String location, int quantity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(location, style: TextStyle(color: Colors.grey[800])),
            ],
          ),
          Text(
            quantity.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStockLocationChildren(ThemeData theme, Drug drug) {
    final id = drug.id;
    if (id == null || id.isEmpty) {
      return [
        Text(
          'No stock locations available.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ];
    }

    if (_loadingDrugLocationIds.contains(id)) {
      return const [
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ];
    }

    final error = _drugLocationErrors[id];
    if (error != null && error.isNotEmpty) {
      return [
        Text(
          error,
          style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
        ),
      ];
    }

    final locations =
        _drugLocationQuantities[id] ?? const <DrugLocationQuantity>[];
    if (locations.isEmpty) {
      return [
        Text(
          'No stock locations available.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ];
    }

    final rows = <Widget>[];
    for (var i = 0; i < locations.length; i++) {
      final loc = locations[i];
      rows.add(_buildLocationRow(loc.locationName, loc.quantity));
      if (i < locations.length - 1) {
        rows.add(const Divider());
      }
    }
    return rows;
  }

  void _showAddMedicineModal(BuildContext context, ThemeData theme) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _AddMedicineDialog(
        theme: theme,
        drugService: _drugService,
        manufacturers: _manufacturers,
        onSaved: () {
          _fetchData();
          _loadFilterOptions();
        },
      ),
    );
  }

  void _showEditMedicineModal(
    BuildContext context,
    ThemeData theme,
    Drug drug,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _AddMedicineDialog(
        theme: theme,
        drugService: _drugService,
        manufacturers: _manufacturers,
        existingDrug: drug,
        onSaved: () {
          _fetchData();
          _loadFilterOptions();
          if (_selectedDrug?.id == drug.id) {
            setState(() {
              _selectedDrug = _drugs.cast<Drug?>().firstWhere(
                (d) => d?.id == drug.id,
                orElse: () => _drugs.isNotEmpty ? _drugs.first : null,
              );
            });
          }
        },
      ),
    );
  }

  void _showOrderModal(BuildContext context, ThemeData theme, Drug drug) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _OrderMedicineDialog(
        theme: theme,
        drug: drug,
        drugService: _drugService,
        suppliers: _suppliers,
      ),
    );
  }
}

// ─── Add/Edit Medicine dialog (reusable) ───────────────────────────────────

class _AddMedicineDialog extends StatefulWidget {
  const _AddMedicineDialog({
    required this.theme,
    required this.drugService,
    required this.manufacturers,
    this.existingDrug,
    required this.onSaved,
  });

  final ThemeData theme;
  final PharmacyApiService drugService;
  final List<Manufacturer> manufacturers;
  final Drug? existingDrug;
  final VoidCallback onSaved;

  @override
  State<_AddMedicineDialog> createState() => _AddMedicineDialogState();
}

class _AddMedicineDialogState extends State<_AddMedicineDialog> {
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingDrug != null;
    return Dialog(
      insetPadding: const EdgeInsets.all(24.0),
      child: SizedBox(
        width: 800,
        height: 600,
        child: AddDrugScreen(
          existingDrug: widget.existingDrug,
          service: widget.drugService,
          onSaved: widget.onSaved,
          key: ValueKey(isEdit ? 'edit-drug-dialog' : 'add-drug-dialog'),
        ),
      ),
    );
  }
}

// ─── Order medicine dialog ─────────────────────────────────────────────────

class _OrderMedicineDialog extends StatefulWidget {
  const _OrderMedicineDialog({
    required this.theme,
    required this.drug,
    required this.drugService,
    required this.suppliers,
  });

  final ThemeData theme;
  final Drug drug;
  final PharmacyApiService drugService;
  final List<Supplier> suppliers;

  @override
  State<_OrderMedicineDialog> createState() => _OrderMedicineDialogState();
}

class _OrderMedicineDialogState extends State<_OrderMedicineDialog> {
  String? _supplierId;
  final _quantityCtrl = TextEditingController(text: '1');
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _createOrder() async {
    if (_supplierId == null || _supplierId!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a supplier')));
      return;
    }
    final qty = int.tryParse(_quantityCtrl.text);
    if (qty == null || qty < 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid quantity')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Create a draft purchase order; backend may expect createdById from auth.
      await widget.drugService.createPurchaseOrder(
        PurchaseOrder(
          supplierId: _supplierId!,
          totalAmount: 0,
          createdById: 'current-user', // TODO: from auth
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order created successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Order ${widget.drug.brandName}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create a purchase order for ${widget.drug.genericName} (${widget.drug.brandName}).',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            if (widget.suppliers.isEmpty)
              const Text('No suppliers available.')
            else ...[
              const Text(
                'Supplier',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _supplierId,
                decoration: InputDecoration(
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('— Select supplier —'),
                  ),
                  ...widget.suppliers.map(
                    (s) => DropdownMenuItem<String?>(
                      value: s.id,
                      child: Text(s.name),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _supplierId = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _quantityCtrl,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _createOrder,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create order'),
        ),
      ],
    );
  }
}
