import 'package:flutter/material.dart';

/// Provides inpatient view context to tab content.
///
/// Exposes patient/admission identifiers as well as high-level role flags for
/// the currently logged-in staff, so tabs can adjust behavior based on whether
/// the viewer is a doctor or nurse (e.g. ordering vs administering).
class InpatientViewScope extends InheritedWidget {
  const InpatientViewScope({
    super.key,
    required this.patientId,
    this.admissionId,
    this.encounterId,
    this.staffId,
    this.role,
    this.accountType,
    this.isDoctor = false,
    this.isNurse = false,
    required super.child,
  });

  final String patientId;
  final String? admissionId;

  /// Optional encounter backing this admission, when available.
  final String? encounterId;

  /// Currently logged-in staff identifiers.
  final String? staffId;
  final String? role;
  final String? accountType;

  /// Convenience booleans derived from [role]/[accountType].
  final bool isDoctor;
  final bool isNurse;

  static InpatientViewScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InpatientViewScope>();

  @override
  bool updateShouldNotify(InpatientViewScope old) =>
      patientId != old.patientId ||
      admissionId != old.admissionId ||
      encounterId != old.encounterId ||
      staffId != old.staffId ||
      role != old.role ||
      accountType != old.accountType ||
      isDoctor != old.isDoctor ||
      isNurse != old.isNurse;
}
