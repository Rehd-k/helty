import 'package:freezed_annotation/freezed_annotation.dart';

part 'invoice_item.freezed.dart';
part 'invoice_item.g.dart';

@freezed
class InvoiceItem with _$InvoiceItem {
  const factory InvoiceItem({
    required String id,
    required String invoiceId,
    required String serviceId,
    required int quantity,
    required double priceAtTime, // ← important: double, not int
  }) = _InvoiceItem;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) =>
      _$InvoiceItemFromJson(json);

  @override
  String get id => throw UnimplementedError();

  @override
  String get invoiceId => throw UnimplementedError();

  @override
  double get priceAtTime => throw UnimplementedError();

  @override
  int get quantity => throw UnimplementedError();

  @override
  String get serviceId => throw UnimplementedError();

  @override
  Map<String, dynamic> toJson() {
    throw UnimplementedError();
  }
}
