/// Response from `GET /server-time`.
class ServerTimePayload {
  const ServerTimePayload({required this.iso, required this.unixMs});

  final String iso;
  final int unixMs;

  factory ServerTimePayload.fromJson(Map<String, dynamic> json) {
    final unixRaw = json['unixMs'];
    if (unixRaw is! num) {
      throw FormatException('server-time: unixMs must be a number');
    }
    final isoRaw = json['iso'];
    if (isoRaw is! String || isoRaw.isEmpty) {
      throw FormatException('server-time: iso must be a non-empty string');
    }
    return ServerTimePayload(iso: isoRaw, unixMs: unixRaw.toInt());
  }
}
