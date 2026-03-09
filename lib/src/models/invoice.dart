import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:helty/src/models/service_model.dart';

part 'invoice.freezed.dart';
part 'invoice.g.dart';

@freezed
abstract class Invoice with _$Invoice {
  const Invoice._();

  const factory Invoice({
    required String id,
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

  factory Invoice.fromJson(Map<String, dynamic> json) =>
      _$InvoiceFromJson(json);
}
