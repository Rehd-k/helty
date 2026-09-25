// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invoice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Invoice {

 String get id; Patient get patient; Map<String, dynamic> get staff; String get patientId; String get status; String get createdById; String? get updatedById; String? get staffId; DateTime get createdAt; DateTime get updatedAt; List<ServiceModel> get invoiceItems; double get totalAmount; double get amountPaid; String? get encounterId; Map<String, dynamic>? get createdBy; Map<String, dynamic>? get count;/// Human-facing bill code (`invoiceID` from API), when present.
 String? get invoiceDisplayId;/// `OUTPATIENT` | `INPATIENT` from staff invoice detail.
 String? get billType;/// Ward name when [billType] is inpatient.
 String? get wardName;
/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvoiceCopyWith<Invoice> get copyWith => _$InvoiceCopyWithImpl<Invoice>(this as Invoice, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Invoice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Invoice&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.patient, _this.patient) || other.patient == _this.patient)&&const DeepCollectionEquality().equals(other.staff, _this.staff)&&(identical(other.patientId, _this.patientId) || other.patientId == _this.patientId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdById, _this.createdById) || other.createdById == _this.createdById)&&(identical(other.updatedById, _this.updatedById) || other.updatedById == _this.updatedById)&&(identical(other.staffId, _this.staffId) || other.staffId == _this.staffId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&const DeepCollectionEquality().equals(other.invoiceItems, _this.invoiceItems)&&(identical(other.totalAmount, _this.totalAmount) || other.totalAmount == _this.totalAmount)&&(identical(other.amountPaid, _this.amountPaid) || other.amountPaid == _this.amountPaid)&&(identical(other.encounterId, _this.encounterId) || other.encounterId == _this.encounterId)&&const DeepCollectionEquality().equals(other.createdBy, _this.createdBy)&&const DeepCollectionEquality().equals(other.count, _this.count)&&(identical(other.invoiceDisplayId, _this.invoiceDisplayId) || other.invoiceDisplayId == _this.invoiceDisplayId)&&(identical(other.billType, _this.billType) || other.billType == _this.billType)&&(identical(other.wardName, _this.wardName) || other.wardName == _this.wardName));
}


@override
int get hashCode {
  final _this = this as Invoice;
  return Object.hashAll([runtimeType,_this.id,_this.patient,const DeepCollectionEquality().hash(_this.staff),_this.patientId,_this.status,_this.createdById,_this.updatedById,_this.staffId,_this.createdAt,_this.updatedAt,const DeepCollectionEquality().hash(_this.invoiceItems),_this.totalAmount,_this.amountPaid,_this.encounterId,const DeepCollectionEquality().hash(_this.createdBy),const DeepCollectionEquality().hash(_this.count),_this.invoiceDisplayId,_this.billType,_this.wardName]);
}

@override
String toString() {
  final _this = this as Invoice;
  return 'Invoice(id: ${_this.id}, patient: ${_this.patient}, staff: ${_this.staff}, patientId: ${_this.patientId}, status: ${_this.status}, createdById: ${_this.createdById}, updatedById: ${_this.updatedById}, staffId: ${_this.staffId}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, invoiceItems: ${_this.invoiceItems}, totalAmount: ${_this.totalAmount}, amountPaid: ${_this.amountPaid}, encounterId: ${_this.encounterId}, createdBy: ${_this.createdBy}, count: ${_this.count}, invoiceDisplayId: ${_this.invoiceDisplayId}, billType: ${_this.billType}, wardName: ${_this.wardName})';
}


}

/// @nodoc
abstract mixin class $InvoiceCopyWith<$Res>  {
  factory $InvoiceCopyWith(Invoice value, $Res Function(Invoice) _then) = _$InvoiceCopyWithImpl;
@useResult
$Res call({
 String id, Patient patient, Map<String, dynamic> staff, String patientId, String status, String createdById, String? updatedById, String? staffId, DateTime createdAt, DateTime updatedAt, List<ServiceModel> invoiceItems, double totalAmount, double amountPaid, String? encounterId, Map<String, dynamic>? createdBy, Map<String, dynamic>? count, String? invoiceDisplayId, String? billType, String? wardName
});




}
/// @nodoc
class _$InvoiceCopyWithImpl<$Res>
    implements $InvoiceCopyWith<$Res> {
  _$InvoiceCopyWithImpl(this._self, this._then);

  final Invoice _self;
  final $Res Function(Invoice) _then;

/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? patient = null,Object? staff = null,Object? patientId = null,Object? status = null,Object? createdById = null,Object? updatedById = freezed,Object? staffId = freezed,Object? createdAt = null,Object? updatedAt = null,Object? invoiceItems = null,Object? totalAmount = null,Object? amountPaid = null,Object? encounterId = freezed,Object? createdBy = freezed,Object? count = freezed,Object? invoiceDisplayId = freezed,Object? billType = freezed,Object? wardName = freezed,}) {
  return _then(Invoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patient: null == patient ? _self.patient : patient // ignore: cast_nullable_to_non_nullable
as Patient,staff: null == staff ? _self.staff : staff // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdById: null == createdById ? _self.createdById : createdById // ignore: cast_nullable_to_non_nullable
as String,updatedById: freezed == updatedById ? _self.updatedById : updatedById // ignore: cast_nullable_to_non_nullable
as String?,staffId: freezed == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,invoiceItems: null == invoiceItems ? _self.invoiceItems : invoiceItems // ignore: cast_nullable_to_non_nullable
as List<ServiceModel>,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,amountPaid: null == amountPaid ? _self.amountPaid : amountPaid // ignore: cast_nullable_to_non_nullable
as double,encounterId: freezed == encounterId ? _self.encounterId : encounterId // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,count: freezed == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,invoiceDisplayId: freezed == invoiceDisplayId ? _self.invoiceDisplayId : invoiceDisplayId // ignore: cast_nullable_to_non_nullable
as String?,billType: freezed == billType ? _self.billType : billType // ignore: cast_nullable_to_non_nullable
as String?,wardName: freezed == wardName ? _self.wardName : wardName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Invoice].
extension InvoicePatterns on Invoice {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Invoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Invoice() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Invoice value)  $default,){
final _that = this;
switch (_that) {
case _Invoice():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Invoice value)?  $default,){
final _that = this;
switch (_that) {
case _Invoice() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Patient patient,  Map<String, dynamic> staff,  String patientId,  String status,  String createdById,  String? updatedById,  String? staffId,  DateTime createdAt,  DateTime updatedAt,  List<ServiceModel> invoiceItems,  double totalAmount,  double amountPaid,  String? encounterId,  Map<String, dynamic>? createdBy,  Map<String, dynamic>? count,  String? invoiceDisplayId,  String? billType,  String? wardName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Invoice() when $default != null:
return $default(_that.id,_that.patient,_that.staff,_that.patientId,_that.status,_that.createdById,_that.updatedById,_that.staffId,_that.createdAt,_that.updatedAt,_that.invoiceItems,_that.totalAmount,_that.amountPaid,_that.encounterId,_that.createdBy,_that.count,_that.invoiceDisplayId,_that.billType,_that.wardName);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Patient patient,  Map<String, dynamic> staff,  String patientId,  String status,  String createdById,  String? updatedById,  String? staffId,  DateTime createdAt,  DateTime updatedAt,  List<ServiceModel> invoiceItems,  double totalAmount,  double amountPaid,  String? encounterId,  Map<String, dynamic>? createdBy,  Map<String, dynamic>? count,  String? invoiceDisplayId,  String? billType,  String? wardName)  $default,) {final _that = this;
switch (_that) {
case _Invoice():
return $default(_that.id,_that.patient,_that.staff,_that.patientId,_that.status,_that.createdById,_that.updatedById,_that.staffId,_that.createdAt,_that.updatedAt,_that.invoiceItems,_that.totalAmount,_that.amountPaid,_that.encounterId,_that.createdBy,_that.count,_that.invoiceDisplayId,_that.billType,_that.wardName);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Patient patient,  Map<String, dynamic> staff,  String patientId,  String status,  String createdById,  String? updatedById,  String? staffId,  DateTime createdAt,  DateTime updatedAt,  List<ServiceModel> invoiceItems,  double totalAmount,  double amountPaid,  String? encounterId,  Map<String, dynamic>? createdBy,  Map<String, dynamic>? count,  String? invoiceDisplayId,  String? billType,  String? wardName)?  $default,) {final _that = this;
switch (_that) {
case _Invoice() when $default != null:
return $default(_that.id,_that.patient,_that.staff,_that.patientId,_that.status,_that.createdById,_that.updatedById,_that.staffId,_that.createdAt,_that.updatedAt,_that.invoiceItems,_that.totalAmount,_that.amountPaid,_that.encounterId,_that.createdBy,_that.count,_that.invoiceDisplayId,_that.billType,_that.wardName);case _:
  return null;

}
}

}

/// @nodoc


class _Invoice extends Invoice {
  const _Invoice({required this.id, required this.patient, required  Map<String, dynamic> staff, required this.patientId, required this.status, required this.createdById, this.updatedById, this.staffId, required this.createdAt, required this.updatedAt, required  List<ServiceModel> invoiceItems, required this.totalAmount, required this.amountPaid, this.encounterId,  Map<String, dynamic>? createdBy,  Map<String, dynamic>? count, this.invoiceDisplayId, this.billType, this.wardName}): _staff = staff,_invoiceItems = invoiceItems,_createdBy = createdBy,_count = count,super._();
  

@override final  String id;
@override final  Patient patient;
 final  Map<String, dynamic> _staff;
@override Map<String, dynamic> get staff {
  if (_staff is EqualUnmodifiableMapView) return _staff;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_staff);
}

@override final  String patientId;
@override final  String status;
@override final  String createdById;
@override final  String? updatedById;
@override final  String? staffId;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
 final  List<ServiceModel> _invoiceItems;
@override List<ServiceModel> get invoiceItems {
  if (_invoiceItems is EqualUnmodifiableListView) return _invoiceItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_invoiceItems);
}

@override final  double totalAmount;
@override final  double amountPaid;
@override final  String? encounterId;
 final  Map<String, dynamic>? _createdBy;
@override Map<String, dynamic>? get createdBy {
  final value = _createdBy;
  if (value == null) return null;
  if (_createdBy is EqualUnmodifiableMapView) return _createdBy;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _count;
@override Map<String, dynamic>? get count {
  final value = _count;
  if (value == null) return null;
  if (_count is EqualUnmodifiableMapView) return _count;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Human-facing bill code (`invoiceID` from API), when present.
@override final  String? invoiceDisplayId;
/// `OUTPATIENT` | `INPATIENT` from staff invoice detail.
@override final  String? billType;
/// Ward name when [billType] is inpatient.
@override final  String? wardName;

/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvoiceCopyWith<_Invoice> get copyWith => __$InvoiceCopyWithImpl<_Invoice>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Invoice&&(identical(other.id, id) || other.id == id)&&(identical(other.patient, patient) || other.patient == patient)&&const DeepCollectionEquality().equals(other.staff, _staff)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdById, createdById) || other.createdById == createdById)&&(identical(other.updatedById, updatedById) || other.updatedById == updatedById)&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.invoiceItems, _invoiceItems)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.amountPaid, amountPaid) || other.amountPaid == amountPaid)&&(identical(other.encounterId, encounterId) || other.encounterId == encounterId)&&const DeepCollectionEquality().equals(other.createdBy, _createdBy)&&const DeepCollectionEquality().equals(other.count, _count)&&(identical(other.invoiceDisplayId, invoiceDisplayId) || other.invoiceDisplayId == invoiceDisplayId)&&(identical(other.billType, billType) || other.billType == billType)&&(identical(other.wardName, wardName) || other.wardName == wardName));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,id,patient,const DeepCollectionEquality().hash(_staff),patientId,status,createdById,updatedById,staffId,createdAt,updatedAt,const DeepCollectionEquality().hash(_invoiceItems),totalAmount,amountPaid,encounterId,const DeepCollectionEquality().hash(_createdBy),const DeepCollectionEquality().hash(_count),invoiceDisplayId,billType,wardName]);
}

@override
String toString() {
    return 'Invoice(id: $id, patient: $patient, staff: $staff, patientId: $patientId, status: $status, createdById: $createdById, updatedById: $updatedById, staffId: $staffId, createdAt: $createdAt, updatedAt: $updatedAt, invoiceItems: $invoiceItems, totalAmount: $totalAmount, amountPaid: $amountPaid, encounterId: $encounterId, createdBy: $createdBy, count: $count, invoiceDisplayId: $invoiceDisplayId, billType: $billType, wardName: $wardName)';
}


}

/// @nodoc
abstract mixin class _$InvoiceCopyWith<$Res> implements $InvoiceCopyWith<$Res> {
  factory _$InvoiceCopyWith(_Invoice value, $Res Function(_Invoice) _then) = __$InvoiceCopyWithImpl;
@override @useResult
$Res call({
 String id, Patient patient, Map<String, dynamic> staff, String patientId, String status, String createdById, String? updatedById, String? staffId, DateTime createdAt, DateTime updatedAt, List<ServiceModel> invoiceItems, double totalAmount, double amountPaid, String? encounterId, Map<String, dynamic>? createdBy, Map<String, dynamic>? count, String? invoiceDisplayId, String? billType, String? wardName
});




}
/// @nodoc
class __$InvoiceCopyWithImpl<$Res>
    implements _$InvoiceCopyWith<$Res> {
  __$InvoiceCopyWithImpl(this._self, this._then);

  final _Invoice _self;
  final $Res Function(_Invoice) _then;

/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patient = null,Object? staff = null,Object? patientId = null,Object? status = null,Object? createdById = null,Object? updatedById = freezed,Object? staffId = freezed,Object? createdAt = null,Object? updatedAt = null,Object? invoiceItems = null,Object? totalAmount = null,Object? amountPaid = null,Object? encounterId = freezed,Object? createdBy = freezed,Object? count = freezed,Object? invoiceDisplayId = freezed,Object? billType = freezed,Object? wardName = freezed,}) {
  return _then(_Invoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patient: null == patient ? _self.patient : patient // ignore: cast_nullable_to_non_nullable
as Patient,staff: null == staff ? _self._staff : staff // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdById: null == createdById ? _self.createdById : createdById // ignore: cast_nullable_to_non_nullable
as String,updatedById: freezed == updatedById ? _self.updatedById : updatedById // ignore: cast_nullable_to_non_nullable
as String?,staffId: freezed == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,invoiceItems: null == invoiceItems ? _self._invoiceItems : invoiceItems // ignore: cast_nullable_to_non_nullable
as List<ServiceModel>,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,amountPaid: null == amountPaid ? _self.amountPaid : amountPaid // ignore: cast_nullable_to_non_nullable
as double,encounterId: freezed == encounterId ? _self.encounterId : encounterId // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self._createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,count: freezed == count ? _self._count : count // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,invoiceDisplayId: freezed == invoiceDisplayId ? _self.invoiceDisplayId : invoiceDisplayId // ignore: cast_nullable_to_non_nullable
as String?,billType: freezed == billType ? _self.billType : billType // ignore: cast_nullable_to_non_nullable
as String?,wardName: freezed == wardName ? _self.wardName : wardName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
