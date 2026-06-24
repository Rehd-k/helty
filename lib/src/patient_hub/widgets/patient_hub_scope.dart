import 'package:flutter/material.dart';

/// Provides [patientUuid] to nested Patient Hub tab routes.
class PatientHubScope extends InheritedWidget {
  const PatientHubScope({
    super.key,
    required this.patientUuid,
    required super.child,
  });

  final String patientUuid;

  static PatientHubScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PatientHubScope>();

  static String requirePatientUuid(BuildContext context) {
    final scope = of(context);
    assert(scope != null, 'PatientHubScope not found');
    return scope!.patientUuid;
  }

  @override
  bool updateShouldNotify(PatientHubScope old) =>
      patientUuid != old.patientUuid;
}
