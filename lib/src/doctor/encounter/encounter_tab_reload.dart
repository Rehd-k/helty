import 'package:flutter/material.dart';

import 'doctor_encounter_view_screen.dart';

/// Refetches tab draft data when [EncounterScope.reloadGeneration] changes.
void reloadEncounterTabIfTemplateApplied({
  required BuildContext context,
  required int lastReloadGeneration,
  required void Function(int next) updateLastReloadGeneration,
  required bool loaded,
  required VoidCallback reload,
}) {
  final scope = EncounterScope.of(context);
  if (scope == null) return;
  if (scope.reloadGeneration == lastReloadGeneration) return;
  updateLastReloadGeneration(scope.reloadGeneration);
  if (loaded) reload();
}
