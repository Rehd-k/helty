import 'package:helty/src/core/utils/api_decimal.dart';

/// Single MAR row from GET `/admissions/:admissionId/medication-administrations`.
class MedicationAdministrationModel {
  const MedicationAdministrationModel({
    required this.id,
    this.scheduledTime,
    this.actualTime,
    required this.status,
    this.quantity,
    this.reasonIfNotGiven,
    this.drugName,
    this.dose,
    this.route,
    this.nurseDisplayName,
  });

  final String id;
  final DateTime? scheduledTime;
  final DateTime? actualTime;
  final String status;

  /// Units administered when [status] is GIVEN (API: Decimal 12,3).
  final double? quantity;
  final String? reasonIfNotGiven;
  final String? drugName;
  final String? dose;
  final String? route;
  final String? nurseDisplayName;

  static DateTime? _parseDt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static String _str(dynamic v) => v?.toString() ?? '';

  static double? _parseQuantity(dynamic v) => tryParseApiDecimal(v);

  factory MedicationAdministrationModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? asMap(dynamic e) =>
        e is Map ? Map<String, dynamic>.from(e) : null;

    final order = asMap(json['medicationOrder']) ??
        asMap(json['medication_order']) ??
        asMap(json['order']);

    var drugName = order != null
        ? _str(order['drugName'] ?? order['drug_name'])
        : '';
    var dose = order != null ? _str(order['dose']) : '';
    var route = order != null ? _str(order['route']) : '';

    if (drugName.isEmpty) {
      drugName = _str(json['drugName'] ?? json['drug_name']);
    }
    if (dose.isEmpty) dose = _str(json['dose']);
    if (route.isEmpty) route = _str(json['route']);

    final nurseMap = asMap(json['nurse']) ??
        asMap(json['recorder']) ??
        asMap(json['recordedBy']) ??
        asMap(json['recorded_by']);
    Map<String, dynamic>? staff;
    if (nurseMap != null) {
      staff = asMap(nurseMap['staff']) ?? nurseMap;
    }

    var nurseName = '';
    if (staff != null) {
      final first = _str(staff['firstName'] ?? staff['first_name']);
      final last = _str(staff['surname'] ?? staff['lastName'] ?? staff['last_name']);
      final combined = [first, last].where((s) => s.isNotEmpty).join(' ');
      nurseName = combined.isNotEmpty
          ? combined
          : _str(staff['displayName'] ?? staff['name']);
    }
    if (nurseName.isEmpty) {
      nurseName = _str(json['nurseName'] ?? json['recordedByName']);
    }

    return MedicationAdministrationModel(
      id: _str(json['id']),
      scheduledTime: _parseDt(json['scheduledTime'] ?? json['scheduled_time']),
      actualTime: _parseDt(json['actualTime'] ?? json['actual_time']),
      status: _str(json['status']),
      quantity: _parseQuantity(json['quantity']),
      reasonIfNotGiven: json['reasonIfNotGiven']?.toString() ??
          json['reason_if_not_given']?.toString(),
      drugName: drugName.isEmpty ? null : drugName,
      dose: dose.isEmpty ? null : dose,
      route: route.isEmpty ? null : route,
      nurseDisplayName: nurseName.isEmpty ? null : nurseName,
    );
  }

  /// Best time for sorting / display (prefer actual, then scheduled).
  DateTime? get sortTime => actualTime ?? scheduledTime;
}
