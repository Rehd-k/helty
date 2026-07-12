import '../core/utils/patient_display_name.dart';
import '../core/utils/patient_initials.dart';
import '../models/hmo_models.dart';

/// Sent to GET /patients as `listStatusFilter` so the server narrows by [Patient.status].
enum PatientListStatusFilter { none, onlyAdmitted, excludeAdmitted }

/// Optional allergy row from GET /patients/:id when the API includes it.
class PatientAllergyEntry {
  const PatientAllergyEntry({required this.name, this.isSevere = false});

  final String name;
  final bool isSevere;

  factory PatientAllergyEntry.fromDynamic(dynamic e) {
    if (e is String) {
      return PatientAllergyEntry(name: e.trim());
    }
    if (e is Map) {
      final m = Map<String, dynamic>.from(e);
      final name =
          m['name']?.toString().trim() ??
          m['allergy']?.toString().trim() ??
          m['substance']?.toString().trim() ??
          '';
      final severe =
          m['isSevere'] == true ||
          m['severe'] == true ||
          m['severity']?.toString().toUpperCase() == 'SEVERE';
      return PatientAllergyEntry(name: name, isSevere: severe);
    }
    return const PatientAllergyEntry(name: '');
  }
}

/// Optional prescription / medication history from GET /patients/:id.
class PatientPrescriptionHistoryEntry {
  const PatientPrescriptionHistoryEntry({required this.name, this.detail});

  final String name;
  final String? detail;

  factory PatientPrescriptionHistoryEntry.fromDynamic(dynamic e) {
    if (e is Map) {
      final m = Map<String, dynamic>.from(e);
      final name =
          m['drugName']?.toString().trim() ??
          m['name']?.toString().trim() ??
          m['medication']?.toString().trim() ??
          '';
      final detail =
          m['status']?.toString() ??
          m['dose']?.toString() ??
          m['frequency']?.toString();
      final date =
          m['createdAt']?.toString() ?? m['date']?.toString() ?? m['orderedAt']?.toString();
      final parts = <String>[];
      if (detail != null && detail.isNotEmpty) parts.add(detail);
      if (date != null && date.isNotEmpty) parts.add(date);
      return PatientPrescriptionHistoryEntry(
        name: name,
        detail: parts.isEmpty ? null : parts.join(' · '),
      );
    }
    return PatientPrescriptionHistoryEntry(name: e.toString());
  }
}

List<PatientAllergyEntry> _parsePatientAllergies(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map(PatientAllergyEntry.fromDynamic).where((a) => a.name.isNotEmpty).toList();
}

List<PatientPrescriptionHistoryEntry> _parsePatientPrescriptionHistory(
  Map<String, dynamic> json,
) {
  final candidates = [
    json['prescriptionHistory'],
    json['medicationOrders'],
    json['prescriptions'],
    json['medicationHistory'],
  ];
  for (final raw in candidates) {
    if (raw is List && raw.isNotEmpty) {
      return raw
          .map(PatientPrescriptionHistoryEntry.fromDynamic)
          .where((h) => h.name.isNotEmpty)
          .toList();
    }
  }
  return const [];
}

/// True when [status] represents an inpatient admission (matches API spellings).
bool patientStatusIsAdmitted(String? status) {
  if (status == null) return false;
  final u = status.toUpperCase().trim();
  return u == 'ADMITED' || u == 'ADMITTED';
}

class Patient {
  final String? id;
  final String patientId;
  final String cardNo;
  final String title;
  final String surname;
  final String firstName;
  final String? otherName;
  final DateTime dob;
  final String gender;
  final String maritalStatus;
  final String nationality;
  final String stateOfOrigin;
  final String lga;
  final String town;
  final String permanentAddress;
  final String? religion;
  final String? email;
  final String? preferredLanguage;
  final String? phoneNumber;
  final String? addressOfResidence;
  final String? profession;
  final String? nextOfKinName;
  final String? nextOfKinPhone;
  final String? nextOfKinAddress;
  final String? nextOfKinRelationship;
  final String? hmo;

  /// FK to HMO plan (`GET /hmos`).
  final String? hmoId;

  /// Nested provider when API includes it on patient responses.
  final HmoProviderSummary? hmoProvider;

  final String? fingerprintData;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? ward;

  /// FK to Ward on the server (Prisma: `wardId` → `ward` relation).
  final String? wardId;

  final String? bedNumber;

  /// FK to Bed on the server when the API exposes it (Prisma: `bedId` → `bed`).
  final String? bedId;

  final DateTime? admissionDate;

  /// Inpatient / visit status from the API (e.g. `ADMITED`).
  final String? status;

  /// Client-side flags/metadata (not necessarily persisted).
  /// When `true`, the UI should treat surname/firstName as read‑only.
  final bool lockNames;

  /// Indicates this patient came from the "unregistered patient" transaction flow.
  final bool fromUnregisteredFlow;

  /// Optional transaction id that originated this registration flow.
  final String? unregisteredTransactionId;

  /// When returned by GET /patients/:id (shape varies by backend).
  final List<PatientAllergyEntry> allergies;

  /// When returned by GET /patients/:id (e.g. medicationOrders, prescriptions).
  final List<PatientPrescriptionHistoryEntry> prescriptionHistory;

  /// Public profile photo URL from the patient portal (512×512 JPEG).
  final String? avatarUrl;

  Patient({
    this.id,
    required this.patientId,
    required this.cardNo,
    required this.title,
    required this.surname,
    required this.firstName,
    this.otherName,
    required this.dob,
    required this.gender,
    required this.maritalStatus,
    required this.nationality,
    required this.stateOfOrigin,
    required this.lga,
    required this.town,
    required this.permanentAddress,
    this.religion,
    this.email,
    this.preferredLanguage,
    this.phoneNumber,
    this.addressOfResidence,
    this.profession,
    this.nextOfKinName,
    this.nextOfKinPhone,
    this.nextOfKinAddress,
    this.nextOfKinRelationship,
    this.hmo,
    this.hmoId,
    this.hmoProvider,
    this.fingerprintData,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.status,
    this.lockNames = false,
    this.fromUnregisteredFlow = false,
    this.unregisteredTransactionId,
    this.ward,
    this.wardId,
    this.bedNumber,
    this.bedId,
    this.admissionDate,
    this.allergies = const [],
    this.prescriptionHistory = const [],
    this.avatarUrl,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    String? firstNonEmptyString(List<dynamic> candidates) {
      for (final value in candidates) {
        final text = value?.toString().trim();
        if (text != null && text.isNotEmpty) return text;
      }
      return null;
    }

    DateTime? firstParsableDate(List<dynamic> candidates) {
      for (final value in candidates) {
        final text = value?.toString().trim();
        if (text == null || text.isEmpty) continue;
        final parsed = DateTime.tryParse(text);
        if (parsed != null) return parsed;
      }
      return null;
    }

    final admission =
        json['admission'] is Map
            ? Map<String, dynamic>.from(json['admission'] as Map)
            : null;

    final wardMap =
        json['ward'] is Map ? Map<String, dynamic>.from(json['ward'] as Map) : null;
    final bedMap =
        json['bed'] is Map ? Map<String, dynamic>.from(json['bed'] as Map) : null;

    // use nullable casts to avoid runtime type errors when keys are missing
    final String? dobStr = json['dob'] as String?;
    return Patient(
      id: json['id'] as String?,
      patientId: json['patientId'] as String? ?? '',
      cardNo: json['cardNo'] as String? ?? '',
      title: json['title'] as String? ?? '',
      surname: json['surname'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      otherName: json['otherName'] as String?,
      dob: dobStr != null ? DateTime.parse(dobStr) : DateTime(1970),
      gender: json['gender'] as String? ?? '',
      maritalStatus: json['maritalStatus'] as String? ?? '',
      nationality: json['nationality'] as String? ?? '',
      stateOfOrigin: json['stateOfOrigin'] as String? ?? '',
      lga: json['lga'] as String? ?? '',
      town: json['town'] as String? ?? '',
      permanentAddress: json['permanentAddress'] as String? ?? '',
      religion: json['religion'] as String?,
      email: json['email'] as String?,
      preferredLanguage: json['preferredLanguage'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      addressOfResidence: json['addressOfResidence'] as String?,
      profession: json['profession'] as String?,
      nextOfKinName: json['nextOfKinName'] as String?,
      nextOfKinPhone: json['nextOfKinPhone'] as String?,
      nextOfKinAddress: json['nextOfKinAddress'] as String?,
      nextOfKinRelationship: json['nextOfKinRelationship'] as String?,
      hmo: () {
        final t = json['hmo']?.toString().trim();
        if (t == null || t.isEmpty || t == 'No HMO') return null;
        return t;
      }(),
      hmoId: json['hmoId']?.toString(),
      hmoProvider: json['hmoProvider'] is Map
          ? HmoProviderSummary.fromJson(
              Map<String, dynamic>.from(json['hmoProvider'] as Map),
            )
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      createdBy: json['createdBy'] != null
          ? '${json['createdBy']['lastName']} ${json['createdBy']['firstName']}'
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      updatedBy: json['updatedBy'] != null
          ? '${json['updatedBy']['lastName']} ${json['updatedBy']['firstName']}'
          : null,
      status: json['status']?.toString(),
      fingerprintData: json['fingerprintData'] as String? ?? 'No Fingerprint',
      // Client-only flags default to false/null when coming from backend.
      lockNames: false,
      fromUnregisteredFlow: false,
      unregisteredTransactionId: null,
      ward:
          firstNonEmptyString([
            json['ward'] is String ? json['ward'] : null,
            wardMap?['name'],
            admission?['ward'],
            admission?['wardName'],
          ]) ??
          'OPD',
      wardId: () {
        final top = json['wardId']?.toString().trim();
        if (top != null && top.isNotEmpty) return top;
        final nested = wardMap?['id']?.toString().trim();
        if (nested != null && nested.isNotEmpty) return nested;
        return admission?['wardId']?.toString().trim();
      }(),
      bedNumber: firstNonEmptyString([
        json['bedNumber'],
        json['bedNo'],
        json['bed'] is String ? json['bed'] : null,
        bedMap?['bedNumber'],
        admission?['bedNumber'],
        admission?['bedNo'],
        admission?['bedPreference'],
      ]),
      bedId: () {
        final top = json['bedId']?.toString().trim();
        if (top != null && top.isNotEmpty) return top;
        final nested = bedMap?['id']?.toString().trim();
        if (nested != null && nested.isNotEmpty) return nested;
        return admission?['bedId']?.toString().trim();
      }(),
      admissionDate: firstParsableDate([
        json['admissionDate'],
        json['admittedAt'],
        admission?['admissionDate'],
        admission?['createdAt'],
      ]),
      allergies: _parsePatientAllergies(json['allergies']),
      prescriptionHistory: _parsePatientPrescriptionHistory(json),
      avatarUrl: avatarUrlFromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'cardNo': cardNo,
      'title': title,
      'surname': surname,
      'firstName': firstName,
      'otherName': otherName,
      'dob': dob.toIso8601String(), // ✅ serialize
      'gender': gender,
      'maritalStatus': maritalStatus,
      'nationality': nationality,
      'stateOfOrigin': stateOfOrigin,
      'lga': lga,
      'town': town,
      'permanentAddress': permanentAddress,
      'religion': religion,
      'email': email,
      'preferredLanguage': preferredLanguage,
      'phoneNumber': phoneNumber,
      'addressOfResidence': addressOfResidence,
      'profession': profession,
      'nextOfKinName': nextOfKinName,
      'nextOfKinPhone': nextOfKinPhone,
      'nextOfKinAddress': nextOfKinAddress,
      'nextOfKinRelationship': nextOfKinRelationship,
      if (hmoId != null && hmoId!.trim().isNotEmpty) 'hmoId': hmoId!.trim(),
      if (hmo != null && hmo!.trim().isNotEmpty) 'hmo': hmo!.trim(),
      'createdAt': createdAt
          ?.toIso8601String(), // or remove if server sets this
      'createdBy': createdBy, // consider removing if server owns this
      'updatedAt': updatedAt?.toIso8601String(),
      'updatedBy': updatedBy,
      'fingerprintData': fingerprintData,
      if (status != null) 'status': status,
      if (wardId != null && wardId!.trim().isNotEmpty) 'wardId': wardId,
      if (bedId != null && bedId!.trim().isNotEmpty) 'bedId': bedId,
      if (ward != null) 'ward': ward,
      if (bedNumber != null) 'bedNumber': bedNumber,
      if (admissionDate != null) 'admissionDate': admissionDate!.toIso8601String(),
    };
  }

  /// Returns a copy with [status] and optional inpatient location (for PATCH).
  Patient withStatusWardBed(
    String newStatus, {
    String? ward,
    String? wardId,
    String? bedNumber,
    String? bedId,
    DateTime? admissionDate,
  }) {
    return Patient(
      id: id,
      patientId: patientId,
      cardNo: cardNo,
      title: title,
      surname: surname,
      firstName: firstName,
      otherName: otherName,
      dob: dob,
      gender: gender,
      maritalStatus: maritalStatus,
      nationality: nationality,
      stateOfOrigin: stateOfOrigin,
      lga: lga,
      town: town,
      permanentAddress: permanentAddress,
      religion: religion,
      email: email,
      preferredLanguage: preferredLanguage,
      phoneNumber: phoneNumber,
      addressOfResidence: addressOfResidence,
      profession: profession,
      nextOfKinName: nextOfKinName,
      nextOfKinPhone: nextOfKinPhone,
      nextOfKinAddress: nextOfKinAddress,
      nextOfKinRelationship: nextOfKinRelationship,
      hmo: hmo,
      hmoId: hmoId,
      hmoProvider: hmoProvider,
      fingerprintData: fingerprintData,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
      updatedBy: updatedBy,
      status: newStatus,
      lockNames: lockNames,
      fromUnregisteredFlow: fromUnregisteredFlow,
      unregisteredTransactionId: unregisteredTransactionId,
      ward: ward ?? this.ward,
      wardId: wardId ?? this.wardId,
      bedNumber: bedNumber ?? this.bedNumber,
      bedId: bedId ?? this.bedId,
      admissionDate: admissionDate ?? this.admissionDate,
      allergies: allergies,
      prescriptionHistory: prescriptionHistory,
      avatarUrl: avatarUrl,
    );
  }

  /// Returns a copy with [status] set (for PATCH via [PatientService.updatePatient]).
  Patient withStatus(String newStatus) {
    return Patient(
      id: id,
      patientId: patientId,
      cardNo: cardNo,
      title: title,
      surname: surname,
      firstName: firstName,
      otherName: otherName,
      dob: dob,
      gender: gender,
      maritalStatus: maritalStatus,
      nationality: nationality,
      stateOfOrigin: stateOfOrigin,
      lga: lga,
      town: town,
      permanentAddress: permanentAddress,
      religion: religion,
      email: email,
      preferredLanguage: preferredLanguage,
      phoneNumber: phoneNumber,
      addressOfResidence: addressOfResidence,
      profession: profession,
      nextOfKinName: nextOfKinName,
      nextOfKinPhone: nextOfKinPhone,
      nextOfKinAddress: nextOfKinAddress,
      nextOfKinRelationship: nextOfKinRelationship,
      hmo: hmo,
      hmoId: hmoId,
      hmoProvider: hmoProvider,
      fingerprintData: fingerprintData,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
      updatedBy: updatedBy,
      status: newStatus,
      lockNames: lockNames,
      fromUnregisteredFlow: fromUnregisteredFlow,
      unregisteredTransactionId: unregisteredTransactionId,
      ward: ward,
      wardId: wardId,
      bedNumber: bedNumber,
      bedId: bedId,
      admissionDate: admissionDate,
      allergies: allergies,
      prescriptionHistory: prescriptionHistory,
      avatarUrl: avatarUrl,
    );
  }

  /// Ward label for UI (defaults to OPD when missing).
  String get wardDisplayName {
    final w = ward?.trim();
    return (w != null && w.isNotEmpty) ? w : 'OPD';
  }

  /// HMO name when known; null when patient has no HMO.
  String? get hmoDisplayName {
    final fromProvider = hmoProvider?.name.trim();
    if (fromProvider != null && fromProvider.isNotEmpty) return fromProvider;
    final fromField = hmo?.trim();
    if (fromField != null && fromField.isNotEmpty) return fromField;
    return null;
  }

  /// e.g. `OPD - CBN` or `OPD` when no HMO.
  String get wardHmoDisplayLine {
    final hmoName = hmoDisplayName;
    if (hmoName == null) return wardDisplayName;
    return '$wardDisplayName - $hmoName';
  }

  /// Full display label: title + first + other + surname (see docs/patient-names.md).
  String get displayName => formatPatientDisplayName(
        title: title,
        firstName: firstName,
        otherName: otherName,
        surname: surname,
      );
}
