import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/doctor/encounter/widgets/encounter_side_panel.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/service_model.dart';
import 'package:helty/src/obstetrics/ui/widgets/antenatal_package_scope.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';
import 'package:helty/src/radiology/services/radiology_service.dart';
import 'package:helty/src/radiology/ui/widgets/radiology_order_results_dialog.dart';
import 'package:helty/src/services/service_category_service.dart';
import 'package:helty/src/services/service_service.dart';

@RoutePage()
class DoctorEncounterImagingTab extends StatefulWidget {
  const DoctorEncounterImagingTab({super.key, this.embedded = false});

  final bool embedded;

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
  bool _sidePanelExpanded = true;

  /// `false` = all radiology orders for [EncounterScope.patientId] (default).
  /// `true` = only this [EncounterScope.encounterId].
  bool _encounterOnly = false;

  /// Study names keyed by service id (for list labels when API omits service).
  final Map<String, String> _studyNamesByServiceId = {};

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
    final serviceId = service.serviceId.isNotEmpty
        ? service.serviceId
        : service.id;
    _studyNamesByServiceId[serviceId] = service.name;
    final pregnancyId = scope.pregnancyId;
    final itemPayload = {
      'scanType': RadiologyModality.inferFromStudyName(service.name).apiValue,
      'priority': _urgencyToPriorityApi(result.urgency),
      'bodyPart': result.area,
      'clinicalNotes': result.notesToRadiologist,
      'contrast': result.contrast,
      'serviceId': serviceId,
      if (pregnancyId != null && pregnancyId.isNotEmpty)
        'useAntenatalPackage': true,
    };
    await _orderService.createOrder({
      'encounterId': scope.encounterId,
      'patientId': patientId!,
      'requestedById': staffId!,
      if (pregnancyId != null && pregnancyId.isNotEmpty)
        'pregnancyId': pregnancyId,
      'items': [itemPayload],
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Imaging order added')));
      _load();
    }
  }

  bool _canDeleteRadiologyOrder(RadiologyOrder order, EncounterScope scope) {
    if (!scope.canEdit) return false;
    if (order.id.isEmpty) return false;
    final encounterId = order.encounterId?.trim();
    return encounterId != null &&
        encounterId.isNotEmpty &&
        encounterId == scope.encounterId;
  }

  Future<bool> _confirmDeleteRequest(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _itemStudyLabel(RadiologyOrderItem item) {
    return item.studyLabel(namesByServiceId: _studyNamesByServiceId);
  }

  String _radiologyOrderLabel(RadiologyOrder order) {
    if (order.items.isNotEmpty) {
      return _itemStudyLabel(order.items.first);
    }
    return 'Imaging order';
  }

  Future<void> _deleteRadiologyOrder(RadiologyOrder order) async {
    final label = _radiologyOrderLabel(order);
    final confirmed = await _confirmDeleteRequest(
      context,
      title: 'Delete imaging request?',
      message: 'Remove "$label" from this encounter? This cannot be undone.',
    );
    if (!confirmed || !mounted) return;

    try {
      await _orderService.deleteOrder(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imaging request "$label" deleted')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete imaging request: $e')),
      );
    }
  }

  void _showImagingOrderResults(
    BuildContext context,
    RadiologyOrder order,
    EncounterScope scope,
  ) {
    final canDelete = _canDeleteRadiologyOrder(order, scope);
    showRadiologyOrderResultsDialog(
      context,
      service: _orderService,
      order: order,
      studyNamesByServiceId: _studyNamesByServiceId,
      showEncounterId: true,
      canDelete: canDelete,
      onDelete: canDelete ? () => _deleteRadiologyOrder(order) : null,
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

    final readOnly = !scope.canEdit;

    final completedCount = _orders
        .where((o) => o.status == RadiologyOrderStatus.COMPLETED)
        .length;
    final pendingCount = _orders
        .where(
          (o) =>
              o.status == RadiologyOrderStatus.PENDING ||
              o.status == RadiologyOrderStatus.ACTIVE,
        )
        .length;
    final scheme = theme.colorScheme;

    final sidePanel = EncounterSidePanel(
      title: 'Imaging',
      expanded: _sidePanelExpanded,
      onToggleExpanded: () =>
          setState(() => _sidePanelExpanded = !_sidePanelExpanded),
      forceStacked: widget.embedded,
      subtitle: _orders.isEmpty
          ? (_encounterOnly
                ? 'No imaging orders yet for this encounter'
                : 'No imaging history for this patient')
          : '${_orders.length} order${_orders.length == 1 ? '' : 's'}'
                '${_encounterOnly ? ' on this encounter' : ''}',
      controls: SegmentedButton<bool>(
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
      chips: [
        if (_orders.isNotEmpty) ...[
          EncounterSidePanelChip(
            icon: Icons.medical_services_outlined,
            label: '${_orders.length} total',
            color: scheme.primary,
          ),
          if (completedCount > 0)
            EncounterSidePanelChip(
              icon: Icons.check_circle_outline,
              label: '$completedCount completed',
              color: Colors.green.shade700,
            ),
          if (pendingCount > 0)
            EncounterSidePanelChip(
              icon: Icons.hourglass_top_outlined,
              label: '$pendingCount pending',
              color: scheme.tertiary,
            ),
        ],
      ],
      railBadges: [
        EncounterSidePanelBadge(
          icon: Icons.medical_services_outlined,
          value: '${_orders.length}',
          color: scheme.primary,
          tooltip: '${_orders.length} total',
        ),
        if (completedCount > 0)
          EncounterSidePanelBadge(
            icon: Icons.check_circle_outline,
            value: '$completedCount',
            color: Colors.green.shade700,
            tooltip: '$completedCount completed',
          ),
        if (pendingCount > 0)
          EncounterSidePanelBadge(
            icon: Icons.hourglass_top_outlined,
            value: '$pendingCount',
            color: scheme.tertiary,
            tooltip: '$pendingCount pending',
          ),
      ],
      addLabel: 'Order Imaging',
      addTooltip: 'Order Imaging',
      onAdd: readOnly ? null : _openOrderModal,
    );

    final list = _orders.isEmpty
        ? _ImagingEmptyState(
            encounterOnly: _encounterOnly,
            theme: theme,
            compact: widget.embedded,
          )
        : widget.embedded
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final o in _orders)
                _imagingOrderCard(context, o, scope, theme),
            ],
          )
        : ListView.builder(
            itemCount: _orders.length,
            itemBuilder: (_, i) =>
                _imagingOrderCard(context, _orders[i], scope, theme),
          );

    final layout = EncounterTabLayout(
      embedded: widget.embedded,
      sidePanel: sidePanel,
      child: list,
    );

    if (widget.embedded) return layout;

    return ResponsiveBody(center: false, builder: (context, bp) => layout);
  }

  Widget _imagingOrderCard(
    BuildContext context,
    RadiologyOrder o,
    EncounterScope scope,
    ThemeData theme,
  ) {
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
              ? _itemStudyLabel(o.items.first)
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
        onTap: () => _showImagingOrderResults(context, o, scope),
      ),
    );
  }
}

class _ImagingEmptyState extends StatelessWidget {
  const _ImagingEmptyState({
    required this.encounterOnly,
    required this.theme,
    this.compact = false,
  });

  final bool encounterOnly;
  final ThemeData theme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medical_services_outlined,
              size: 32,
              color: cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            encounterOnly ? 'No imaging orders yet' : 'No imaging history',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            encounterOnly
                ? 'Order imaging for this encounter using the panel on the right.'
                : 'This patient has no imaging orders on file. Use "Order Imaging" to request one.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: content,
      );
    }

    return Center(child: content);
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
    required this.area,
    required this.contrast,
    required this.urgency,
    required this.notesToRadiologist,
  });
  final ServiceModel? selected;
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
                          final serviceId = s.serviceId.isNotEmpty
                              ? s.serviceId
                              : s.id;
                          return ListTile(
                            dense: true,
                            title: Row(
                              children: [
                                Expanded(child: Text(s.name)),
                                antenatalPackageBadge(
                                  context,
                                  serviceId: serviceId,
                                ),
                              ],
                            ),
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
                const SizedBox(height: 6),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('No'),
                      icon: Icon(Icons.close, size: 18),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Yes'),
                      icon: Icon(Icons.check, size: 18),
                    ),
                  ],
                  emptySelectionAllowed: true,
                  selected: _contrast == null ? <bool>{} : <bool>{_contrast!},
                  onSelectionChanged: (Set<bool> next) {
                    setState(() {
                      _contrast = next.isEmpty ? null : next.first;
                    });
                  },
                ),
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
