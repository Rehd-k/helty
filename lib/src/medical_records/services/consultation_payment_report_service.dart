import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/medical_records/models/consultation_payment_report_row.dart';
import 'package:helty/src/medical_records/utils/encounter_diagnosis_formatter.dart';
import 'package:helty/src/models/encounter_model.dart';
import 'package:helty/src/models/invoice.dart';
import 'package:helty/src/models/service_model.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_service.dart';
import 'package:helty/src/services/encounter_service.dart';
import 'package:helty/src/services/invoice_service.dart';

/// Fetches paid consultation payments in a date range and enriches with diagnosis when available.
class ConsultationPaymentReportService {
  ConsultationPaymentReportService({
    InvoiceService? invoiceService,
    EncounterService? encounterService,
    PatientService? patientService,
  })  : _invoiceService = invoiceService ?? InvoiceService(),
        _encounterService = encounterService ?? EncounterService(),
        _patientService = patientService ?? PatientService();

  final InvoiceService _invoiceService;
  final EncounterService _encounterService;
  final PatientService _patientService;

  static const _pageSize = 100;
  static const _encounterPageSize = 200;

  /// Matches [pay.bill] consultation detection and queue category naming.
  static bool isConsultationLineItem(ServiceModel item) {
    final cat = (item.categoryName ?? '').toLowerCase();
    final name = item.name.toLowerCase();
    return cat.contains('consultation') || name.contains('consultation');
  }

  static bool isPaidInvoice(Invoice invoice) {
    final status = invoice.status.toUpperCase();
    return status == 'PAID' ||
        (invoice.amountPaid > 0 &&
            invoice.totalAmount > 0 &&
            invoice.amountPaid >= invoice.totalAmount - 0.01);
  }

  static String patientDisplayName(Patient patient) {
    final parts = [
      patient.title.trim(),
      patient.firstName.trim(),
      patient.surname.trim(),
    ].where((s) => s.isNotEmpty);
    final name = parts.join(' ').trim();
    return name.isEmpty ? patient.patientId : name;
  }

  Future<List<ConsultationPaymentReportRow>> fetchReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final from = DateTime(fromDate.year, fromDate.month, fromDate.day, 0, 0, 0);
    final to = DateTime(
      toDate.year,
      toDate.month,
      toDate.day,
      23,
      59,
      59,
      999,
    );

    final consultationInvoices = await _fetchPaidConsultationInvoices(from, to);
    if (consultationInvoices.isEmpty) return const [];

    final encounterByPatient = await _loadEncounterIndex(from, to);
    final encounterById = <String, EncounterModel>{};
    for (final enc in encounterByPatient.values) {
      encounterById[enc.id] = enc;
    }

    final rowsByPatient = <String, ConsultationPaymentReportRow>{};
    final patientCache = <String, Patient>{};

    for (final invoice in consultationInvoices) {
      if (!_invoiceHasConsultationItem(invoice)) continue;
      if (!isPaidInvoice(invoice)) continue;

      final patientId = invoice.patientId.trim();
      if (patientId.isEmpty) continue;

      final paidAt = _invoicePaidAt(invoice);
      final existing = rowsByPatient[patientId];
      if (existing != null && !paidAt.isAfter(existing.paidAt)) {
        continue;
      }

      var patient = invoice.patient;
      if (_patientNeedsHydration(patient)) {
        patient = patientCache[patientId] ??
            await _patientService.getPatientById(patientId);
        patientCache[patientId] = patient;
      }

      final diagnosis = await _resolveDiagnosis(
        invoice: invoice,
        patientId: patientId,
        encounterById: encounterById,
        encounterByPatient: encounterByPatient,
      );

      rowsByPatient[patientId] = ConsultationPaymentReportRow(
        patientId: patientId,
        patientName: patientDisplayName(patient),
        ageLabel: DateFormatter.patientAgeFromDob(patient.dob),
        gender: patient.gender.trim().isEmpty ? '—' : patient.gender.trim(),
        diagnosis: diagnosis.isEmpty ? '—' : diagnosis,
        paidAt: paidAt,
        invoiceId: invoice.id,
        encounterId: invoice.encounterId,
      );
    }

    final rows = rowsByPatient.values.toList()
      ..sort((a, b) => b.paidAt.compareTo(a.paidAt));
    return rows;
  }

  bool _invoiceHasConsultationItem(Invoice invoice) {
    return invoice.invoiceItems.any(isConsultationLineItem);
  }

  DateTime _invoicePaidAt(Invoice invoice) {
    return invoice.updatedAt.isAfter(invoice.createdAt)
        ? invoice.updatedAt
        : invoice.createdAt;
  }

  bool _patientNeedsHydration(Patient patient) {
    return patient.firstName.trim().isEmpty || patient.gender.trim().isEmpty;
  }

  Future<List<Invoice>> _fetchPaidConsultationInvoices(
    DateTime from,
    DateTime to,
  ) async {
    final all = <Invoice>[];
    var page = 1;
    while (true) {
      final batch = await _invoiceService.getInvoices(
        status: 'PAID',
        from: from,
        to: to,
        page: page,
        limit: _pageSize,
        allowIP: true,
      );
      if (batch.isEmpty) break;
      all.addAll(batch);
      if (batch.length < _pageSize) break;
      page++;
      if (page > 50) break;
    }
    return all;
  }

  Future<Map<String, EncounterModel>> _loadEncounterIndex(
    DateTime from,
    DateTime to,
  ) async {
    final byPatient = <String, EncounterModel>{};
    var skip = 0;
    while (true) {
      final batch = await _encounterService.fetchOutpatientEncounters(
        fromDate: from,
        toDate: to,
        status: 'COMPLETED',
        skip: skip,
        take: _encounterPageSize,
      );
      if (batch.isEmpty) break;

      for (final enc in batch) {
        final pid = enc.patientId.trim();
        if (pid.isEmpty) continue;
        final closed = enc.closedAt ?? enc.startedAt;
        final current = byPatient[pid];
        if (current == null) {
          byPatient[pid] = enc;
          continue;
        }
        final currentClosed = current.closedAt ?? current.startedAt;
        if (closed.isAfter(currentClosed)) {
          byPatient[pid] = enc;
        }
      }

      if (batch.length < _encounterPageSize) break;
      skip += _encounterPageSize;
      if (skip > 5000) break;
    }
    return byPatient;
  }

  Future<String> _resolveDiagnosis({
    required Invoice invoice,
    required String patientId,
    required Map<String, EncounterModel> encounterById,
    required Map<String, EncounterModel> encounterByPatient,
  }) async {
    EncounterModel? encounter;

    final linkedId = invoice.encounterId?.trim();
    if (linkedId != null && linkedId.isNotEmpty) {
      encounter = encounterById[linkedId];
      encounter ??= await _encounterService.getById(linkedId);
      if (encounter != null) {
        encounterById[linkedId] = encounter;
      }
    }

    encounter ??= encounterByPatient[patientId];

    if (encounter == null) return '';
    return formatEncounterDiagnosis(encounter);
  }
}
