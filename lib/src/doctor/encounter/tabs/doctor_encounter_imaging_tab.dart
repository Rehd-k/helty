import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/models/imaging_order_model.dart';
import 'package:helty/src/models/service_model.dart';
import 'package:helty/src/services/imaging_order_service.dart';
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
  final _orderService = ImagingOrderService();

  List<ImagingOrderModel> _orders = [];
  bool _loading = true;
  bool _loadScheduled = false;

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
    final list = await _orderService.getByEncounter(scope.encounterId);
    if (!mounted) return;
    setState(() {
      _orders = list;
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
    await _orderService.create(
      encounterId: scope.encounterId,
      studyName: service.name,
      patientId: patientId!,
      staffId: staffId!,
      serviceId: service.id,
      area: result.area.isEmpty ? null : result.area,
      contrast: result.contrast,
      urgency: result.urgency,
      notesToRadiologist: result.notesToRadiologist.isEmpty
          ? null
          : result.notesToRadiologist,
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Imaging order added')));
      _load();
    }
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
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _openOrderModal,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Order Imaging'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _orders.isEmpty
                ? Center(
                    child: Text(
                      'No imaging orders. Tap "Order Imaging" to add.',
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
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(o.studyName),
                          subtitle: Text(
                            '${o.urgency ?? "Routine"} • ${o.status}',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: Chip(
                            label: Text(o.status),
                            backgroundColor: theme.colorScheme.primaryContainer,
                          ),
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

  final _searchCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  ServiceModel? _selected;
  List<ServiceModel> _suggestions = [];
  bool _searchLoading = false;
  int _page = 0;
  bool _contrast = false;
  String _urgency = 'Routine';
  Timer? _searchDebounce;

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
    final list = await widget.serviceService.fetchServices(
      query: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      skip: skip,
      take: pageSize,
    );
    if (!mounted) return;
    setState(() {
      if (append) {
        _suggestions = [..._suggestions, ...list];
      } else {
        _suggestions = list;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Order Imaging'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Study',
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
                              child: CircularProgressIndicator(strokeWidth: 2),
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
                              _runSearch(skip: _page * pageSize, append: true);
                            },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Load more'),
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _areaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Area',
                  hintText: 'e.g. Chest, Abdomen',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _contrast,
                title: const Text('Contrast'),
                onChanged: (v) => setState(() => _contrast = v ?? false),
              ),
              DropdownButtonFormField<String>(
                initialValue: _urgency,
                decoration: const InputDecoration(
                  labelText: 'Urgency',
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
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes to radiologist',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.of(context).pop(
                  _ImagingOrderDialogResult(
                    selected: _selected,
                    area: _areaCtrl.text.trim(),
                    contrast: _contrast,
                    urgency: _urgency,
                    notesToRadiologist: _notesCtrl.text.trim(),
                  ),
                ),
          child: const Text('Order'),
        ),
      ],
    );
  }
}
