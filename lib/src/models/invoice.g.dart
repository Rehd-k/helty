// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Invoice _$InvoiceFromJson(Map<String, dynamic> json) => _Invoice(
  id: json['id'] as String,
  patientId: json['patientId'] as String,
  status: json['status'] as String,
  createdById: json['createdById'] as String,
  updatedById: json['updatedById'] as String?,
  staffId: json['staffId'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  invoiceItems: (json['invoiceItems'] as List<dynamic>)
      .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$InvoiceToJson(_Invoice instance) => <String, dynamic>{
  'id': instance.id,
  'patientId': instance.patientId,
  'status': instance.status,
  'createdById': instance.createdById,
  'updatedById': instance.updatedById,
  'staffId': instance.staffId,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'invoiceItems': instance.invoiceItems,
};
