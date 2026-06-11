import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:helty/src/core/utils/api_decimal.dart';
import 'package:helty/src/models/service_model.dart';

import '../paitients/patient_model.dart';

part 'invoice.freezed.dart';

@freezed
abstract class Invoice with _$Invoice {
  const Invoice._();

  const factory Invoice({
    required String id,
    required Patient patient,
    required Map<String, dynamic> staff,
    required String patientId,
    required String
    status, // consider → @JsonKey(name: 'status') TransactionStatus status later
    required String createdById,
    String? updatedById,
    String? staffId,
    required DateTime createdAt,
    required DateTime updatedAt,
    required List<ServiceModel> invoiceItems,
    required double totalAmount,
    required double amountPaid,
    String? encounterId,
    Map<String, dynamic>? createdBy,
    Map<String, dynamic>? count,

    /// Human-facing bill code (`invoiceID` from API), when present.
    String? invoiceDisplayId,
  }) = _Invoice;

  // Custom getter — now allowed
  double get total => totalAmount > 0
      ? totalAmount
      : invoiceItems.fold(
          0.0,
          (sum, item) => sum + ((item.qty ?? 1) * item.cost),
        );

  bool get hasDrugItems =>
      invoiceItems.any((item) => item.drugId?.trim().isNotEmpty ?? false);

  static double _parseDouble(dynamic value) => parseApiDecimal(value);

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final patientRaw = json['patient'];
    final staffRaw = json['staff'];
    final itemsRaw = json['invoiceItems'] ?? json['items'];

    final patientId =
        (json['patientId'] ??
                (patientRaw is Map<String, dynamic>
                    ? patientRaw['patientId']
                    : null) ??
                '')
            .toString();

    final patientJson = patientRaw is Map<String, dynamic>
        ? patientRaw
        : <String, dynamic>{'patientId': patientId};

    final staffJson = staffRaw is Map<String, dynamic>
        ? staffRaw
        : <String, dynamic>{};

    final invoiceItems = itemsRaw is List
        ? itemsRaw
              .whereType<Map>()
              .map((e) => ServiceModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <ServiceModel>[];
    final invoiceDisplayRaw = json['invoiceID']?.toString().trim();
    final invoiceDisplayId =
        invoiceDisplayRaw != null && invoiceDisplayRaw.isNotEmpty
        ? invoiceDisplayRaw
        : null;

    return _Invoice(
      id: (json['id'] ?? '').toString(),
      patient: Patient.fromJson(patientJson),
      staff: staffJson,
      patientId: patientId,
      invoiceDisplayId: invoiceDisplayId,
      status: (json['status'] ?? 'PENDING').toString(),
      createdById: (json['createdById'] ?? json['staffId'] ?? '').toString(),
      updatedById: json['updatedById'] as String?,
      staffId: (json['staffId'] ?? json['createdById'])?.toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      invoiceItems: invoiceItems,
      totalAmount: _parseDouble(json['totalAmount']),
      amountPaid: _parseDouble(json['amountPaid']),
      encounterId: json['encounterId'] as String?,
      createdBy: json['createdBy'] as Map<String, dynamic>?,
      count: json['_count'] as Map<String, dynamic>?,
    );
  }
}
