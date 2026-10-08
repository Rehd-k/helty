import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/pharmacy/widgets/pharmacy_page_chrome.dart';
import 'package:helty/src/shared/department_colors.dart';
import 'package:helty/src/widgets/helty_surface.dart';

import '../../core/errors/app_exception.dart';
import '../models/pharmacy_model.dart';
import '../services/pharmacy_service.dart';
import 'add_drug_screen.dart';
import 'medicine_filters_panel.dart';

Color drugStatusColor(String status) {
  switch (status) {
    case 'In Stock':
      return PharmacyAccent.green;
    case 'Low Stock':
    case 'Expiring Soon':
      return PharmacyAccent.amber;
    case 'Out of Stock':
      return const Color(0xFFDC2626);
    default:
      return PharmacyAccent.indigo;
  }
}

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
      if (!mounted) return;
      final showRail =
          MediaQuery.sizeOf(context).width >= PharmacyAccent.railBreakpoint;

      setState(() {
        _drugs = response.items;
        _totalItems = response.total;
        if (showRail && _drugs.isNotEmpty && _selectedDrug == null) {
          _selectedDrug = _drugs.first;
        }
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  void _onDrugPressed(Drug drug, {required bool useSheet}) {
    if (useSheet) {
      _showDrugSheet(drug);
      return;
    }
    setState(() => _selectedDrug = drug);
  }

  Future<void> _showDrugSheet(Drug drug) async {
    setState(() => _selectedDrug = drug);
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        void afterClose(VoidCallback action) {
          Navigator.of(sheetContext).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            action();
          });
        }

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.42,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return _MedicineDrugDetails(
              drug: drug,
              drugService: _drugService,
              scrollController: scrollController,
              onEdit: () => afterClose(
                () => _showEditMedicineModal(context, theme, drug),
              ),
              onHide: () => afterClose(() => _hideDrug(drug)),
              onOrder: () =>
                  afterClose(() => _showOrderModal(context, theme, drug)),
              onPricing: () => afterClose(() {
                final id = drug.id;
                if (id == null || id.trim().isEmpty) return;
                context.router.push(BatchesPreviewWardPricingRoute(id: id));
              }),
            );
          },
        );
      },
    );
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
      });
    } on AppException catch (e) {
      if (mounted) _showSnack(e.message, isError: true);
    } catch (e) {
      if (mounted) _showSnack(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final width = bp.maxWidth > 0
              ? bp.maxWidth
              : MediaQuery.sizeOf(context).width;
          final useCards = width < PharmacyAccent.cardBreakpoint;
          final showRail = width >= PharmacyAccent.railBreakpoint;

          final main = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 10),
              _buildFilterBar(compact: useCards),
              const SizedBox(height: 8),
              _buildQuickFilters(),
              const SizedBox(height: 10),
              Expanded(
                child: _buildInventoryBody(
                  theme,
                  useCards: useCards,
                  useSheet: !showRail,
                ),
              ),
            ],
          );

          if (!showRail) return main;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 7, child: main),
              const SizedBox(width: 12),
              SizedBox(width: 380, child: _buildDetailsRail(theme)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final subtitle = _isLoading
        ? 'Manage stock, track expiries, and update details'
        : '$_totalItems medicines in this view';
    return PharmacyPageHeader(
      title: 'Medicine Inventory',
      subtitle: subtitle,
      icon: Icons.medication_outlined,
      iconColor: DepartmentColors.pharmacy,
      onRefresh: _isLoading ? null : _fetchData,
    );
  }

  Widget _buildFilterBar({required bool compact}) {
    final search = TextField(
      controller: _searchController,
      style: const TextStyle(fontSize: 13),
      textInputAction: TextInputAction.search,
      onSubmitted: (_) {
        setState(() => _currentPage = 1);
        _fetchData();
      },
      decoration: pharmacyFieldDecoration(
        context,
        label: 'Search',
        hint: _searchFieldType == SearchFieldType.brandName
            ? 'Brand name'
            : 'Generic name',
        icon: Icons.search,
        iconColor: PharmacyAccent.indigo,
        suffixIcon: IconButton(
          tooltip: 'Search',
          onPressed: () {
            setState(() => _currentPage = 1);
            _fetchData();
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(Icons.search, size: 18),
        ),
      ),
    );

    final fieldType = PopupMenuButton<SearchFieldType>(
      tooltip: 'Search field',
      initialValue: _searchFieldType,
      onSelected: (value) => setState(() => _searchFieldType = value),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: SearchFieldType.brandName,
          child: Text('Brand name'),
        ),
        PopupMenuItem(
          value: SearchFieldType.genericName,
          child: Text('Generic name'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _searchFieldType == SearchFieldType.brandName
                  ? 'Brand'
                  : 'Generic',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );

    final add = compact
        ? IconButton(
            tooltip: 'Add medicine',
            onPressed: () => _showAddMedicineModal(context, Theme.of(context)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const HeltySolidIcon(
              icon: Icons.add,
              color: PharmacyAccent.teal,
              size: 32,
              iconSize: 18,
              radius: 8,
            ),
          )
        : FilledButton.icon(
            onPressed: () => _showAddMedicineModal(context, Theme.of(context)),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add medicine'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          );

    return Row(
      children: [
        fieldType,
        const SizedBox(width: 4),
        Expanded(child: search),
        const SizedBox(width: 8),
        PharmacyFilterButton(onPressed: _openFilters),
        const SizedBox(width: 4),
        add,
      ],
    );
  }

  Widget _buildQuickFilters() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FilterPillType.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final pill = FilterPillType.values[index];
          final selected = _filterPill == pill;
          return FilterChip(
            label: Text(_pillLabel(pill)),
            selected: selected,
            visualDensity: VisualDensity.compact,
            onSelected: (_) {
              setState(() {
                _filterPill = pill;
                _currentPage = 1;
              });
              _fetchData();
            },
          );
        },
      ),
    );
  }

  String _pillLabel(FilterPillType pill) {
    switch (pill) {
      case FilterPillType.all:
        return 'All';
      case FilterPillType.lowStock:
        return 'Low stock';
      case FilterPillType.expiringSoon:
        return 'Expiring';
      case FilterPillType.antibiotics:
        return 'Antibiotics';
      case FilterPillType.painkillers:
        return 'Painkillers';
    }
  }

  Future<void> _openFilters() {
    return showPharmacyFilterDialog(
      context: context,
      body: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void apply(VoidCallback change) {
              setState(() {
                change();
                _currentPage = 1;
              });
              setDialogState(() {});
              _fetchData();
            }

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.7,
              ),
              child: MedicineFiltersPanel(
                theme: Theme.of(context),
                showSearch: false,
                showQuickFilters: false,
                searchController: _searchController,
                searchFieldType: _searchFieldType,
                onSearchFieldTypeChanged: (v) =>
                    setState(() => _searchFieldType = v),
                onPerformSearch: () {},
                filterPill: _filterPill,
                onFilterPillChanged: (pill) => apply(() => _filterPill = pill),
                manufacturers: _manufacturers,
                suppliers: _suppliers,
                selectedManufacturerId: _manufacturerId,
                onManufacturerChanged: (v) => apply(() => _manufacturerId = v),
                selectedSupplierId: _supplierId,
                onSupplierChanged: (v) => apply(() => _supplierId = v),
                isControlledFilter: _isControlledFilter,
                onControlledFilterChanged: (v) =>
                    apply(() => _isControlledFilter = v),
                manufacturingDateFrom: _manufacturingDateFrom,
                manufacturingDateTo: _manufacturingDateTo,
                onManufacturingDateFromChanged: (d) =>
                    apply(() => _manufacturingDateFrom = d),
                onManufacturingDateToChanged: (d) =>
                    apply(() => _manufacturingDateTo = d),
                expiryDateFrom: _expiryDateFrom,
                expiryDateTo: _expiryDateTo,
                onExpiryDateFromChanged: (d) => apply(() => _expiryDateFrom = d),
                onExpiryDateToChanged: (d) => apply(() => _expiryDateTo = d),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInventoryBody(
    ThemeData theme, {
    required bool useCards,
    required bool useSheet,
  }) {
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage.isNotEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          )
        : _drugs.isEmpty
        ? const Center(child: Text('No medicines found.'))
        : useCards
        ? _buildCards(theme)
        : _buildTable(theme, useSheet: useSheet);

    return HeltySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: body),
          _buildPagination(theme),
        ],
      ),
    );
  }

  Widget _buildDetailsRail(ThemeData theme) {
    final drug = _selectedDrug;
    return HeltySurfaceCard(
      child: drug == null
          ? const Center(child: Text('Select a medicine to view details'))
          : _MedicineDrugDetails(
              key: ValueKey(drug.id),
              drug: drug,
              drugService: _drugService,
              onEdit: () => _showEditMedicineModal(context, theme, drug),
              onHide: () => _hideDrug(drug),
              onOrder: () => _showOrderModal(context, theme, drug),
              onPricing: () {
                final id = drug.id;
                if (id == null || id.trim().isEmpty) return;
                context.router.push(BatchesPreviewWardPricingRoute(id: id));
              },
            ),
    );
  }

  Widget _buildCards(ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      itemCount: _drugs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final drug = _drugs[index];
        final canHide =
            !_hasSellableStock(drug) && (drug.id?.trim().isNotEmpty ?? false);
        return _MedicineInventoryCard(
          drug: drug,
          onTap: () => _onDrugPressed(drug, useSheet: true),
          onHide: canHide ? () => _hideDrug(drug) : null,
        );
      },
    );
  }

  Widget _buildTable(ThemeData theme, {required bool useSheet}) {
    final cs = theme.colorScheme;
    final columnHeaderStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
      color: cs.onSurfaceVariant,
    );
    return ResponsiveDataTable(
      minWidth: 1100,
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
            headingRowColor: WidgetStateProperty.all(theme.colorScheme.surface),
            dataRowMinHeight: 70,
            dataRowMaxHeight: 70,
            showCheckboxColumn:
                false, // Hide default checkboxes to match design
            columns: [
              DataColumn(
                label: Text('MEDICINE NAME', style: columnHeaderStyle),
                onSort: (idx, asc) => _onSort(idx, asc, 'brandName'),
              ),
              DataColumn(
                label: Text('COMPOSITION', style: columnHeaderStyle),
                onSort: (idx, asc) => _onSort(idx, asc, 'genericName'),
              ),
              DataColumn(
                label: Text('STOCK', style: columnHeaderStyle),
                onSort: (idx, asc) => _onSort(idx, asc, 'stock'),
              ),
              DataColumn(
                label: Text('EXPIRY', style: columnHeaderStyle),
                onSort: (idx, asc) => _onSort(idx, asc, 'expiryDate'),
              ),
              DataColumn(label: Text('STATUS', style: columnHeaderStyle)),
              DataColumn(label: Text('ACTIONS', style: columnHeaderStyle)),
            ],
            rows: _drugs.map((drug) {
              final isSelected = _selectedDrug?.id == drug.id;
              return DataRow(
                selected: isSelected,
                onSelectChanged: (selected) {
                  if (selected != null && selected) {
                    _onDrugPressed(drug, useSheet: useSheet);
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
                        const HeltySolidIcon(
                          icon: Icons.medication,
                          color: PharmacyAccent.teal,
                          size: 36,
                          iconSize: 18,
                          radius: 8,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                drug.brandName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'ID: ${drug.id ?? '—'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (drug.createdByName != null &&
                                  drug.createdByName!.trim().isNotEmpty)
                                Text(
                                  'Created by: ${drug.createdByName}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      drug.genericName,
                      style: TextStyle(color: cs.onSurface),
                    ),
                  ),
                  DataCell(
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: '${drug.displayStock} ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: drug.displayUnit,
                            style: TextStyle(color: cs.onSurfaceVariant),
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
                              ? DateFormatter.monthYear(drug.expiryDate!)
                              : '—',
                          style: TextStyle(
                            color: drug.displayStatus == 'Expiring Soon'
                                ? Colors.orange[800]
                                : cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    HeltyStatusChip(
                      label: drug.displayStatus,
                      color: drugStatusColor(drug.displayStatus),
                    ),
                  ),
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
                                    ? cs.onSurfaceVariant
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Hide from catalog',
                                style: TextStyle(
                                  color: _hasSellableStock(drug)
                                      ? cs.onSurfaceVariant
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
    );
  }

  Widget _buildPagination(ThemeData theme) {
    final cs = theme.colorScheme;
    var totalPages = (_totalItems / _pageSize).ceil();
    if (totalPages == 0) totalPages = 1;
    final start = _totalItems == 0 ? 0 : (_currentPage - 1) * _pageSize + 1;
    final end = (_currentPage * _pageSize).clamp(0, _totalItems);
    final label = _totalItems == 0
        ? 'No medicines to display'
        : 'Showing $start–$end of $_totalItems';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: HeltyEllipsisText(
              text: label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          PopupMenuButton<int>(
            tooltip: 'Rows per page',
            initialValue: _pageSize,
            onSelected: (value) {
              setState(() {
                _pageSize = value;
                _currentPage = 1;
              });
              _fetchData();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 10, child: Text('10 / page')),
              PopupMenuItem(value: 25, child: Text('25 / page')),
              PopupMenuItem(value: 50, child: Text('50 / page')),
              PopupMenuItem(value: 100, child: Text('100 / page')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Text(
                '$_pageSize',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Previous page',
            onPressed: _currentPage > 1
                ? () => _onPageChanged(_currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            '$_currentPage/$totalPages',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            tooltip: 'Next page',
            onPressed: _currentPage < totalPages
                ? () => _onPageChanged(_currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
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

// ??? Add/Edit Medicine dialog (reusable) ???????????????????????????????????

class _MedicineInventoryCard extends StatelessWidget {
  const _MedicineInventoryCard({
    required this.drug,
    required this.onTap,
    required this.onHide,
  });

  final Drug drug;
  final VoidCallback onTap;
  final VoidCallback? onHide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final expiry = drug.expiryDate == null
        ? 'No expiry'
        : DateFormatter.monthYear(drug.expiryDate!);

    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HeltySolidIcon(
                    icon: Icons.medication,
                    color: PharmacyAccent.teal,
                    size: 34,
                    iconSize: 18,
                    radius: 8,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeltyEllipsisText(
                          text: drug.brandName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        HeltyEllipsisText(
                          text: drug.genericName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    tooltip: 'Actions',
                    onSelected: (value) {
                      if (value == 'hide') onHide?.call();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'hide',
                        enabled: onHide != null,
                        child: const Text('Hide from catalog'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              HeltyStatusChip(
                label: drug.displayStatus,
                color: drugStatusColor(drug.displayStatus),
              ),
              const SizedBox(height: 6),
              HeltyEllipsisText(
                text: '${drug.displayStock} ${drug.displayUnit} · $expiry',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicineDrugDetails extends StatefulWidget {
  const _MedicineDrugDetails({
    super.key,
    required this.drug,
    required this.drugService,
    required this.onEdit,
    required this.onHide,
    required this.onOrder,
    required this.onPricing,
    this.scrollController,
  });

  final Drug drug;
  final PharmacyApiService drugService;
  final VoidCallback onEdit;
  final VoidCallback onHide;
  final VoidCallback onOrder;
  final VoidCallback onPricing;
  final ScrollController? scrollController;

  @override
  State<_MedicineDrugDetails> createState() => _MedicineDrugDetailsState();
}

class _MedicineDrugDetailsState extends State<_MedicineDrugDetails> {
  List<DrugLocationQuantity>? _locations;
  bool _loadingLocations = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void didUpdateWidget(covariant _MedicineDrugDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.drug.id != widget.drug.id) _loadLocations();
  }

  Future<void> _loadLocations() async {
    final id = widget.drug.id;
    if (id == null || id.trim().isEmpty) {
      setState(() {
        _locations = const [];
        _locationError = null;
        _loadingLocations = false;
      });
      return;
    }
    setState(() {
      _loadingLocations = true;
      _locationError = null;
    });
    try {
      final locations = await widget.drugService.getDrugLocationQuantities(id);
      if (!mounted) return;
      setState(() => _locations = locations);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _locationError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingLocations = false);
    }
  }

  bool get _canHide {
    final id = widget.drug.id;
    return (widget.drug.stock ?? 0) <= 0 && id != null && id.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final drug = widget.drug;
    final daysLeft = drug.expiryDate?.difference(DateTime.now()).inDays;

    return Material(
      color: cs.surface,
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Row(
            children: [
              const HeltySolidIcon(
                icon: Icons.medication,
                color: PharmacyAccent.teal,
                size: 40,
                iconSize: 20,
                radius: 10,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Edit',
                icon: Icon(Icons.edit, color: cs.onSurfaceVariant),
                onPressed: widget.onEdit,
              ),
              IconButton(
                tooltip: 'Batch and ward pricing',
                icon: Icon(Icons.sell_outlined, color: cs.onSurfaceVariant),
                onPressed: drug.id == null || drug.id!.trim().isEmpty
                    ? null
                    : widget.onPricing,
              ),
              IconButton(
                tooltip: 'Hide from catalog',
                icon: Icon(
                  Icons.visibility_off_outlined,
                  color: _canHide
                      ? const Color(0xFFDC2626)
                      : cs.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                onPressed: _canHide ? widget.onHide : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            drug.brandName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${drug.therapeuticClass ?? '—'} · ${drug.id ?? '—'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          if (drug.createdByName != null &&
              drug.createdByName!.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Created by ${drug.createdByName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              HeltyStatusChip(
                label: drug.displayStatus,
                color: drugStatusColor(drug.displayStatus),
                dense: false,
              ),
              if (drug.displayStatus == 'Expiring Soon' && daysLeft != null)
                HeltyStatusChip(
                  label: 'Expires in $daysLeft days',
                  color: PharmacyAccent.amber,
                  dense: false,
                ),
            ],
          ),
          if ((drug.stock ?? 0) > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Deplete or transfer stock before hiding.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stock = _statCard(
                cs,
                theme,
                'Total stock',
                '${drug.displayStock}',
                drug.displayUnit,
              );
              final prices = _pricesCard(cs, theme, drug.prices);
              if (constraints.maxWidth < 340) {
                return Column(
                  children: [
                    stock,
                    const SizedBox(height: 8),
                    prices,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: stock),
                  const SizedBox(width: 8),
                  Expanded(child: prices),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _infoCard(cs, 'Drug composition', Icons.science_outlined, [
            _infoRow(cs, 'Generic name', drug.genericName),
            _infoRow(cs, 'Strength', drug.strength ?? '—'),
            _infoRow(cs, 'Dosage form', drug.dosageForm ?? '—'),
            _infoRow(
              cs,
              'Manufacturer',
              drug.manufacturerName ?? drug.manufacturerId ?? '—',
            ),
          ]),
          const SizedBox(height: 12),
          _infoCard(
            cs,
            'Stock locations',
            Icons.storefront_outlined,
            _locationChildren(cs, theme),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: widget.onOrder,
            icon: const Icon(Icons.shopping_cart_outlined, size: 18),
            label: Text(
              'Order ${drug.brandName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    ColorScheme cs,
    ThemeData theme,
    String title,
    String value,
    String suffix,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              text: value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              children: [
                TextSpan(
                  text: ' $suffix',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pricesCard(ColorScheme cs, ThemeData theme, List<DrugPrice>? prices) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selling prices',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          if (prices == null || prices.isEmpty)
            Text(
              '—',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            )
          else
            ...prices.map((price) {
              final wardName = price.wardName ?? 'Unknown ward';
              final priceText = price.price.toFinancial(isMoney: true);
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: HeltyEllipsisText(
                  text: '$wardName: $priceText/unit',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _infoCard(
    ColorScheme cs,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(ColorScheme cs, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  List<Widget> _locationChildren(ColorScheme cs, ThemeData theme) {
    if (_loadingLocations) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ];
    }
    final error = _locationError;
    if (error != null && error.isNotEmpty) {
      return [
        Text(
          error,
          style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
        ),
      ];
    }
    final locations = _locations ?? const <DrugLocationQuantity>[];
    if (locations.isEmpty) {
      return [
        Text(
          'No stock locations available.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      ];
    }
    return [
      for (final loc in locations)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.locationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                loc.quantity.toString(),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
    ];
  }
}

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
    final media = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: math.min(800, media.width - 32),
        height: math.min(640, media.height - 48),
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

// ??? Order medicine dialog ?????????????????????????????????????????????????

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
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text('Order ${widget.drug.brandName}'),
      content: SizedBox(
        width: math.min(400, MediaQuery.sizeOf(context).width - 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create a purchase order for ${widget.drug.genericName} (${widget.drug.brandName}).',
              style: TextStyle(color: cs.onSurfaceVariant),
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
                    child: Text('Select supplier'),
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
