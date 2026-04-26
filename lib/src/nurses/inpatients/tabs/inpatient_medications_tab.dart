import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/models/medication_administration_model.dart';
import 'package:helty/src/models/medication_order_model.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_layout_constants.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_responsive_row_or_column.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/services/medication_administration_service.dart';
import 'package:helty/src/services/medication_order_service.dart';
import 'package:helty/src/services/transaction_service.dart';

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
  final _transactionService = TransactionService();

  List<MedicationOrderModel> _orders = [];
  List<MedicationAdministrationModel> _administrations = [];
  bool _loadingMar = true;

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

  static DateTime _parseAdministrationTime(String text) {
    final t = text.trim();
    final now = DateTime.now();
    if (t.isEmpty) return now;
    final parts = t.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0].trim());
      final m = int.tryParse(parts[1].trim());
      if (h != null &&
          m != null &&
          h >= 0 &&
          h < 24 &&
          m >= 0 &&
          m < 60) {
        return DateTime(now.year, now.month, now.day, h, m);
      }
    }
    return now;
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
    final d = '${t.day.toString().padLeft(2, '0')}/'
        '${t.month.toString().padLeft(2, '0')}/'
        '${t.year}';
    final time =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '$time · $d';
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
      'Status',
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
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            )
            .toList(),
        rows: _orders
            .map(
              (o) => DataRow(
                cells: [
                  DataCell(Text(o.drugName)),
                  DataCell(Text(o.dose ?? '')),
                  DataCell(Text(o.route ?? '')),
                  DataCell(Text(o.frequency ?? '')),
                  DataCell(Text(o.duration ?? '')),
                  DataCell(Text(o.status)),
                  DataCell(
                    scope.isNurse
                        ? TextButton(
                            onPressed: () =>
                                _openAdministerDialog(context, scope, o),
                            child: const Text('Administer'),
                          )
                        : const Text('-'),
                  ),
                ],
              ),
            )
            .toList(),
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

    final columns = [
      'Time',
      'Drug',
      'Dose',
      'Route',
      'Status',
      'Nurse',
      'Reason',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns
            .map(
              (c) => DataColumn(
                label: Text(
                  c,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            )
            .toList(),
        rows: _administrations
            .map(
              (a) => DataRow(
                cells: [
                  DataCell(Text(_formatHistoryTime(a))),
                  DataCell(Text(a.drugName ?? '—')),
                  DataCell(Text(a.dose ?? '')),
                  DataCell(Text(a.route ?? '')),
                  DataCell(Text(a.status)),
                  DataCell(Text(a.nurseDisplayName ?? '—')),
                  DataCell(Text(a.reasonIfNotGiven ?? '')),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _openAdministerDialog(
    BuildContext context,
    InpatientViewScope scope,
    MedicationOrderModel order,
  ) async {
    final statusNotifier = ValueNotifier<String>('Given');
    final timeCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final signatureCtrl = TextEditingController();

    final patientName = scope.patientDisplayName ?? '—';
    final hospNo = scope.hospitalNumber ?? '—';
    final orderLine = _formatOrderSummaryLine(order);

    final rootMessenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final scheme = theme.colorScheme;

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Administer Medication'),
          content: SizedBox(
            width: inpatientDialogBodyWidth(dialogContext),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      Text(
                        'Patient: $patientName • Hosp No: $hospNo\n$orderLine',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: timeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Actual administration time',
                    hintText: 'e.g. 13:45',
                  ),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<String>(
                  valueListenable: statusNotifier,
                  builder: (context, status, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          key: ValueKey<String>(status),
                          initialValue: status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Given',
                              child: Text('Given'),
                            ),
                            DropdownMenuItem(
                              value: 'Missed',
                              child: Text('Missed'),
                            ),
                            DropdownMenuItem(
                              value: 'Refused',
                              child: Text('Refused'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) statusNotifier.value = val;
                          },
                        ),
                        const SizedBox(height: 12),
                        if (status != 'Given')
                          TextFormField(
                            controller: reasonCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Reason (if not given)',
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: signatureCtrl,
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final admissionId = scope.admissionId;
                if (admissionId == null || admissionId.isEmpty) {
                  rootMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Admission is not available for MAR save.'),
                    ),
                  );
                  return;
                }

                final uiStatus = statusNotifier.value;
                final apiStatus = _mapAdminStatusToApi(uiStatus);
                final scheduled = _parseAdministrationTime(timeCtrl.text);
                final actualTime = apiStatus == 'GIVEN' ? scheduled : null;

                try {
                  await _medicationAdministrationService.create(
                    admissionId: admissionId,
                    medicationOrderId: order.id,
                    scheduledTime: scheduled,
                    actualTime: actualTime,
                    status: apiStatus,
                    reasonIfNotGiven:
                        uiStatus != 'Given' ? reasonCtrl.text : null,
                  );

                  if (uiStatus == 'Given') {
                    final staffId = scope.staffId;
                    if (staffId != null && staffId.isNotEmpty) {
                      final dto = CreateTransactionDto(
                        patientId: scope.patientId,
                        staffId: staffId,
                        admissionId: scope.admissionId,
                        items: [
                          const CreateTransactionItemDto(
                            serviceId: '',
                            name: 'Medication administration',
                            unitPrice: 0,
                            quantity: 1,
                            source: 'MEDICATION',
                          ),
                        ],
                      );
                      await _transactionService.createTransaction(dto);
                    }
                  }

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (context.mounted) {
                    rootMessenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Medication administration saved and billed to inpatient account.',
                        ),
                      ),
                    );
                    await _loadMarData();
                  }
                } on DioException catch (e) {
                  if (context.mounted) {
                    rootMessenger.showSnackBar(
                      SnackBar(content: Text(_dioErrorMessage(e))),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    rootMessenger.showSnackBar(
                      SnackBar(content: Text('Save failed: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
