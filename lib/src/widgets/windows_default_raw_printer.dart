// ignore_for_file: depend_on_referenced_packages

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Sends raw bytes (e.g. ESC/POS) to the **Windows default printer** as a RAW job.
///
/// Works with drivers that accept RAW passthrough (typical for USB thermal ESC/POS).
Future<void> sendRawBytesToWindowsDefaultPrinter(List<int> data) async {
  if (!Platform.isWindows) {
    throw UnsupportedError(
      'Default system printer RAW output is only implemented on Windows.',
    );
  }
  if (data.isEmpty) return;

  final name = _readDefaultPrinterName();
  if (name == null || name.isEmpty) {
    throw StateError('No default Windows printer is set.');
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
