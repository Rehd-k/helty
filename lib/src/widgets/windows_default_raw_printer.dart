// ignore_for_file: depend_on_referenced_packages

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Local / connected Windows printer suitable for RAW thermal jobs.
class WindowsPrinterInfo {
  const WindowsPrinterInfo({required this.name, required this.isDefault});

  final String name;
  final bool isDefault;
}

const int _printerStatusPendingDeletion = 0x00000004;
const int _printerAttributeWorkOffline = 0x00000400;

/// Printers that are not pending deletion and not marked work-offline.
Future<List<WindowsPrinterInfo>> listActiveWindowsPrinters() async {
  if (!Platform.isWindows) return [];

  final defaultName = _readDefaultPrinterName();
  final flags = PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS;
  final pcbNeeded = calloc<Uint32>();
  final pcReturned = calloc<Uint32>();
  try {
    var ok = EnumPrinters(
      flags,
      nullptr,
      2,
      nullptr,
      0,
      pcbNeeded,
      pcReturned,
    );
    if (ok == 0 && GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
      return [];
    }
    final needed = pcbNeeded.value;
    if (needed == 0) return [];

    final pBuf = calloc<Uint8>(needed);
    try {
      ok = EnumPrinters(
        flags,
        nullptr,
        2,
        pBuf,
        needed,
        pcbNeeded,
        pcReturned,
      );
      if (ok == 0) return [];

      final count = pcReturned.value;
      if (count == 0) return [];

      final pFirst = pBuf.cast<PRINTER_INFO_2>();
      final out = <WindowsPrinterInfo>[];

      for (var i = 0; i < count; i++) {
        final pi = (pFirst + i).ref;
        final namePtr = pi.pPrinterName;
        if (namePtr == nullptr) continue;
        final name = namePtr.toDartString();
        if (name.isEmpty) continue;

        if ((pi.Status & _printerStatusPendingDeletion) != 0) continue;
        if ((pi.Attributes & _printerAttributeWorkOffline) != 0) continue;

        out.add(
          WindowsPrinterInfo(
            name: name,
            isDefault: defaultName != null && name == defaultName,
          ),
        );
      }

      out.sort((a, b) {
        if (a.isDefault != b.isDefault) {
          return a.isDefault ? -1 : 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      return out;
    } finally {
      calloc.free(pBuf);
    }
  } finally {
    calloc.free(pcbNeeded);
    calloc.free(pcReturned);
  }
}

/// Sends raw bytes (e.g. ESC/POS) to the named Windows printer as a RAW job.
Future<void> sendRawBytesToWindowsPrinter(
  String printerName,
  List<int> data,
) async {
  if (!Platform.isWindows) {
    throw UnsupportedError(
      'Windows printer RAW output is only implemented on Windows.',
    );
  }
  if (data.isEmpty) return;

  final name = printerName.trim();
  if (name.isEmpty) {
    throw StateError('Printer name is empty.');
  }

  final pPrinterName = name.toNativeUtf16();
  final phPrinter = calloc<IntPtr>();
  Pointer<DOC_INFO_1>? pDoc;
  Pointer<Utf16>? pDocName;
  Pointer<Utf16>? pDatatype;

  try {
    if (OpenPrinter(pPrinterName, phPrinter, nullptr) == 0) {
      throw StateError('OpenPrinter failed for "$name"');
    }
    final hPrinter = phPrinter.value;

    pDocName = 'Helty Receipt'.toNativeUtf16();
    pDatatype = 'RAW'.toNativeUtf16();
    pDoc = calloc<DOC_INFO_1>();
    pDoc.ref
      ..pDocName = pDocName
      ..pOutputFile = nullptr
      ..pDatatype = pDatatype;

    if (StartDocPrinter(hPrinter, 1, pDoc) <= 0) {
      throw StateError('StartDocPrinter failed');
    }

    try {
      if (StartPagePrinter(hPrinter) == 0) {
        throw StateError('StartPagePrinter failed');
      }
      final u8 = Uint8List.fromList(data);
      final buffer = calloc<Uint8>(u8.length);
      final written = calloc<Uint32>();
      try {
        buffer.asTypedList(u8.length).setAll(0, u8);
        if (WritePrinter(hPrinter, buffer.cast(), u8.length, written) == 0) {
          throw StateError('WritePrinter failed');
        }
      } finally {
        calloc.free(buffer);
        calloc.free(written);
      }
      EndPagePrinter(hPrinter);
    } finally {
      EndDocPrinter(hPrinter);
    }
  } finally {
    if (phPrinter.value != 0) {
      ClosePrinter(phPrinter.value);
    }
    calloc.free(pPrinterName);
    calloc.free(phPrinter);
    if (pDoc != null) calloc.free(pDoc);
    if (pDocName != null) calloc.free(pDocName);
    if (pDatatype != null) calloc.free(pDatatype);
  }
}

/// Sends raw bytes (e.g. ESC/POS) to the **Windows default printer** as a RAW job.
///
/// Works with drivers that accept RAW passthrough (typical for USB thermal ESC/POS).
Future<void> sendRawBytesToWindowsDefaultPrinter(List<int> data) async {
  final name = _readDefaultPrinterName();
  if (name == null || name.isEmpty) {
    throw StateError('No default Windows printer is set.');
  }
  await sendRawBytesToWindowsPrinter(name, data);
}

String? _readDefaultPrinterName() {
  final pcch = calloc<Uint32>();
  try {
    if (GetDefaultPrinter(nullptr, pcch) == 0) return null;
    final needed = pcch.value;
    if (needed == 0) return null;
    final psz = calloc<Uint16>(needed).cast<Utf16>();
    try {
      pcch.value = needed;
      if (GetDefaultPrinter(psz, pcch) == 0) return null;
      return psz.toDartString();
    } finally {
      calloc.free(psz);
    }
  } finally {
    calloc.free(pcch);
  }
}
