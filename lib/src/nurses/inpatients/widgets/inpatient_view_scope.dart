import 'package:flutter/material.dart';

/// Provides inpatient view context (patientId, admissionId) to tab content
/// so tabs like Ward Round can load and create notes for the current admission.
class InpatientViewScope extends InheritedWidget {
  const InpatientViewScope({
    super.key,
    required this.patientId,
    this.admissionId,
    required super.child,
  });

  final String patientId;
  final String? admissionId;

  static InpatientViewScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InpatientViewScope>();

  @override
  bool updateShouldNotify(InpatientViewScope old) =>
      patientId != old.patientId || admissionId != old.admissionId;
}
