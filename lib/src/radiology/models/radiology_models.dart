// ignore_for_file: constant_identifier_names

enum RadiologyPriority {
  ROUTINE,
  URGENT,
  EMERGENCY;

  String get apiValue => name;

  static RadiologyPriority? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    final v = value.toUpperCase();
    for (final e in RadiologyPriority.values) {
      if (e.name == v) return e;
    }
    return null;
  }
}

enum RadiologyModality {
  X_RAY,
  CT,
  MRI,
  ULTRASOUND,
  MAMMOGRAPHY,
  FLUOROSCOPY,
  OTHER;

  String get apiValue => name;

  /// Short label for forms and lists (distinct from [name] / API value).
  String get displayLabel {
    switch (this) {
      case RadiologyModality.X_RAY:
        return 'X-ray';
      case RadiologyModality.CT:
        return 'Computed Tomography (CT)';
      case RadiologyModality.MRI:
        return 'Magnetic Resonance Imaging (MRI)';
      case RadiologyModality.ULTRASOUND:
        return 'Ultrasound / Sonography';
      case RadiologyModality.MAMMOGRAPHY:
        return 'Mammography';
      case RadiologyModality.FLUOROSCOPY:
        return 'Fluoroscopy';
      case RadiologyModality.OTHER:
        return 'Other';
    }
  }

  static RadiologyModality? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    final v = value.toUpperCase().replaceAll(' ', '_');
    for (final e in RadiologyModality.values) {
      if (e.name == v) return e;
    }
    return null;
  }
}

enum RadiologyOrderStatus {
  PENDING,
  ACTIVE,
  COMPLETED,
  CANCELLED;

  String get apiValue => name;

  static RadiologyOrderStatus? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    final v = value.toUpperCase().replaceAll(' ', '_');
    for (final e in RadiologyOrderStatus.values) {
      if (e.name == v) return e;
    }
    return null;
  }
}

enum RadiologyOrderItemStatus {
  PENDING,
  SCHEDULED,
  IN_PROGRESS,
  COMPLETED,
  REPORTED,
  CANCELLED;

  String get apiValue => name;

  static RadiologyOrderItemStatus? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    final v = value.toUpperCase().replaceAll(' ', '_');
    for (final e in RadiologyOrderItemStatus.values) {
      if (e.name == v) return e;
    }
    return null;
  }
}

enum ReportSeverity {
  NORMAL,
  ABNORMAL,
  CRITICAL;

  String get apiValue => name;

  static ReportSeverity? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    final v = value.toUpperCase();
    for (final e in ReportSeverity.values) {
      if (e.name == v) return e;
    }
    return null;
  }
}

class RadiologyPatientRef {
  const RadiologyPatientRef({
    required this.id,
    this.firstName,
    this.surname,
    this.patientId,
  });

  final String id;
  final String? firstName;
  final String? surname;
  final String? patientId;

  String get displayName =>
      [firstName, surname].where((e) => e != null && e.isNotEmpty).join(' ');

  factory RadiologyPatientRef.fromJson(Map<String, dynamic> json) {
    return RadiologyPatientRef(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String?,
      surname: json['surname'] as String?,
      patientId: json['patientId'] as String?,
    );
  }
}

class RadiologyStaffRef {
  const RadiologyStaffRef({
    required this.id,
    this.firstName,
    this.lastName,
  });

  final String id;
  final String? firstName;
  final String? lastName;

  String get displayName =>
      [firstName, lastName].where((e) => e != null && e.isNotEmpty).join(' ');

  factory RadiologyStaffRef.fromJson(Map<String, dynamic> json) {
    return RadiologyStaffRef(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
    );
  }
}

class RadiologyMachineRef {
  const RadiologyMachineRef({
    required this.id,
    this.name,
    this.modality,
  });

  final String id;
  final String? name;
  final String? modality;

  factory RadiologyMachineRef.fromJson(Map<String, dynamic> json) {
    return RadiologyMachineRef(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      modality: json['modality'] as String?,
    );
  }
}

class RadiologyOrder {
  const RadiologyOrder({
    required this.id,
    required this.patientId,
    required this.requestedById,
    required this.items,
    this.encounterId,
    this.departmentId,
    this.status = RadiologyOrderStatus.PENDING,
    this.createdAt,
    this.updatedAt,
    this.patient,
    this.requestedBy,
  });

  final String id;
  final String patientId;
  final String requestedById;
  final String? encounterId;
  final String? departmentId;
  final RadiologyOrderStatus status;
  final String? createdAt;
  final String? updatedAt;
  final List<RadiologyOrderItem> items;
  final RadiologyPatientRef? patient;
  final RadiologyStaffRef? requestedBy;

  factory RadiologyOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const [];
    return RadiologyOrder(
      id: json['id'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      requestedById: json['requestedById'] as String? ?? '',
      encounterId: json['encounterId'] as String?,
      departmentId: json['departmentId'] as String?,
      status: RadiologyOrderStatus.fromString(json['status'] as String?) ??
          RadiologyOrderStatus.PENDING,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      items: rawItems
          .map((e) => RadiologyOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      patient: json['patient'] != null
          ? RadiologyPatientRef.fromJson(json['patient'] as Map<String, dynamic>)
          : null,
      requestedBy: json['requestedBy'] != null
          ? RadiologyStaffRef.fromJson(
              json['requestedBy'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class RadiologyOrderItem {
  const RadiologyOrderItem({
    required this.id,
    required this.orderId,
    required this.scanType,
    required this.priority,
    required this.status,
    this.bodyPart,
    this.contrast,
    this.clinicalNotes,
    this.reasonForInvestigation,
    this.invoiceId,
    this.invoiceItemId,
    this.serviceId,
    this.createdAt,
    this.updatedAt,
    this.schedule,
    this.procedure,
    this.images,
    this.report,
  });

  final String id;
  final String orderId;
  final RadiologyModality scanType;
  final RadiologyPriority priority;
  final RadiologyOrderItemStatus status;
  final String? bodyPart;
  final bool? contrast;
  final String? clinicalNotes;
  final String? reasonForInvestigation;
  final String? invoiceId;
  final String? invoiceItemId;
  final String? serviceId;
  final String? createdAt;
  final String? updatedAt;
  final RadiologySchedule? schedule;
  final RadiologyProcedure? procedure;
  final List<RadiologyImage>? images;
  final RadiologyStudyReport? report;

  factory RadiologyOrderItem.fromJson(Map<String, dynamic> json) {
    return RadiologyOrderItem(
      id: json['id'] as String? ?? '',
      orderId: (json['orderId'] ?? json['radiologyOrderId']) as String? ?? '',
      scanType: RadiologyModality.fromString(json['scanType'] as String?) ??
          RadiologyModality.OTHER,
      priority: RadiologyPriority.fromString(json['priority'] as String?) ??
          RadiologyPriority.ROUTINE,
      status:
          RadiologyOrderItemStatus.fromString(json['status'] as String?) ??
              RadiologyOrderItemStatus.PENDING,
      bodyPart: json['bodyPart'] as String?,
      contrast: json['contrast'] as bool?,
      clinicalNotes: json['clinicalNotes'] as String?,
      reasonForInvestigation: json['reasonForInvestigation'] as String?,
      invoiceId: json['invoiceId'] as String?,
      invoiceItemId: json['invoiceItemId'] as String?,
      serviceId: json['serviceId'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      schedule: json['schedule'] != null
          ? RadiologySchedule.fromJson(json['schedule'] as Map<String, dynamic>)
          : null,
      procedure: json['procedure'] != null
          ? RadiologyProcedure.fromJson(
              json['procedure'] as Map<String, dynamic>,
            )
          : null,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => RadiologyImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      report: json['report'] != null
          ? RadiologyStudyReport.fromJson(json['report'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'scanType': scanType.apiValue,
        if (bodyPart != null && bodyPart!.isNotEmpty) 'bodyPart': bodyPart,
        'priority': priority.apiValue,
        if (contrast != null) 'contrast': contrast,
        if (clinicalNotes != null && clinicalNotes!.isNotEmpty)
          'clinicalNotes': clinicalNotes,
        if (reasonForInvestigation != null && reasonForInvestigation!.isNotEmpty)
          'reasonForInvestigation': reasonForInvestigation,
        if (invoiceId != null && invoiceId!.isNotEmpty) 'invoiceId': invoiceId,
        if (invoiceItemId != null && invoiceItemId!.isNotEmpty)
          'invoiceItemId': invoiceItemId,
        if (serviceId != null && serviceId!.isNotEmpty) 'serviceId': serviceId,
      };
}

// ─── RadiologySchedule ─────────────────────────────────────────────────────

class RadiologySchedule {
  const RadiologySchedule({
    required this.id,
    required this.orderItemId,
    required this.scheduledAt,
    this.radiographerId,
    this.machineId,
    this.createdAt,
    this.updatedAt,
    this.radiographer,
    this.machine,
  });

  final String id;
  final String orderItemId;
  final String scheduledAt;
  final String? radiographerId;
  final String? machineId;
  final String? createdAt;
  final String? updatedAt;
  final RadiologyStaffRef? radiographer;
  final RadiologyMachineRef? machine;

  factory RadiologySchedule.fromJson(Map<String, dynamic> json) {
    return RadiologySchedule(
      id: json['id'] as String? ?? '',
      orderItemId:
          (json['orderItemId'] ?? json['radiologyOrderItemId']) as String? ??
              '',
      scheduledAt: json['scheduledAt'] as String? ?? '',
      radiographerId: json['radiographerId'] as String?,
      machineId: json['machineId'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      radiographer: json['radiographer'] != null
          ? RadiologyStaffRef.fromJson(
              json['radiographer'] as Map<String, dynamic>)
          : null,
      machine: json['machine'] != null
          ? RadiologyMachineRef.fromJson(
              json['machine'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'scheduledAt': scheduledAt,
        if (radiographerId != null) 'radiographerId': radiographerId,
        if (machineId != null) 'machineId': machineId,
      };
}

// ─── RadiologyProcedure ───────────────────────────────────────────────────

class RadiologyProcedure {
  const RadiologyProcedure({
    required this.id,
    required this.orderItemId,
    required this.performedById,
    required this.startTime,
    this.machineId,
    this.endTime,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.performedBy,
    this.machine,
  });

  final String id;
  final String orderItemId;
  final String performedById;
  final String? machineId;
  final String startTime;
  final String? endTime;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;
  final RadiologyStaffRef? performedBy;
  final RadiologyMachineRef? machine;

  factory RadiologyProcedure.fromJson(Map<String, dynamic> json) {
    return RadiologyProcedure(
      id: json['id'] as String? ?? '',
      orderItemId:
          (json['orderItemId'] ?? json['radiologyOrderItemId']) as String? ??
              '',
      performedById: json['performedById'] as String? ?? '',
      machineId: json['machineId'] as String?,
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      performedBy: json['performedBy'] != null
          ? RadiologyStaffRef.fromJson(
              json['performedBy'] as Map<String, dynamic>)
          : null,
      machine: json['machine'] != null
          ? RadiologyMachineRef.fromJson(
              json['machine'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'performedById': performedById,
        'startTime': startTime,
        if (machineId != null) 'machineId': machineId,
        if (endTime != null) 'endTime': endTime,
        if (notes != null) 'notes': notes,
      };
}

// ─── RadiologyImage ───────────────────────────────────────────────────────

class RadiologyImage {
  const RadiologyImage({
    required this.id,
    required this.orderItemId,
    required this.fileName,
    required this.filePath,
    this.mimeType,
    this.fileSize,
    this.uploadedById,
    this.uploadedAt,
    this.uploadedBy,
  });

  final String id;
  final String orderItemId;
  final String fileName;
  final String filePath;
  final String? mimeType;
  final int? fileSize;
  final String? uploadedById;
  final String? uploadedAt;
  final RadiologyStaffRef? uploadedBy;

  factory RadiologyImage.fromJson(Map<String, dynamic> json) {
    return RadiologyImage(
      id: json['id'] as String? ?? '',
      orderItemId:
          (json['orderItemId'] ?? json['radiologyOrderItemId']) as String? ??
              '',
      fileName: json['fileName'] as String? ?? '',
      filePath: json['filePath'] as String? ?? '',
      mimeType: json['mimeType'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      uploadedById: json['uploadedById'] as String?,
      uploadedAt: json['uploadedAt'] as String?,
      uploadedBy: json['uploadedBy'] != null
          ? RadiologyStaffRef.fromJson(
              json['uploadedBy'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ─── RadiologyStudyReport ─────────────────────────────────────────────────

class RadiologyStudyReport {
  const RadiologyStudyReport({
    required this.id,
    required this.orderItemId,
    required this.signedById,
    required this.signedAt,
    this.findings,
    this.impression,
    this.recommendations,
    this.severity,
    this.createdAt,
    this.updatedAt,
    this.signedBy,
  });

  final String id;
  final String orderItemId;
  final String? findings;
  final String? impression;
  final String? recommendations;
  final ReportSeverity? severity;
  final String signedById;
  final String signedAt;
  final String? createdAt;
  final String? updatedAt;
  final RadiologyStaffRef? signedBy;

  factory RadiologyStudyReport.fromJson(Map<String, dynamic> json) {
    return RadiologyStudyReport(
      id: json['id'] as String? ?? '',
      orderItemId:
          (json['orderItemId'] ?? json['radiologyOrderItemId']) as String? ??
              '',
      findings: json['findings'] as String?,
      impression: json['impression'] as String?,
      recommendations: json['recommendations'] as String?,
      severity: ReportSeverity.fromString(json['severity'] as String?),
      signedById: json['signedById'] as String? ?? '',
      signedAt: json['signedAt'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      signedBy: json['signedBy'] != null
          ? RadiologyStaffRef.fromJson(
              json['signedBy'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (findings != null) 'findings': findings,
        if (impression != null) 'impression': impression,
        if (recommendations != null) 'recommendations': recommendations,
        if (severity != null) 'severity': severity!.apiValue,
      };
}

// ─── RadiologyMachine ────────────────────────────────────────────────────

class RadiologyMachine {
  const RadiologyMachine({
    required this.id,
    required this.name,
    required this.modality,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String modality;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  factory RadiologyMachine.fromJson(Map<String, dynamic> json) {
    return RadiologyMachine(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      modality: json['modality'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

// ─── List / dashboard responses ────────────────────────────────────────────

class RadiologyOrdersListResponse {
  const RadiologyOrdersListResponse({
    required this.orders,
    required this.total,
    required this.skip,
    required this.take,
  });

  final List<RadiologyOrder> orders;
  final int total;
  final int skip;
  final int take;

  factory RadiologyOrdersListResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['orders'] ?? json['requests']) as List<dynamic>? ?? [];
    return RadiologyOrdersListResponse(
      orders: list
          .map((e) => RadiologyOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      take: (json['take'] as num?)?.toInt() ?? 20,
    );
  }
}

class RadiologyDashboardResponse {
  const RadiologyDashboardResponse({
    this.totalScansToday = 0,
    this.pending = 0,
    this.completed = 0,
    this.waitingReports = 0,
    this.urgentCases = 0,
  });

  final int totalScansToday;
  final int pending;
  final int completed;
  final int waitingReports;
  final int urgentCases;

  factory RadiologyDashboardResponse.fromJson(Map<String, dynamic> json) {
    return RadiologyDashboardResponse(
      totalScansToday: (json['totalScansToday'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      waitingReports: (json['waitingReports'] as num?)?.toInt() ?? 0,
      urgentCases: (json['urgentCases'] as num?)?.toInt() ?? 0,
    );
  }
}

class RadiologyPatientHistoryResponse {
  const RadiologyPatientHistoryResponse({
    required this.patientId,
    this.patient,
    this.orders = const [],
  });

  final String patientId;
  final RadiologyPatientRef? patient;
  final List<RadiologyOrder> orders;

  factory RadiologyPatientHistoryResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['orders'] ?? json['requests']) as List<dynamic>? ?? [];
    return RadiologyPatientHistoryResponse(
      patientId: json['patientId'] as String? ?? '',
      patient: json['patient'] != null
          ? RadiologyPatientRef.fromJson(
              json['patient'] as Map<String, dynamic>)
          : null,
      orders: list
          .map((e) => RadiologyOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
