import 'package:freezed_annotation/freezed_annotation.dart';
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
  }) = _Invoice;

  // Custom getter — now allowed
  double get total => invoiceItems.fold(
    0.0,
    (sum, item) => sum + ((item.qty ?? 1) * item.cost),
  );

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

    return _Invoice(
      id: (json['id'] ?? '').toString(),
      patient: Patient.fromJson(patientJson),
      staff: staffJson,
      patientId: patientId,
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
    );
  }
}
