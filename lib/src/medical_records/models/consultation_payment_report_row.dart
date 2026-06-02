/// One row in the Medical Records paid-consultation report.
class ConsultationPaymentReportRow {
  const ConsultationPaymentReportRow({
    required this.patientId,
    required this.patientName,
    required this.ageLabel,
    required this.gender,
    required this.diagnosis,
    required this.paidAt,
    this.invoiceId,
    this.encounterId,
  });

  final String patientId;
  final String patientName;
  final String ageLabel;
  final String gender;
  final String diagnosis;
  final DateTime paidAt;
  final String? invoiceId;
  final String? encounterId;
}
