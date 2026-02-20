import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';

/// Helper class to transport raw data from your API
class PagedData<T> {
  final List<T> items;
  final int totalCount;

  PagedData({required this.items, required this.totalCount});
}

// Definition for the fetch function
typedef FetchDataCallback<T> =
    Future<PagedData<T>> Function(int startIndex, int count);

class ReusableAsyncTable<T> extends StatefulWidget {
  final List<DataColumn2> columns;
  final FetchDataCallback<T> fetchData;
  final List<DataCell> Function(T item) rowBuilder;
  final String Function(T item) idGetter;
  final Function(List<T> selectedItems)? onSelectionChanged;
  final int rowsPerPage;
  final bool showFooter;

  const ReusableAsyncTable({
    super.key,
    required this.columns,
    required this.fetchData,
    required this.rowBuilder,
    required this.idGetter,
    this.onSelectionChanged,
    this.rowsPerPage = 10,
    this.showFooter = true,
  });

  @override
  State<ReusableAsyncTable<T>> createState() => _ReusableAsyncTableState<T>();
}

class _ReusableAsyncTableState<T> extends State<ReusableAsyncTable<T>> {
  final PaginatorController _paginatorController = PaginatorController();
  late _GenericDataSource<T> _source;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _source = _GenericDataSource<T>(
        context: context,
        initialFetchData: widget.fetchData,
        initialRowBuilder: widget.rowBuilder,
        initialIdGetter: widget.idGetter,
        onSelectionChanged: widget.onSelectionChanged,
      );
      _initialized = true;
    }
  }

  @override
  void didUpdateWidget(ReusableAsyncTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the data source with new callbacks and refresh
    _source.updateCallbacks(
      fetchData: widget.fetchData,
      rowBuilder: widget.rowBuilder,
      idGetter: widget.idGetter,
      onSelectionChanged: widget.onSelectionChanged,
    );
    _source.refreshDatasource();
  }

  @override
  void dispose() {
    _paginatorController.dispose();
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncPaginatedDataTable2(
      columns: widget.columns,
      controller: _paginatorController,
      source: _source,
      rowsPerPage: widget.rowsPerPage,
      columnSpacing: 12,
      horizontalMargin: 12,
      minWidth: 1600,
      checkboxAlignment: Alignment.center,
      // hidePaginator: widget.showFooter,
      availableRowsPerPage: [20, 50, 100],
      onSelectAll: (bool? isAll) {
        // FIXED: Renamed method to avoid override conflict
        _source.updateSelection(isAll);
      },
    );
  }
}

class _GenericDataSource<T> extends AsyncDataTableSource {
  final BuildContext context;
  late FetchDataCallback<T> fetchData;
  late List<DataCell> Function(T item) rowBuilder;
  late String Function(T item) idGetter;
  Function(List<T> selectedItems)? onSelectionChanged;

  final Set<String> _selectedIds = {};
  final Map<String, T> _cachedItems = {};

  _GenericDataSource({
    required this.context,
    required FetchDataCallback<T> initialFetchData,
    required List<DataCell> Function(T item) initialRowBuilder,
    required String Function(T item) initialIdGetter,
    this.onSelectionChanged,
  }) {
    fetchData = initialFetchData;
    rowBuilder = initialRowBuilder;
    idGetter = initialIdGetter;
  }

  void updateCallbacks({
    required FetchDataCallback<T> fetchData,
    required List<DataCell> Function(T item) rowBuilder,
    required String Function(T item) idGetter,
    required Function(List<T> selectedItems)? onSelectionChanged,
  }) {
    this.fetchData = fetchData;
    this.rowBuilder = rowBuilder;
    this.idGetter = idGetter;
    this.onSelectionChanged = onSelectionChanged;
  }

  // FIXED: Renamed from 'selectAll' to 'updateSelection'
  void updateSelection(bool? isAll) {
    if (isAll == true) {
      for (var key in _cachedItems.keys) {
        _selectedIds.add(key);
      }
    } else {
      _selectedIds.clear();
    }
    _notifySelection();
    refreshDatasource();
  }

  void _notifySelection() {
    if (onSelectionChanged != null) {
      final selectedItems = _selectedIds
          .map((id) => _cachedItems[id])
          .where((item) => item != null)
          .cast<T>()
          .toList();
      onSelectionChanged!(selectedItems);
    }
  }

  @override
  Future<AsyncRowsResponse> getRows(int start, int count) async {
    try {
      final PagedData<T> data = await fetchData(start, count);
      log(data.items.length.toString());
      final rows = data.items.map((item) {
        final id = idGetter(item);
        _cachedItems[id] = item;

        return DataRow2(
          key: ValueKey(id),
          selected: _selectedIds.contains(id),
          onSelectChanged: (value) {
            if (value == true) {
              _selectedIds.add(id);
            } else {
              _selectedIds.remove(id);
            }
            _notifySelection();
            refreshDatasource();
          },
          cells: rowBuilder(item),
        );
      }).toList();

      return AsyncRowsResponse(data.totalCount, rows);
    } catch (e) {
      debugPrint("Error fetching data: $e");
      return AsyncRowsResponse(0, []);
    }
  }
}
