import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/helper/app_timezone.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/medication_administration_model.dart';
import 'package:helty/src/models/medication_order_model.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_layout_constants.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_responsive_row_or_column.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/services/medication_administration_service.dart';
import 'package:helty/src/services/medication_order_service.dart';

@RoutePage()
class InpatientMedicationsScreen extends StatefulWidget {
  const InpatientMedicationsScreen({super.key});

  @override
  State<InpatientMedicationsScreen> createState() =>
      _InpatientMedicationsScreenState();
}

class _InpatientMedicationsScreenState
    extends State<InpatientMedicationsScreen> {
  final _medicationOrderService = MedicationOrderService();
  final _medicationAdministrationService = MedicationAdministrationService();

  List<MedicationOrderModel> _orders = [];
  List<MedicationAdministrationModel> _administrations = [];
  bool _loadingMar = true;

  /// Drug group keys the user has collapsed in MAR history (default: expanded).
  final Set<String> _collapsedHistoryDrugKeys = {};

  /// Tracks scope changes so we refetch when [encounterId] appears after load.
  String? _loadKey;

  static String _formatOrderSummaryLine(MedicationOrderModel o) {
    final parts = <String>[o.drugName.trim()];
    if (o.dose != null && o.dose!.trim().isNotEmpty) parts.add(o.dose!.trim());
    if (o.route != null && o.route!.trim().isNotEmpty) {
      parts.add(o.route!.trim());
    }
    if (o.frequency != null && o.frequency!.trim().isNotEmpty) {
      parts.add(o.frequency!.trim());
    }
    return 'Drug: ${parts.join(' ')}';
  }

  static String _mapAdminStatusToApi(String ui) {
    switch (ui) {
      case 'Missed':
        return 'MISSED';
      case 'Refused':
        return 'REFUSED';
      case 'Given':
      default:
        return 'GIVEN';
    }
  }

  static String _dioErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return e.message ?? 'Request failed';
  }

  static String _formatHistoryTime(MedicationAdministrationModel a) {
    final t = a.sortTime;
    if (t == null) return '—';
    return '${DateFormatter.timeOnly(t)} · ${DateFormatter.shortDate(t)}';
  }

  static String _formatAdministeredQuantity(double? quantity) {
    if (quantity == null) return '—';
    final s = quantity.toStringAsFixed(3);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static String _drugGroupKey(MedicationAdministrationModel a) {
    final name = (a.drugName ?? '').trim().toLowerCase();
    if (name.isEmpty) return '__unknown__:${a.id}';
    return name;
  }

  static String _statusLabel(String status) {
    final s = status.trim().toUpperCase();
    switch (s) {
      case 'GIVEN':
        return 'Given';
      case 'MISSED':
        return 'Missed';
      case 'REFUSED':
        return 'Refused';
      default:
        return status.trim().isEmpty ? '—' : status;
    }
  }

  static Color? _statusColor(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status.trim().toUpperCase()) {
      case 'GIVEN':
        return scheme.primary;
      case 'MISSED':
        return scheme.error;
      case 'REFUSED':
        return scheme.tertiary;
      default:
        return null;
    }
  }

  /// Groups administrations by drug; each group sorted newest-first.
  List<({String key, List<MedicationAdministrationModel> items})>
  _groupAdministrationsByDrug() {
    final map = <String, List<MedicationAdministrationModel>>{};
    for (final a in _administrations) {
      map.putIfAbsent(_drugGroupKey(a), () => []).add(a);
    }
    final groups =
        map.entries
            .map(
              (e) => (
                key: e.key,
                items: List<MedicationAdministrationModel>.from(e.value),
              ),
            )
            .toList()
          ..sort((a, b) {
            final ta = a.items.first.sortTime;
            final tb = b.items.first.sortTime;
            if (ta == null && tb == null) return 0;
            if (ta == null) return 1;
            if (tb == null) return -1;
            return tb.compareTo(ta);
          });
    return groups;
  }

  static String _formatDrugSubtitle(MedicationAdministrationModel a) {
    final parts = <String>[];
    if (a.dose != null && a.dose!.trim().isNotEmpty) parts.add(a.dose!.trim());
    if (a.route != null && a.route!.trim().isNotEmpty) {
      parts.add(a.route!.trim());
    }
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  String _groupStatusSummary(List<MedicationAdministrationModel> items) {
    var given = 0;
    var missed = 0;
    var refused = 0;
    for (final a in items) {
      switch (a.status.trim().toUpperCase()) {
        case 'GIVEN':
          given++;
        case 'MISSED':
          missed++;
        case 'REFUSED':
          refused++;
      }
    }
    final parts = <String>[];
    if (given > 0) parts.add('$given given');
    if (missed > 0) parts.add('$missed missed');
    if (refused > 0) parts.add('$refused refused');
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  /// Parses quantity for GIVEN administrations (max 3 decimal places).
  static double? _parseAdministeredQuantity(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    final value = double.tryParse(t);
    if (value == null || value <= 0) return null;
    final parts = t.split('.');
    if (parts.length == 2 && parts[1].length > 3) return null;
    return value;
  }

  Future<void> _loadMarData() async {
    if (!mounted) return;
    final scope = InpatientViewScope.of(context);
    final encounterId = scope?.encounterId;
    final admissionId = scope?.admissionId;
    final embedded = List<MedicationOrderModel>.from(
      scope?.embeddedMedicationOrders ?? const [],
    );

    setState(() => _loadingMar = true);
    try {
      List<MedicationOrderModel> orders;
      if (encounterId == null || encounterId.isEmpty) {
        orders = embedded;
      } else {
        final list = await _medicationOrderService.getByEncounter(encounterId);
        orders = list.isNotEmpty ? list : embedded;
      }

      var admins = <MedicationAdministrationModel>[];
      if (admissionId != null && admissionId.isNotEmpty) {
        try {
          admins = await _medicationAdministrationService.listByAdmission(
            admissionId,
          );
        } catch (_) {
          admins = [];
        }
      }

      admins.sort((a, b) {
        final ta = a.sortTime;
        final tb = b.sortTime;
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });

      if (!mounted) return;
      setState(() {
        _orders = orders;
        _administrations = admins;
        _loadingMar = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _orders = embedded;
        _administrations = [];
        _loadingMar = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = InpatientViewScope.of(context);
    final encId = scope?.encounterId;
    final admId = scope?.admissionId;
    final embedded = scope?.embeddedMedicationOrders ?? const [];
    final embSig = embedded.isEmpty
        ? '0'
        : '${embedded.length}:${embedded.first.id}';
    final loadKey = '${encId ?? ''}|${admId ?? ''}|$embSig';
    if (loadKey != _loadKey) {
      _loadKey = loadKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadMarData();
      });
    }
    if (scope == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('Inpatient context not available')),
      );
    }

    final isDoctor = scope.isDoctor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: InpatientResponsiveRowOrColumn(
        first: SectionCard(
          title: 'Active Medication Orders',
          subtitle: 'Standing and PRN orders for this inpatient stay',
          actions: [
            if (isDoctor)
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'To add prescriptions, open the doctor encounter view for this patient.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add medication'),
              ),
          ],
          child: _buildActiveOrdersTable(context, scope),
        ),
        second: SectionCard(
          title: 'Medication Administration History',
          subtitle: 'Chronological record of administered doses',
          child: _buildHistoryTable(context),
        ),
      ),
    );
  }

  Widget _buildActiveOrdersTable(
    BuildContext context,
    InpatientViewScope scope,
  ) {
    if (_loadingMar) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_orders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No active medication orders for this admission.'),
      );
    }

    final columns = [
      'Drug',
      'Dose',
      'Route',
      'Frequency',
      'Duration',
      'Dispense',
      'Clinical',
      'Administer',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns
            .map(
              (c) => DataColumn(
                label: Text(
                  c,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            )
            .toList(),
        rows: _orders.map((o) {
          final canAdminister =
              o.administrationStatus == MedicationAdministrationStatus.active;
          return DataRow(
            color: WidgetStateProperty.resolveWith((states) {
              if (!canAdminister) {
                return Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);
              }
              return null;
            }),
            cells: [
              DataCell(Text(o.drugName)),
              DataCell(Text(o.dose ?? '')),
              DataCell(Text(o.route ?? '')),
              DataCell(Text(o.frequency ?? '')),
              DataCell(Text(o.duration ?? '')),
              DataCell(Text(o.status)),
              DataCell(Text(o.administrationStatus.label)),
              DataCell(
                scope.isNurse
                    ? TextButton(
                        onPressed: canAdminister
                            ? () => _openAdministerDialog(context, scope, o)
                            : null,
                        child: const Text('Administer'),
                      )
                    : const Text('-'),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryTable(BuildContext context) {
    if (_loadingMar) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_administrations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No medication administrations recorded yet.'),
      );
    }

    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.bold,
    );
    const columns = [
      'Time',
      'Drug',
      'Dose',
      'Route',
      'Qty given',
      'Status',
      'Nurse',
      'Reason',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 880,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HistoryTableHeader(columns: columns, style: headerStyle),
            const Divider(height: 1),
            ..._groupAdministrationsByDrug().expand((group) {
              if (group.items.length == 1) {
                return [
                  _HistoryAdministrationRow(
                    administration: group.items.first,
                    headerStyle: headerStyle,
                  ),
                ];
              }
              return [
                _HistoryDrugGroupSection(
                  groupKey: group.key,
                  items: group.items,
                  expanded: !_collapsedHistoryDrugKeys.contains(group.key),
                  headerStyle: headerStyle,
                  formatTime: _formatHistoryTime,
                  formatQty: _formatAdministeredQuantity,
                  formatDrugSubtitle: _formatDrugSubtitle,
                  statusSummary: _groupStatusSummary(group.items),
                  statusLabel: _statusLabel,
                  statusColor: _statusColor,
                  onToggle: () {
                    setState(() {
                      if (_collapsedHistoryDrugKeys.contains(group.key)) {
                        _collapsedHistoryDrugKeys.remove(group.key);
                      } else {
                        _collapsedHistoryDrugKeys.add(group.key);
                      }
                    });
                  },
                ),
              ];
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _openAdministerDialog(
    BuildContext context,
    InpatientViewScope scope,
    MedicationOrderModel order,
  ) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _AdministerMedicationDialog(
        scope: scope,
        order: order,
        administrationService: _medicationAdministrationService,
      ),
    );

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Medication administration saved and billed to inpatient account.',
          ),
        ),
      );
      await _loadMarData();
    }
  }
}

class _AdministerMedicationDialog extends StatefulWidget {
  const _AdministerMedicationDialog({
    required this.scope,
    required this.order,
    required this.administrationService,
  });

  final InpatientViewScope scope;
  final MedicationOrderModel order;
  final MedicationAdministrationService administrationService;

  @override
  State<_AdministerMedicationDialog> createState() =>
      _AdministerMedicationDialogState();
}

class _AdministerMedicationDialogState
    extends State<_AdministerMedicationDialog> {
  String _status = 'Given';
  bool _saving = false;

  late final TextEditingController _timeCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _reasonCtrl;
  late final TextEditingController _signatureCtrl;

  @override
  void initState() {
    super.initState();
    final order = widget.order;
    _timeCtrl = TextEditingController(
      text: DateFormatter.timeOnly(AppTimezone.now()),
    );
    _quantityCtrl = TextEditingController(
      text: order.quantity != null && order.quantity! > 0
          ? order.quantity.toString()
          : '',
    );
    _reasonCtrl = TextEditingController();
    _signatureCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _timeCtrl.dispose();
    _quantityCtrl.dispose();
    _reasonCtrl.dispose();
    _signatureCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final admissionId = widget.scope.admissionId;
    if (admissionId == null || admissionId.isEmpty) {
      _showMessage('Admission is not available for MAR save.');
      return;
    }

    final apiStatus = _InpatientMedicationsScreenState._mapAdminStatusToApi(
      _status,
    );
    final parsedTime = AppTimezone.parseTimeOnDate(
      _timeCtrl.text,
      AppTimezone.now(),
    );
    if (parsedTime == null) {
      _showMessage('Enter a valid time (e.g. 2:30 PM).');
      return;
    }
    final scheduled = parsedTime;
    final actualTime = apiStatus == 'GIVEN' ? parsedTime : null;

    double? administeredQuantity;
    if (apiStatus == 'GIVEN') {
      administeredQuantity =
          _InpatientMedicationsScreenState._parseAdministeredQuantity(
            _quantityCtrl.text,
          );
      if (administeredQuantity == null) {
        _showMessage(
          'Enter a valid quantity administered (greater than 0, '
          'up to 3 decimal places).',
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      await widget.administrationService.create(
        admissionId: admissionId,
        medicationOrderId: widget.order.id,
        scheduledTime: scheduled,
        actualTime: actualTime,
        status: apiStatus,
        quantity: administeredQuantity,
        reasonIfNotGiven: _status != 'Given' ? _reasonCtrl.text : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(_InpatientMedicationsScreenState._dioErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Save failed: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final order = widget.order;
    final patientName = widget.scope.patientDisplayName ?? '—';
    final hospNo = widget.scope.hospitalNumber ?? '—';
    final orderLine = _InpatientMedicationsScreenState._formatOrderSummaryLine(
      order,
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Administer Medication'),
      content: SizedBox(
        width: inpatientDialogBodyWidth(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Confirm patient and order',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text('Patient: $patientName • Hosp No: $hospNo\n$orderLine'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _timeCtrl,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Actual administration time',
                hintText: 'e.g. 2:30 PM',
                helperText: 'Enter time as hh:mm AM or PM',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'Given', child: Text('Given')),
                DropdownMenuItem(value: 'Missed', child: Text('Missed')),
                DropdownMenuItem(value: 'Refused', child: Text('Refused')),
              ],
              onChanged: _saving
                  ? null
                  : (val) {
                      if (val != null) setState(() => _status = val);
                    },
            ),
            const SizedBox(height: 12),
            if (_status == 'Given')
              TextFormField(
                controller: _quantityCtrl,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                decoration: InputDecoration(
                  labelText: 'Quantity administered *',
                  hintText: order.quantity != null
                      ? 'e.g. ${order.quantity}'
                      : 'e.g. 1 or 2.5',
                  helperText:
                      'Required when status is Given (up to 3 decimals)',
                ),
              )
            else
              TextFormField(
                controller: _reasonCtrl,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Reason (if not given)',
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _signatureCtrl,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Digital signature / PIN',
              ),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

const List<int> _kHistoryColumnFlex = [2, 3, 2, 2, 2, 2, 2, 3];

class _HistoryTableHeader extends StatelessWidget {
  const _HistoryTableHeader({required this.columns, this.style});

  final List<String> columns;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          for (var i = 0; i < columns.length; i++)
            Expanded(
              flex: _kHistoryColumnFlex[i],
              child: Text(columns[i], style: style),
            ),
        ],
      ),
    );
  }
}

class _HistoryAdministrationRow extends StatelessWidget {
  const _HistoryAdministrationRow({
    required this.administration,
    this.headerStyle,
    this.highlight = false,
  });

  final MedicationAdministrationModel administration;
  final TextStyle? headerStyle;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = administration;
    final statusColor = _InpatientMedicationsScreenState._statusColor(
      context,
      a.status,
    );

    return Container(
      color: highlight
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: _kHistoryColumnFlex[0],
            child: Text(_InpatientMedicationsScreenState._formatHistoryTime(a)),
          ),
          Expanded(
            flex: _kHistoryColumnFlex[1],
            child: Text(a.drugName ?? '—', style: headerStyle),
          ),
          Expanded(flex: _kHistoryColumnFlex[2], child: Text(a.dose ?? '')),
          Expanded(flex: _kHistoryColumnFlex[3], child: Text(a.route ?? '')),
          Expanded(
            flex: _kHistoryColumnFlex[4],
            child: Text(
              _InpatientMedicationsScreenState._formatAdministeredQuantity(
                a.quantity,
              ),
            ),
          ),
          Expanded(
            flex: _kHistoryColumnFlex[5],
            child: Text(
              _InpatientMedicationsScreenState._statusLabel(a.status),
              style: statusColor != null
                  ? TextStyle(color: statusColor, fontWeight: FontWeight.w600)
                  : null,
            ),
          ),
          Expanded(
            flex: _kHistoryColumnFlex[6],
            child: Text(a.nurseDisplayName ?? '—'),
          ),
          Expanded(
            flex: _kHistoryColumnFlex[7],
            child: Text(a.reasonIfNotGiven ?? ''),
          ),
        ],
      ),
    );
  }
}

class _HistoryDrugGroupSection extends StatelessWidget {
  const _HistoryDrugGroupSection({
    required this.groupKey,
    required this.items,
    required this.expanded,
    required this.onToggle,
    required this.formatTime,
    required this.formatQty,
    required this.formatDrugSubtitle,
    required this.statusSummary,
    required this.statusLabel,
    required this.statusColor,
    required this.headerStyle,
  });

  final String groupKey;
  final List<MedicationAdministrationModel> items;
  final bool expanded;
  final VoidCallback onToggle;
  final String Function(MedicationAdministrationModel) formatTime;
  final String Function(double?) formatQty;
  final String Function(MedicationAdministrationModel) formatDrugSubtitle;
  final String statusSummary;
  final String Function(String) statusLabel;
  final Color? Function(BuildContext, String) statusColor;
  final TextStyle? headerStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final latest = items.first;
    final drugName = latest.drugName ?? '—';
    final latestStatusColor = statusColor(context, latest.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: scheme.primaryContainer.withValues(alpha: 0.18),
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 22,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: _kHistoryColumnFlex[0],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatTime(latest),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!expanded && items.length > 1)
                          Text(
                            '+${items.length - 1} earlier',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: _kHistoryColumnFlex[1],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drugName,
                          style: headerStyle?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${items.length} administrations · $statusSummary',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: _kHistoryColumnFlex[2],
                    child: Text(formatDrugSubtitle(latest)),
                  ),
                  Expanded(
                    flex: _kHistoryColumnFlex[3],
                    child: Text(latest.route ?? ''),
                  ),
                  Expanded(
                    flex: _kHistoryColumnFlex[4],
                    child: Text(expanded ? '—' : formatQty(latest.quantity)),
                  ),
                  Expanded(
                    flex: _kHistoryColumnFlex[5],
                    child: Text(
                      expanded ? statusSummary : statusLabel(latest.status),
                      style: latestStatusColor != null && !expanded
                          ? TextStyle(
                              color: latestStatusColor,
                              fontWeight: FontWeight.w600,
                            )
                          : theme.textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    flex: _kHistoryColumnFlex[6],
                    child: Text(
                      expanded ? '—' : (latest.nurseDisplayName ?? '—'),
                    ),
                  ),
                  Expanded(
                    flex: _kHistoryColumnFlex[7],
                    child: Text(
                      expanded
                          ? 'Tap to collapse'
                          : (latest.reasonIfNotGiven ?? ''),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: expanded
                            ? scheme.onSurface.withValues(alpha: 0.45)
                            : null,
                        fontStyle: expanded ? FontStyle.italic : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded)
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: scheme.primary.withValues(alpha: 0.35),
                  width: 3,
                ),
              ),
            ),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 12),
                  _HistoryAdministrationRow(
                    administration: items[i],
                    highlight: i.isOdd,
                  ),
                ],
              ],
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }
}
