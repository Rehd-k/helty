import 'package:flutter/material.dart';
import 'package:helty/src/models/encounter_model.dart';
import 'package:helty/src/paitients/patient_model.dart';

/// Provides the loaded encounter and patient to completed encounter detail tabs (read-only).
class CompletedEncounterScope extends InheritedWidget {
  const CompletedEncounterScope({
    super.key,
    required this.encounter,
    this.patient,
    required super.child,
  });

  final EncounterModel encounter;
  final Patient? patient;

  static CompletedEncounterScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CompletedEncounterScope>();

  @override
  bool updateShouldNotify(CompletedEncounterScope old) =>
      encounter.id != old.encounter.id || patient?.patientId != old.patient?.patientId;
}
