import 'package:flutter/material.dart';

import '../../models/service_model.dart';
import '../../services/service_category_service.dart';
import '../../services/service_service.dart';
import '../../services/widgets/searchable_service_selector.dart';
import '../models/theatre_models.dart';

class SurgeryRequestDialogResult {
  const SurgeryRequestDialogResult({
    required this.service,
    required this.priority,
    this.clinicalNotes,
    this.preferredDate,
  });

  final ServiceModel service;
  final SurgeryPriority priority;
  final String? clinicalNotes;
  final DateTime? preferredDate;
}

Future<SurgeryRequestDialogResult?> showSurgeryRequestDialog({
  required BuildContext context,
  required ServiceService serviceService,
}) {
  return showDialog<SurgeryRequestDialogResult>(
    context: context,
    builder: (ctx) => _SurgeryRequestDialog(serviceService: serviceService),
  );
}

class _SurgeryRequestDialog extends StatefulWidget {
  const _SurgeryRequestDialog({required this.serviceService});

  final ServiceService serviceService;

  @override
  State<_SurgeryRequestDialog> createState() => _SurgeryRequestDialogState();
}

class _SurgeryRequestDialogState extends State<_SurgeryRequestDialog> {
  final _notesCtrl = TextEditingController();
  final _categoryService = ServiceCategoryService();

  ServiceModel? _selected;
  SurgeryPriority _priority = SurgeryPriority.routine;
  DateTime? _preferredDate;
  Set<String> _surgeryCategoryIds = {};
  bool _loadingCategories = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _surgeryCategoryIds = categories
            .where((c) => isSurgeryServiceCategoryName(c.name))
            .map((c) => c.id)
            .toSet();
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingCategories = false;
      });
    }
  }

  bool _isSurgeryService(ServiceModel service) {
    if (_surgeryCategoryIds.contains(service.categoryId)) return true;
    return isSurgeryServiceCategoryName(service.categoryName ?? '');
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _preferredDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _preferredDate ?? DateTime(picked.year, picked.month, picked.day, 8),
      ),
    );
    if (time == null || !mounted) return;
    setState(() {
      _preferredDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    if (_selected == null) {
      setState(() => _error = 'Select a surgical procedure.');
      return;
    }
    Navigator.of(context).pop(
      SurgeryRequestDialogResult(
        service: _selected!,
        priority: _priority,
        clinicalNotes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        preferredDate: _preferredDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Request surgery'),
      content: SizedBox(
        width: 480,
        child: _loadingCategories
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Text(
                      'Procedure *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SearchableServiceSelector(
                      serviceService: widget.serviceService,
                      selectedService: _selected,
                      filter: _isSurgeryService,
                      searchHint: 'Search surgical procedure (10 at a time)...',
                      onServiceSelected: (s) => setState(() {
                        _selected = s;
                        _error = null;
                      }),
                      onClear: () => setState(() => _selected = null),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<SurgeryPriority>(
                      initialValue: _priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: SurgeryPriority.values
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.displayLabel),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _priority = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Clinical notes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        _preferredDate == null
                            ? 'Preferred date (optional)'
                            : 'Preferred: ${_preferredDate!.toLocal()}',
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
          onPressed: _loadingCategories ? null : _submit,
          child: const Text('Submit request'),
        ),
      ],
    );
  }
}
