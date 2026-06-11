import 'package:helty/src/models/service_model.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/providers/module_request_flow_provider.dart';

/// In-session snapshot of a billing cart waiting for payment.
class ParkedBillingSession {
  const ParkedBillingSession({
    required this.id,
    required this.patient,
    required this.items,
    required this.flowConfig,
    required this.parkedAt,
    required this.totalDue,
  });

  final String id;
  final Patient patient;
  final List<ServiceModel> items;
  final ModuleRequestFlowConfig flowConfig;
  final DateTime parkedAt;
  final double totalDue;

  int get itemCount =>
      items.fold<int>(0, (sum, line) => sum + (line.qty ?? 1));

  String get patientKey {
    final uuid = patient.id?.trim() ?? '';
    if (uuid.isNotEmpty) return uuid;
    return patient.patientId.trim();
  }

  ParkedBillingSession copyWith({
    String? id,
    Patient? patient,
    List<ServiceModel>? items,
    ModuleRequestFlowConfig? flowConfig,
    DateTime? parkedAt,
    double? totalDue,
  }) {
    return ParkedBillingSession(
      id: id ?? this.id,
      patient: patient ?? this.patient,
      items: items ?? this.items,
      flowConfig: flowConfig ?? this.flowConfig,
      parkedAt: parkedAt ?? this.parkedAt,
      totalDue: totalDue ?? this.totalDue,
    );
  }
}

/// Deep-copies cart lines so parked sessions are isolated from live edits.
List<ServiceModel> deepCopyServiceLines(Iterable<ServiceModel> lines) {
  return lines.map(copyServiceModel).toList();
}

ServiceModel copyServiceModel(ServiceModel line) {
  return ServiceModel(
    id: line.id,
    serviceId: line.serviceId,
    name: line.name,
    description: line.description,
    categoryId: line.categoryId,
    categoryName: line.categoryName,
    departmentId: line.departmentId,
    departmentName: line.departmentName,
    cost: line.cost,
    qty: line.qty,
    isRecurringDaily: line.isRecurringDaily,
    createdAtIso: line.createdAtIso,
    createdByName: line.createdByName,
    settled: line.settled,
    amountPaid: line.amountPaid,
    transactionItemId: line.transactionItemId,
    drugId: line.drugId,
    invoiceId: line.invoiceId,
    hmoPrices: List<ServiceHmoPrice>.from(line.hmoPrices),
    serviceCode: line.serviceCode,
  );
}
