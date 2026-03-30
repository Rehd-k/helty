import 'package:flutter/material.dart';

import 'receipt_escpos_service.dart';

class TransactionReceiptPrinter extends StatefulWidget {
  final Map<String, dynamic> data;

  /// When [sink] is [ReceiptPrintSink.network], set [printerIp].
  final String? printerIp;
  final int printerPort;

  final ReceiptPrintSink sink;

  /// Header under the logo.
  final String hospitalName;
  final String hospitalAddress;
  final String hospitalPhone;
  final String hospitalEmail;

  final String logoAssetPath;

  const TransactionReceiptPrinter({
    super.key,
    required this.data,
    this.printerIp,
    this.printerPort = 9100,
    this.sink = ReceiptPrintSink.windowsDefault,
    required this.hospitalName,
    required this.hospitalAddress,
    required this.hospitalPhone,
    required this.hospitalEmail,
    this.logoAssetPath = 'assets/logo.png',
  });

  @override
  State<TransactionReceiptPrinter> createState() =>
      _TransactionReceiptPrinterState();
}

class _TransactionReceiptPrinterState extends State<TransactionReceiptPrinter> {
  bool _isPrinting = false;

  ReceiptHospitalHeader get _header => ReceiptHospitalHeader(
    name: widget.hospitalName,
    address: widget.hospitalAddress,
    phone: widget.hospitalPhone,
    email: widget.hospitalEmail,
  );

  Future<void> _print({bool isCopy = false}) async {
    setState(() => _isPrinting = true);
    try {
      await ReceiptEscposService.printReceipt(
        data: widget.data,
        header: _header,
        sink: widget.sink,
        printerIp: widget.printerIp,
        printerPort: widget.printerPort,
        isCopy: isCopy,
        logoAssetPath: widget.logoAssetPath,
      );
    } catch (e) {
      debugPrint('Printing error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _isPrinting ? null : () => _print(isCopy: false),
          icon: const Icon(Icons.print),
          label: const Text('Print Receipt'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: _isPrinting ? null : () => _print(isCopy: true),
          child: const Text('Print Copy'),
        ),
      ],
    );
  }
}
