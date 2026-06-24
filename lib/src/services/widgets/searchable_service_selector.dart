import 'dart:async';

import 'package:flutter/material.dart';
import 'package:helty/src/models/service_model.dart';
import 'package:helty/src/services/service_service.dart';

/// Searchable paginated service picker (same UX as encounter Procedures tab).
class SearchableServiceSelector extends StatefulWidget {
  const SearchableServiceSelector({
    super.key,
    required this.serviceService,
    required this.selectedService,
    required this.onServiceSelected,
    required this.onClear,
    this.filter,
    this.showOther = false,
    this.isOther = false,
    this.otherTextController,
    this.onOtherSelected,
    this.searchHint = 'Search procedure type (10 at a time)...',
  });

  final ServiceService serviceService;
  final ServiceModel? selectedService;
  final void Function(ServiceModel) onServiceSelected;
  final VoidCallback onClear;
  final bool Function(ServiceModel service)? filter;
  final bool showOther;
  final bool isOther;
  final TextEditingController? otherTextController;
  final VoidCallback? onOtherSelected;
  final String searchHint;

  @override
  State<SearchableServiceSelector> createState() =>
      _SearchableServiceSelectorState();
}

class _SearchableServiceSelectorState extends State<SearchableServiceSelector> {
  static const int _pageSize = 10;

  final _searchCtrl = TextEditingController();
  List<ServiceModel> _suggestions = [];
  bool _loading = false;
  int _page = 0;
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  List<ServiceModel> _applyFilter(List<ServiceModel> list) {
    final filter = widget.filter;
    if (filter == null) return list;
    return list.where(filter).toList();
  }

  Future<void> _runSearch({int skip = 0, bool append = false}) async {
    setState(() => _loading = true);
    final list = await widget.serviceService.fetchServices(
      query: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      skip: skip,
      take: _pageSize,
    );
    if (!mounted) return;
    final filtered = _applyFilter(list);
    setState(() {
      if (append) {
        _suggestions = [..._suggestions, ...filtered];
      } else {
        _suggestions = filtered;
        _page = 0;
      }
      _loading = false;
    });
  }

  void _loadMore() {
    _page += 1;
    _runSearch(skip: _page * _pageSize, append: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.selectedService != null) {
      final service = widget.selectedService!;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (service.departmentName != null &&
                      service.departmentName!.isNotEmpty)
                    Text(
                      service.departmentName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            TextButton(onPressed: widget.onClear, child: const Text('Change')),
          ],
        ),
      );
    }

    if (widget.showOther && widget.isOther) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: widget.otherTextController,
            decoration: const InputDecoration(
              labelText: 'Other procedure type',
              hintText: 'e.g. Suturing, I&D, Injection',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          TextButton(onPressed: widget.onClear, child: const Text('Change')),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: widget.searchHint,
            border: const OutlineInputBorder(),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: (v) {
            _debounce?.cancel();
            _debounce = Timer(
              const Duration(milliseconds: 300),
              () => _runSearch(skip: 0),
            );
          },
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView(
            shrinkWrap: true,
            children: [
              if (_suggestions.isEmpty && !_loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Type to search services',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ..._suggestions.map(
                (s) => ListTile(
                  dense: true,
                  title: Text(s.name),
                  subtitle: s.departmentName != null
                      ? Text(
                          s.departmentName!,
                          style: theme.textTheme.bodySmall,
                        )
                      : s.categoryName != null
                      ? Text(
                          s.categoryName!,
                          style: theme.textTheme.bodySmall,
                        )
                      : null,
                  onTap: () => widget.onServiceSelected(s),
                ),
              ),
              if (_suggestions.length >= _pageSize)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TextButton.icon(
                    onPressed: _loading ? null : _loadMore,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Load more'),
                  ),
                ),
              if (widget.showOther) ...[
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  title: const Text('Other'),
                  subtitle: const Text('Enter procedure type manually'),
                  trailing: const Icon(Icons.edit),
                  onTap: widget.onOtherSelected,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
