import 'dart:io';

import 'package:flutter/material.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';

class TransactionReceiptPrinter extends StatefulWidget {
  final Map<String, dynamic> data;

  /// Printer details
  final String printerIp;
  final int printerPort;

  /// Header details from parent
  final String hospitalName;
  final String hospitalAddress;
  final String hospitalPhone;
  final String hospitalEmail;

  const TransactionReceiptPrinter({
    super.key,
    required this.data,
    required this.printerIp,
    this.printerPort = 9100,
    required this.hospitalName,
    required this.hospitalAddress,
    required this.hospitalPhone,
    required this.hospitalEmail,
  });

  @override
  State<TransactionReceiptPrinter> createState() =>
      _TransactionReceiptPrinterState();
}

class _TransactionReceiptPrinterState extends State<TransactionReceiptPrinter> {
  bool _isPrinting = false;

  String _formatNaira(num value) {
    final format = NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 2,
    );
    return format.format(value);
  }

  Future<void> _print({bool isCopy = false}) async {
    setState(() => _isPrinting = true);

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      final transaction = widget.data['transaction'] as Map<String, dynamic>;
      final patient = widget.data['patient'] as Map<String, dynamic>;
      final staff = widget.data['staff'] as Map<String, dynamic>;
      final items = (widget.data['itemSnapshots'] as List)
          .cast<Map<String, dynamic>>();

      // Treat values as already in Naira (no /100)
      final num totalAmount = (transaction['totalAmount'] ?? 0) as num;
      final num discountAmount = (transaction['discountAmount'] ?? 0) as num;
      final num amountPaid = (transaction['amountPaid'] ?? 0) as num;

      final createdAt = transaction['createdAt']?.toString() ?? '';

      // ===== HEADER from parent =====
      bytes += generator.text(
        widget.hospitalName,
        styles: const PosStyles(
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          align: PosAlign.center,
        ),
      );
      bytes += generator.text(
        widget.hospitalAddress,
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'Tel: ${widget.hospitalPhone}',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        widget.hospitalEmail,
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        isCopy ? '*** RECEIPT COPY ***' : '*** PAYMENT RECEIPT ***',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.hr();

      // ===== TRANSACTION / PATIENT INFO =====
      bytes += generator.row([
        PosColumn(text: 'Txn:', width: 3, styles: const PosStyles(bold: true)),
        PosColumn(
          text: transaction['transactionID']?.toString() ?? '',
          width: 9,
        ),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Date:', width: 3, styles: const PosStyles(bold: true)),
        PosColumn(text: createdAt, width: 9),
      ]);
      bytes += generator.row([
        PosColumn(
          text: 'Patient:',
          width: 3,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: '${patient['surname'] ?? ''} ${patient['firstName'] ?? ''}'
              .trim(),
          width: 9,
        ),
      ]);
      bytes += generator.row([
        PosColumn(
          text: 'Cashier:',
          width: 3,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: '${staff['firstName'] ?? ''} ${staff['lastName'] ?? ''}'.trim(),
          width: 9,
        ),
      ]);
      bytes += generator.hr();

      // ===== ITEMS =====
      bytes += generator.row([
        PosColumn(text: 'Desc', width: 7, styles: const PosStyles(bold: true)),
        PosColumn(
          text: 'Qty',
          width: 1,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
        PosColumn(
          text: 'Amt',
          width: 4,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
      ]);

      for (final item in items) {
        final desc = (item['description'] ?? '').toString();
        final qty = (item['quantity'] ?? 0).toString();
        final totalStr = item['total']?.toString() ?? '0';
        final totalVal = num.tryParse(totalStr) ?? 0;

        bytes += generator.row([
          PosColumn(text: desc, width: 7),
          PosColumn(
            text: qty,
            width: 1,
            styles: const PosStyles(align: PosAlign.right),
          ),
          PosColumn(
            text: _formatNaira(totalVal),
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      bytes += generator.hr();

      // ===== TOTALS in Naira =====
      bytes += generator.row([
        PosColumn(
          text: 'Subtotal:',
          width: 6,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: _formatNaira(totalAmount + discountAmount),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      bytes += generator.row([
        PosColumn(
          text: 'Discount:',
          width: 6,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: '-${_formatNaira(discountAmount)}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      bytes += generator.row([
        PosColumn(
          text: 'Total:',
          width: 6,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: _formatNaira(totalAmount),
          width: 6,
          styles: const PosStyles(
            align: PosAlign.right,
            bold: true,
            height: PosTextSize.size2,
          ),
        ),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Paid:', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
          text: _formatNaira(amountPaid),
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);

      bytes += generator.hr();
      bytes += generator.text(
        'Thank you for your patronage.',
        styles: const PosStyles(align: PosAlign.center),
      );
      // QR code at bottom
      bytes += generator.hr();
      bytes += generator.qrcode(
        'https://vesselinc.org',
        align: PosAlign.center,
      );
      bytes += generator.feed(2);
      bytes += generator.cut();

      // Send raw ESC/POS bytes directly to the network thermal printer
      final socket = await Socket.connect(widget.printerIp, widget.printerPort);
      socket.add(bytes.cast<int>());
      await socket.flush();
      await socket.close();
    } catch (e) {
      debugPrint('Printing error: $e');
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
