// Models for the pharmacy prescription queue (drugs sent to pharmacy on behalf of patients).

enum UrgencyLevel { urgent, standard, waiting }

/// Body for `POST /invoice-drugs/:id/items/:itemId/return`.
class ReturnDrugInvoiceItemDto {
  const ReturnDrugInvoiceItemDto({required this.quantity, this.reason});

  final int quantity;
  final String? reason;

  Map<String, dynamic> toJson() {
    final r = reason?.trim();
    return {
      'quantity': quantity,
      if (r != null && r.isNotEmpty) 'reason': r,
    };
  }
}

class PrescribedMedication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final int quantity;
  /// Pharmacy inventory count (loaded via [PharmacyApiService.getDrugById]).
  int stockAvailable;
  bool isDispensed;
  final String? drugId;
  final bool settled;
  /// When the API links an invoice line to a clinical order (optional).
  final String? medicationOrderId;

  PrescribedMedication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.quantity,
    this.stockAvailable = 0,
    this.isDispensed = false,
    this.drugId,
    this.settled = false,
    this.medicationOrderId,
  });

  /// Enough stock to dispense the prescribed line quantity.
  bool get inStock => stockAvailable >= quantity;

  factory PrescribedMedication.fromJson(Map<String, dynamic> json) {
    return PrescribedMedication(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      quantity: _parseInt(json['quantity']) ?? 0,
      stockAvailable: _parseInt(json['stockAvailable']) ?? 0,
      isDispensed: json['isDispensed'] as bool? ?? false,
      drugId: json['drugId'] as String?,
      settled: json['settled'] as bool? ?? false,
      medicationOrderId: json['medicationOrderId']?.toString(),
    );
  }

  /// Invoice line item with nested [drug] (GET /invoice-drugs).
  factory PrescribedMedication.fromInvoiceItemJson(Map<String, dynamic> json) {
    final drug = json['drug'] is Map<String, dynamic>
        ? json['drug'] as Map<String, dynamic>
        : null;
    final drugId =
        json['drugId']?.toString() ?? drug?['id']?.toString();
    final name = _drugDisplayName(drug, json);
    final strength = drug?['strength']?.toString();
    final form = drug?['dosageForm']?.toString();
    final dosage = <String>[
      if (strength != null && strength.isNotEmpty) strength,
      if (form != null && form.isNotEmpty) form,
    ].join(' · ');

    final moRaw = json['medicationOrderId'] ?? json['medicationOrder'];
    final medicationOrderId = moRaw is Map
        ? moRaw['id']?.toString()
        : moRaw?.toString();

    return PrescribedMedication(
      id: json['id']?.toString() ?? '',
      name: name,
      dosage: dosage.isNotEmpty ? dosage : '—',
      frequency: '—',
      duration: '—',
      quantity: _parseInt(json['quantity']) ?? 0,
      stockAvailable: 0,
      drugId: drugId?.isNotEmpty == true ? drugId : null,
      settled: json['settled'] as bool? ?? false,
      medicationOrderId:
          medicationOrderId != null && medicationOrderId.isNotEmpty
          ? medicationOrderId
          : null,
    );
  }

  static String _drugDisplayName(
    Map<String, dynamic>? drug,
    Map<String, dynamic> json,
  ) {
    if (drug != null) {
      final generic = drug['genericName']?.toString().trim() ?? '';
      final brand = drug['brandName']?.toString().trim() ?? '';
      if (generic.isNotEmpty && brand.isNotEmpty && generic != brand) {
        return '$generic ($brand)';
      }
      return generic.isNotEmpty ? generic : brand;
    }
    return json['customDescription']?.toString() ?? 'Unknown item';
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'frequency': frequency,
    'duration': duration,
    'quantity': quantity,
    'stockAvailable': stockAvailable,
    'isDispensed': isDispensed,
    if (drugId != null) 'drugId': drugId,
    'settled': settled,
    if (medicationOrderId != null) 'medicationOrderId': medicationOrderId,
  };
}

class Allergy {
  final String name;
  final bool isSevere;
  Allergy(this.name, this.isSevere);

  factory Allergy.fromJson(Map<String, dynamic> json) {
    return Allergy(
      json['name'] as String? ?? '',
      json['isSevere'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'isSevere': isSevere};
}

class PastMedication {
  final String name;
  final String date;
  final bool isDiscontinued;
  PastMedication(this.name, this.date, {this.isDiscontinued = false});

  factory PastMedication.fromJson(Map<String, dynamic> json) {
    return PastMedication(
      json['name'] as String? ?? '',
      json['date'] as String? ?? '',
      isDiscontinued: json['isDiscontinued'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'date': date,
    'isDiscontinued': isDiscontinued,
  };
}

class PharmacyQueuePatient {
  final String id;
  final String name;
  final String gender;
  final int age;
  final String weight;
  final String height;
  final List<Allergy> allergies;
  final String? interactionWarning;
  final List<PastMedication> history;

  PharmacyQueuePatient({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.weight,
    required this.height,
    required this.allergies,
    this.interactionWarning,
    required this.history,
  });

  /// Minimal patient object from invoice list API (`surname`, `firstName`).
  factory PharmacyQueuePatient.fromInvoicePatientJson(
    Map<String, dynamic> json,
  ) {
    final id = json['id']?.toString() ?? '';
    final sn = json['surname']?.toString().trim() ?? '';
    final fn = json['firstName']?.toString().trim() ?? '';
    final parts = <String>[];
    if (sn.isNotEmpty) parts.add(sn);
    if (fn.isNotEmpty) parts.add(fn);
    final display = parts.join(', ');
    return PharmacyQueuePatient(
      id: id,
      name: display.isNotEmpty ? display : (json['name']?.toString() ?? ''),
      gender: '',
      age: 0,
      weight: '',
      height: '',
      allergies: [],
      history: [],
    );
  }

  factory PharmacyQueuePatient.fromJson(Map<String, dynamic> json) {
    if (json['surname'] != null || json['firstName'] != null) {
      return PharmacyQueuePatient.fromInvoicePatientJson(json);
    }
    return PharmacyQueuePatient(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      weight: json['weight'] as String? ?? '',
      height: json['height'] as String? ?? '',
      allergies: json['allergies'] is List
          ? (json['allergies'] as List)
                .map((a) => Allergy.fromJson(a as Map<String, dynamic>))
                .toList()
          : [],
      interactionWarning: json['interactionWarning'] as String?,
      history: json['history'] is List
          ? (json['history'] as List)
                .map((h) => PastMedication.fromJson(h as Map<String, dynamic>))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gender': gender,
    'age': age,
    'weight': weight,
    'height': height,
    'allergies': allergies.map((a) => a.toJson()).toList(),
    if (interactionWarning != null) 'interactionWarning': interactionWarning,
    'history': history.map((h) => h.toJson()).toList(),
  };
}

class QueueOrder {
  final String id;
  final PharmacyQueuePatient patient;
  /// Prescriber display name (from invoice `staff` or legacy mock).
  final String doctorDisplayName;
  final String department;
  final DateTime timestamp;
  final UrgencyLevel urgency;
  final String? doctorNotes;
  final List<PrescribedMedication> medications;
  /// Raw invoice status e.g. `PENDING`, `Paid`, `PAID`.
  final String invoiceStatus;

  QueueOrder({
    required this.id,
    required this.patient,
    required this.doctorDisplayName,
    this.department = '',
    required this.timestamp,
    this.urgency = UrgencyLevel.standard,
    this.doctorNotes,
    required this.medications,
    this.invoiceStatus = '',
  });

  String get medSummary => medications.map((m) => m.name).join(', ');

  static String _staffDisplayName(Map<String, dynamic>? staff) {
    if (staff == null) return '';
    final fn = staff['firstName']?.toString().trim() ?? '';
    final ln = staff['lastName']?.toString().trim() ?? '';
    final t = '$fn $ln'.trim();
    if (t.isEmpty) return '';
    return 'Dr. $t';
  }

  static DateTime _parseDate(dynamic v) {
    if (v is String && v.isNotEmpty) {
      return DateTime.tryParse(v) ?? DateTime.now();
    }
    return DateTime.now();
  }

  factory QueueOrder.fromInvoiceJson(Map<String, dynamic> json) {
    final patientRaw = json['patient'];
    final patient = patientRaw is Map<String, dynamic>
        ? PharmacyQueuePatient.fromInvoicePatientJson(patientRaw)
        : PharmacyQueuePatient(
            id: '',
            name: '',
            gender: '',
            age: 0,
            weight: '',
            height: '',
            allergies: [],
            history: [],
          );

    final staff = json['staff'] is Map<String, dynamic>
        ? json['staff'] as Map<String, dynamic>
        : null;
    final itemsRaw = json['invoiceItems'] ?? json['items'];
    final medications = <PrescribedMedication>[];
    if (itemsRaw is List) {
      for (final e in itemsRaw) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final hasDrug =
            m['drugId'] != null ||
            (m['drug'] is Map && (m['drug'] as Map).isNotEmpty);
        if (!hasDrug) continue;
        medications.add(PrescribedMedication.fromInvoiceItemJson(m));
      }
    }

    return QueueOrder(
      id: json['id']?.toString() ?? '',
      patient: patient,
      doctorDisplayName: _staffDisplayName(staff),
      department: '',
      timestamp: _parseDate(json['createdAt']),
      urgency: UrgencyLevel.standard,
      doctorNotes: null,
      medications: medications,
      invoiceStatus: json['status']?.toString() ?? '',
    );
  }

  factory QueueOrder.fromJson(Map<String, dynamic> json) {
    if (json['invoiceItems'] is List) {
      return QueueOrder.fromInvoiceJson(json);
    }

    final urgencyStr = (json['urgency'] as String? ?? 'standard').toLowerCase();
    final urgency = UrgencyLevel.values.firstWhere(
      (u) => u.name == urgencyStr,
      orElse: () => UrgencyLevel.standard,
    );

    return QueueOrder(
      id: json['id'] as String? ?? '',
      patient: json['patient'] is Map
          ? PharmacyQueuePatient.fromJson(
              json['patient'] as Map<String, dynamic>,
            )
          : PharmacyQueuePatient(
              id: '',
              name: '',
              gender: '',
              age: 0,
              weight: '',
              height: '',
              allergies: [],
              history: [],
            ),
      doctorDisplayName:
          json['doctorDisplayName'] as String? ??
          json['doctorName'] as String? ??
          '',
      department: json['department'] as String? ?? '',
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      urgency: urgency,
      doctorNotes: json['doctorNotes'] as String?,
      medications: json['medications'] is List
          ? (json['medications'] as List)
                .map(
                  (m) =>
                      PrescribedMedication.fromJson(m as Map<String, dynamic>),
                )
                .toList()
          : [],
      invoiceStatus: json['invoiceStatus'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient': patient.toJson(),
    'doctorDisplayName': doctorDisplayName,
    'department': department,
    'timestamp': timestamp.toIso8601String(),
    'urgency': urgency.name,
    if (doctorNotes != null) 'doctorNotes': doctorNotes,
    'medications': medications.map((m) => m.toJson()).toList(),
    'invoiceStatus': invoiceStatus,
  };
}

bool invoiceStatusIsPaid(String status) {
  return status.trim().toUpperCase() == 'PAID';
}
