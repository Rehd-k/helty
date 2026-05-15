/// Human-facing hospital / invoice codes are 10 characters when valid.
String formatTenCharDisplayId(String? raw) {
  final s = (raw ?? '').trim();
  if (s.length == 10) return s;
  return 'No ID';
}

/// Picks the first non-empty candidate, then applies [formatTenCharDisplayId].
String resolveTenCharDisplayId(Iterable<String?> candidates) {
  for (final c in candidates) {
    final t = (c ?? '').trim();
    if (t.isNotEmpty) return formatTenCharDisplayId(t);
  }
  return 'No ID';
}
