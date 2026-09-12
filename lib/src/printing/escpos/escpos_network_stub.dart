Future<void> sendEscposOverNetwork(
  String ip,
  int printerPort,
  List<int> bytes,
) async {
  throw UnsupportedError(
    'Network thermal printing is not available in the browser.',
  );
}
