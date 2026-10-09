import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/printing/pdf/lab_order_modern_pdf.dart' as modern;
import 'package:helty/src/printing/pdf/lab_order_themed_pdf.dart' as themed;
import 'package:helty/src/printing/pdf/report_template_preference.dart';
import 'package:helty/src/printing/pdf/report_templates/report_pdf_theme.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether an order item has results visible on a patient report.
bool labOrderItemHasPrintableResults(LabOrderItem item) =>
    modern.labOrderItemHasPrintableResults(item);

Future<bool> _useClassicNavyLayout() async {
  final prefs = await SharedPreferences.getInstance();
  return ReportTemplatePersistence.read(prefs) ==
      ReportPdfTemplateId.classicNavy;
}

/// Builds a laboratory order PDF for print / share.
///
/// Classic Navy uses the colorful report. The other templates keep their
/// existing letterhead layouts.
Future<List<int>> buildLabOrderPdf(LabOrder order, PdfPageFormat format) async {
  if (await _useClassicNavyLayout()) {
    return modern.buildLabOrderPdf(order, format);
  }
  return themed.buildLabOrderPdf(order, format);
}

/// Combined PDF for selected tests from one patient (may span multiple orders).
Future<List<int>> buildLabPatientItemsPdf({
  required LabOrderPatient patient,
  required List<({LabOrder order, LabOrderItem item})> entries,
  required PdfPageFormat format,
}) async {
  if (await _useClassicNavyLayout()) {
    return modern.buildLabPatientItemsPdf(
      patient: patient,
      entries: entries,
      format: format,
    );
  }
  return themed.buildLabPatientItemsPdf(
    patient: patient,
    entries: entries,
    format: format,
  );
}
