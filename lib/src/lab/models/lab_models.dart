// Dynamic laboratory module — typed models for /lab API.

import 'dart:convert';

import 'package:helty/src/core/extensions/capitalizer.extention.dart';
import 'package:helty/src/models/staff_model.dart';

/// Lab category (e.g. Hematology, Biochemistry).
class LabCategory {
  const LabCategory({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? description;
  final DateTime? createdAt;

  factory LabCategory.fromJson(Map<String, dynamic> json) => LabCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}

/// Lab test (e.g. CBC, Urinalysis).
class LabTest {
  const LabTest({
    required this.id,
    required this.name,
    required this.sampleType,
    this.description,
    this.price,
    this.isActive = true,
    this.category,
    this.versions,
  });

  final String id;
  final String name;
  final String sampleType;
  final String? description;
  final double? price;
  final bool isActive;
  final LabCategoryRef? category;
  final List<LabTestVersion>? versions;

  factory LabTest.fromJson(Map<String, dynamic> json) => LabTest(
        id: json['id'] as String,
        name: json['name'] as String,
        sampleType: json['sampleType'] as String,
        description: json['description'] as String?,
        price: (json['price'] as num?)?.toDouble(),
        isActive: (json['isActive'] as bool?) ?? true,
        category: json['category'] != null
            ? LabCategoryRef.fromJson(
                json['category'] as Map<String, dynamic>)
            : null,
        versions: (json['versions'] as List<dynamic>?)
            ?.map((e) => LabTestVersion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sampleType': sampleType,
        if (description != null) 'description': description,
        if (price != null) 'price': price,
        'isActive': isActive,
        if (category != null) 'category': category!.toJson(),
      };
}

class LabCategoryRef {
  const LabCategoryRef({required this.id, required this.name});
  final String id;
  final String name;

  factory LabCategoryRef.fromJson(Map<String, dynamic> json) => LabCategoryRef(
        id: json['id'] as String,
        name: json['name'] as String,
      );
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

/// Version of a test (template revision).
class LabTestVersion {
  const LabTestVersion({
    required this.id,
    required this.versionNumber,
    this.isActive = false,
    this.test,
    this.fieldCount,
  });

  final String id;
  final int versionNumber;
  final bool isActive;
  final LabTestRef? test;
  final int? fieldCount;

  factory LabTestVersion.fromJson(Map<String, dynamic> json) => LabTestVersion(
        id: json['id'] as String,
        versionNumber: (json['versionNumber'] as num).toInt(),
        isActive: (json['isActive'] as bool?) ?? false,
        test: json['test'] != null
            ? LabTestRef.fromJson(json['test'] as Map<String, dynamic>)
            : null,
        fieldCount: (json['_count'] as Map<String, dynamic>?)?['fields'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'versionNumber': versionNumber,
        'isActive': isActive,
      };
}

class LabTestRef {
  const LabTestRef({required this.id, required this.name});
  final String id;
  final String name;

  factory LabTestRef.fromJson(Map<String, dynamic> json) => LabTestRef(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}

/// Field type for dynamic result form.
enum LabFieldType {
  text,
  number,
  dropdown,
  checkbox,
  multiselect,
  date;

  static LabFieldType fromString(String? value) {
    if (value == null) return LabFieldType.text;
    switch (value.toUpperCase()) {
      case 'TEXT':
        return LabFieldType.text;
      case 'NUMBER':
        return LabFieldType.number;
      case 'DROPDOWN':
        return LabFieldType.dropdown;
      case 'CHECKBOX':
        return LabFieldType.checkbox;
      case 'MULTISELECT':
        return LabFieldType.multiselect;
      case 'DATE':
        return LabFieldType.date;
      default:
        return LabFieldType.text;
    }
  }
}

/// Single field in a test version (form template).
class LabTestField {
  const LabTestField({
    required this.id,
    required this.testVersionId,
    required this.label,
    required this.fieldType,
    this.unit,
    this.referenceRange,
    this.required = false,
    this.position = 0,
    this.optionsJson,
  });

  final String id;
  final String testVersionId;
  final String label;
  final LabFieldType fieldType;
  final String? unit;
  final String? referenceRange;
  final bool required;
  final int position;
  final String? optionsJson;

  /// Parsed options for DROPDOWN/MULTISELECT: list of strings or {value, label}.
  List<LabFieldOption> get options => _parseOptions(optionsJson);

  static List<LabFieldOption> _parseOptions(String? jsonStr) {
    if (jsonStr == null || jsonStr.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonStr) as List<dynamic>?;
      if (decoded == null) return [];
      return decoded.map((e) {
        if (e is String) return LabFieldOption(value: e, label: e);
        if (e is Map<String, dynamic>) {
          return LabFieldOption(
            value: (e['value'] ?? e['label'] ?? '').toString(),
            label: (e['label'] ?? e['value'] ?? '').toString(),
          );
        }
        return LabFieldOption(value: e.toString(), label: e.toString());
      }).toList();
    } catch (_) {
      return [];
    }
  }

  factory LabTestField.fromJson(Map<String, dynamic> json) => LabTestField(
        id: (json['id'] as String?) ?? '',
        testVersionId: (json['testVersionId'] as String?) ?? '',
        label: (json['label'] as String?) ?? '',
        fieldType: LabFieldType.fromString(json['fieldType'] as String?),
        unit: json['unit'] as String?,
        referenceRange: json['referenceRange'] as String?,
        required: (json['required'] as bool?) ?? false,
        position: (json['position'] as num?)?.toInt() ?? 0,
        optionsJson: json['optionsJson'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'testVersionId': testVersionId,
        'label': label,
        'fieldType': fieldType.name.toUpperCase(),
        if (unit != null) 'unit': unit,
        if (referenceRange != null) 'referenceRange': referenceRange,
        'required': required,
        'position': position,
        if (optionsJson != null) 'optionsJson': optionsJson,
      };
}

class LabFieldOption {
  const LabFieldOption({required this.value, required this.label});
  final String value;
  final String label;
}

/// Order status.
enum LabOrderStatus {
  pending,
  sampleCollected,
  processing,
  completed,
  verified;

  static LabOrderStatus fromString(String? value) {
    if (value == null) return LabOrderStatus.pending;
    switch (value.toUpperCase().replaceAll('_', ' ')) {
      case 'PENDING':
        return LabOrderStatus.pending;
      case 'SAMPLE COLLECTED':
        return LabOrderStatus.sampleCollected;
      case 'PROCESSING':
        return LabOrderStatus.processing;
      case 'COMPLETED':
        return LabOrderStatus.completed;
      case 'VERIFIED':
        return LabOrderStatus.verified;
      default:
        return LabOrderStatus.pending;
    }
  }

  String get apiValue {
    switch (this) {
      case LabOrderStatus.pending:
        return 'PENDING';
      case LabOrderStatus.sampleCollected:
        return 'SAMPLE_COLLECTED';
      case LabOrderStatus.processing:
        return 'PROCESSING';
      case LabOrderStatus.completed:
        return 'COMPLETED';
      case LabOrderStatus.verified:
        return 'VERIFIED';
    }
  }
}

/// Lab order (request for tests).
class LabOrder {
  const LabOrder({
    required this.id,
    required this.status,
    this.patient,
    this.doctor,
    this.items = const [],
    this.createdAt,
  });

  final String id;
  final LabOrderStatus status;
  final LabOrderPatient? patient;
  final LabOrderStaff? doctor;
  final List<LabOrderItem> items;
  final DateTime? createdAt;

  factory LabOrder.fromJson(Map<String, dynamic> json) => LabOrder(
        id: (json['id'] as String?) ?? '',
        status: LabOrderStatus.fromString(json['status'] as String?),
        patient: json['patient'] != null
            ? LabOrderPatient.fromJson(
                json['patient'] as Map<String, dynamic>)
            : null,
        doctor: json['doctor'] != null
            ? LabOrderStaff.fromJson(json['doctor'] as Map<String, dynamic>)
            : null,
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => LabOrderItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status.apiValue,
        if (patient != null) 'patient': patient!.toJson(),
        if (doctor != null) 'doctor': doctor!.toJson(),
        'items': items.map((e) => e.toJson()).toList(),
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

  LabOrder copyWith({List<LabOrderItem>? items}) => LabOrder(
        id: id,
        status: status,
        patient: patient,
        doctor: doctor,
        items: items ?? this.items,
        createdAt: createdAt,
      );
}

class LabOrderPatient {
  const LabOrderPatient({
    required this.id,
    this.firstName,
    this.otherName,
    this.surname,
    this.patientId,
    this.gender,
    this.dob,
  });

  final String id;
  final String? firstName;
  final String? otherName;
  final String? surname;
  final String? patientId;
  final String? gender;
  final DateTime? dob;

  String get displayName =>
      [firstName, otherName, surname]
          .where((e) => e != null && e.isNotEmpty)
          .join(' ');

  String get capitalizedDisplayName {
    final parts = <String>[];
    for (final name in [firstName, otherName, surname]) {
      final trimmed = name?.trim() ?? '';
      if (trimmed.isNotEmpty) parts.add(trimmed.capitalize());
    }
    return parts.join(' ');
  }

  factory LabOrderPatient.fromJson(Map<String, dynamic> json) =>
      LabOrderPatient(
        id: (json['id'] as String?) ?? '',
        firstName: json['firstName'] as String?,
        otherName: json['otherName'] as String?,
        surname: (json['surname'] ?? json['lastName']) as String?,
        patientId: json['patientId'] as String?,
        gender: json['gender'] as String?,
        dob: json['dob'] != null
            ? DateTime.tryParse(json['dob'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (firstName != null) 'firstName': firstName,
        if (otherName != null) 'otherName': otherName,
        if (surname != null) 'surname': surname,
        if (patientId != null) 'patientId': patientId,
        if (gender != null) 'gender': gender,
        if (dob != null) 'dob': dob!.toIso8601String(),
      };
}

class LabOrderStaff {
  const LabOrderStaff({
    required this.id,
    this.firstName,
    this.lastName,
    this.accountType,
  });

  final String id;
  final String? firstName;
  final String? lastName;
  final AccountType? accountType;

  bool get isPhysician => accountType == AccountType.physician;

  String get displayName =>
      [firstName, lastName].where((e) => e != null && e.isNotEmpty).join(' ');

  String get capitalizedDisplayName {
    final parts = <String>[];
    for (final name in [firstName, lastName]) {
      final trimmed = name?.trim() ?? '';
      if (trimmed.isNotEmpty) parts.add(trimmed.capitalize());
    }
    return parts.join(' ');
  }

  factory LabOrderStaff.fromJson(Map<String, dynamic> json) => LabOrderStaff(
        id: (json['id'] as String?) ?? '',
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        accountType: json['accountType'] != null
            ? AccountType.fromString(json['accountType'] as String?)
            : null,
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (accountType != null) 'accountType': accountType!.apiValue,
      };
}

/// Input for a single line when creating a lab order.
class LabOrderItemInput {
  const LabOrderItemInput({
    required this.testVersionId,
    this.astRequested = false,
  });

  final String testVersionId;
  final bool astRequested;

  Map<String, dynamic> toJson() => {
        'testVersionId': testVersionId,
        'astRequested': astRequested,
      };
}

/// Single line item in an order (one test).
class LabOrderItem {
  const LabOrderItem({
    required this.id,
    required this.orderId,
    this.testVersion,
    this.sample,
    this.results = const [],
    this.fields,
    this.astRequested = false,
    this.astResults = const [],
  });

  final String id;
  final String orderId;
  final LabOrderItemTestVersion? testVersion;
  final LabSample? sample;
  final List<LabResult> results;
  final List<LabTestField>? fields;
  final bool astRequested;
  final List<LabAstResult> astResults;

  factory LabOrderItem.fromJson(Map<String, dynamic> json) => LabOrderItem(
        id: (json['id'] as String?) ?? '',
        orderId: (json['orderId'] as String?) ?? '',
        testVersion: json['testVersion'] != null
            ? LabOrderItemTestVersion.fromJson(
                json['testVersion'] as Map<String, dynamic>)
            : null,
        sample: json['sample'] != null
            ? LabSample.fromJson(json['sample'] as Map<String, dynamic>)
            : null,
        results: (json['results'] as List<dynamic>?)
                ?.map((e) => LabResult.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        fields: (json['testVersion']?['fields'] as List<dynamic>?)
                ?.map((e) => LabTestField.fromJson(e as Map<String, dynamic>))
                .toList(),
        astRequested: (json['astRequested'] as bool?) ?? false,
        astResults: (json['astResults'] as List<dynamic>?)
                ?.map((e) => LabAstResult.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        if (testVersion != null) 'testVersion': testVersion!.toJson(),
        if (sample != null) 'sample': sample!.toJson(),
        'results': results.map((e) => e.toJson()).toList(),
        'astRequested': astRequested,
        'astResults': astResults.map((e) => e.toJson()).toList(),
      };

  LabOrderItem copyWith({List<LabResult>? results}) => LabOrderItem(
        id: id,
        orderId: orderId,
        testVersion: testVersion,
        sample: sample,
        results: results ?? this.results,
        fields: fields,
        astRequested: astRequested,
        astResults: astResults,
      );
}

class LabOrderItemTestVersion {
  const LabOrderItemTestVersion({
    required this.id,
    this.test,
    this.fields,
  });

  final String id;
  final LabOrderItemTest? test;
  final List<LabTestField>? fields;

  factory LabOrderItemTestVersion.fromJson(Map<String, dynamic> json) {
    final fieldsList = json['fields'] as List<dynamic>?;
    return LabOrderItemTestVersion(
      id: (json['id'] as String?) ?? '',
      test: json['test'] != null
          ? LabOrderItemTest.fromJson(json['test'] as Map<String, dynamic>)
          : null,
      fields: fieldsList
          ?.map((e) => LabTestField.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (test != null) 'test': test!.toJson(),
        if (fields != null) 'fields': fields!.map((e) => e.toJson()).toList(),
      };
}

class LabOrderItemTest {
  const LabOrderItemTest(
      {required this.id, required this.name, this.sampleType});
  final String id;
  final String name;
  final String? sampleType;

  factory LabOrderItemTest.fromJson(Map<String, dynamic> json) =>
      LabOrderItemTest(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        sampleType: json['sampleType'] as String?,
      );
  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'sampleType': sampleType};
}

/// Sample recorded for an order item.
class LabSample {
  const LabSample({
    required this.id,
    required this.orderItemId,
    required this.sampleType,
    required this.collectedBy,
    required this.collectionTime,
    this.barcode,
  });

  final String id;
  final String orderItemId;
  final String sampleType;
  /// Staff user id who collected the sample (API may return this id as a string
  /// or nested under `collectedBy: { id, firstName, lastName }`).
  final String collectedBy;
  final DateTime collectionTime;
  final String? barcode;

  static String _collectedByIdFromJson(Object? raw) {
    if (raw == null) return '';
    if (raw is String) return raw;
    if (raw is Map<String, dynamic>) {
      return (raw['id'] as String?) ?? '';
    }
    return '';
  }

  factory LabSample.fromJson(Map<String, dynamic> json) {
    final collectionTimeStr = json['collectionTime'] as String?;
    return LabSample(
      id: (json['id'] as String?) ?? '',
      orderItemId: (json['orderItemId'] as String?) ?? '',
      sampleType: (json['sampleType'] as String?) ?? '',
      collectedBy: _collectedByIdFromJson(json['collectedBy']),
      collectionTime: collectionTimeStr != null
          ? (DateTime.tryParse(collectionTimeStr) ?? DateTime.now())
          : DateTime.now(),
      barcode: json['barcode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderItemId': orderItemId,
        'sampleType': sampleType,
        'collectedBy': collectedBy,
        'collectionTime': collectionTime.toIso8601String(),
        if (barcode != null) 'barcode': barcode,
      };
}

/// Direction when a numeric result is outside the reference range.
enum ReferenceFlag {
  low,
  high;

  static ReferenceFlag? fromString(String? value) {
    if (value == null) return null;
    switch (value.toUpperCase()) {
      case 'LOW':
        return ReferenceFlag.low;
      case 'HIGH':
        return ReferenceFlag.high;
      default:
        return null;
    }
  }
}

/// Server-computed comparison of a result value to the field reference range.
class ReferenceEvaluation {
  const ReferenceEvaluation({
    this.inRange,
    this.flag,
    this.parsedValue,
    this.referenceRange,
  });

  final bool? inRange;
  final ReferenceFlag? flag;
  final double? parsedValue;
  final String? referenceRange;

  bool get isAbnormal => inRange == false;

  factory ReferenceEvaluation.fromJson(Map<String, dynamic> json) =>
      ReferenceEvaluation(
        inRange: json['inRange'] as bool?,
        flag: ReferenceFlag.fromString(json['flag'] as String?),
        parsedValue: (json['parsedValue'] as num?)?.toDouble(),
        referenceRange: json['referenceRange'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (inRange != null) 'inRange': inRange,
        if (flag != null)
          'flag': flag == ReferenceFlag.low ? 'LOW' : 'HIGH',
        if (parsedValue != null) 'parsedValue': parsedValue,
        if (referenceRange != null) 'referenceRange': referenceRange,
      };
}

/// Single result value for a field.
class LabResult {
  const LabResult({
    required this.id,
    required this.orderItemId,
    required this.fieldId,
    required this.value,
    this.field,
    this.enteredBy,
    this.hiddenFromReport = false,
    this.referenceEvaluation,
  });

  final String id;
  final String orderItemId;
  final String fieldId;
  final String value;
  final LabTestField? field;
  /// Staff id who entered the result (API may send [enteredById] only or nested [enteredBy]).
  final String? enteredBy;

  /// When true, field is omitted from print/PDF and typically not shown on the
  /// report view for this order item only (template fields are unchanged).
  final bool hiddenFromReport;

  /// Computed on read from field reference range and numeric value.
  final ReferenceEvaluation? referenceEvaluation;

  static String? _enteredByStaffIdFromJson(Map<String, dynamic> json) {
    final direct = json['enteredById']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final raw = json['enteredBy'];
    if (raw == null) return null;
    if (raw is String) {
      final s = raw.trim();
      return s.isEmpty ? null : s;
    }
    if (raw is Map) {
      final id = raw['id']?.toString().trim();
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }

  static String _valueToString(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) return raw;
    if (raw is num || raw is bool) return raw.toString();
    if (raw is Map) return jsonEncode(raw);
    if (raw is List) return jsonEncode(raw);
    return raw.toString();
  }

  factory LabResult.fromJson(Map<String, dynamic> json) => LabResult(
        id: (json['id'] as String?) ?? '',
        orderItemId: (json['orderItemId'] as String?) ?? '',
        fieldId: (json['fieldId'] as String?) ?? '',
        value: _valueToString(json['value']),
        field: json['field'] != null
            ? LabTestField.fromJson(json['field'] as Map<String, dynamic>)
            : null,
        enteredBy: _enteredByStaffIdFromJson(json),
        hiddenFromReport: (json['hiddenFromReport'] as bool?) ??
            (json['excludeFromPrint'] as bool?) ??
            false,
        referenceEvaluation: json['referenceEvaluation'] != null
            ? ReferenceEvaluation.fromJson(
                json['referenceEvaluation'] as Map<String, dynamic>,
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderItemId': orderItemId,
        'fieldId': fieldId,
        'value': value,
        if (field != null) 'field': field!.toJson(),
        if (enteredBy != null) 'enteredBy': enteredBy,
        'hiddenFromReport': hiddenFromReport,
        if (referenceEvaluation != null)
          'referenceEvaluation': referenceEvaluation!.toJson(),
      };

  LabResult copyWith({ReferenceEvaluation? referenceEvaluation}) =>
      LabResult(
        id: id,
        orderItemId: orderItemId,
        fieldId: fieldId,
        value: value,
        field: field,
        enteredBy: enteredBy,
        hiddenFromReport: hiddenFromReport,
        referenceEvaluation: referenceEvaluation ?? this.referenceEvaluation,
      );
}

// ── MCS / AST (antibiotic susceptibility) ───────────────────────────────────

/// Antibiotic in the lab susceptibility panel catalog.
class LabAntibiotic {
  const LabAntibiotic({
    required this.id,
    required this.name,
    this.code,
    this.isActive = true,
    this.position = 0,
  });

  final String id;
  final String name;
  final String? code;
  final bool isActive;
  final int position;

  factory LabAntibiotic.fromJson(Map<String, dynamic> json) => LabAntibiotic(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        code: json['code'] as String?,
        isActive: (json['isActive'] as bool?) ?? true,
        position: (json['position'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (code != null) 'code': code,
        'isActive': isActive,
        'position': position,
      };
}

/// Susceptibility result option (e.g. Sensitive, Resistant).
class LabAstResultOption {
  const LabAstResultOption({
    required this.id,
    required this.label,
    this.code,
    this.isActive = true,
    this.position = 0,
  });

  final String id;
  final String label;
  final String? code;
  final bool isActive;
  final int position;

  factory LabAstResultOption.fromJson(Map<String, dynamic> json) =>
      LabAstResultOption(
        id: (json['id'] as String?) ?? '',
        label: (json['label'] as String?) ?? '',
        code: json['code'] as String?,
        isActive: (json['isActive'] as bool?) ?? true,
        position: (json['position'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        if (code != null) 'code': code,
        'isActive': isActive,
        'position': position,
      };
}

/// Single AST result row for an order item.
class LabAstResult {
  const LabAstResult({
    required this.id,
    required this.orderItemId,
    required this.antibiotic,
    required this.resultOption,
    this.enteredBy,
  });

  final String id;
  final String orderItemId;
  final LabAntibiotic antibiotic;
  final LabAstResultOption resultOption;
  final LabOrderStaff? enteredBy;

  factory LabAstResult.fromJson(Map<String, dynamic> json) => LabAstResult(
        id: (json['id'] as String?) ?? '',
        orderItemId: (json['orderItemId'] as String?) ?? '',
        antibiotic: LabAntibiotic.fromJson(
          json['antibiotic'] as Map<String, dynamic>,
        ),
        resultOption: LabAstResultOption.fromJson(
          json['resultOption'] as Map<String, dynamic>,
        ),
        enteredBy: json['enteredBy'] != null
            ? LabOrderStaff.fromJson(
                json['enteredBy'] as Map<String, dynamic>,
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderItemId': orderItemId,
        'antibiotic': antibiotic.toJson(),
        'resultOption': resultOption.toJson(),
        if (enteredBy != null) 'enteredBy': enteredBy!.toJson(),
      };
}
