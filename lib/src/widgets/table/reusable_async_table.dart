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
  final ValueChanged<T>? onRowTap;
  final List<PopupMenuEntry<dynamic>> Function(T item)? contextMenuBuilder;
  final void Function(T item, dynamic value)? onContextMenuSelected;
  final int rowsPerPage;
  final bool showFooter;

  const ReusableAsyncTable({
    super.key,
    required this.columns,
    required this.fetchData,
    required this.rowBuilder,
    required this.idGetter,
    this.onSelectionChanged,
    this.onRowTap,
    this.contextMenuBuilder,
    this.onContextMenuSelected,
    this.rowsPerPage = 10,
    this.showFooter = true,
  });

  @override
  State<ReusableAsyncTable<T>> createState() => _ReusableAsyncTableState<T>();
}

class _ReusableAsyncTableState<T> extends State<ReusableAsyncTable<T>> {
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
        onRowTap: widget.onRowTap,
        contextMenuBuilder: widget.contextMenuBuilder,
        onContextMenuSelected: widget.onContextMenuSelected,
      );
      _initialized = true;
    }
  }

  @override
  void didUpdateWidget(ReusableAsyncTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update callbacks only. Do not call refreshDatasource() here: the parent
    // rebuilds often (errors, banners, etc.) and function references change
    // every build, which would trigger an infinite loop of API calls.
    // Remount with a new [key] when query/sort/filter inputs change so data
    // reloads when those actually change.
    _source.updateCallbacks(
      fetchData: widget.fetchData,
      rowBuilder: widget.rowBuilder,
      idGetter: widget.idGetter,
      onSelectionChanged: widget.onSelectionChanged,
      onRowTap: widget.onRowTap,
      contextMenuBuilder: widget.contextMenuBuilder,
      onContextMenuSelected: widget.onContextMenuSelected,
    );
  }

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncPaginatedDataTable2(
      columns: widget.columns,
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
  ValueChanged<T>? onRowTap;
  List<PopupMenuEntry<dynamic>> Function(T item)? contextMenuBuilder;
  void Function(T item, dynamic value)? onContextMenuSelected;

  final Set<String> _selectedIds = {};
  final Map<String, T> _cachedItems = {};

  /// When [dispose] runs, [AsyncDataTableSource] may still complete an in-flight
  /// fetch and call [notifyListeners]. Suppress those to avoid
  /// "used after being disposed" on the underlying [ChangeNotifier].
  bool _suppressNotifications = false;

  @override
  void notifyListeners() {
    if (_suppressNotifications) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _suppressNotifications = true;
    super.dispose();
  }

  _GenericDataSource({
    required this.context,
    required FetchDataCallback<T> initialFetchData,
    required List<DataCell> Function(T item) initialRowBuilder,
    required String Function(T item) initialIdGetter,
    this.onSelectionChanged,
    this.onRowTap,
    this.contextMenuBuilder,
    this.onContextMenuSelected,
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
    ValueChanged<T>? onRowTap,
    List<PopupMenuEntry<dynamic>> Function(T item)? contextMenuBuilder,
    void Function(T item, dynamic value)? onContextMenuSelected,
  }) {
    this.fetchData = fetchData;
    this.rowBuilder = rowBuilder;
    this.idGetter = idGetter;
    this.onSelectionChanged = onSelectionChanged;
    this.onRowTap = onRowTap;
    this.contextMenuBuilder = contextMenuBuilder;
    this.onContextMenuSelected = onContextMenuSelected;
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
      final rows = data.items.map((item) {
        final id = idGetter(item);
        _cachedItems[id] = item;

        return DataRow2(
          key: ValueKey(id),
          selected: _selectedIds.contains(id),
          onTap: onRowTap != null ? () => onRowTap!(item) : null,
          onSecondaryTapDown: contextMenuBuilder != null
              ? (details) async {
                  final items = contextMenuBuilder!(item);
                  if (items.isEmpty) return;
                  final selected = await showMenu<dynamic>(
                    context: context,
                    position: RelativeRect.fromLTRB(
                      details.globalPosition.dx,
                      details.globalPosition.dy,
                      details.globalPosition.dx,
                      details.globalPosition.dy,
                    ),
                    items: items,
                  );
                  if (selected != null && onContextMenuSelected != null) {
                    onContextMenuSelected!(item, selected);
                  }
                }
              : null,
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
