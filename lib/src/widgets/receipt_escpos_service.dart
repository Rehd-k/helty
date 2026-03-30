import 'dart:io';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

import 'windows_default_raw_printer.dart';

/// Header lines printed under the logo.
class ReceiptHospitalHeader {
  const ReceiptHospitalHeader({
    this.name = 'Helty Hospital',
    this.address = '',
    this.phone = '',
    this.email = '',
  });

  final String name;
  final String address;
  final String phone;
  final String email;
}

/// Where to send ESC/POS output.
enum ReceiptPrintSink {
  /// Windows: default printer, RAW job (USB thermal).
  windowsDefault,

  /// LAN thermal printer (port 9100).
  network,
}

/// Builds receipt bytes and sends to [ReceiptPrintSink].
class ReceiptEscposService {
  ReceiptEscposService._();

  static final NumberFormat _naira = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 2,
  );

  static String _sanitizeEscPosText(String input) {
    // `esc_pos_utils_plus`'s `generator.text()` supports only a limited charset.
    // Replace known unsupported Unicode characters with safe fallbacks.
    return input.replaceAll('₦', 'N');
  }

  static String _formatNaira(num value) {
    final formatted = _naira.format(value);
    return _sanitizeEscPosText(formatted);
  }

  /// Normalizes [TransactionMap] from transactions screen / API.
  static Map<String, dynamic> fromTransactionMap(Map<String, dynamic> t) {
    final services = (t['services'] as List?) ?? [];
    final itemSnapshots = services.map<Map<String, dynamic>>((e) {
      final m = e as Map<String, dynamic>;
      final qty = m['quantity'] ?? 1;
      final total = m['totalPrice'] ?? m['cost'] ?? 0;
      return {
        'description': m['name'] ?? m['description'] ?? '',
        'quantity': qty,
        'total': total.toString(),
      };
    }).toList();

    return {
      'transaction': {
        'transactionID': t['tranId']?.toString() ?? t['id']?.toString() ?? '',
        'totalAmount': t['amountDue'] ?? 0,
        'discountAmount': t['discount'] ?? 0,
        'amountPaid': t['amountPaid'] ?? 0,
        'createdAt': t['date']?.toString() ?? '',
      },
      'patient': {
        'firstName': t['patientName']?.toString() ?? '',
        'surname': '',
      },
      'staff': {
        'firstName': t['initiator']?.toString() ?? '',
        'lastName': '',
      },
      'itemSnapshots': itemSnapshots,
    };
  }

  /// Receipt payload after PayBill (no server transaction id).
  static Map<String, dynamic> fromPayBillSnapshot({
    required String patientName,
    required String patientId,
    required String cashierFirst,
    required String cashierLast,
    required List<Map<String, dynamic>> itemSnapshots,
    required double totalAmount,
    required double discountAmount,
    required double amountPaid,
    String? transactionId,
  }) {
    final id =
        transactionId?.trim().isNotEmpty == true
        ? transactionId!.trim()
        : 'PAY-${DateTime.now().millisecondsSinceEpoch}';
    return {
      'transaction': {
        'transactionID': id,
        'totalAmount': totalAmount,
        'discountAmount': discountAmount,
        'amountPaid': amountPaid,
        'createdAt': DateTime.now().toIso8601String(),
      },
      'patient': {
        'firstName': patientName,
        'surname': '',
        'patientId': patientId,
      },
      'staff': {'firstName': cashierFirst, 'lastName': cashierLast},
      'itemSnapshots': itemSnapshots,
    };
  }

  static String _barcodeDataFromTxnId(String? txnId) {
    var digits = (txnId ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) digits = '12345';
    if (digits.length.isOdd) digits = '0$digits';
    return digits;
  }

  static List<dynamic> _itfChars(String digitsOnly) =>
      digitsOnly.split('').toList();

  static Future<img.Image?> _loadLogoRaster(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final decoded = img.decodeImage(data.buffer.asUint8List());
      if (decoded == null) return null;
      const maxW = 384;
      if (decoded.width > maxW) {
        return img.copyResize(decoded, width: maxW);
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  /// Generates ESC/POS bytes (logo, barcode, body).
  static Future<List<int>> buildBytes({
    required Map<String, dynamic> data,
    required ReceiptHospitalHeader header,
    required bool isCopy,
    String logoAssetPath = 'assets/logo.png',
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    var bytes = <int>[];

    final transaction = Map<String, dynamic>.from(
      data['transaction'] as Map? ?? {},
    );
    final patient = Map<String, dynamic>.from(data['patient'] as Map? ?? {});
    final staff = Map<String, dynamic>.from(data['staff'] as Map? ?? {});
    final items =
        ((data['itemSnapshots'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

    final txnId = transaction['transactionID']?.toString() ?? '';
    final barcodeDigits = _barcodeDataFromTxnId(txnId);

    final logo = await _loadLogoRaster(logoAssetPath);
    if (logo != null) {
      bytes += generator.image(logo, align: PosAlign.center);
      bytes += generator.feed(1);
    }

    bytes += generator.text(
      header.name,
      styles: const PosStyles(
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        align: PosAlign.center,
      ),
    );
    if (header.address.isNotEmpty) {
      bytes += generator.text(
        header.address,
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (header.phone.isNotEmpty) {
      bytes += generator.text(
        'Tel: ${header.phone}',
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (header.email.isNotEmpty) {
      bytes += generator.text(
        header.email,
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    bytes += generator.hr();
    bytes += generator.barcode(
      Barcode.itf(_itfChars(barcodeDigits)),
      font: BarcodeFont.fontA,
      align: PosAlign.center,
    );
    bytes += generator.text(
      txnId.isNotEmpty ? txnId : barcodeDigits,
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.hr();

    bytes += generator.text(
      isCopy ? '*** RECEIPT COPY ***' : '*** PAYMENT RECEIPT ***',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.hr();

    final num totalAmount = (transaction['totalAmount'] ?? 0) as num;
    final num discountAmount = (transaction['discountAmount'] ?? 0) as num;
    final num amountPaid = (transaction['amountPaid'] ?? 0) as num;
    final createdAt = transaction['createdAt']?.toString() ?? '';

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

    final pFirst = patient['firstName']?.toString() ?? '';
    final pLast = patient['surname']?.toString() ?? '';
    final patientLine = '$pFirst $pLast'.trim();

    bytes += generator.row([
      PosColumn(
        text: 'Patient:',
        width: 3,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(text: patientLine, width: 9),
    ]);
    bytes += generator.row([
      PosColumn(
        text: 'Cashier:',
        width: 3,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text:
            '${staff['firstName'] ?? ''} ${staff['lastName'] ?? ''}'.trim(),
        width: 9,
      ),
    ]);
    bytes += generator.hr();

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
      PosColumn(text: 'Total:', width: 6, styles: const PosStyles(bold: true)),
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
    bytes += generator.hr();
    bytes += generator.qrcode(
      'https://vesselinc.org',
      align: PosAlign.center,
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  static Future<void> printReceipt({
    required Map<String, dynamic> data,
    ReceiptHospitalHeader header = const ReceiptHospitalHeader(),
    ReceiptPrintSink sink = ReceiptPrintSink.windowsDefault,
    String? printerIp,
    int printerPort = 9100,
    bool isCopy = false,
    String logoAssetPath = 'assets/logo.png',
  }) async {
    final bytes = await buildBytes(
      data: data,
      header: header,
      isCopy: isCopy,
      logoAssetPath: logoAssetPath,
    );

    switch (sink) {
      case ReceiptPrintSink.windowsDefault:
        if (!Platform.isWindows) {
          throw UnsupportedError(
            'windowsDefault sink requires Windows; use ReceiptPrintSink.network on other platforms.',
          );
        }
        await sendRawBytesToWindowsDefaultPrinter(bytes);
        break;
      case ReceiptPrintSink.network:
        final ip = printerIp?.trim() ?? '';
        if (ip.isEmpty) {
          throw StateError('printerIp is required for network sink');
        }
        final socket = await Socket.connect(ip, printerPort);
        try {
          socket.add(Uint8List.fromList(bytes));
          await socket.flush();
        } finally {
          await socket.close();
        }
        break;
    }
  }
}
