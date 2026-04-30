import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/service_model.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';
import 'package:helty/src/radiology/services/radiology_service.dart';
import 'package:helty/src/services/service_category_service.dart';
import 'package:helty/src/services/service_service.dart';

@RoutePage()
class DoctorEncounterImagingTab extends StatefulWidget {
  const DoctorEncounterImagingTab({super.key});

  @override
  State<DoctorEncounterImagingTab> createState() =>
      _DoctorEncounterImagingTabState();
}

class _DoctorEncounterImagingTabState extends State<DoctorEncounterImagingTab> {
  final _serviceService = ServiceService();
  final _orderService = RadiologyService();

  List<RadiologyOrder> _orders = [];
  bool _loading = true;
  bool _loadScheduled = false;

  /// `false` = all radiology orders for [EncounterScope.patientId] (default).
  /// `true` = only this [EncounterScope.encounterId].
  bool _encounterOnly = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadScheduled) {
      _loadScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  Future<void> _load() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    setState(() => _loading = true);
    final list = await _orderService.listOrders(
      patientId: _encounterOnly ? null : scope.patientId,
      encounterId: _encounterOnly ? scope.encounterId : null,
      take: 100,
    );
    if (!mounted) return;
    setState(() {
      _orders = list.orders;
      _loading = false;
    });
  }

  Future<void> _openOrderModal() async {
    final scope = EncounterScope.of(context);
    final patientId = scope?.patientId;
    final staffId = scope?.doctorId;
    if (scope == null) return;

    final result = await showDialog<_ImagingOrderDialogResult>(
      context: context,
      builder: (ctx) => _OrderImagingDialog(serviceService: _serviceService),
    );

    if (result == null || result.selected == null || !mounted) return;

    final service = result.selected!;
    await _orderService.createOrder({
      'encounterId': scope.encounterId,
      'patientId': patientId!,
      'requestedById': staffId!,
      'items': [
        {
          'scanType': result.scanType.apiValue,
          'priority': _urgencyToPriorityApi(result.urgency),
          'bodyPart': result.area,
          'clinicalNotes': result.notesToRadiologist,
          'contrast': result.contrast,
          'serviceId': service.serviceId.isNotEmpty
              ? service.serviceId
              : service.id,
        },
      ],
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Imaging order added')));
      _load();
    }
  }

  void _showImagingOrderResults(
    BuildContext context,
    RadiologyOrder order,
    ThemeData theme,
  ) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Order ${order.id.substring(0, 8)}'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ResultRow(
                  label: 'Ordered',
                  value: DateFormatter.formatFromBackend(
                    order.createdAt,
                    DateFormatter.dateTime,
                  ),
                ),
                if (order.encounterId != null &&
                    order.encounterId!.trim().isNotEmpty)
                  _ResultRow(label: 'Encounter', value: order.encounterId!),
                _ResultRow(label: 'Status', value: order.status.name),
                _ResultRow(label: 'Items', value: '${order.items.length}'),
                if (firstItem != null) ...[
                  _ResultRow(
                    label: 'Modality',
                    value: firstItem.scanType.displayLabel,
                  ),
                  if (firstItem.bodyPart != null &&
                      firstItem.bodyPart!.trim().isNotEmpty)
                    _ResultRow(label: 'Area', value: firstItem.bodyPart!),
                  if (firstItem.contrast != null)
                    _ResultRow(
                      label: 'Contrast',
                      value: firstItem.contrast! ? 'Yes' : 'No',
                    ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Results',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Open radiology detail screen for full item schedule/procedure/images/report.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = EncounterScope.of(context);
    if (scope == null) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: Text('Encounter context not available')),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('All patient'),
                      icon: Icon(Icons.person_outline, size: 18),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('This encounter'),
                      icon: Icon(Icons.event_note_outlined, size: 18),
                    ),
                  ],
                  selected: {_encounterOnly},
                  onSelectionChanged: (s) {
                    if (s.isEmpty) return;
                    setState(() => _encounterOnly = s.first);
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _openOrderModal,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Order Imaging'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _orders.isEmpty
                ? Center(
                    child: Text(
                      _encounterOnly
                          ? 'No imaging orders for this encounter. Tap "Order Imaging" to add.'
                          : 'No imaging orders on file for this patient. Tap "Order Imaging" to add.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _orders.length,
                    itemBuilder: (_, i) {
                      final o = _orders[i];
                      final otherVisit =
                          !_encounterOnly &&
                          o.encounterId != null &&
                          o.encounterId!.isNotEmpty &&
                          o.encounterId != scope.encounterId;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            o.items.isNotEmpty
                                ? o.items.first.scanType.displayLabel
                                : 'Order with no items',
                          ),
                          subtitle: Text(
                            '${otherVisit ? 'Other visit • ' : ''}'
                            '${DateFormatter.formatFromBackend(o.createdAt, DateFormatter.medicalDate)} • ${o.items.length} item(s) • ${o.status.name}',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: Chip(
                            label: Text(o.status.name),
                            backgroundColor: theme.colorScheme.primaryContainer,
                          ),
                          onTap: () =>
                              _showImagingOrderResults(context, o, theme),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

String _urgencyToPriorityApi(String urgency) {
  switch (urgency) {
    case 'Urgent':
      return 'URGENT';
    case 'STAT':
      return 'EMERGENCY';
    default:
      return 'ROUTINE';
  }
}

class _ImagingOrderDialogResult {
  _ImagingOrderDialogResult({
    required this.selected,
    required this.scanType,
    required this.area,
    required this.contrast,
    required this.urgency,
    required this.notesToRadiologist,
  });
  final ServiceModel? selected;
  final RadiologyModality scanType;
  final String area;
  final bool contrast;
  final String urgency;
  final String notesToRadiologist;
}

class _OrderImagingDialog extends StatefulWidget {
  const _OrderImagingDialog({required this.serviceService});

  final ServiceService serviceService;

  @override
  State<_OrderImagingDialog> createState() => _OrderImagingDialogState();
}

class _OrderImagingDialogState extends State<_OrderImagingDialog> {
  static const int pageSize = 10;
  static const _imagingCategoryName = 'radiology & imaging';

  final _formKey = GlobalKey<FormState>();
  final _searchCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _categoryService = ServiceCategoryService();
  ServiceModel? _selected;
  List<ServiceModel> _suggestions = [];
  bool _searchLoading = false;
  int _page = 0;
  RadiologyModality? _scanType;
  bool? _contrast;
  String _urgency = 'Routine';
  Timer? _searchDebounce;
  Set<String>? _imagingCategoryIds;

  Future<void> _ensureImagingCategoryIds() async {
    if (_imagingCategoryIds != null) return;
    final categories = await _categoryService.fetchCategories();
    _imagingCategoryIds = categories
        .where((c) => c.name.trim().toLowerCase() == _imagingCategoryName)
        .map((c) => c.id)
        .toSet();
  }

  bool _isImaging(ServiceModel s) {
    if ((s.categoryName ?? '').trim().toLowerCase() == _imagingCategoryName) {
      return true;
    }
    final cid = s.categoryId?.trim();
    return cid != null &&
        cid.isNotEmpty &&
        _imagingCategoryIds != null &&
        _imagingCategoryIds!.contains(cid);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _areaCtrl.dispose();
    _notesCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _runSearch({int skip = 0, bool append = false}) async {
    setState(() => _searchLoading = true);
    await _ensureImagingCategoryIds();
    final q = _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim();
    List<ServiceModel> list = const [];
    if (_imagingCategoryIds != null && _imagingCategoryIds!.isNotEmpty) {
      final batches = await Future.wait(
        _imagingCategoryIds!.map(
          (id) => widget.serviceService.fetchServices(
            query: q,
            categoryId: id,
            skip: skip,
            take: pageSize,
          ),
        ),
      );
      final seen = <String>{};
      final merged = <ServiceModel>[];
      for (final batch in batches) {
        for (final s in batch) {
          final key = s.id.isNotEmpty ? s.id : s.serviceId;
          if (key.isEmpty || seen.contains(key)) continue;
          seen.add(key);
          merged.add(s);
        }
      }
      list = merged;
    } else {
      list = await widget.serviceService.fetchServices(
        query: q,
        skip: skip,
        take: pageSize,
      );
    }
    if (!mounted) return;
    final filtered = list.where(_isImaging).toList();
    setState(() {
      if (append) {
        _suggestions = [..._suggestions, ...filtered];
      } else {
        _suggestions = filtered;
      }
      _searchLoading = false;
    });
  }

  void _selectService(ServiceModel s) {
    setState(() {
      _selected = s;
      _searchCtrl.clear();
      _suggestions = [];
      if (_areaCtrl.text.isEmpty && s.departmentName != null) {
        _areaCtrl.text = s.departmentName ?? '';
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selected = null;
      _suggestions = [];
    });
  }

  void _submitOrder() {
    if (_selected == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a study.')));
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_contrast == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select whether this study uses contrast.'),
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      _ImagingOrderDialogResult(
        selected: _selected,
        scanType: _scanType!,
        area: _areaCtrl.text.trim(),
        contrast: _contrast!,
        urgency: _urgency,
        notesToRadiologist: _notesCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Order Imaging'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Study *',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (_selected != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selected!.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _clearSelection,
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search study (10 at a time)...',
                      border: const OutlineInputBorder(),
                      suffixIcon: _searchLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
                    ),
                    onChanged: (v) {
                      _searchDebounce?.cancel();
                      _searchDebounce = Timer(
                        const Duration(milliseconds: 300),
                        () => _runSearch(skip: 0),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  if (_suggestions.isEmpty && !_searchLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Type to search for a study.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        itemBuilder: (_, i) {
                          final s = _suggestions[i];
                          return ListTile(
                            dense: true,
                            title: Text(s.name),
                            subtitle: s.departmentName != null
                                ? Text(
                                    s.departmentName!,
                                    style: theme.textTheme.bodySmall,
                                  )
                                : null,
                            onTap: () => _selectService(s),
                          );
                        },
                      ),
                    ),
                  if (_suggestions.length >= pageSize)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TextButton.icon(
                        onPressed: _searchLoading
                            ? null
                            : () {
                                _page += 1;
                                _runSearch(
                                  skip: _page * pageSize,
                                  append: true,
                                );
                              },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Load more'),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<RadiologyModality>(
                  initialValue: _scanType,
                  decoration: const InputDecoration(
                    labelText: 'Scan type *',
                    hintText: 'Select modality',
                    border: OutlineInputBorder(),
                  ),
                  items: RadiologyModality.values
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.displayLabel),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _scanType = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _areaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Body area / region *',
                    hintText: 'e.g. Chest, Abdomen, Right knee',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Contrast *',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),

                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _urgency,
                  decoration: const InputDecoration(
                    labelText: 'Urgency *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Routine', child: Text('Routine')),
                    DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                    DropdownMenuItem(value: 'STAT', child: Text('STAT')),
                  ],
                  onChanged: (v) => setState(() => _urgency = v ?? _urgency),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Clinical notes for radiology *',
                    hintText: 'Indication, relevant history, questions…',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submitOrder, child: const Text('Order')),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
