import 'package:helty/src/models/staff_attribution.dart';

enum MedicationRequestStatus {
  requested,
  billed,
  dispensed,
  cancelled,
}

extension MedicationRequestStatusX on MedicationRequestStatus {
  String get apiValue {
    switch (this) {
      case MedicationRequestStatus.requested:
        return 'REQUESTED';
      case MedicationRequestStatus.billed:
        return 'BILLED';
      case MedicationRequestStatus.dispensed:
        return 'DISPENSED';
      case MedicationRequestStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get label {
    switch (this) {
      case MedicationRequestStatus.requested:
        return 'Requested';
      case MedicationRequestStatus.billed:
        return 'Billed';
      case MedicationRequestStatus.dispensed:
        return 'Dispensed';
      case MedicationRequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  static MedicationRequestStatus fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'BILLED':
        return MedicationRequestStatus.billed;
      case 'DISPENSED':
        return MedicationRequestStatus.dispensed;
      case 'CANCELLED':
        return MedicationRequestStatus.cancelled;
      case 'REQUESTED':
      default:
        return MedicationRequestStatus.requested;
    }
  }
}

class MedicationRequestStaffRef {
  const MedicationRequestStaffRef({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;

  factory MedicationRequestStaffRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const MedicationRequestStaffRef(id: '', displayName: '');
    }
    return MedicationRequestStaffRef(
      id: json['id']?.toString() ?? '',
      displayName: staffDisplayNameFromJson(json),
    );
  }
}

class MedicationRequestDrugRef {
  const MedicationRequestDrugRef({
    required this.id,
    required this.displayName,
    this.genericName,
    this.brandName,
  });

  final String id;
  final String displayName;
  final String? genericName;
  final String? brandName;

  factory MedicationRequestDrugRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const MedicationRequestDrugRef(id: '', displayName: '');
    }
    final generic = json['genericName']?.toString().trim() ?? '';
    final brand = json['brandName']?.toString().trim() ?? '';
    String display;
    if (generic.isNotEmpty && brand.isNotEmpty && generic != brand) {
      display = '$generic ($brand)';
    } else {
      display = generic.isNotEmpty ? generic : brand;
    }
    return MedicationRequestDrugRef(
      id: json['id']?.toString() ?? '',
      displayName: display.isNotEmpty ? display : '—',
      genericName: generic.isEmpty ? null : generic,
      brandName: brand.isEmpty ? null : brand,
    );
  }
}

class MedicationRequestInvoiceItemRef {
  const MedicationRequestInvoiceItemRef({
    required this.id,
    this.invoiceId,
    this.settled = false,
    this.amountPaid = 0,
    this.allocationCount = 0,
    this.invoiceStatus,
  });

  final String id;
  final String? invoiceId;
  final bool settled;
  final double amountPaid;
  final int allocationCount;
  final String? invoiceStatus;

  factory MedicationRequestInvoiceItemRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const MedicationRequestInvoiceItemRef(id: '');
    }
    final countRaw = json['_count'];
    final countMap = countRaw is Map ? Map<String, dynamic>.from(countRaw) : null;
    final allocations = countMap?['allocations'];
    final invoiceRaw = json['invoice'];
    final invoiceMap =
        invoiceRaw is Map ? Map<String, dynamic>.from(invoiceRaw) : null;
    final amountPaidRaw = json['amountPaid'];
    return MedicationRequestInvoiceItemRef(
      id: json['id']?.toString() ?? '',
      invoiceId:
          json['invoiceId']?.toString() ?? invoiceMap?['id']?.toString(),
      settled: json['settled'] as bool? ?? false,
      amountPaid: amountPaidRaw is num
          ? amountPaidRaw.toDouble()
          : double.tryParse(amountPaidRaw?.toString() ?? '') ?? 0,
      allocationCount: allocations is num
          ? allocations.toInt()
          : int.tryParse(allocations?.toString() ?? '') ?? 0,
      invoiceStatus: invoiceMap?['status']?.toString(),
    );
  }
}

class MedicationRequestPatientRef {
  const MedicationRequestPatientRef({
    required this.id,
    required this.firstName,
    required this.surname,
    this.hospitalNumber,
  });

  final String id;
  final String firstName;
  final String surname;
  final String? hospitalNumber;

  String get displayName =>
      [firstName, surname].where((s) => s.trim().isNotEmpty).join(' ');

  factory MedicationRequestPatientRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const MedicationRequestPatientRef(id: '', firstName: '', surname: '');
    }
    return MedicationRequestPatientRef(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      surname: json['surname']?.toString() ??
          json['lastName']?.toString() ??
          '',
      hospitalNumber: json['patientId']?.toString(),
    );
  }
}

class MedicationRequestEncounterRef {
  const MedicationRequestEncounterRef({
    required this.id,
    this.encounterType,
  });

  final String id;
  final String? encounterType;

  factory MedicationRequestEncounterRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const MedicationRequestEncounterRef(id: '');
    }
    return MedicationRequestEncounterRef(
      id: json['id']?.toString() ?? '',
      encounterType: json['encounterType']?.toString(),
    );
  }

  bool get isOpd {
    final t = encounterType?.trim().toUpperCase() ?? '';
    return t == 'OPD' || t.contains('OUTPATIENT');
  }
}

/// Summary of parent medication order embedded on pharmacy queue rows.
class MedicationRequestOrderSummary {
  const MedicationRequestOrderSummary({
    required this.id,
    required this.drugName,
    this.drugId,
    this.dose,
    this.frequency,
    this.route,
    this.genericName,
    this.doctor,
    this.encounterId,
    this.prescribedDrugName,
    this.prescribedDrugId,
    this.prescribedDrug,
    this.drug,
    this.substitutedByPharmacist,
    this.substitutedAt,
  });

  final String id;
  final String drugName;
  final String? drugId;
  final String? dose;
  final String? frequency;
  final String? route;
  final String? genericName;
  final MedicationRequestStaffRef? doctor;
  final String? encounterId;
  final String? prescribedDrugName;
  final String? prescribedDrugId;
  final MedicationRequestDrugRef? prescribedDrug;
  final MedicationRequestDrugRef? drug;
  final MedicationRequestStaffRef? substitutedByPharmacist;
  final DateTime? substitutedAt;

  bool get wasSubstituted =>
      substitutedByPharmacist != null ||
      (prescribedDrugId != null &&
          prescribedDrugId!.isNotEmpty &&
          drugId != null &&
          prescribedDrugId != drugId);

  String get prescribedDrugLabel =>
      prescribedDrugName?.trim().isNotEmpty == true
      ? prescribedDrugName!.trim()
      : (prescribedDrug?.displayName.trim().isNotEmpty == true
            ? prescribedDrug!.displayName
            : drugName);

  String get currentDrugLabel {
    final fromDrug = drug?.displayName.trim();
    if (fromDrug != null && fromDrug.isNotEmpty) return fromDrug;
    final generic = genericName?.trim();
    if (generic != null &&
        generic.isNotEmpty &&
        generic != drugName.trim()) {
      return '${drugName.trim()} ($generic)';
    }
    return drugName;
  }

  factory MedicationRequestOrderSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const MedicationRequestOrderSummary(id: '', drugName: '');
    }
    final drugRaw = json['drug'];
    final drugMap = drugRaw is Map ? Map<String, dynamic>.from(drugRaw) : null;
    final prescribedDrugRaw = json['prescribedDrug'];
    final prescribedDrugMap = prescribedDrugRaw is Map
        ? Map<String, dynamic>.from(prescribedDrugRaw)
        : null;
    final doctorRaw = json['doctor'];
    final substitutedRaw = json['substitutedByPharmacist'];
    return MedicationRequestOrderSummary(
      id: json['id']?.toString() ?? '',
      drugName: json['drugName']?.toString() ??
          drugMap?['brandName']?.toString() ??
          '',
      drugId: json['drugId']?.toString() ?? drugMap?['id']?.toString(),
      dose: json['dose']?.toString(),
      frequency: json['frequency']?.toString(),
      route: json['route']?.toString(),
      genericName: drugMap?['genericName']?.toString(),
      doctor: doctorRaw is Map<String, dynamic>
          ? MedicationRequestStaffRef.fromJson(doctorRaw)
          : null,
      encounterId: json['encounterId']?.toString(),
      prescribedDrugName: json['prescribedDrugName']?.toString(),
      prescribedDrugId: json['prescribedDrugId']?.toString() ??
          prescribedDrugMap?['id']?.toString(),
      prescribedDrug: prescribedDrugMap != null
          ? MedicationRequestDrugRef.fromJson(prescribedDrugMap)
          : null,
      drug: drugMap != null ? MedicationRequestDrugRef.fromJson(drugMap) : null,
      substitutedByPharmacist: substitutedRaw is Map<String, dynamic>
          ? MedicationRequestStaffRef.fromJson(substitutedRaw)
          : null,
      substitutedAt: DateTime.tryParse(
        json['substitutedAt']?.toString() ?? '',
      ),
    );
  }
}

class MedicationRequestModel {
  const MedicationRequestModel({
    required this.id,
    required this.medicationOrderId,
    required this.requestedQuantity,
    required this.status,
    this.notes,
    this.createdAt,
    this.requestedByNurse,
    this.invoiceItem,
    this.medicationOrder,
    this.patient,
    this.encounter,
  });

  final String id;
  final String medicationOrderId;
  final int requestedQuantity;
  final MedicationRequestStatus status;
  final String? notes;
  final DateTime? createdAt;
  final MedicationRequestStaffRef? requestedByNurse;
  final MedicationRequestInvoiceItemRef? invoiceItem;
  final MedicationRequestOrderSummary? medicationOrder;
  final MedicationRequestPatientRef? patient;
  final MedicationRequestEncounterRef? encounter;

  bool get isRequested => status == MedicationRequestStatus.requested;

  String? get encounterId =>
      encounter?.id ?? medicationOrder?.encounterId;

  bool canCancelAsNurse(String currentStaffId) {
    if (!isRequested) return false;
    if (currentStaffId.isEmpty) return false;
    final nurseId = requestedByNurse?.id.trim() ?? '';
    return nurseId.isNotEmpty && nurseId == currentStaffId;
  }

  bool get isOpdEncounter => encounter?.isOpd ?? false;

  factory MedicationRequestModel.fromJson(Map<String, dynamic> json) {
    final qtyRaw = json['requestedQuantity'] ?? json['quantity'];
    final qty = qtyRaw is num
        ? qtyRaw.toInt()
        : int.tryParse(qtyRaw?.toString() ?? '') ?? 0;

    Map<String, dynamic>? map(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : null;

    final nurseRaw = map(json['requestedByNurse']) ??
        map(json['requestedBy']) ??
        map(json['nurse']);
    final invoiceRaw = map(json['invoiceItem']);
    final orderRaw = map(json['medicationOrder']);
    final patientRaw = map(json['patient']);
    final encounterRaw = map(json['encounter']);

    return MedicationRequestModel(
      id: json['id']?.toString() ?? '',
      medicationOrderId: json['medicationOrderId']?.toString() ??
          orderRaw?['id']?.toString() ??
          '',
      requestedQuantity: qty,
      status: MedicationRequestStatusX.fromApi(json['status']?.toString()),
      notes: json['notes']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      requestedByNurse: nurseRaw != null
          ? MedicationRequestStaffRef.fromJson(nurseRaw)
          : null,
      invoiceItem: invoiceRaw != null
          ? MedicationRequestInvoiceItemRef.fromJson(invoiceRaw)
          : null,
      medicationOrder: orderRaw != null
          ? MedicationRequestOrderSummary.fromJson(orderRaw)
          : null,
      patient: patientRaw != null
          ? MedicationRequestPatientRef.fromJson(patientRaw)
          : null,
      encounter: encounterRaw != null
          ? MedicationRequestEncounterRef.fromJson(encounterRaw)
          : null,
    );
  }
}

class MedicationRequestBillInvoiceRef {
  const MedicationRequestBillInvoiceRef({
    required this.id,
    this.invoiceDisplayId,
    this.status,
  });

  final String id;
  final String? invoiceDisplayId;
  final String? status;

  factory MedicationRequestBillInvoiceRef.fromJson(Map<String, dynamic> json) {
    return MedicationRequestBillInvoiceRef(
      id: json['id']?.toString() ?? '',
      invoiceDisplayId: json['invoiceID']?.toString() ??
          json['invoiceId']?.toString(),
      status: json['status']?.toString(),
    );
  }
}

class MedicationRequestBillResult {
  const MedicationRequestBillResult({
    required this.invoice,
    required this.billedRequests,
  });

  final MedicationRequestBillInvoiceRef invoice;
  final List<MedicationRequestModel> billedRequests;

  factory MedicationRequestBillResult.fromJson(Map<String, dynamic> json) {
    final invoiceRaw = json['invoice'];
    final invoiceMap = invoiceRaw is Map<String, dynamic>
        ? invoiceRaw
        : <String, dynamic>{};

    final billedRaw = json['billedRequests'];
    final billedList = billedRaw is List
        ? billedRaw
            .whereType<Map>()
            .map((e) => MedicationRequestModel.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <MedicationRequestModel>[];

    return MedicationRequestBillResult(
      invoice: MedicationRequestBillInvoiceRef.fromJson(invoiceMap),
      billedRequests: billedList,
    );
  }
}

class MedicationRequestListPage {
  const MedicationRequestListPage({
    required this.requests,
    required this.total,
  });

  final List<MedicationRequestModel> requests;
  final int total;
}

class MedicationOrderInvoiceItemRef {
  const MedicationOrderInvoiceItemRef({
    required this.id,
    this.invoiceId,
  });

  final String id;
  final String? invoiceId;

  factory MedicationOrderInvoiceItemRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const MedicationOrderInvoiceItemRef(id: '');
    }
    return MedicationOrderInvoiceItemRef(
      id: json['id']?.toString() ?? '',
      invoiceId: json['invoiceId']?.toString(),
    );
  }

  bool get isPresent => id.isNotEmpty;
}
