import '../models/ward_models.dart';

const _chargeNurseRoles = {
  'WARD_CHARGE_NURSE',
  'ICU_CHARGE_NURSE',
  'EMERGENCY_CHARGE_NURSE',
  'OPD_CHARGE_NURSE',
  'ONG_CHARGE_NURSE',
};

const _emergencyKeywords = [
  'emergency',
  'er',
  'a&e',
  'a & e',
  'accident',
  'casualty',
];

const _opdKeywords = [
  'opd',
  'outpatient',
  'out patient',
  'out-patient',
  'clinic',
];

const _ongKeywords = [
  'obstetrics',
  'gynaecology',
  'gynecology',
  'o&g',
  'o & g',
  'obgyn',
  'maternity',
  'labour',
  'labor',
];

String _normalizeRole(String role) =>
    role.trim().toUpperCase().replaceAll('-', '_');

String _normalizeText(String? value) => value?.trim().toLowerCase() ?? '';

bool _matchesKeywords(String? text, List<String> keywords) {
  final normalized = _normalizeText(text);
  if (normalized.isEmpty) return false;
  for (final keyword in keywords) {
    if (normalized.contains(keyword)) return true;
  }
  return false;
}

bool isOpdLikeName(String? wardName, [String? departmentName]) =>
    _matchesKeywords(wardName, _opdKeywords) ||
    _matchesKeywords(departmentName, _opdKeywords);

bool isChargeNurseStaffRole(String role) =>
    _chargeNurseRoles.contains(_normalizeRole(role));

bool wardMatchesChargeNurseRole(Ward ward, String staffRole) {
  final r = _normalizeRole(staffRole);
  final wardName = ward.name;
  final deptName = ward.departmentName;

  switch (r) {
    case 'WARD_CHARGE_NURSE':
      return ward.type != WardType.icu && !isOpdLikeName(wardName, deptName);
    case 'ICU_CHARGE_NURSE':
      return ward.type == WardType.icu;
    case 'EMERGENCY_CHARGE_NURSE':
      return _matchesKeywords(wardName, _emergencyKeywords) ||
          _matchesKeywords(deptName, _emergencyKeywords);
    case 'OPD_CHARGE_NURSE':
      return isOpdLikeName(wardName, deptName);
    case 'ONG_CHARGE_NURSE':
      return _matchesKeywords(wardName, _ongKeywords) ||
          _matchesKeywords(deptName, _ongKeywords);
    default:
      return false;
  }
}

List<Ward> wardsForChargeNurseRole(String staffRole, List<Ward> all) {
  if (!isChargeNurseStaffRole(staffRole)) return const [];
  return all
      .where((w) => wardMatchesChargeNurseRole(w, staffRole))
      .toList(growable: false);
}

/// Wards for charge-nurse dropdowns: role-filtered when possible, otherwise all
/// wards from [GET /wards] (database). Ensures `wardId` is always a real ward id.
List<Ward> selectableWardsForChargeNurseRole(
  String staffRole,
  List<Ward> allWards, {
  String? currentWardId,
}) {
  if (allWards.isEmpty) return const [];

  var options = wardsForChargeNurseRole(staffRole, allWards);
  if (options.isEmpty) options = allWards;

  if (currentWardId != null &&
      currentWardId.isNotEmpty &&
      !options.any((w) => w.id == currentWardId)) {
    final current = allWards.where((w) => w.id == currentWardId).toList();
    if (current.isNotEmpty) {
      options = [...current, ...options];
    }
  }

  return options;
}

List<Ward> wardsForNursingUnit(String? nursingUnit, List<Ward> all) {
  final unit = nursingUnit?.trim().toUpperCase().replaceAll('-', '_');
  if (unit == null || unit.isEmpty) return all;

  return all.where((ward) {
    switch (unit) {
      case 'INPATIENT_WARD':
        return ward.type != WardType.icu && !isOpdLikeName(ward.name, ward.departmentName);
      case 'ICU':
        return ward.type == WardType.icu;
      case 'EMERGENCY':
        return _matchesKeywords(ward.name, _emergencyKeywords) ||
            _matchesKeywords(ward.departmentName, _emergencyKeywords);
      case 'OPD':
        return isOpdLikeName(ward.name, ward.departmentName);
      case 'ONG':
        return _matchesKeywords(ward.name, _ongKeywords) ||
            _matchesKeywords(ward.departmentName, _ongKeywords);
      default:
        return true;
    }
  }).toList(growable: false);
}
