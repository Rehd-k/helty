/// ED workflow status (mirrors backend `EdWorkflowStatus`).
enum EdWorkflowStatus {
  registered,
  triage,
  waitingDoctor,
  inTreatment,
  dispositionPending,
  discharged,
  transferred,
  admitted,
  lwbs,
  deceased,
  cancelled;

  static EdWorkflowStatus fromString(String? value) {
    if (value == null || value.trim().isEmpty) return EdWorkflowStatus.registered;
    final k = value.trim().toUpperCase().replaceAll('-', '_');
    switch (k) {
      case 'REGISTERED':
        return EdWorkflowStatus.registered;
      case 'TRIAGE':
        return EdWorkflowStatus.triage;
      case 'WAITING_DOCTOR':
        return EdWorkflowStatus.waitingDoctor;
      case 'IN_TREATMENT':
        return EdWorkflowStatus.inTreatment;
      case 'DISPOSITION_PENDING':
        return EdWorkflowStatus.dispositionPending;
      case 'DISCHARGED':
        return EdWorkflowStatus.discharged;
      case 'TRANSFERRED':
        return EdWorkflowStatus.transferred;
      case 'ADMITTED':
        return EdWorkflowStatus.admitted;
      case 'LWBS':
        return EdWorkflowStatus.lwbs;
      case 'DECEASED':
        return EdWorkflowStatus.deceased;
      case 'CANCELLED':
        return EdWorkflowStatus.cancelled;
      default:
        return EdWorkflowStatus.registered;
    }
  }

  String get apiValue {
    switch (this) {
      case EdWorkflowStatus.registered:
        return 'REGISTERED';
      case EdWorkflowStatus.triage:
        return 'TRIAGE';
      case EdWorkflowStatus.waitingDoctor:
        return 'WAITING_DOCTOR';
      case EdWorkflowStatus.inTreatment:
        return 'IN_TREATMENT';
      case EdWorkflowStatus.dispositionPending:
        return 'DISPOSITION_PENDING';
      case EdWorkflowStatus.discharged:
        return 'DISCHARGED';
      case EdWorkflowStatus.transferred:
        return 'TRANSFERRED';
      case EdWorkflowStatus.admitted:
        return 'ADMITTED';
      case EdWorkflowStatus.lwbs:
        return 'LWBS';
      case EdWorkflowStatus.deceased:
        return 'DECEASED';
      case EdWorkflowStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get label {
    switch (this) {
      case EdWorkflowStatus.registered:
        return 'Registered';
      case EdWorkflowStatus.triage:
        return 'Triage';
      case EdWorkflowStatus.waitingDoctor:
        return 'Waiting doctor';
      case EdWorkflowStatus.inTreatment:
        return 'In treatment';
      case EdWorkflowStatus.dispositionPending:
        return 'Disposition pending';
      case EdWorkflowStatus.discharged:
        return 'Discharged';
      case EdWorkflowStatus.transferred:
        return 'Transferred';
      case EdWorkflowStatus.admitted:
        return 'Admitted';
      case EdWorkflowStatus.lwbs:
        return 'LWBS';
      case EdWorkflowStatus.deceased:
        return 'Deceased';
      case EdWorkflowStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isTerminal =>
      this == EdWorkflowStatus.discharged ||
      this == EdWorkflowStatus.transferred ||
      this == EdWorkflowStatus.admitted ||
      this == EdWorkflowStatus.lwbs ||
      this == EdWorkflowStatus.deceased ||
      this == EdWorkflowStatus.cancelled;
}

/// Arrival mode for ED registration.
enum EdArrivalMode {
  walkIn,
  ambulance,
  police,
  referral;

  static EdArrivalMode fromString(String? value) {
    if (value == null || value.trim().isEmpty) return EdArrivalMode.walkIn;
    final k = value.trim().toUpperCase();
    switch (k) {
      case 'AMBULANCE':
        return EdArrivalMode.ambulance;
      case 'POLICE':
        return EdArrivalMode.police;
      case 'REFERRAL':
        return EdArrivalMode.referral;
      default:
        return EdArrivalMode.walkIn;
    }
  }

  String get apiValue {
    switch (this) {
      case EdArrivalMode.walkIn:
        return 'WALK_IN';
      case EdArrivalMode.ambulance:
        return 'AMBULANCE';
      case EdArrivalMode.police:
        return 'POLICE';
      case EdArrivalMode.referral:
        return 'REFERRAL';
    }
  }

  String get label {
    switch (this) {
      case EdArrivalMode.walkIn:
        return 'Walk-in';
      case EdArrivalMode.ambulance:
        return 'Ambulance';
      case EdArrivalMode.police:
        return 'Police';
      case EdArrivalMode.referral:
        return 'Referral';
    }
  }
}

/// ED disposition outcome.
enum EdDisposition {
  dischargeHome,
  dischargeAma,
  admitWard,
  admitIcu,
  transferExternal,
  observation,
  lwbs,
  deceased;

  static EdDisposition fromString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return EdDisposition.dischargeHome;
    }
    final k = value.trim().toUpperCase();
    switch (k) {
      case 'DISCHARGE_AMA':
        return EdDisposition.dischargeAma;
      case 'ADMIT_WARD':
        return EdDisposition.admitWard;
      case 'ADMIT_ICU':
        return EdDisposition.admitIcu;
      case 'TRANSFER_EXTERNAL':
        return EdDisposition.transferExternal;
      case 'OBSERVATION':
        return EdDisposition.observation;
      case 'LWBS':
        return EdDisposition.lwbs;
      case 'DECEASED':
        return EdDisposition.deceased;
      default:
        return EdDisposition.dischargeHome;
    }
  }

  String get apiValue {
    switch (this) {
      case EdDisposition.dischargeHome:
        return 'DISCHARGE_HOME';
      case EdDisposition.dischargeAma:
        return 'DISCHARGE_AMA';
      case EdDisposition.admitWard:
        return 'ADMIT_WARD';
      case EdDisposition.admitIcu:
        return 'ADMIT_ICU';
      case EdDisposition.transferExternal:
        return 'TRANSFER_EXTERNAL';
      case EdDisposition.observation:
        return 'OBSERVATION';
      case EdDisposition.lwbs:
        return 'LWBS';
      case EdDisposition.deceased:
        return 'DECEASED';
    }
  }

  String get label {
    switch (this) {
      case EdDisposition.dischargeHome:
        return 'Discharge home';
      case EdDisposition.dischargeAma:
        return 'Discharge AMA';
      case EdDisposition.admitWard:
        return 'Admit to ward';
      case EdDisposition.admitIcu:
        return 'Admit to ICU';
      case EdDisposition.transferExternal:
        return 'Transfer external';
      case EdDisposition.observation:
        return 'Observation';
      case EdDisposition.lwbs:
        return 'LWBS';
      case EdDisposition.deceased:
        return 'Deceased';
    }
  }
}
