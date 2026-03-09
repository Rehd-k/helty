import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../models/pharmacy_queue_models.dart';
import '../services/pharmacy_queue_service.dart';

// -----------------------------------------------------------------------------
// MAIN UI – Pharmacy prescription queue (drugs sent on patients' behalf)
// -----------------------------------------------------------------------------

@RoutePage()
class WaitingPatientScreen extends StatefulWidget {
  const WaitingPatientScreen({
    super.key,
    this.queueService,
  });

  /// Inject your API implementation when ready; defaults to [MockPharmacyQueueService].
  final IPharmacyQueueService? queueService;

  @override
  State<WaitingPatientScreen> createState() => _WaitingPatientScreenState();
}

class _WaitingPatientScreenState extends State<WaitingPatientScreen> {
  int _selectedTabIndex = 0;
  QueueOrder? _selectedOrder;
  List<QueueOrder> _orders = [];
  bool _loading = true;
  String? _error;

  late final IPharmacyQueueService _queueService;

  @override
  void initState() {
    super.initState();
    _queueService = widget.queueService ?? MockPharmacyQueueService();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await _queueService.getQueueOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _selectedOrder = orders.isNotEmpty ? orders.first : null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _dispenseMedication(PrescribedMedication med) {
    setState(() => med.isDispensed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dispensed ${med.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorScheme.error, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _loadOrders,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        flex: 0,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
                          child: _buildQueueList(colorScheme),
                        ),
                      ),
                      Expanded(
                        child: _selectedOrder == null
                            ? Center(
                                child: Text(
                                  'Select an order',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : _buildPrescriptionDetails(_selectedOrder!, colorScheme),
                      ),
                      Flexible(
                        flex: 0,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
                          child: _selectedOrder == null
                              ? const SizedBox.shrink()
                              : _buildPatientSidebar(_selectedOrder!.patient, colorScheme),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildQueueList(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prescription Queue',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Sorted by urgency & time',
                style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _buildTab('All (${_orders.length})', 0, colorScheme),
              const SizedBox(width: 8),
              _buildTab(
                'Urgent (${_orders.where((o) => o.urgency == UrgencyLevel.urgent).length})',
                1,
                colorScheme,
              ),
              const SizedBox(width: 8),
              _buildTab(
                'Waiting (${_orders.where((o) => o.urgency != UrgencyLevel.urgent).length})',
                2,
                colorScheme,
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        Expanded(
          child: ListView.separated(
            itemCount: _orders.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
            itemBuilder: (context, index) {
              final order = _orders[index];
              final isSelected = _selectedOrder?.id == order.id;
              final timeAgo = DateTime.now().difference(order.timestamp).inMinutes;

              return InkWell(
                onTap: () => setState(() => _selectedOrder = order),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primaryContainer.withValues(alpha: 0.15)
                        : Colors.transparent,
                    border: Border(
                      left: BorderSide(
                        color: isSelected ? colorScheme.primary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildUrgencyBadge(order.urgency, colorScheme),
                          Text(
                            '$timeAgo m',
                            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.patient.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${order.doctorName} • ${order.department}',
                        style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.medSummary,
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurface),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String title, int index, ColorScheme colorScheme) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildUrgencyBadge(UrgencyLevel urgency, ColorScheme colorScheme) {
    final isUrgent = urgency == UrgencyLevel.urgent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isUrgent ? 'Urgent' : 'Standard',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isUrgent ? Colors.red : Colors.orange,
        ),
      ),
    );
  }

  Widget _buildPrescriptionDetails(QueueOrder order, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '#${order.id}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.print, size: 20),
                      tooltip: 'Print label',
                      style: IconButton.styleFrom(
                        foregroundColor: colorScheme.onSurface,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(order.timestamp),
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.person, size: 12, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${order.doctorName} (${order.department})',
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (order.doctorNotes != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colorScheme.secondaryContainer),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notes, size: 14, color: colorScheme.onSecondaryContainer),
                            const SizedBox(width: 6),
                            Text(
                              "Doctor's Notes",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.doctorNotes!,
                          style: TextStyle(
                            height: 1.4,
                            fontSize: 11,
                            color: colorScheme.onSecondaryContainer,
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Prescribed Medications',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 10),
          ...order.medications.map((med) => _buildMedicationCard(med, colorScheme)),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime t) {
    return '${t.day}/${t.month}/${t.year} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMedicationCard(PrescribedMedication med, ColorScheme colorScheme) {
    final borderColor = med.inStock ? Colors.green : Colors.deepOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 400;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  med.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStockBadge(med, colorScheme),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (narrow)
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                _buildMedChip('Dose', med.dosage, colorScheme),
                                _buildMedChip('Freq', med.frequency.replaceAll('\n', ' '), colorScheme),
                                _buildMedChip('Dur', med.duration, colorScheme),
                                _buildMedChip('Qty', '${med.quantity}', colorScheme),
                              ],
                            )
                          else
                            Row(
                              children: [
                                _buildMedDetailColumn('DOSE', med.dosage, colorScheme),
                                _buildMedDetailColumn('FREQ', med.frequency.replaceAll('\n', ' '), colorScheme),
                                _buildMedDetailColumn('DUR', med.duration, colorScheme),
                                _buildMedDetailColumn('QTY', '${med.quantity}', colorScheme),
                              ],
                            ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (med.inStock)
                                IconButton.filled(
                                  onPressed: med.isDispensed
                                      ? null
                                      : () => _dispenseMedication(med),
                                  icon: Icon(
                                    med.isDispensed ? Icons.check : Icons.vaccines,
                                    size: 20,
                                  ),
                                  tooltip: med.isDispensed ? 'Dispensed' : 'Dispense',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.greenAccent.shade400,
                                    foregroundColor: Colors.black87,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                              else
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: null,
                                      icon: const Icon(Icons.block, size: 20),
                                      tooltip: 'Out of stock',
                                      style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                                    ),
                                    IconButton(
                                      onPressed: () {},
                                      icon: const Icon(Icons.sync_alt, size: 18),
                                      tooltip: 'Suggest alternative',
                                      style: IconButton.styleFrom(
                                        foregroundColor: Colors.orange,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ],
                );
              },
            ),
          ),
    );
  }

  Widget _buildMedChip(String label, String value, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 10, color: colorScheme.onSurface),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStockBadge(PrescribedMedication med, ColorScheme colorScheme) {
    if (med.inStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 10),
            const SizedBox(width: 4),
            Text(
              '${med.stockAvailable}',
              style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning, color: Colors.red, size: 10),
          SizedBox(width: 4),
          Text(
            'Out',
            style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMedDetailColumn(String label, String value, ColorScheme colorScheme) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 11, height: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPatientSidebar(PharmacyQueuePatient patient, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(Icons.person, size: 18, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${patient.id} • ${patient.gender} • ${patient.age}y',
                      style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weight',
                        style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        patient.weight,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Height',
                        style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        patient.height,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.warning, color: colorScheme.error, size: 14),
              const SizedBox(width: 6),
              Text(
                'ALLERGIES',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  letterSpacing: 0.5,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (patient.allergies.isEmpty)
            Text(
              'None',
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: patient.allergies.map((a) {
                final isSevere = a.isSevere;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSevere
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    border: Border.all(
                      color: isSevere ? Colors.red.withValues(alpha: 0.5) : Colors.orange.withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${a.name} (${isSevere ? 'Severe' : 'Mild'})',
                    style: TextStyle(
                      fontSize: 10,
                      color: isSevere ? Colors.redAccent : Colors.orangeAccent,
                    ),
                  ),
                );
              }).toList(),
            ),
          if (patient.interactionWarning != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Interaction',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          patient.interactionWarning!,
                          style: TextStyle(fontSize: 10, color: Colors.amber.shade800, height: 1.3),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Divider(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.history, color: colorScheme.onSurface, size: 14),
              const SizedBox(width: 6),
              Text(
                'RECENT MEDS',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  letterSpacing: 0.5,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (patient.history.isEmpty)
            Text(
              'None',
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
            )
          else
            ...patient.history.map(
              (h) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.name,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${h.date}${h.isDiscontinued ? ' • Discontinued' : ''}',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View history',
                style: TextStyle(fontSize: 11, color: colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
