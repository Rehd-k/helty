/// Parses CSV tariff files for HMO service pricing import.

class HmoTariffImportRow {
  HmoTariffImportRow({
    required this.lineNumber,
    this.serviceId,
    this.serviceCode,
    this.cost,
    this.error,
  });

  final int lineNumber;
  final String? serviceId;
  final String? serviceCode;
  final double? cost;
  final String? error;

  bool get isValid =>
      error == null &&
      cost != null &&
      cost! >= 0 &&
      ((serviceId != null && serviceId!.isNotEmpty) ||
          (serviceCode != null && serviceCode!.isNotEmpty));
}

class HmoTariffCsvParseResult {
  const HmoTariffCsvParseResult({required this.rows});

  final List<HmoTariffImportRow> rows;

  List<HmoTariffImportRow> get validRows =>
      rows.where((r) => r.isValid).toList();
  List<HmoTariffImportRow> get invalidRows =>
      rows.where((r) => !r.isValid).toList();
}

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

const _serviceIdHeaders = {'serviceid', 'service_id', 'id', 'uuid'};
const _serviceCodeHeaders = {'servicecode', 'service_code', 'code'};
const _costHeaders = {'cost', 'price', 'amount', 'fullcost'};

/// Parses CSV text into import rows. Supports optional header row.
HmoTariffCsvParseResult parseHmoTariffCsv(String text) {
  final lines = _splitLines(text);
  if (lines.isEmpty) {
    return const HmoTariffCsvParseResult(rows: []);
  }

  final firstCells = _parseCsvLine(lines.first);
  final headerMap = _detectHeaders(firstCells);
  final dataStart = headerMap != null ? 1 : 0;

  final rows = <HmoTariffImportRow>[];
  for (var i = dataStart; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;

    final cells = _parseCsvLine(line);
    final lineNumber = i + 1;

    String? serviceId;
    String? serviceCode;
    double? cost;
    String? error;

    if (headerMap != null) {
      serviceId = _cellAt(cells, headerMap['serviceId'])?.trim();
      serviceCode = _cellAt(cells, headerMap['serviceCode'])?.trim();
      final costRaw = _cellAt(cells, headerMap['cost']);
      cost = _parseCost(costRaw);
    } else {
      if (cells.length >= 2) {
        final first = cells[0].trim();
        final second = cells[1].trim();
        if (_looksLikeUuid(first)) {
          serviceId = first;
        } else {
          serviceCode = first;
        }
        cost = _parseCost(second);
      } else if (cells.length == 1) {
        error = 'Expected at least two columns (identifier and cost)';
      }
    }

    if (error == null) {
      final hasId = serviceId != null && serviceId.isNotEmpty;
      final hasCode = serviceCode != null && serviceCode.isNotEmpty;
      if (!hasId && !hasCode) {
        error = 'Missing service identifier (serviceId or serviceCode)';
      } else if (hasId && !_looksLikeUuid(serviceId)) {
        error = 'Invalid service UUID format';
      } else if (cost == null) {
        error = 'Invalid or missing cost amount';
      }
    }

    rows.add(
      HmoTariffImportRow(
        lineNumber: lineNumber,
        serviceId: serviceId?.isEmpty == true ? null : serviceId,
        serviceCode: serviceCode?.isEmpty == true ? null : serviceCode,
        cost: cost,
        error: error,
      ),
    );
  }

  return HmoTariffCsvParseResult(rows: rows);
}

List<String> _splitLines(String text) {
  return text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
}

Map<String, int>? _detectHeaders(List<String> cells) {
  if (cells.isEmpty) return null;

  int? serviceIdIdx;
  int? serviceCodeIdx;
  int? costIdx;

  for (var i = 0; i < cells.length; i++) {
    final normalized = cells[i].trim().toLowerCase().replaceAll(' ', '_');
    if (_serviceIdHeaders.contains(normalized)) {
      serviceIdIdx = i;
    } else if (_serviceCodeHeaders.contains(normalized)) {
      serviceCodeIdx = i;
    } else if (_costHeaders.contains(normalized)) {
      costIdx = i;
    }
  }

  if (costIdx == null || (serviceIdIdx == null && serviceCodeIdx == null)) {
    return null;
  }

  return {
    if (serviceIdIdx != null) 'serviceId': serviceIdIdx,
    if (serviceCodeIdx != null) 'serviceCode': serviceCodeIdx,
    'cost': costIdx,
  };
}

String? _cellAt(List<String> cells, int? index) {
  if (index == null || index < 0 || index >= cells.length) return null;
  return cells[index];
}

double? _parseCost(String? raw) {
  if (raw == null) return null;
  final t = raw.trim().replaceAll(',', '');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

bool _looksLikeUuid(String value) => _uuidPattern.hasMatch(value.trim());

/// Minimal RFC4180-style CSV line parser (handles quoted fields).
List<String> _parseCsvLine(String line) {
  final result = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        buffer.write(c);
      }
    } else if (c == '"') {
      inQuotes = true;
    } else if (c == ',') {
      result.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(c);
    }
  }
  result.add(buffer.toString());
  return result;
}

const hmoTariffCsvTemplate = '''serviceCode,cost
LAB-FBC,3500
RAD-XRAY,12000''';
