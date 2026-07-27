import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'report_templates/report_pdf_theme.dart';

const _kReportTemplateKey = 'pdf_report_template_id';

/// Reads/writes the selected lab/diagnostic PDF template id.
abstract final class ReportTemplatePersistence {
  static ReportPdfTemplateId read(SharedPreferences prefs) {
    return ReportPdfTemplateId.fromStorage(
      prefs.getString(_kReportTemplateKey),
    );
  }

  static Future<void> write(
    SharedPreferences prefs,
    ReportPdfTemplateId id,
  ) async {
    await prefs.setString(_kReportTemplateKey, id.storageKey);
  }
}

class ReportTemplateNotifier extends StateNotifier<ReportPdfTemplateId> {
  ReportTemplateNotifier(super.initial);

  Future<void> setTemplate(ReportPdfTemplateId id) async {
    state = id;
    final prefs = await SharedPreferences.getInstance();
    await ReportTemplatePersistence.write(prefs, id);
  }
}

final reportTemplateProvider =
    StateNotifierProvider<ReportTemplateNotifier, ReportPdfTemplateId>((ref) {
  return ReportTemplateNotifier(ReportPdfTemplateId.classicNavy);
});

/// Resolves the active [ReportPdfTheme] from the selected template id.
final reportPdfThemeProvider = Provider<ReportPdfTheme>((ref) {
  return ReportPdfTheme.forId(ref.watch(reportTemplateProvider));
});

/// Loads the currently persisted PDF theme (for builders outside Riverpod).
Future<ReportPdfTheme> resolveSelectedReportPdfTheme() async {
  final prefs = await SharedPreferences.getInstance();
  return ReportPdfTheme.forId(ReportTemplatePersistence.read(prefs));
}
