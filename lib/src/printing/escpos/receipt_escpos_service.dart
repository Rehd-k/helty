import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:qr/qr.dart';

import '../../helper/date.formatter.dart';
import 'windows_default_raw_printer.dart';

/// Header lines printed under the logo.
class ReceiptHospitalHeader {
  const ReceiptHospitalHeader({
    this.name = 'Ibom Multi-Specialty Hospital',
    this.address = 'Ikot Ekpene - Uyo Rd, Uyo, Akwa Ibom',
    this.phone = '0802 181 4674',
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

  /// Capitalizes the first letter of a string.
  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  static String _nameFromPersonMap(Map<String, dynamic> m) {
    final first = m['firstName']?.toString().trim() ?? '';
    final last =
        (m['surname'] ?? m['lastName'])?.toString().trim() ?? '';
    final fromParts = [first, last].where((s) => s.isNotEmpty).join(' ');
    if (fromParts.isNotEmpty) return fromParts;
    for (final k in ['fullName', 'name', 'displayName', 'userName']) {
      final v = m[k]?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  /// [TransactionMap] names + optional nested `patient` / `receivedBy` / `createdBy` from API.
  static String _patientNameFromTransactionMap(Map<String, dynamic> t) {
    final top = t['patientName']?.toString().trim() ?? '';
    if (top.isNotEmpty) return _sanitizeEscPosText(top);
    final p = t['patient'];
    if (p is Map) {
      return _sanitizeEscPosText(
        _nameFromPersonMap(Map<String, dynamic>.from(p)),
      );
    }
    return '';
  }

  static String _staffNameFromTransactionMap(Map<String, dynamic> t) {
    for (final k in [
      'initiator',
      'initiatedByName',
      'staffName',
      'receivedByName',
      'cashierName',
      'userName',
    ]) {
      final s = t[k]?.toString().trim() ?? '';
      if (s.isNotEmpty) return _sanitizeEscPosText(s);
    }
    for (final k in [
      'receivedBy',
      'createdBy',
      'staff',
      'initiatedBy',
      'user',
    ]) {
      final v = t[k];
      if (v is Map) {
        final s = _nameFromPersonMap(Map<String, dynamic>.from(v));
        if (s.isNotEmpty) return _sanitizeEscPosText(s);
      }
    }
    for (final k in ['createdById', 'receivedById']) {
      final s = t[k]?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  /// [fromPayBillSnapshot] uses first+last; [fromTransactionMap] may put the full
  /// name in [firstName] only — do not run [_capitalize] on the whole string in that case.
  static String _receiptLineStaffName(Map<String, dynamic> staff) {
    final fn = (staff['firstName'] ?? '').toString().trim();
    final ln = (staff['lastName'] ?? '').toString().trim();
    if (ln.isEmpty) {
      if (fn.isEmpty) return '';
      return _sanitizeEscPosText(fn);
    }
    return _sanitizeEscPosText(
      '${_capitalize(fn)} ${_capitalize(ln)}'.trim(),
    );
  }

  /// Parses [transactionModelToMap]'s ISO string or legacy display [date] (`MMM d, y h:mm a`).
  static DateTime? _parseReceiptCreatedAt(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {}
    try {
      return DateFormat('MMM d, y h:mm a').parse(s);
    } catch (_) {}
    return null;
  }

  /// Generates a QR code as a raster image for printers that don't support
  /// the native ESC/POS QR command.
  static img.Image? _generateQrImage(String data, {int moduleSize = 4}) {
    try {
      final qrCode = QrCode.fromData(
        data: data,
        errorCorrectLevel: QrErrorCorrectLevel.L,
      );
      final qrImage = QrImage(qrCode);
      final moduleCount = qrCode.moduleCount;
      final size = moduleCount * moduleSize;
      final image = img.Image(width: size, height: size);
      // Fill white background
      img.fill(image, color: img.ColorUint8.rgb(255, 255, 255));
      // Draw QR modules
      for (var x = 0; x < moduleCount; x++) {
        for (var y = 0; y < moduleCount; y++) {
          if (qrImage.isDark(y, x)) {
            for (var px = 0; px < moduleSize; px++) {
              for (var py = 0; py < moduleSize; py++) {
                image.setPixel(
                  x * moduleSize + px,
                  y * moduleSize + py,
                  img.ColorUint8.rgb(0, 0, 0),
                );
              }
            }
          }
        }
      }
      return image;
    } catch (e) {
      log('QR image generation failed: $e');
      return null;
    }
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
        'createdAt':
            t['createdAtIso']?.toString() ??
            t['createdAt']?.toString() ??
            t['date']?.toString() ??
            '',
      },
      'patient': {
        'firstName': _patientNameFromTransactionMap(t),
        'surname': '',
      },
      'staff': {
        'firstName': _staffNameFromTransactionMap(t),
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
    final id = transactionId?.trim().isNotEmpty == true
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

  static img.Image _threshold(img.Image image, int threshold) {
    final result = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final color = pixel.a < 128
            ? img.ColorUint8.rgb(255, 255, 255) // Transparent -> white
            : (img.getLuminance(pixel) > threshold
                  ? img.ColorUint8.rgb(255, 255, 255)
                  : img.ColorUint8.rgb(0, 0, 0));
        result.setPixel(x, y, color);
      }
    }
    return result;
  }

  static Future<img.Image?> _loadLogoRaster(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List pngBytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final img.Image? decoded = img.decodeImage(pngBytes);
      if (decoded == null) {
        log('Failed to decode logo image from $assetPath');
        return null;
      }

      // Constrain both width AND height to reasonable thermal printer size
      const maxW = 300; // 80mm ≈ 384px, but leave margins
      const maxH = 200; // Prevent huge vertical spacing

      int newWidth = decoded.width;
      int newHeight = decoded.height;

      // Scale down if any dimension exceeds max
      double scale = 1.0;
      if (decoded.width > maxW) {
        scale = maxW / decoded.width;
      }
      if ((decoded.height * scale) > maxH) {
        scale = maxH / decoded.height;
      }

      img.Image finalImage;
      if (scale < 1.0) {
        newWidth = (decoded.width * scale).round();
        newHeight = (decoded.height * scale).round();
        finalImage = img.copyResize(
          decoded,
          width: newWidth,
          height: newHeight,
        );
        log(
          'Logo resized from ${decoded.width}×${decoded.height} to ${finalImage.width}×${finalImage.height}',
        );
      } else {
        finalImage = decoded;
        log('Logo loaded: ${finalImage.width}×${finalImage.height}');
      }

      // Convert to black and white for thermal printer
      final processed = _threshold(img.grayscale(finalImage), 128);
      log('Logo processed to ${processed.width}×${processed.height} BW');
      return processed;
    } catch (e) {
      log('Error loading logo: $e');
      return null;
    }
  }

  /// Generates ESC/POS bytes (logo, barcode, body).
  static Future<List<int>> buildBytes({
    required Map<String, dynamic> data,
    required ReceiptHospitalHeader header,
    required bool isCopy,
    String logoAssetPath = 'assets/imsh.png',
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    var bytes = <int>[];

    final transaction = Map<String, dynamic>.from(
      data['transaction'] as Map? ?? {},
    );
    final patient = Map<String, dynamic>.from(data['patient'] as Map? ?? {});
    final staff = Map<String, dynamic>.from(data['staff'] as Map? ?? {});
    final items = ((data['itemSnapshots'] as List?) ?? [])
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
        height: PosTextSize.size1,
        width: PosTextSize.size1,
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
    final createdRaw = transaction['createdAt']?.toString() ?? '';
    final createdDt = _parseReceiptCreatedAt(createdRaw);
    final dateLine = createdDt != null
        ? DateFormatter.dateTime(createdDt)
        : (createdRaw.isNotEmpty ? _sanitizeEscPosText(createdRaw) : '—');

    bytes += generator.row([
      PosColumn(text: 'Txn:', width: 3, styles: const PosStyles(bold: true)),
      PosColumn(text: transaction['transactionID']?.toString() ?? '', width: 9),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Date:', width: 3, styles: const PosStyles(bold: true)),
      PosColumn(
        text: dateLine,
        width: 9,
      ),
    ]);

    final pFirst = patient['firstName']?.toString() ?? '';
    final pLast = patient['surname']?.toString() ?? '';
    final patientLine = _sanitizeEscPosText('$pFirst $pLast'.trim());
    if (patientLine.isEmpty) {
      bytes += generator.row([
        PosColumn(
          text: 'Patient:',
          width: 4,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(text: '—', width: 8),
      ]);
    } else {
      bytes += generator.row([
        PosColumn(
          text: 'Patient:',
          width: 4,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(text: patientLine, width: 8),
      ]);
    }
    final cashierLine = _receiptLineStaffName(staff);
    bytes += generator.row([
      PosColumn(
        text: 'Cashier:',
        width: 4,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: cashierLine.isNotEmpty ? cashierLine : '—',
        width: 8,
      ),
    ]);

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(text: 'Desc', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Qty', width: 2, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Amt', width: 4, styles: const PosStyles(bold: true)),
    ]);

    for (final item in items) {
      final desc = (item['description'] ?? '').toString();
      final qty = (item['quantity'] ?? 0).toString();
      final totalStr = item['total']?.toString() ?? '0';
      final totalVal = num.tryParse(totalStr) ?? 0;

      bytes += generator.row([
        PosColumn(text: desc.trim(), width: 6),
        PosColumn(text: qty, width: 2),
        PosColumn(text: _formatNaira(totalVal), width: 4),
      ]);
    }

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
        text: 'Subtotal:',
        width: 6,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(text: _formatNaira(totalAmount + discountAmount), width: 6),
    ]);
    bytes += generator.row([
      PosColumn(
        text: 'Discount:',
        width: 6,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(text: '-${_formatNaira(discountAmount)}', width: 6),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Total:', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
        text: _formatNaira(totalAmount),
        width: 6,
        styles: const PosStyles(bold: true, height: PosTextSize.size2),
      ),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Paid:', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
        text: _formatNaira(amountPaid),
        width: 6,
        styles: const PosStyles(bold: true),
      ),
    ]);

    bytes += generator.hr();
    bytes += generator.text(
      'Thank you.',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr();
    // Use image-based QR code (more compatible with 58mm thermal printers)
    final qrImg = _generateQrImage(
      'https://www.vessellabs.org/',
      moduleSize: 4,
    );
    if (qrImg != null) {
      bytes += generator.image(qrImg, align: PosAlign.center);
    } else {
      // Fallback: print URL as text if QR generation fails
      bytes += generator.text(
        'https://www.vessellabs.org/',
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  static Future<void> printReceipt({
    required Map<String, dynamic> data,
    ReceiptHospitalHeader header = const ReceiptHospitalHeader(),
    ReceiptPrintSink sink = ReceiptPrintSink.windowsDefault,

    /// When set on Windows, sends the RAW job to this queue instead of the default.
    String? windowsPrinterName,
    String? printerIp,
    int printerPort = 9100,
    bool isCopy = false,
    String logoAssetPath = 'assets/imsh.png',
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
        final chosen = windowsPrinterName?.trim();
        if (chosen != null && chosen.isNotEmpty) {
          await sendRawBytesToWindowsPrinter(chosen, bytes);
        } else {
          await sendRawBytesToWindowsDefaultPrinter(bytes);
        }
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
