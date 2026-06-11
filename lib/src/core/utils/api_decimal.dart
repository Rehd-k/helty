/// Parses API numeric values, including Prisma/decimal.js `{s, e, d}` objects.
double parseApiDecimal(dynamic value, {double fallback = 0}) {
  return tryParseApiDecimal(value) ?? fallback;
}

/// Like [parseApiDecimal] but returns `null` when [value] cannot be parsed.
double? tryParseApiDecimal(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  if (value is Map) return _parseDecimalJsMap(value);
  return null;
}

double? _parseDecimalJsMap(Map<dynamic, dynamic> map) {
  final digitsRaw = map['d'];
  final exponentRaw = map['e'];
  if (digitsRaw is! List || exponentRaw is! num) return null;
  if (digitsRaw.isEmpty) return 0;

  final coefficient = digitsRaw.map((chunk) => chunk.toString()).join();
  if (coefficient.isEmpty) return 0;

  final exponent = exponentRaw.toInt();
  final decimalPlaces = coefficient.length - exponent - 1;

  final String numericString;
  if (decimalPlaces > 0) {
    if (coefficient.length <= decimalPlaces) {
      final frac = coefficient.padLeft(decimalPlaces, '0');
      numericString = '0.$frac';
    } else {
      final whole = coefficient.substring(0, coefficient.length - decimalPlaces);
      final frac = coefficient.substring(coefficient.length - decimalPlaces);
      numericString = '$whole.$frac';
    }
  } else {
    numericString = coefficient + ('0' * -decimalPlaces);
  }

  final parsed = double.tryParse(numericString);
  if (parsed == null) return null;

  final signRaw = map['s'];
  final sign = signRaw is num && signRaw < 0 ? -1.0 : 1.0;
  return parsed * sign;
}

/// True when [value] looks like a Prisma/decimal.js serialized decimal.
bool isDecimalJsMap(dynamic value) {
  if (value is! Map) return false;
  final digits = value['d'];
  final exponent = value['e'];
  final sign = value['s'];
  return digits is List &&
      exponent is num &&
      sign is num &&
      value.length <= 3;
}

/// Recursively replaces `{s, e, d}` decimal maps in API JSON with [double] values.
dynamic normalizeApiDecimals(dynamic value) {
  if (isDecimalJsMap(value)) {
    return parseApiDecimal(value);
  }
  if (value is List) {
    return value.map(normalizeApiDecimals).toList();
  }
  if (value is Map) {
    // Preserve Map<String, dynamic> — plain Map.map() yields Map<dynamic, dynamic>
    // and breaks downstream `as Map<String, dynamic>` casts (e.g. auth/login).
    final normalized = <String, dynamic>{};
    value.forEach((key, nested) {
      normalized[key.toString()] = normalizeApiDecimals(nested);
    });
    return normalized;
  }
  return value;
}
