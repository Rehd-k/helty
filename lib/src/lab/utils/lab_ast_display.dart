import '../models/lab_models.dart';

enum LabAstInterpretation { sensitive, intermediate, resistant, other }

LabAstInterpretation classifyLabAstResult(LabAstResultOption option) {
  final code = (option.code ?? '').trim().toUpperCase();
  final label = option.label.trim().toLowerCase();
  if (code == 'S' ||
      label.startsWith('sensit') ||
      label.startsWith('suscept')) {
    return LabAstInterpretation.sensitive;
  }
  if (code == 'R' || label.startsWith('resist')) {
    return LabAstInterpretation.resistant;
  }
  if (code == 'I' || label.startsWith('inter') || label.startsWith('moder')) {
    return LabAstInterpretation.intermediate;
  }
  return LabAstInterpretation.other;
}

int compareLabAstResults(LabAstResult a, LabAstResult b) {
  final byPosition = a.antibiotic.position.compareTo(b.antibiotic.position);
  if (byPosition != 0) return byPosition;
  return a.antibiotic.name.toLowerCase().compareTo(
    b.antibiotic.name.toLowerCase(),
  );
}

List<LabAstResult> sortedLabAstResults(Iterable<LabAstResult> results) {
  return List<LabAstResult>.from(results)..sort(compareLabAstResults);
}

String labAstAntibioticName(LabAntibiotic antibiotic) {
  final name = antibiotic.name.trim();
  return name.isEmpty ? '-' : name;
}

String labAstAntibioticCode(LabAntibiotic antibiotic) {
  final code = antibiotic.code?.trim() ?? '';
  return code.isEmpty ? '-' : code;
}

/// Full susceptibility text, e.g. `Sensitive (S)`.
String labAstResultText(LabAstResultOption option) {
  final label = option.label.trim();
  final code = option.code?.trim() ?? '';
  if (label.isEmpty) return code.isEmpty ? '-' : code;
  if (code.isEmpty || label.toUpperCase() == code.toUpperCase()) return label;
  return '$label ($code)';
}

/// Reads a free-text susceptibility token such as `R`, `S`, or `3+`.
LabAstInterpretation classifyAstToken(String token) {
  final value = token.trim().toLowerCase();
  if (value == 'r' || value.startsWith('resist')) {
    return LabAstInterpretation.resistant;
  }
  if (value == 's' ||
      value.startsWith('sensit') ||
      value.startsWith('suscept') ||
      value == '3+' ||
      value == '4+' ||
      value == '+++' ||
      value == '++++') {
    return LabAstInterpretation.sensitive;
  }
  if (value == 'i' ||
      value.startsWith('inter') ||
      value == '2+' ||
      value == '++') {
    return LabAstInterpretation.intermediate;
  }
  return LabAstInterpretation.other;
}

class EmbeddedAstRow {
  const EmbeddedAstRow({required this.antibiotic, required this.result});

  final String antibiotic;
  final String result;
}

class EmbeddedAstLegend {
  const EmbeddedAstLegend({required this.code, required this.meaning});

  final String code;
  final String meaning;
}

/// Culture narrative plus the antibiotic lines pasted into one result value.
class EmbeddedAstReport {
  const EmbeddedAstReport({
    required this.narrative,
    required this.rows,
    required this.legend,
  });

  final String narrative;
  final List<EmbeddedAstRow> rows;
  final List<EmbeddedAstLegend> legend;
}

final _astLegendLine = RegExp(
  r'^([A-Za-z0-9+]+)\s*=\s*([A-Za-z][A-Za-z /+-]*)$',
);
final _astResultToken = RegExp(
  r'^(?:[1-4]\+|\+{1,4}|S|R|I|SS|MS|NS|Sensitive|Susceptible|Resistant|Resistance|Intermediate|Sensitivity)$',
  caseSensitive: false,
);

/// Pulls an antibiotic table out of a result value like the pasted MCS block.
/// Returns null when the value is an ordinary result.
EmbeddedAstReport? parseEmbeddedAstReport(String raw) {
  if (!raw.toUpperCase().contains('ANTIBIOTIC')) return null;
  final lines = raw.replaceAll('\r\n', '\n').split('\n');
  var start = -1;
  for (var i = 0; i < lines.length; i++) {
    if (_isAstHeader(_plainAstLine(lines[i]))) {
      start = i;
      break;
    }
  }
  if (start < 0) return null;

  final narrative = lines
      .take(start)
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
  final rows = <EmbeddedAstRow>[];
  final legend = <EmbeddedAstLegend>[];
  for (final line in lines.skip(start)) {
    final plain = _plainAstLine(line);
    if (plain.isEmpty || _isAstHeader(plain)) continue;
    final legendItem = _parseAstLegend(plain);
    if (legendItem != null) {
      legend.add(legendItem);
      continue;
    }
    final row = _parseAstDataLine(line);
    if (row != null) rows.add(row);
  }
  if (rows.length < 2) return null;
  return EmbeddedAstReport(narrative: narrative, rows: rows, legend: legend);
}

/// Narrative for previews. Ordinary values are returned unchanged.
String labResultReadableValue(String value) {
  final report = parseEmbeddedAstReport(value);
  if (report == null) return value.trim();
  if (report.narrative.isNotEmpty) return report.narrative;
  return 'Antibiotic susceptibility (${report.rows.length})';
}

/// Plain-text susceptibility block for messages.
String formatEmbeddedAstMessage(String value) {
  final report = parseEmbeddedAstReport(value);
  if (report == null) return value.trim();
  final buffer = StringBuffer();
  if (report.narrative.isNotEmpty) buffer.writeln(report.narrative);
  buffer.writeln('Antibiotic | Result');
  for (final row in report.rows) {
    buffer.writeln('${row.antibiotic} | ${row.result}');
  }
  for (final item in report.legend) {
    buffer.writeln('${item.code} = ${item.meaning}');
  }
  return buffer.toString().trim();
}

String _plainAstLine(String line) {
  return line
      .replaceAll('\t', ' ')
      .replaceAll('\r', ' ')
      .replaceAll(RegExp(r' +'), ' ')
      .trim();
}

bool _isAstHeader(String plain) {
  final normalized = plain
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return normalized == 'ANTIBIOTIC SUSCEPTIBILITY' ||
      normalized == 'ANTIBIOTIC SENSITIVITY' ||
      normalized == 'ANTIBIOTIC USED' ||
      normalized == 'ANTIBIOTICS USED' ||
      normalized.startsWith('ANTIBIOTIC SUSCEPT') ||
      normalized.startsWith('ANTIBIOTIC SENSIT');
}

EmbeddedAstLegend? _parseAstLegend(String plain) {
  final match = _astLegendLine.firstMatch(plain);
  if (match == null) return null;
  final code = match.group(1)!.trim().toUpperCase();
  final meaning = _astTitleCase(match.group(2)!.trim());
  return EmbeddedAstLegend(code: code, meaning: meaning);
}

EmbeddedAstRow? _parseAstDataLine(String line) {
  String? name;
  String? result;
  if (line.contains('\r')) {
    final parts = line
        .split('\r')
        .map((part) => part.replaceAll('\t', ' ').trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      name = parts.first;
      result = _extractAstResult(parts.sublist(1).join(' '));
    }
  }
  if (result == null) {
    final parts = line
        .split(RegExp(r'\t+| {2,}'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      result = _extractAstResult(parts.last);
      if (result != null) {
        name = parts.sublist(0, parts.length - 1).join(' ');
      }
    }
  }
  if (name == null || result == null) return null;
  name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (name.length < 3 || name.length > 60 || name.contains('=')) return null;
  if (!RegExp(r'^[A-Za-z]').hasMatch(name)) return null;
  if (_isAstHeader(name)) return null;
  return EmbeddedAstRow(antibiotic: name, result: result);
}

String? _extractAstResult(String raw) {
  final token = raw.trim().split(RegExp(r'\s+')).firstWhere(
    (part) => part.isNotEmpty,
    orElse: () => '',
  );
  if (!_astResultToken.hasMatch(token)) return null;
  if (RegExp(r'^[A-Za-z]$').hasMatch(token) ||
      RegExp(r'^[1-4]\+$').hasMatch(token) ||
      RegExp(r'^\++$').hasMatch(token)) {
    return token.toUpperCase();
  }
  return _astTitleCase(token);
}

String _astTitleCase(String value) {
  final lower = value.toLowerCase();
  if (lower.isEmpty) return value;
  return '${lower[0].toUpperCase()}${lower.substring(1)}';
}

/// Short key for the printed legend, built only from codes that were reported.
String? labAstResultLegend(Iterable<LabAstResult> results) {
  final seen = <String, String>{};
  for (final result in results) {
    final code = result.resultOption.code?.trim() ?? '';
    final label = result.resultOption.label.trim();
    if (code.isEmpty || label.isEmpty) continue;
    if (code.toUpperCase() == label.toUpperCase()) continue;
    seen.putIfAbsent(code.toUpperCase(), () => '$code $label');
  }
  if (seen.isEmpty) return null;
  final lines = seen.values.toList()..sort();
  return lines.join(' | ');
}
