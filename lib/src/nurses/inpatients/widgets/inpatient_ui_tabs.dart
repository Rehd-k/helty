/// UI tab indices for [InpatientPatientViewScreen].
///
/// Consumables is UI-only (not in [AutoTabsRouter]); router index is
/// `uiIndex` when `uiIndex < consumables`, otherwise `uiIndex - 1`.
abstract final class InpatientUiTabs {
  static const int overview = 0;
  static const int vitals = 1;
  static const int medications = 2;
  static const int iv = 3;
  static const int io = 4;
  static const int nursingReport = 5;
  static const int wound = 6;
  static const int wardRound = 7;
  static const int procedures = 8;
  static const int consumables = 9;
  static const int carePlan = 10;
  static const int monitoring = 11;
  static const int labResults = 12;
  static const int imaging = 13;
  static const int alerts = 14;
  static const int handover = 15;

  static const List<String> labels = [
    'Overview',
    'Vitals',
    'Medications',
    'IV',
    'I&O',
    'Nursing Report',
    'Wound',
    'Ward round',
    'Procedures',
    'Consumables',
    'Care Plan',
    'Monitoring',
    'Lab Results',
    'Imaging',
    'Alerts',
    'Handover',
  ];

  static int? routerIndexForUiTab(int uiIndex) {
    if (uiIndex == consumables) return null;
    if (uiIndex < consumables) return uiIndex;
    return uiIndex - 1;
  }
}
