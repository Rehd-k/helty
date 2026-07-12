import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/medication_order_model.dart';
import 'package:helty/src/models/medication_request_model.dart';
import 'package:helty/src/pharmacy/services/pharmacy_service.dart';
import 'package:helty/src/pharmacy/utils/medication_request_permissions.dart';
import 'package:helty/src/pharmacy/widgets/medication_attribution_widgets.dart';
import 'package:helty/src/pharmacy/widgets/medication_request_edit_dialog.dart';
import 'package:helty/src/pharmacy/widgets/medication_workflow_badges.dart';
import 'package:helty/src/pharmacy/widgets/prescription_drug_form_dialog.dart';
import 'package:helty/src/services/medication_order_service.dart';
import 'package:helty/src/services/medication_request_service.dart';

@RoutePage()
class DoctorEncounterPrescriptionTab extends StatefulWidget {
  const DoctorEncounterPrescriptionTab({super.key});

  @override
  State<DoctorEncounterPrescriptionTab> createState() =>
      _DoctorEncounterPrescriptionTabState();
}

class _DoctorEncounterPrescriptionTabState
    extends State<DoctorEncounterPrescriptionTab> {
  final _pharmacyService = PharmacyApiService();
  final _medicationOrderService = MedicationOrderService();
  final _medicationRequestService = MedicationRequestService();

  List<MedicationOrderModel> _orders = [];
  bool _loading = true;
  bool _loadScheduled = false;
  bool _sidePanelExpanded = true;
  final Set<String> _updatingOrderIds = {};
  final Set<String> _expandedRequestHistoryOrderIds = {};

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
    final list = await _medicationOrderService.getByEncounter(
      scope.encounterId,
    );
    if (!mounted) return;
    setState(() {
      _orders = list;
      _loading = false;
    });
  }

  Future<void> _toggleAdministrationStatus(MedicationOrderModel order) async {
    if (order.id.isEmpty || _updatingOrderIds.contains(order.id)) return;

    final next =
        order.administrationStatus == MedicationAdministrationStatus.active
        ? MedicationAdministrationStatus.stopped
        : MedicationAdministrationStatus.active;

    setState(() => _updatingOrderIds.add(order.id));
    try {
      await _medicationOrderService.update(
        id: order.id,
        administrationStatus: next,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next == MedicationAdministrationStatus.active
                ? '${order.drugName} activated for nursing administration'
                : '${order.drugName} deactivated — nurses cannot administer',
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update prescription: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingOrderIds.remove(order.id));
      }
    }
  }

  Future<void> _authorizeBeyondDuration(MedicationOrderModel order) async {
    if (order.id.isEmpty || _updatingOrderIds.contains(order.id)) return;

    final noteCtrl = TextEditingController();
    final extendCtrl = TextEditingController(text: '2');
    var extendUnit = RxDurationUnit.days;
    var extendDuration = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text('Authorize ${order.drugName}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'The prescribed course has ended. Extend duration and/or '
                  'record consent so nurses may continue administration.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Consent note',
                    hintText: 'Clinical reason for continuing',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Extend duration'),
                  value: extendDuration,
                  onChanged: (v) => setLocal(() => extendDuration = v),
                ),
                if (extendDuration) ...[
                  TextField(
                    controller: extendCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Additional duration',
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<RxDurationUnit>(
                    initialValue: extendUnit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: RxDurationUnit.values
                        .map(
                          (u) => DropdownMenuItem(
                            value: u,
                            child: Text(u.label),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setLocal(() => extendUnit = v);
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Authorize'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _updatingOrderIds.add(order.id));
    try {
      final extendValue = int.tryParse(extendCtrl.text.trim());
      await _medicationOrderService.recordBeyondDurationConsent(
        id: order.id,
        consentNote: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
        extendDurationValue:
            extendDuration && extendValue != null && extendValue > 0
            ? extendValue
            : null,
        extendDurationUnit: extendDuration ? extendUnit : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authorization recorded for ${order.drugName}')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to authorize: $e')),
      );
    } finally {
      noteCtrl.dispose();
      extendCtrl.dispose();
      if (mounted) setState(() => _updatingOrderIds.remove(order.id));
    }
  }

  Future<void> _openAddModal() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;

    final form = await showPrescriptionDrugFormDialog(
      context,
      pharmacyApi: _pharmacyService,
      mode: PrescriptionDrugFormMode.add,
    );
    if (form == null || !mounted) return;

    final drugId = form.drug.id;
    if (drugId == null || drugId.isEmpty) return;

    try {
      await _medicationOrderService.create(
        staffId: scope.doctorId!,
        encounterId: scope.encounterId,
        patientId: scope.patientId,
        drugId: drugId,
        drugName: form.drug.brandName,
        dose: form.dose,
        frequency: form.frequency,
        duration: form.duration,
        quantity: form.quantity,
        requestedQuantity: scope.isOutpatient ? form.requestedQuantity : null,
        route: form.route,
        specialInstructions: form.specialInstructions,
        notes: form.notes,
        administrationStatus: form.administrationStatus,
        admissionId: scope.isOutpatient ? null : scope.activeAdmissionId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              scope.isOutpatient
                  ? 'Prescription saved — sent to pharmacy queue'
                  : 'Prescription saved — awaiting nurse request',
            ),
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add prescription: $e')),
        );
      }
    }
  }

  Future<void> _editMedicationRequest(
    MedicationRequestModel request,
    String doctorId,
  ) async {
    final result = await showMedicationRequestQtyEditDialog(
      context,
      request: request,
      requestService: _medicationRequestService,
      modifiedByStaffId: doctorId,
    );
    if (result == null || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Medication request updated')));
    await _load();
  }

  Future<void> _cancelMedicationRequest(
    MedicationRequestModel request,
    String doctorId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel medication request?'),
        content: const Text(
          'This removes the billing line and cancels the pharmacy request. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _medicationRequestService.cancel(
        id: request.id,
        cancelledByStaffId: doctorId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medication request cancelled')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _toggleRequestHistory(String orderId) {
    setState(() {
      if (_expandedRequestHistoryOrderIds.contains(orderId)) {
        _expandedRequestHistoryOrderIds.remove(orderId);
      } else {
        _expandedRequestHistoryOrderIds.add(orderId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final scope = EncounterScope.of(context);
    if (scope == null) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: Text('Encounter context not available')),
      );
    }

    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading prescriptions…',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    final activeCount = _orders
        .where(
          (o) =>
              o.administrationStatus == MedicationAdministrationStatus.active,
        )
        .length;
    final pendingCount = _orders
        .where((o) => o.status.trim() == 'Pending Dispense')
        .length;

    final canEdit = scope.canEdit;
    final onAdd = canEdit ? _openAddModal : null;

    return ResponsiveBody(
      center: false,
      builder: (context, bp) {
        final sidePanel = _PrescriptionSidePanel(
          totalCount: _orders.length,
          activeCount: activeCount,
          pendingCount: pendingCount,
          onAdd: onAdd,
          expanded: _sidePanelExpanded,
          onToggleExpanded: () =>
              setState(() => _sidePanelExpanded = !_sidePanelExpanded),
        );

        final list = _orders.isEmpty
            ? _PrescriptionEmptyState(onAdd: onAdd)
            : ListView.separated(
                itemCount: _orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final order = _orders[i];
                  return _EncounterPrescriptionCard(
                    order: order,
                    expanded: _expandedRequestHistoryOrderIds.contains(
                      order.id,
                    ),
                    isUpdating: _updatingOrderIds.contains(order.id),
                    doctorId: scope.doctorId ?? '',
                    canEdit: canEdit,
                    onToggleAdministration: () =>
                        _toggleAdministrationStatus(order),
                    onToggleRequestHistory: () =>
                        _toggleRequestHistory(order.id),
                    onEditRequest: (req) =>
                        _editMedicationRequest(req, scope.doctorId ?? ''),
                    onCancelRequest: (req) =>
                        _cancelMedicationRequest(req, scope.doctorId ?? ''),
                    onAuthorizeBeyondDuration: () =>
                        _authorizeBeyondDuration(order),
                  );
                },
              );

        if (bp.isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sidePanel,
              const SizedBox(height: 12),
              Expanded(child: list),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: list),
            const SizedBox(width: 16),
            sidePanel,
          ],
        );
      },
    );
  }
}

class _PrescriptionSidePanel extends StatelessWidget {
  const _PrescriptionSidePanel({
    required this.totalCount,
    required this.activeCount,
    required this.pendingCount,
    required this.onAdd,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final int totalCount;
  final int activeCount;
  final int pendingCount;
  final VoidCallback? onAdd;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final bp = AppBreakpoints.of(context);
    if (bp.isMobile) return _buildMobile(context);
    return _buildSide(context);
  }

  /// Collapsible summary card stacked above the list on mobile.
  Widget _buildMobile(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Prescriptions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (onAdd != null)
                    IconButton(
                      tooltip: 'Add prescription',
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _SummaryContent(
                totalCount: totalCount,
                activeCount: activeCount,
                pendingCount: pendingCount,
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  /// Expandable side rail on tablet/desktop.
  Widget _buildSide(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: expanded ? 260 : 60,
      child: Material(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: expanded
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Summary',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Collapse panel',
                          visualDensity: VisualDensity.compact,
                          onPressed: onToggleExpanded,
                          icon: const Icon(
                            Icons.keyboard_double_arrow_right_rounded,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _SummaryContent(
                      totalCount: totalCount,
                      activeCount: activeCount,
                      pendingCount: pendingCount,
                    ),
                    if (onAdd != null) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add prescription'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : Column(
                children: [
                  const SizedBox(height: 8),
                  IconButton(
                    tooltip: 'Expand summary',
                    onPressed: onToggleExpanded,
                    icon: const Icon(Icons.keyboard_double_arrow_left_rounded),
                  ),
                  if (onAdd != null)
                    IconButton(
                      tooltip: 'Add prescription',
                      onPressed: onAdd,
                      icon: Icon(Icons.add_rounded, color: scheme.primary),
                    ),
                  const SizedBox(height: 12),
                  _RailBadge(
                    icon: Icons.medication_outlined,
                    value: '$totalCount',
                    color: scheme.primary,
                    tooltip: '$totalCount total',
                  ),
                  if (activeCount > 0)
                    _RailBadge(
                      icon: Icons.play_circle_outline,
                      value: '$activeCount',
                      color: Colors.green.shade700,
                      tooltip: '$activeCount active',
                    ),
                  if (pendingCount > 0)
                    _RailBadge(
                      icon: Icons.hourglass_top_outlined,
                      value: '$pendingCount',
                      color: scheme.tertiary,
                      tooltip: '$pendingCount pending dispense',
                    ),
                ],
              ),
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({
    required this.totalCount,
    required this.activeCount,
    required this.pendingCount,
  });

  final int totalCount;
  final int activeCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          totalCount == 0
              ? 'No medications prescribed yet'
              : '$totalCount medication${totalCount == 1 ? '' : 's'} on this encounter',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        if (totalCount > 0) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _SummaryChip(
                icon: Icons.medication_outlined,
                label: '$totalCount total',
                color: scheme.primary,
              ),
              if (activeCount > 0)
                _SummaryChip(
                  icon: Icons.play_circle_outline,
                  label: '$activeCount active',
                  color: Colors.green.shade700,
                ),
              if (pendingCount > 0)
                _SummaryChip(
                  icon: Icons.hourglass_top_outlined,
                  label: '$pendingCount pending dispense',
                  color: scheme.tertiary,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _RailBadge extends StatelessWidget {
  const _RailBadge({
    required this.icon,
    required this.value,
    required this.color,
    required this.tooltip,
  });

  final IconData icon;
  final String value;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionEmptyState extends StatelessWidget {
  const _PrescriptionEmptyState({this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medication_liquid_outlined,
                size: 40,
                color: scheme.primary.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No prescriptions yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add medications for this encounter. Inpatient orders await nurse requests; outpatient orders go straight to pharmacy.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            if (onAdd != null)
              FilledButton.tonalIcon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add first prescription'),
              ),
          ],
        ),
      ),
    );
  }
}

class _EncounterPrescriptionCard extends StatelessWidget {
  const _EncounterPrescriptionCard({
    required this.order,
    required this.expanded,
    required this.isUpdating,
    required this.doctorId,
    required this.onToggleAdministration,
    required this.onToggleRequestHistory,
    required this.onEditRequest,
    required this.onCancelRequest,
    required this.onAuthorizeBeyondDuration,
    this.canEdit = true,
  });

  final MedicationOrderModel order;
  final bool expanded;
  final bool isUpdating;
  final String doctorId;
  final bool canEdit;
  final VoidCallback onToggleAdministration;
  final VoidCallback onToggleRequestHistory;
  final ValueChanged<MedicationRequestModel> onEditRequest;
  final ValueChanged<MedicationRequestModel> onCancelRequest;
  final VoidCallback onAuthorizeBeyondDuration;

  MedicationScheduleStatus get _scheduleStatus {
    final schedule = order.doseSchedule;
    if (schedule != null) return schedule.scheduleStatus;
    return MedicationScheduleStatus.notStarted;
  }

  bool get _needsAuthorization =>
      _scheduleStatus == MedicationScheduleStatus.expired &&
      order.doseSchedule?.hasBeyondDurationConsent != true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isActive =
        order.administrationStatus == MedicationAdministrationStatus.active;
    final accentColor = isActive ? scheme.primary : scheme.outline;
    final requestCount = order.medicationRequests.length;
    final hasInstructions =
        order.specialInstructions != null &&
        order.specialInstructions!.trim().isNotEmpty;
    final hasNotes = order.notes != null && order.notes!.trim().isNotEmpty;

    return Material(
      color: scheme.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.medication_outlined,
                            color: accentColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (order.wasSubstituted)
                                MedicationSubstitutionSummary(
                                  prescribedDrug: order.prescribedDrugLabel,
                                  currentDrug: order.currentDrugLabel,
                                  compact: true,
                                )
                              else
                                Text(
                                  order.currentDrugLabel,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              if (order.displayDateTime != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Prescribed ${DateFormatter.medicalDate(order.displayDateTime!)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.55,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            MedicationOrderStatusBadge(status: order.status),
                            const SizedBox(height: 6),
                            _AdministrationBadge(
                              status: order.administrationStatus,
                            ),
                            if (_scheduleStatus !=
                                MedicationScheduleStatus.notStarted) ...[
                              const SizedBox(height: 6),
                              Chip(
                                label: Text(_scheduleStatus.label),
                                visualDensity: VisualDensity.compact,
                                backgroundColor:
                                    _scheduleStatus ==
                                        MedicationScheduleStatus.expired
                                    ? scheme.errorContainer
                                    : scheme.tertiaryContainer,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    if (_needsAuthorization) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: scheme.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: scheme.error),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Course expired — nurses need your authorization '
                              'before further doses.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton.tonal(
                              onPressed: !canEdit || isUpdating
                                  ? null
                                  : onAuthorizeBeyondDuration,
                              child: const Text('Authorize / extend duration'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _SigChipRow(order: order),
                    if (hasInstructions || hasNotes) ...[
                      const SizedBox(height: 10),
                      if (hasInstructions)
                        _InstructionCallout(
                          icon: Icons.tips_and_updates_outlined,
                          label: 'Special instructions',
                          text: order.specialInstructions!.trim(),
                        ),
                      if (hasNotes) ...[
                        if (hasInstructions) const SizedBox(height: 6),
                        _InstructionCallout(
                          icon: Icons.notes_outlined,
                          label: 'Notes',
                          text: order.notes!.trim(),
                        ),
                      ],
                    ],
                    if (order.startDateTime != null ||
                        order.endDateTime != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range_outlined,
                              size: 14,
                              color: scheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDateRange(order),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (order.doctor != null &&
                            order.doctor!.displayName.trim().isNotEmpty ||
                        order.substitutedByPharmacist != null &&
                            order.substitutedByPharmacist!.displayName
                                .trim()
                                .isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(
                            alpha: 0.45,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: MedicationStaffAttributionColumn(
                          prescribingDoctor: order.doctor?.displayName,
                          substitutedBy:
                              order.substitutedByPharmacist?.displayName,
                          substitutedAt: order.substitutedAt,
                          compact: true,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (requestCount > 0)
                          TextButton.icon(
                            onPressed: onToggleRequestHistory,
                            icon: Icon(
                              expanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                            ),
                            label: Text('Pharmacy requests ($requestCount)'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                        else
                          Text(
                            'No pharmacy requests yet',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.5),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        const Spacer(),
                        if (isUpdating)
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (canEdit)
                          FilledButton.tonalIcon(
                            onPressed: order.id.isEmpty
                                ? null
                                : onToggleAdministration,
                            icon: Icon(
                              isActive
                                  ? Icons.pause_circle_outline
                                  : Icons.play_circle_outline,
                              size: 18,
                            ),
                            label: Text(isActive ? 'Deactivate' : 'Activate'),
                            style: FilledButton.styleFrom(
                              backgroundColor: isActive
                                  ? scheme.errorContainer.withValues(
                                      alpha: 0.55,
                                    )
                                  : scheme.primaryContainer.withValues(
                                      alpha: 0.55,
                                    ),
                              foregroundColor: isActive
                                  ? scheme.onErrorContainer
                                  : scheme.onPrimaryContainer,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (expanded && requestCount > 0) ...[
                      const SizedBox(height: 4),
                      ...order.medicationRequests.map(
                        (req) => _PharmacyRequestTile(
                          request: req,
                          doctorId: doctorId,
                          canEdit: canEdit,
                          onEdit: () => onEditRequest(req),
                          onCancel: () => onCancelRequest(req),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(MedicationOrderModel order) {
    final start = order.startDateTime;
    final end = order.endDateTime;
    if (start != null && end != null) {
      return '${DateFormatter.medicalDate(start)} → ${DateFormatter.medicalDate(end)}';
    }
    if (start != null) {
      return 'From ${DateFormatter.medicalDate(start)}';
    }
    if (end != null) {
      return 'Until ${DateFormatter.medicalDate(end)}';
    }
    return '';
  }
}

class _AdministrationBadge extends StatelessWidget {
  const _AdministrationBadge({required this.status});

  final MedicationAdministrationStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = status == MedicationAdministrationStatus.active;
    final color = isActive ? Colors.green.shade700 : scheme.outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.circle : Icons.pause_circle_filled,
            size: 8,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SigChipRow extends StatelessWidget {
  const _SigChipRow({required this.order});

  final MedicationOrderModel order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chips = <_SigChipData>[];

    void add(String? value, IconData icon, String label) {
      final v = value?.trim();
      if (v == null || v.isEmpty) return;
      chips.add(_SigChipData(icon: icon, label: label, value: v));
    }

    add(order.dose, Icons.straighten_outlined, 'Dose');
    add(order.route, Icons.alt_route_outlined, 'Route');
    add(order.frequency, Icons.schedule_outlined, 'Frequency');
    add(order.duration, Icons.timelapse_outlined, 'Duration');
    if (order.quantity != null) {
      chips.add(
        _SigChipData(
          icon: Icons.inventory_2_outlined,
          label: 'Qty',
          value: order.quantity.toString(),
        ),
      );
    }

    if (chips.isEmpty) {
      return Text(
        'No dosing details recorded',
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.5),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips
          .map((c) => _SigChip(data: c, scheme: scheme, theme: theme))
          .toList(),
    );
  }
}

class _SigChipData {
  const _SigChipData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _SigChip extends StatelessWidget {
  const _SigChip({
    required this.data,
    required this.scheme,
    required this.theme,
  });

  final _SigChipData data;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            data.icon,
            size: 14,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 6),
          Text(
            '${data.label}: ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            data.value,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionCallout extends StatelessWidget {
  const _InstructionCallout({
    required this.icon,
    required this.label,
    required this.text,
  });

  final IconData icon;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: scheme.tertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PharmacyRequestTile extends StatelessWidget {
  const _PharmacyRequestTile({
    required this.request,
    required this.doctorId,
    required this.onEdit,
    required this.onCancel,
    this.canEdit = true,
  });

  final MedicationRequestModel request;
  final String doctorId;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canModify = canEdit &&
        canModifyMedicationRequest(
          request,
          currentStaffId: doctorId,
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: medicationRequestStatusColor(
                context,
                request.status,
              ).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_pharmacy_outlined,
              size: 16,
              color: medicationRequestStatusColor(context, request.status),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Qty ${request.requestedQuantity}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    MedicationRequestStatusBadge(status: request.status),
                  ],
                ),
                const SizedBox(height: 6),
                MedicationRequestAttribution(request: request, compact: true),
                if (request.createdAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormatter.dateTime(request.createdAt!),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (canModify)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit quantity',
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: doctorId.isEmpty ? null : onEdit,
                ),
                IconButton(
                  tooltip: 'Cancel request',
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: scheme.error,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: doctorId.isEmpty ? null : onCancel,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
