import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/doctor/encounter/widgets/encounter_side_panel.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/lab/utils/lab_reference_evaluation.dart';
import 'package:helty/src/models/lab_order_model.dart';
import 'package:helty/src/models/service_model.dart';
import 'package:helty/src/services/service_category_service.dart';
import 'package:helty/src/lab/widgets/lab_order_results_dialog.dart';
import 'package:helty/src/services/lab_order_service.dart';
import 'package:helty/src/services/service_service.dart';

@RoutePage()
class DoctorEncounterInvestigationsTab extends StatefulWidget {
  const DoctorEncounterInvestigationsTab({super.key});

  @override
  State<DoctorEncounterInvestigationsTab> createState() =>
      _DoctorEncounterInvestigationsTabState();
}

class _DoctorEncounterInvestigationsTabState
    extends State<DoctorEncounterInvestigationsTab> {
  final _serviceService = ServiceService();
  final _labOrderService = LabOrderService();

  List<LabOrderModel> _orders = [];
  bool _loading = true;
  bool _loadScheduled = false;
  bool _sidePanelExpanded = true;

  /// `false` = all lab requests for [EncounterScope.patientId] (default).
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
    final list = await _labOrderService.listForScope(
      patientId: scope.patientId,
      encounterId: scope.encounterId,
      encounterOnly: _encounterOnly,
    );
    if (!mounted) return;
    setState(() {
      _orders = list;
      _loading = false;
    });
  }

  bool _canDeleteLabOrder(LabOrderModel order, EncounterScope scope) {
    if (!scope.canEdit) return false;
    if (order.id.isEmpty) return false;
    return order.encounterId.isNotEmpty &&
        order.encounterId == scope.encounterId;
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

  Future<void> _deleteLabOrder(LabOrderModel order) async {
    final confirmed = await _confirmDeleteRequest(
      context,
      title: 'Delete lab request?',
      message:
          'Remove "${order.testType}" from this encounter? This cannot be undone.',
    );
    if (!confirmed || !mounted) return;

    try {
      await _labOrderService.delete(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lab request "${order.testType}" deleted')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete lab request: $e')),
      );
    }
  }

  void _showLabOrderResults(
    BuildContext context,
    LabOrderModel order,
    ThemeData theme,
    EncounterScope scope,
  ) {
    final canDelete = _canDeleteLabOrder(order, scope);
    showLabOrderResultsDialog(
      context,
      order: order,
      onDelete: canDelete ? () => _deleteLabOrder(order) : null,
    );
  }

  Future<void> _openOrderModal() async {
    final scope = EncounterScope.of(context);
    final patientId = scope?.patientId;
    final staffId = scope?.doctorId;
    if (scope == null) return;

    final result = await showDialog<_LabOrderDialogResult>(
      context: context,
      builder: (ctx) => _OrderLabTestDialog(serviceService: _serviceService),
    );

    if (result == null || result.selected.isEmpty || !mounted) return;

    final notes = result.notes.trim();
    for (final service in result.selected) {
      await _labOrderService.create(
        encounterId: scope.encounterId,
        patientId: patientId!,
        testType: service.name,
        staffId: staffId!,
        // Use canonical service template id to preserve invoice linkage behavior.
        serviceId: service.serviceId.isNotEmpty
            ? service.serviceId
            : service.id,
        priority: result.priority,
        notes: notes.isEmpty ? null : notes,
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.selected.length} lab order(s) added')),
      );
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

    final readOnly = !scope.canEdit;

    final completedCount = _orders.where(_labOrderIsCompleted).length;
    final pendingCount = _orders.where(_labOrderIsPending).length;
    final scheme = theme.colorScheme;

    final sidePanel = EncounterSidePanel(
      title: 'Investigations',
      expanded: _sidePanelExpanded,
      onToggleExpanded: () =>
          setState(() => _sidePanelExpanded = !_sidePanelExpanded),
      subtitle: _orders.isEmpty
          ? (_encounterOnly
              ? 'No lab orders yet for this encounter'
              : 'No lab history for this patient')
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
            icon: Icons.science_outlined,
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
          icon: Icons.science_outlined,
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
      addLabel: 'Order Lab Test',
      addTooltip: 'Order Lab Test',
      onAdd: readOnly ? null : _openOrderModal,
    );

    final list = _orders.isEmpty
        ? _InvestigationsEmptyState(
            encounterOnly: _encounterOnly,
            theme: theme,
          )
        : ListView.separated(
            itemCount: _orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final o = _orders[i];
              final otherVisit =
                  !_encounterOnly &&
                  o.encounterId.isNotEmpty &&
                  o.encounterId != scope.encounterId;
              return _InvestigationOrderCard(
                order: o,
                otherVisit: otherVisit,
                theme: theme,
                onTap: () => _showLabOrderResults(context, o, theme, scope),
              );
            },
          );

    return ResponsiveBody(
      center: false,
      builder: (context, bp) => EncounterTabLayout(
        sidePanel: sidePanel,
        child: list,
      ),
    );
  }
}

bool _labOrderHasResults(LabOrderModel order) {
  final lines = order.resultLines;
  return (lines != null && lines.isNotEmpty) ||
      (order.resultValues != null && order.resultValues!.isNotEmpty);
}

bool _labOrderIsCompleted(LabOrderModel order) {
  if (_labOrderHasResults(order)) return true;
  final status = order.status.toLowerCase();
  return status.contains('complete') ||
      status.contains('verified') ||
      status.contains('reported');
}

bool _labOrderIsPending(LabOrderModel order) {
  final status = order.status.toLowerCase();
  if (status.contains('cancel') || status.contains('reject')) return false;
  return !_labOrderIsCompleted(order);
}

class _InvestigationsEmptyState extends StatelessWidget {
  const _InvestigationsEmptyState({
    required this.encounterOnly,
    required this.theme,
  });

  final bool encounterOnly;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
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
                Icons.biotech_outlined,
                size: 32,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              encounterOnly ? 'No lab orders yet' : 'No lab history',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              encounterOnly
                  ? 'Order investigations for this encounter using the panel on the right.'
                  : 'This patient has no lab orders on file. Use "Order Lab Test" to request one.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InvestigationOrderCard extends StatelessWidget {
  const _InvestigationOrderCard({
    required this.order,
    required this.otherVisit,
    required this.theme,
    required this.onTap,
  });

  final LabOrderModel order;
  final bool otherVisit;
  final ThemeData theme;
  final VoidCallback onTap;

  bool get _hasResults {
    final lines = order.resultLines;
    return (lines != null && lines.isNotEmpty) ||
        (order.resultValues != null && order.resultValues!.isNotEmpty);
  }

  int get _abnormalCount {
    final lines = order.resultLines;
    if (lines == null) return 0;
    return lines.where((line) {
      final eval = resolveLabReferenceEvaluation(
        value: line.value,
        referenceRange: line.referenceRange,
        serverEvaluation: line.referenceEvaluation,
      );
      return labResultIsAbnormal(eval);
    }).length;
  }

  (Color, Color) _statusColors() {
    final cs = theme.colorScheme;
    final s = order.status.toLowerCase();
    if (_hasResults ||
        s.contains('complete') ||
        s.contains('verified') ||
        s.contains('reported')) {
      return (cs.primaryContainer, cs.onPrimaryContainer);
    }
    if (s.contains('process') ||
        s.contains('sample') ||
        s.contains('progress') ||
        s.contains('collect')) {
      return (cs.tertiaryContainer, cs.onTertiaryContainer);
    }
    if (s.contains('cancel') || s.contains('reject')) {
      return (cs.errorContainer, cs.onErrorContainer);
    }
    return (cs.secondaryContainer, cs.onSecondaryContainer);
  }

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final (statusBg, statusFg) = _statusColors();
    final lines = order.resultLines;
    final legacy = order.resultValues;
    final previewLines = lines != null && lines.isNotEmpty
        ? lines.take(3).toList()
        : null;
    final previewLegacy =
        previewLines == null && legacy != null && legacy.isNotEmpty
        ? legacy.entries.take(3).toList()
        : null;

    return Material(
      color: cs.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.science_outlined,
                      size: 20,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.testType,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                order.status,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusFg,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _MetaPill(
                              icon: Icons.flag_outlined,
                              label: order.priority ?? 'Routine',
                              theme: theme,
                            ),
                            if (otherVisit)
                              _MetaPill(
                                icon: Icons.history_outlined,
                                label: 'Other visit',
                                theme: theme,
                                tone: _MetaPillTone.warning,
                              ),
                            if (_abnormalCount > 0)
                              _MetaPill(
                                icon: Icons.warning_amber_rounded,
                                label: '$_abnormalCount abnormal',
                                theme: theme,
                                tone: _MetaPillTone.alert,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.formatFromBackend(
                      order.createdAt,
                      DateFormatter.medicalDate,
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (_hasResults) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 14,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to view results',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              if (previewLines != null || previewLegacy != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (previewLines != null)
                        ...previewLines.map((line) {
                          final eval = resolveLabReferenceEvaluation(
                            value: line.value,
                            referenceRange: line.referenceRange,
                            serverEvaluation: line.referenceEvaluation,
                          );
                          final abnormal = labResultIsAbnormal(eval);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    line.label,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  line.valueWithUnit,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: abnormal ? cs.error : cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                      else if (previewLegacy != null)
                        ...previewLegacy.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    e.key,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  e.value,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if ((lines?.length ?? legacy?.length ?? 0) > 3)
                        Text(
                          '+ ${(lines?.length ?? legacy!.length) - 3} more',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _MetaPillTone { neutral, warning, alert }

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.theme,
    this.tone = _MetaPillTone.neutral,
  });

  final IconData icon;
  final String label;
  final ThemeData theme;
  final _MetaPillTone tone;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final (bg, fg) = switch (tone) {
      _MetaPillTone.warning => (
        cs.tertiaryContainer.withValues(alpha: 0.7),
        cs.onTertiaryContainer,
      ),
      _MetaPillTone.alert => (cs.errorContainer, cs.onErrorContainer),
      _MetaPillTone.neutral => (
        cs.surfaceContainerHighest.withValues(alpha: 0.8),
        cs.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabOrderDialogResult {
  _LabOrderDialogResult({
    required this.selected,
    required this.priority,
    required this.notes,
  });
  final List<ServiceModel> selected;
  final String priority;
  final String notes;
}

class _OrderLabTestDialog extends StatefulWidget {
  const _OrderLabTestDialog({required this.serviceService});

  final ServiceService serviceService;

  @override
  State<_OrderLabTestDialog> createState() => _OrderLabTestDialogState();
}

class _OrderLabTestDialogState extends State<_OrderLabTestDialog> {
  static const int pageSize = 10;
  static const _labCategoryNames = <String>{'laboratory', 'laboratory tests'};

  final _searchCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _categoryService = ServiceCategoryService();
  final _selected = <ServiceModel>[];
  List<ServiceModel> _searchResults = [];
  bool _searchLoading = false;
  int _page = 0;
  String _priority = 'Routine';
  Timer? _searchDebounce;
  Set<String>? _labCategoryIds;

  bool _isLabService(ServiceModel s) {
    final byName = (s.categoryName ?? '').trim().toLowerCase();
    if (_labCategoryNames.contains(byName)) return true;
    final cid = s.categoryId?.trim();
    if (cid != null && cid.isNotEmpty && _labCategoryIds != null) {
      return _labCategoryIds!.contains(cid);
    }
    return false;
  }

  Future<void> _ensureLabCategoryIds() async {
    if (_labCategoryIds != null) return;
    final categories = await _categoryService.fetchCategories();
    final ids = categories
        .where((c) => _labCategoryNames.contains(c.name.trim().toLowerCase()))
        .map((c) => c.id)
        .toSet();
    _labCategoryIds = ids;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _notesCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _runSearch({int skip = 0, bool append = false}) async {
    setState(() => _searchLoading = true);
    await _ensureLabCategoryIds();
    final q = _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim();

    List<ServiceModel> list = const [];
    if (_labCategoryIds != null && _labCategoryIds!.isNotEmpty) {
      final batches = await Future.wait(
        _labCategoryIds!.map(
          (categoryId) => widget.serviceService.fetchServices(
            query: q,
            categoryId: categoryId,
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
      // Fallback for environments where category records are missing.
      list = await widget.serviceService.fetchServices(
        query: q,
        skip: skip,
        take: pageSize,
      );
    }

    if (!mounted) return;
    final filtered = list.where(_isLabService).toList();
    setState(() {
      if (append) {
        _searchResults = [..._searchResults, ...filtered];
      } else {
        _searchResults = filtered;
      }
      _searchLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Order Lab Test'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Routine', child: Text('Routine')),
                  DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                  DropdownMenuItem(value: 'STAT', child: Text('STAT')),
                ],
                onChanged: (v) => setState(() => _priority = v ?? _priority),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Clinical notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Search services (10 per page):',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Type to search...',
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
              if (_searchResults.isEmpty && !_searchLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Enter a search term to load services.',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (_, i) {
                      final s = _searchResults[i];
                      final isSelected = _selected.any((e) => e.id == s.id);
                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(s.name),
                        subtitle: Text(
                          s.departmentName ?? s.categoryName ?? "—",
                        ),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selected.add(s);
                            } else {
                              _selected.removeWhere((e) => e.id == s.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              if (_searchResults.length >= pageSize)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
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
              if (_selected.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Selected: ${_selected.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
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
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(
                  _LabOrderDialogResult(
                    selected: List.from(_selected),
                    priority: _priority,
                    notes: _notesCtrl.text,
                  ),
                ),
          child: const Text('Order'),
        ),
      ],
    );
  }
}
