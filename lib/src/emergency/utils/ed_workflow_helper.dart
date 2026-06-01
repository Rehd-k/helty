import '../models/ed_enums.dart';

/// ED board action visibility from [EdWorkflowStatus].
class EdWorkflowHelper {
  EdWorkflowHelper._();

  static bool isTerminal(EdWorkflowStatus status) => status.isTerminal;

  static bool canShowTriage(EdWorkflowStatus status) {
    return status == EdWorkflowStatus.registered ||
        status == EdWorkflowStatus.triage;
  }

  static bool canShowOpenDoctor(EdWorkflowStatus status) {
    return !status.isTerminal;
  }

  /// LWBS allowed from REGISTERED through IN_TREATMENT per doc status machine.
  static bool canMarkLwbs(EdWorkflowStatus status) {
    switch (status) {
      case EdWorkflowStatus.registered:
      case EdWorkflowStatus.triage:
      case EdWorkflowStatus.waitingDoctor:
      case EdWorkflowStatus.inTreatment:
        return true;
      default:
        return false;
    }
  }

  /// Death from IN_TREATMENT or DISPOSITION_PENDING per doc.
  static bool canMarkDeceased(EdWorkflowStatus status) {
    return status == EdWorkflowStatus.inTreatment ||
        status == EdWorkflowStatus.dispositionPending;
  }
}
