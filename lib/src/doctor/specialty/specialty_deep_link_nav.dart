import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';

import '../../models/clinical_specialty_models.dart';

/// Navigates for catalog `deep_link` sections (Ob/Gyn and future hints).
void navigateSpecialtyDeepLink({
  required BuildContext context,
  required CatalogSectionModel section,
  required String patientId,
  required String encounterId,
}) {
  final route = section.deepLinkRoute?.trim();
  final key = section.key;

  if (key == 'obgyn.antenatal_visit' ||
      route == '/obstetrics/antenatal' ||
      route == 'obstetrics.antenatal') {
    context.router.push(
      ObstetricsPregnanciesListRoute(
        patientId: patientId,
        encounterId: encounterId,
      ),
    );
    return;
  }
  if (key == 'obgyn.gynae_procedure' ||
      route == '/obstetrics/gynae' ||
      route == 'obstetrics.gynae') {
    context.router.push(
      ObstetricsAddGynaeProcedureRoute(
        patientId: patientId,
        encounterId: encounterId,
      ),
    );
    return;
  }

  if (route != null && route.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Deep link "$route" is not wired in the app. Section: ${section.label}',
        ),
      ),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Open ${section.label} in its dedicated module (patient $patientId).',
      ),
    ),
  );
}
