/// Local / connected Windows printer suitable for RAW thermal jobs.
class WindowsPrinterInfo {
  const WindowsPrinterInfo({required this.name, required this.isDefault});

  final String name;
  final bool isDefault;
}

Future<List<WindowsPrinterInfo>> listActiveWindowsPrinters() async => [];

Future<void> sendRawBytesToWindowsPrinter(
  String printerName,
  List<int> data,
) async {
  throw UnsupportedError(
    'Windows printer RAW output is only implemented on Windows.',
  );
}

Future<void> sendRawBytesToWindowsDefaultPrinter(List<int> data) async {
  throw UnsupportedError(
    'Windows printer RAW output is only implemented on Windows.',
  );
}
