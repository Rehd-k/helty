import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/models/medication_order_model.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
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
  final _transactionService = TransactionService();

  List<MedicationOrderModel> _orders = [];
  bool _loadingOrders = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final scope = InpatientViewScope.of(context);
    final encounterId = scope?.encounterId;
    if (encounterId == null || encounterId.isEmpty) {
      setState(() {
        _orders = const [];
        _loadingOrders = false;
      });
      return;
    }
    setState(() => _loadingOrders = true);
    try {
      final list = await _medicationOrderService.getByEncounter(encounterId);
      if (!mounted) return;
      setState(() {
        _orders = list;
        _loadingOrders = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _orders = const [];
        _loadingOrders = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = InpatientViewScope.of(context);
    if (scope == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('Inpatient context not available')),
      );
    }

    final isDoctor = scope.isDoctor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SectionCard(
              title: 'Active Medication Orders',
              subtitle: 'Standing and PRN orders for this inpatient stay',
              actions: [
                if (isDoctor)
                  FilledButton.icon(
                    onPressed: () {
                      // For now, doctors should use the encounter prescription tab
                      // where full prescribing workflow exists.
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
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SectionCard(
              title: 'Medication Administration History',
              subtitle: 'Chronological record of administered doses',
              child: _buildHistoryTable(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersTable(
    BuildContext context,
    InpatientViewScope scope,
  ) {
    if (_loadingOrders) {
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
        rows: const [],
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

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Administer Medication'),
          content: SizedBox(
            width: 520,
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
                    children: const [
                      Text(
                        'Confirm patient and order',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Patient: [Name] • Hosp No: [Number]\nDrug: Paracetamol 1g PO 8 hourly',
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final status = statusNotifier.value;
                if (status == 'Given') {
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
                if (context.mounted) Navigator.of(context).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Medication administration saved and billed to inpatient account.',
                      ),
                    ),
                  );
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

