import 'package:freezed_annotation/freezed_annotation.dart';
import 'invoice_item.dart'; // adjust import path if needed

part 'invoice.freezed.dart';
part 'invoice.g.dart';

@freezed
class Invoice with _$Invoice {
  // ── This line is the fix ──
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
    required List<InvoiceItem> invoiceItems,
  }) = _Invoice;

  // Custom getter — now allowed
  double get total => invoiceItems.fold(
    0.0,
    (sum, item) => sum + (item.quantity * item.priceAtTime),
  );

  factory Invoice.fromJson(Map<String, dynamic> json) =>
      _$InvoiceFromJson(json);

  @override
  DateTime get createdAt => throw UnimplementedError();

  @override
  String get createdById => throw UnimplementedError();

  @override
  String get id => throw UnimplementedError();

  @override
  List<InvoiceItem> get invoiceItems => throw UnimplementedError();

  @override
  String get patientId => throw UnimplementedError();

  @override
  String? get staffId => throw UnimplementedError();

  @override
  String get status => throw UnimplementedError();

  @override
  Map<String, dynamic> toJson() {
    throw UnimplementedError();
  }

  @override
  DateTime get updatedAt => throw UnimplementedError();

  @override
  String? get updatedById => throw UnimplementedError();
}
