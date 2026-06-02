import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/medication_order_model.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_service.dart';
import 'package:helty/src/pharmacy/models/pharmacy_model.dart';
import 'package:helty/src/pharmacy/services/pharmacy_service.dart';
import 'package:helty/src/services/medication_order_service.dart';
import 'package:helty/src/widgets/date.filter.dart';

import '../models/pharmacy_queue_models.dart';
import '../services/pharmacy_queue_service.dart';
import '../widgets/prescription_drug_form_dialog.dart';

// -----------------------------------------------------------------------------
// MAIN UI – Pharmacy prescription queue (drugs sent on patients' behalf)
// -----------------------------------------------------------------------------

@RoutePage()
class WaitingPatientScreen extends StatefulWidget {
  const WaitingPatientScreen({super.key, this.queueService});

  /// Inject your API implementation when testing; defaults to [PharmacyQueueApiService].
  final IPharmacyQueueService? queueService;

  @override
  State<WaitingPatientScreen> createState() => _WaitingPatientScreenState();
}

class _WaitingPatientScreenState extends State<WaitingPatientScreen> {
  static const int _pageSize = 20;

  int _selectedTabIndex = 0;
  QueueOrder? _selectedOrder;
  List<QueueOrder> _orders = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  DateTime? _fromDate;
  DateTime? _toDate;
  int _totalFromServer = 0;
  bool _listExhausted = false;

  late final IPharmacyQueueService _queueService;
  final PatientService _patientService = PatientService();
  final PharmacyApiService _pharmacyApi = PharmacyApiService();
  final MedicationOrderService _medicationOrderService =
      MedicationOrderService();

  Patient? _detailPatient;
  bool _patientLoading = false;
  String? _patientError;
  List<PastMedication> _invoiceHistoryMeds = [];
  final Map<String, int> _stockByItemId = {};
  final List<PharmacyLocation> _dispensaryLocations = [];
  String? _selectedDispensaryId;
  bool _loadingDispensaryLocations = false;
  String? _dispensaryLoadError;

  @override
  void initState() {
    super.initState();
    _queueService = widget.queueService ?? PharmacyQueueApiService();
    _loadDispensaryLocations();
  }

  bool _isOrderCleared(QueueOrder order) {
    if (!invoiceStatusIsPaid(order.invoiceStatus)) return false;
    if (order.medications.isEmpty) return false;
    return order.medications.every((m) => m.isDispensed || m.settled);
  }

  bool _isOrderUncleared(QueueOrder order) {
    if (!invoiceStatusIsPaid(order.invoiceStatus)) return false;
    if (order.medications.isEmpty) return true;
    return order.medications.any((m) => !m.isDispensed && !m.settled);
  }

  List<QueueOrder> get _visibleOrders {
    switch (_selectedTabIndex) {
      case 1:
        return _orders.where(_isOrderCleared).toList();
      case 2:
        return _orders.where(_isOrderUncleared).toList();
      case 3:
        return _orders
            .where((o) => !invoiceStatusIsPaid(o.invoiceStatus))
            .toList();
      default:
        return List<QueueOrder>.from(_orders);
    }
  }

  int get _clearedCount => _orders.where(_isOrderCleared).length;
  int get _unclearedCount => _orders.where(_isOrderUncleared).length;
  int get _pendingCount =>
      _orders.where((o) => !invoiceStatusIsPaid(o.invoiceStatus)).length;

  int _effectiveStock(PrescribedMedication med) =>
      _stockByItemId[med.id] ?? med.stockAvailable;

  bool _medHasStock(PrescribedMedication med) =>
      _effectiveStock(med) >= med.quantity;

  bool get _selectedPatientIsInpatient {
    final ward = _detailPatient?.ward?.trim();
    if (ward == null || ward.isEmpty) return false;
    return ward.toUpperCase() != 'OPD';
  }

  bool _canDispense(QueueOrder order, PrescribedMedication med) =>
      _selectedDispensaryId != null &&
      (invoiceStatusIsPaid(order.invoiceStatus) ||
          _selectedPatientIsInpatient) &&
      _medHasStock(med) &&
      !med.isDispensed &&
      !med.settled &&
      (med.drugId != null && med.drugId!.isNotEmpty);

  Future<void> _loadDispensaryLocations() async {
    if (mounted) {
      setState(() {
        _loadingDispensaryLocations = true;
        _dispensaryLoadError = null;
      });
    }
    try {
      final page = await _pharmacyApi.getPharmacyLocations(
        const PharmacyQueryParams(
          pageSize: 100,
          filters: {'locationType': 'DISPENSARY'},
        ),
      );
      if (!mounted) return;
      final dispensaries = page.items
          .where((l) => l.type == PharmacyLocationType.DISPENSARY)
          .toList();
      setState(() {
        _dispensaryLocations
          ..clear()
          ..addAll(dispensaries);
        if (_selectedDispensaryId != null &&
            !_dispensaryLocations.any((l) => l.id == _selectedDispensaryId)) {
          _selectedDispensaryId = null;
        }
        _loadingDispensaryLocations = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dispensaryLocations.clear();
        _selectedDispensaryId = null;
        _loadingDispensaryLocations = false;
        _dispensaryLoadError = e.toString();
      });
    }
  }

  int _ageFromDob(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  String _medicationOrderDetailLine(MedicationOrderModel o) {
    final parts = <String>[
      if (o.dose != null && o.dose!.trim().isNotEmpty) o.dose!.trim(),
      if (o.frequency != null && o.frequency!.trim().isNotEmpty)
        o.frequency!.trim(),
      if (o.duration != null && o.duration!.trim().isNotEmpty)
        o.duration!.trim(),
      if (o.route != null && o.route!.trim().isNotEmpty) o.route!.trim(),
      if (o.quantity != null && o.quantity! > 0) 'Qty ${o.quantity}',
    ];
    return parts.join(' · ');
  }

  String _medicationOrderDateLine(MedicationOrderModel o) {
    final when = o.displayDateTime;
    final dateStr = when != null
        ? DateFormatter.medicalDate(when.toLocal())
        : '—';
    final status = o.status.trim();
    if (status.isEmpty) return dateStr;
    return '$dateStr · $status';
  }

  List<PastMedication> _pastMedsFromMedicationOrders(
    List<MedicationOrderModel> orders,
  ) {
    final sorted = List<MedicationOrderModel>.from(orders)
      ..sort((a, b) {
        final ta = a.displayDateTime;
        final tb = b.displayDateTime;
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });
    return sorted.map((o) {
      final detail = _medicationOrderDetailLine(o);
      return PastMedication(
        o.drugName,
        _medicationOrderDateLine(o),
        detail: detail.isEmpty ? null : detail,
        isDiscontinued:
            o.administrationStatus == MedicationAdministrationStatus.stopped,
      );
    }).toList();
  }

  Future<void> _loadStocksForOrder(QueueOrder order) async {
    final selectedLocationId = _selectedDispensaryId;
    for (final m in order.medications) {
      final did = m.drugId;
      if (did == null || did.isEmpty) continue;
      try {
        int q;
        if (selectedLocationId != null) {
          final quantities = await _pharmacyApi.getDrugLocationQuantities(
            did,
            locationId: selectedLocationId,
          );
          q = quantities.fold<int>(0, (sum, item) => sum + item.quantity);
        } else {
          final drug = await _pharmacyApi.getDrugById(
            did,
            'id,genericName,brandName,quantity',
          );
          q = drug.stock ?? drug.displayStock;
        }
        if (!mounted) return;
        setState(() {
          _stockByItemId[m.id] = q;
          m.stockAvailable = q;
        });
      } catch (_) {
        // Non-UUID mock ids or network errors: keep existing stock hint.
      }
    }
  }

  Future<void> _loadPatientSidebar(QueueOrder order) async {
    if (order.patient.id.isEmpty) {
      if (mounted) {
        setState(() {
          _patientLoading = false;
          _patientError = 'No patient id on this invoice';
          _detailPatient = null;
          _invoiceHistoryMeds = [];
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _patientLoading = true;
        _patientError = null;
      });
    }
    try {
      final p = await _patientService.getPatientById(
        order.patient.id,
        'id,surname,firstName,dob,gender,ward',
      );
      final orders = await _medicationOrderService.getByPatient(
        order.patient.id,
        take: 10,
      );
      final hist = _pastMedsFromMedicationOrders(orders);
      if (!mounted) return;
      setState(() {
        _detailPatient = p;
        _invoiceHistoryMeds = hist;
        _patientLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _patientError = e.toString();
        _patientLoading = false;
        _detailPatient = null;
        _invoiceHistoryMeds = [];
      });
    }
  }

  Future<void> _enrichSelectedOrder(QueueOrder order) async {
    _stockByItemId.removeWhere(
      (key, _) => !order.medications.any((m) => m.id == key),
    );
    await Future.wait<void>([
      _loadStocksForOrder(order),
      _loadPatientSidebar(order),
    ]);
  }

  Future<void> _refreshOrders({
    bool reset = true,
    DateTime? from,
    DateTime? to,
  }) async {
    final f = from ?? _fromDate;
    final t = to ?? _toDate;
    if (f == null || t == null) return;

    final prevId = _selectedOrder?.id;
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _listExhausted = false;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final page = await _queueService.listInvoiceDrugs(
        fromDate: f.toIso8601String(),
        toDate: t.toIso8601String(),
        skip: reset ? 0 : _orders.length,
        take: _pageSize,
      );
      if (!mounted) return;

      setState(() {
        _fromDate = f;
        _toDate = t;
        if (reset) {
          _orders = page.orders;
          _stockByItemId.clear();
          _detailPatient = null;
          _patientError = null;
          _invoiceHistoryMeds = [];
          QueueOrder? sel;
          if (prevId != null) {
            for (final o in _orders) {
              if (o.id == prevId) {
                sel = o;
                break;
              }
            }
          }
          _selectedOrder = sel ?? (_orders.isNotEmpty ? _orders.first : null);
        } else {
          _orders = [..._orders, ...page.orders];
        }
        _totalFromServer = page.total;
        final batchLen = page.orders.length;
        _listExhausted =
            batchLen < _pageSize || _orders.length >= _totalFromServer;
        _loading = false;
        _loadingMore = false;
      });

      final sel = _selectedOrder;
      if (reset && sel != null) await _enrichSelectedOrder(sel);
    } catch (e) {
      if (!mounted) return;
      if (reset) {
        setState(() {
          _error = e.toString();
          _loading = false;
          _loadingMore = false;
        });
      } else {
        setState(() {
          _loadingMore = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not load more: $e')));
        }
      }
    }
  }

  Future<void> _loadMore() async {
    if (_listExhausted || _loadingMore || _loading) return;
    await _refreshOrders(reset: false);
    if (mounted && _listExhausted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No more invoices in this date range')),
      );
    }
  }

  Future<void> _onSelectOrder(QueueOrder order) async {
    setState(() => _selectedOrder = order);
    await _enrichSelectedOrder(order);
  }

  Future<void> _dispenseMedication(
    QueueOrder order,
    PrescribedMedication med,
  ) async {
    if (!_canDispense(order, med)) return;
    final locationId = _selectedDispensaryId;
    if (locationId == null) return;
    final qty = med.quantity;
    try {
      final selectedStock = _effectiveStock(med);
      if (selectedStock < qty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Insufficient stock to dispense')),
          );
        }
        return;
      }
      await _queueService.updateInvoiceDrugItem(order.id, med.id, {
        'settled': true,
      }, locationId: locationId);
      final updated = await _queueService.getInvoiceDrug(order.id);
      if (!mounted) return;
      setState(() {
        final idx = _orders.indexWhere((o) => o.id == order.id);
        if (idx >= 0) _orders[idx] = updated;
        if (_selectedOrder?.id == order.id) _selectedOrder = updated;
      });
      await _loadStocksForOrder(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Dispensed ${med.name}')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Dispense failed: $e')));
      }
    }
  }

  String? _dispenseAuditSummary(PrescribedMedication med) {
    if (!med.isDispensed && !med.settled) return null;
    final parts = <String>[];
    if (med.dispensedAt != null) {
      parts.add(DateFormatter.dateTime(med.dispensedAt!.toLocal()));
    }
    final by = med.dispensedBy?.name;
    if (by != null && by.isNotEmpty) parts.add(by);
    final loc = med.dispensaryLocation?.name;
    if (loc != null && loc.isNotEmpty) parts.add(loc);
    if (parts.isEmpty) return null;
    return 'Dispensed: ${parts.join(' · ')}';
  }

  String _dispenseAuditTooltip(PrescribedMedication med) {
    return _dispenseAuditSummary(med) ?? 'Dispensed';
  }

  double _unitPriceFromDrug(Drug d) {
    final p = d.price;
    if (p != null && p > 0) return p;
    final prices = d.prices;
    if (prices != null && prices.isNotEmpty) return prices.first.price;
    return 0.0;
  }

  Future<void> _openSubstituteDialog(
    QueueOrder order,
    PrescribedMedication med,
  ) async {
    final form = await showPrescriptionDrugFormDialog(
      context,
      pharmacyApi: _pharmacyApi,
      mode: PrescriptionDrugFormMode.substitute,
      initial: PrescriptionDrugFormInitialValues.fromPrescribedLine(med),
      replacingLineName: med.name,
    );
    if (form == null || !mounted) return;
    await _substituteMedication(order, med, form);
  }

  Future<void> _substituteMedication(
    QueueOrder order,
    PrescribedMedication med,
    PrescriptionDrugFormResult form,
  ) async {
    final newDrugId = form.drug.id;
    if (newDrugId == null || newDrugId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected drug has no id')),
        );
      }
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Replacing line…')),
          ],
        ),
      ),
    );

    try {
      final fullDrug = await _pharmacyApi.getDrugById(newDrugId);
      final unitPrice = _unitPriceFromDrug(fullDrug);

      await _queueService.substituteInvoiceDrugItem(order.id, med.id, {
        'drugId': newDrugId,
        'unitPrice': unitPrice,
        'quantity': form.quantity,
      });

      final moId = med.medicationOrderId;
      if (moId != null && moId.isNotEmpty) {
        try {
          await _medicationOrderService.update(
            id: moId,
            drugId: newDrugId,
            drugName: form.drug.brandName,
            dose: form.dose,
            frequency: form.frequency,
            duration: form.duration,
            quantity: form.quantity,
            route: form.route,
            specialInstructions: form.specialInstructions,
          );
        } catch (_) {
          // Clinical chart may lag; invoice line is already substituted.
        }
      }

      final updated = await _queueService.getInvoiceDrug(order.id);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() {
        final idx = _orders.indexWhere((o) => o.id == order.id);
        if (idx >= 0) _orders[idx] = updated;
        if (_selectedOrder?.id == order.id) _selectedOrder = updated;
      });
      await _enrichSelectedOrder(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Substituted with ${form.drug.brandName} (qty ${form.quantity})',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not substitute: $e')));
      }
    }
  }

  Widget _buildMedicationTrailingActions(
    QueueOrder order,
    PrescribedMedication med,
  ) {
    if (med.isDispensed || med.settled) {
      return IconButton(
        onPressed: null,
        icon: const Icon(Icons.check, size: 20),
        tooltip: _dispenseAuditTooltip(med),
        style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
      );
    }

    final unpaid = !invoiceStatusIsPaid(order.invoiceStatus);
    final requiresPaymentBeforeDispense =
        unpaid && !_selectedPatientIsInpatient;
    final hasDrug = med.drugId != null && med.drugId!.isNotEmpty;
    final hasLocation = _selectedDispensaryId != null;
    final oos = !_medHasStock(med);

    if (!hasDrug) {
      return IconButton(
        onPressed: null,
        icon: const Icon(Icons.link_off, size: 20),
        tooltip: 'No drug id for this line',
        style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
      );
    }

    if (!hasLocation) {
      return IconButton(
        onPressed: null,
        icon: const Icon(Icons.location_off, size: 20),
        tooltip: 'Select dispensary location before dispense',
        style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
      );
    }

    if (oos) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (requiresPaymentBeforeDispense)
            IconButton(
              onPressed: null,
              icon: const Icon(Icons.lock_outline, size: 20),
              tooltip: 'Invoice must be paid before dispense',
              style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          IconButton(
            onPressed: null,
            icon: const Icon(Icons.block, size: 20),
            tooltip: 'Out of stock',
            style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
          if (hasDrug)
            IconButton(
              onPressed: () => _openSubstituteDialog(order, med),
              icon: const Icon(Icons.sync_alt, size: 18),
              tooltip: 'Suggest alternative',
              style: IconButton.styleFrom(
                foregroundColor: Colors.orange,
                visualDensity: VisualDensity.compact,
              ),
            )
          else
            IconButton(
              onPressed: null,
              icon: const Icon(Icons.link_off, size: 20),
              tooltip: 'No drug id for this line',
              style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
        ],
      );
    }

    if (requiresPaymentBeforeDispense) {
      return IconButton(
        onPressed: null,
        icon: const Icon(Icons.lock_outline, size: 20),
        tooltip: 'Invoice must be paid before dispense',
        style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
      );
    }

    return IconButton.filled(
      onPressed: () => _dispenseMedication(order, med),
      icon: const Icon(Icons.vaccines, size: 20),
      tooltip: 'Dispense',
      style: IconButton.styleFrom(
        backgroundColor: Colors.greenAccent.shade400,
        foregroundColor: Colors.black87,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  PharmacyQueuePatient _sidebarPatient(QueueOrder order) {
    final p = _detailPatient;
    if (p == null) {
      return order.patient;
    }
    final name = '${p.surname}, ${p.firstName}'.trim();
    final allergies = p.allergies
        .map((a) => Allergy(a.name, a.isSevere))
        .toList();
    final history = _invoiceHistoryMeds;
    return PharmacyQueuePatient(
      id: p.id ?? order.patient.id,
      name: name.isNotEmpty ? name : order.patient.name,
      gender: p.gender,
      age: _ageFromDob(p.dob),
      weight: '—',
      height: '—',
      allergies: allergies,
      history: history,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    flex: 0,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 200,
                        maxWidth: 280,
                      ),
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
                        : _buildPrescriptionDetails(
                            _selectedOrder!,
                            colorScheme,
                          ),
                  ),
                  Flexible(
                    flex: 0,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 180,
                        maxWidth: 260,
                      ),
                      child: _selectedOrder == null
                          ? const SizedBox.shrink()
                          : _buildPatientSidebar(_selectedOrder!, colorScheme),
                    ),
                  ),
                ],
              ),
            ),
            FromToDateFilter(
              doRefresh: () {},
              dateFilter: true,
              labelStyle: DateFilterLabelStyle.shortUs,
              onFilterChanged: (query, category, from, to) {
                setState(() {
                  _fromDate = from;
                  _toDate = to;
                  _selectedTabIndex = 0;
                });
                _refreshOrders(reset: true, from: from, to: to);
              },
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
                'Paid vs pending payment',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
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
              _buildTab('Cleared ($_clearedCount)', 1, colorScheme),
              const SizedBox(width: 8),
              _buildTab('Uncleared ($_unclearedCount)', 2, colorScheme),
              const SizedBox(width: 8),
              _buildTab('Pending ($_pendingCount)', 3, colorScheme),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        Expanded(child: _buildQueueScrollable(colorScheme)),
      ],
    );
  }

  Widget _buildQueueScrollable(ColorScheme colorScheme) {
    if (_loading && _orders.isEmpty && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.error, fontSize: 11),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _refreshOrders(reset: true),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (!_loading && _orders.isEmpty) {
      return Center(
        child: Text(
          'No invoices in this range',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      );
    }
    if (!_loading && _orders.isNotEmpty && _visibleOrders.isEmpty) {
      return Center(
        child: Text(
          'Nothing in this tab',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    final tiles = <Widget>[];
    for (var i = 0; i < _visibleOrders.length; i++) {
      final order = _visibleOrders[i];
      if (i > 0) {
        tiles.add(
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        );
      }
      tiles.add(_buildQueueOrderTile(order, colorScheme));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        ...tiles,
        if (_loadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        if (!_listExhausted && _orders.isNotEmpty && !_loadingMore)
          TextButton(onPressed: _loadMore, child: const Text('Load more')),
        if (_listExhausted && _orders.isNotEmpty && !_loadingMore)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              'All invoices loaded for this range',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQueueOrderTile(QueueOrder order, ColorScheme colorScheme) {
    final isSelected = _selectedOrder?.id == order.id;
    final relative = DateFormatter.relativeTimeAgo(order.timestamp.toLocal());

    return InkWell(
      onTap: () => _onSelectOrder(order),
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
                _buildInvoiceStatusBadge(order.invoiceStatus, colorScheme),
                Text(
                  relative,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              order.patient.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              order.department.isNotEmpty
                  ? '${order.doctorDisplayName} · ${order.department}'
                  : order.doctorDisplayName,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
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
  }

  Widget _buildTab(String title, int index, ColorScheme colorScheme) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        QueueOrder? toEnrich;
        setState(() {
          _selectedTabIndex = index;
          final visible = _visibleOrders;
          if (_selectedOrder != null &&
              !visible.any((o) => o.id == _selectedOrder!.id)) {
            _selectedOrder = visible.isNotEmpty ? visible.first : null;
          }
          toEnrich = _selectedOrder;
        });
        if (toEnrich != null) _enrichSelectedOrder(toEnrich!);
      },
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
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceStatusBadge(String status, ColorScheme colorScheme) {
    final paid = invoiceStatusIsPaid(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: paid
            ? Colors.green.withValues(alpha: 0.2)
            : colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.isEmpty ? '—' : status.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: paid
              ? Colors.green.shade800
              : colorScheme.onSecondaryContainer,
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
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
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
                  ],
                ),
                const SizedBox(height: 8),
                if (_loadingDispensaryLocations)
                  Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loading dispensaries...',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDispensaryId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Dispensary location',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    items: _dispensaryLocations
                        .where((l) => l.id != null && l.id!.isNotEmpty)
                        .map(
                          (location) => DropdownMenuItem<String>(
                            value: location.id!,
                            child: Text(
                              location.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDispensaryId = value;
                      });
                      if (_selectedOrder != null) {
                        _enrichSelectedOrder(_selectedOrder!);
                      }
                    },
                  ),
                  if (_dispensaryLoadError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _dispensaryLoadError!,
                      style: TextStyle(fontSize: 10, color: colorScheme.error),
                    ),
                  ],
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormatter.dateTime(order.timestamp.toLocal()),
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.person,
                      size: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.department.isNotEmpty
                            ? '${order.doctorDisplayName} (${order.department})'
                            : order.doctorDisplayName,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
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
                      color: colorScheme.secondaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colorScheme.secondaryContainer),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notes,
                              size: 14,
                              color: colorScheme.onSecondaryContainer,
                            ),
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
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          ...order.medications.map(
            (med) => _buildMedicationCard(order, med, colorScheme),
          ),
          if (order.medications.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Medications total',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    order.medicationsSubtotal.toFinancial(isMoney: true),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicationCard(
    QueueOrder order,
    PrescribedMedication med,
    ColorScheme colorScheme,
  ) {
    final borderColor = _medHasStock(med) ? Colors.green : Colors.deepOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
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
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(6),
                        ),
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
                              _buildQtyRemainingBadge(med, colorScheme),
                            ],
                          ),
                          if (med.createdByDisplayName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Prescribed by: ${med.createdByDisplayName}',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            '${med.unitPrice.toFinancial(isMoney: true)} × ${med.quantity} = ${med.lineTotal.toFinancial(isMoney: true)}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (narrow)
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                _buildMedChip('Dose', med.dosage, colorScheme),
                                _buildMedChip(
                                  'Freq',
                                  med.frequency.replaceAll('\n', ' '),
                                  colorScheme,
                                ),
                                _buildMedChip('Dur', med.duration, colorScheme),
                                _buildMedChip('Route', med.route, colorScheme),
                                _buildMedChip(
                                  'Qty',
                                  '${med.quantity}',
                                  colorScheme,
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                _buildMedDetailColumn(
                                  'DOSE',
                                  med.dosage,
                                  colorScheme,
                                ),
                                _buildMedDetailColumn(
                                  'FREQ',
                                  med.frequency.replaceAll('\n', ' '),
                                  colorScheme,
                                ),
                                _buildMedDetailColumn(
                                  'DUR',
                                  med.duration,
                                  colorScheme,
                                ),
                                _buildMedDetailColumn(
                                  'ROUTE',
                                  med.route,
                                  colorScheme,
                                ),
                                _buildMedDetailColumn(
                                  'QTY',
                                  '${med.quantity}',
                                  colorScheme,
                                ),
                              ],
                            ),
                          if (_dispenseAuditSummary(med)
                              case final summary?) ...[
                            const SizedBox(height: 8),
                            Text(
                              summary,
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildMedicationTrailingActions(order, med),
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

  Widget _buildQtyRemainingBadge(
    PrescribedMedication med,
    ColorScheme colorScheme,
  ) {
    if (_selectedDispensaryId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Qty remaining',
            style: TextStyle(
              fontSize: 8,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Text(
              '--',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }

    final rem = _effectiveStock(med);
    final ok = _medHasStock(med);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Qty remaining',
          style: TextStyle(
            fontSize: 8,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: ok
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ok ? Colors.green : Colors.red),
          ),
          child: Text(
            '$rem',
            style: TextStyle(
              color: ok ? Colors.green.shade800 : Colors.red,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedDetailColumn(
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
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

  Widget _buildPatientSidebar(QueueOrder order, ColorScheme colorScheme) {
    final patient = _sidebarPatient(order);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_patientLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading patient…',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          if (_patientError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _patientError!,
                style: TextStyle(fontSize: 10, color: colorScheme.error),
              ),
            ),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${patient.id} • ${patient.gender.isEmpty ? '—' : patient.gender} • ${patient.age}y',
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
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weight',
                        style: TextStyle(
                          fontSize: 9,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        patient.weight,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Height',
                        style: TextStyle(
                          fontSize: 9,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        patient.height,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
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
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: patient.allergies.map((a) {
                final isSevere = a.isSevere;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSevere
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    border: Border.all(
                      color: isSevere
                          ? Colors.red.withValues(alpha: 0.5)
                          : Colors.orange.withValues(alpha: 0.5),
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
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.amber.shade800,
                            height: 1.3,
                          ),
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
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
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
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (h.detail != null && h.detail!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        h.detail!,
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      '${h.date}${h.isDiscontinued ? ' • Discontinued' : ''}',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
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
