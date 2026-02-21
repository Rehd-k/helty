// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InvoiceItem _$InvoiceItemFromJson(Map<String, dynamic> json) => _InvoiceItem(
  id: json['id'] as String,
  invoiceId: json['invoiceId'] as String,
  serviceId: json['serviceId'] as String,
  quantity: (json['quantity'] as num).toInt(),
  priceAtTime: (json['priceAtTime'] as num).toDouble(),
);

Map<String, dynamic> _$InvoiceItemToJson(_InvoiceItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'invoiceId': instance.invoiceId,
      'serviceId': instance.serviceId,
      'quantity': instance.quantity,
      'priceAtTime': instance.priceAtTime,
    };
