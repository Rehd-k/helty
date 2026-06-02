import 'dart:convert';

import 'package:helty/src/models/encounter_model.dart';

/// Formats primary, linked, and secondary diagnoses from an encounter for display.
String formatEncounterDiagnosis(EncounterModel encounter) {
  final parts = <String>[];

  var primaryCode = encounter.primaryIcdCode?.trim();
  var primaryDesc = encounter.primaryIcdDescription?.trim();
  if ((primaryCode == null || primaryCode.isEmpty) &&
      (primaryDesc == null || primaryDesc.isEmpty) &&
      encounter.linkedDiagnoses.isNotEmpty) {
    primaryCode = encounter.linkedDiagnoses.first.primaryIcdCode?.trim();
    primaryDesc = encounter.linkedDiagnoses.first.primaryIcdDescription?.trim();
  }

  if (primaryCode != null && primaryCode.isNotEmpty ||
      primaryDesc != null && primaryDesc.isNotEmpty) {
    final code = primaryCode ?? '';
    final desc = primaryDesc ?? '';
    if (code.isNotEmpty && desc.isNotEmpty) {
      parts.add('$code — $desc');
    } else {
      parts.add(code.isNotEmpty ? code : desc);
    }
  }

  for (final d in encounter.linkedDiagnoses) {
    if (d == encounter.linkedDiagnoses.first &&
        encounter.primaryIcdCode == null &&
        encounter.primaryIcdDescription == null) {
      continue;
    }
    final code = d.primaryIcdCode?.trim() ?? '';
    final desc = d.primaryIcdDescription?.trim() ?? '';
    if (code.isEmpty && desc.isEmpty) continue;
    parts.add(
      code.isNotEmpty && desc.isNotEmpty ? '$code — $desc' : (code.isNotEmpty ? code : desc),
    );
  }

  final secondary = _parseSecondary(encounter.secondaryDiagnosesJson);
  parts.addAll(secondary);

  if (parts.isEmpty) return '';
  return parts.join('; ');
}

List<String> _parseSecondary(String? jsonRaw) {
  if (jsonRaw == null || jsonRaw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(jsonRaw) as List<dynamic>?;
    if (decoded == null) return const [];
    final out = <String>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final code = item['code']?.toString().trim() ?? '';
      final desc =
          item['description']?.toString().trim() ??
          item['desc']?.toString().trim() ??
          '';
      if (code.isEmpty && desc.isEmpty) continue;
      out.add(
        code.isNotEmpty && desc.isNotEmpty ? '$code — $desc' : (code.isNotEmpty ? code : desc),
      );
    }
    return out;
  } catch (_) {
    return const [];
  }
}
