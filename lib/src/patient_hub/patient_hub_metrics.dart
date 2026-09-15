import 'package:flutter/material.dart';

import '../widgets/helty_surface.dart';
import 'models/patient_hub_models.dart';

/// Accent tiles and layout thresholds for Patient Hub.
abstract final class PatientHubMetrics {
  static const cardBreakpoint = 768.0;
  static const sidebarBreakpoint = 1100.0;

  static const Color waitGreen = Color(0xFF16A34A);
  static const Color waitAmber = Color(0xFFEA580C);
  static const Color waitRed = Color(0xFFDC2626);

  static const Color iconBlue = Color(0xFF2563EB);
  static const Color iconTeal = Color(0xFF0D9488);
  static const Color iconPurple = Color(0xFF7C3AED);
  static const Color iconPink = Color(0xFFDB2777);
  static const Color iconIndigo = Color(0xFF4F46E5);

  static PatientHubTabDef tabDefForRouteName(String name) {
    for (final def in patientHubTabDefs) {
      if (def.routeName == name) return def;
    }
    return PatientHubTabDef(
      label: name.replaceAll('Route', '').replaceAll('Hub', ''),
      routeName: name,
    );
  }

  static Color accentForTab(String routeName) {
    switch (routeName) {
      case 'HubOverviewRoute':
        return iconBlue;
      case 'HubProfileRoute':
        return iconPurple;
      case 'HubEncountersRoute':
        return iconIndigo;
      case 'HubVitalsRoute':
        return waitRed;
      case 'HubLabsRoute':
        return iconTeal;
      case 'HubImagingRoute':
        return iconPink;
      case 'HubMedsRoute':
        return waitAmber;
      case 'HubDialysisRoute':
        return iconBlue;
      case 'HubTheatreRoute':
        return iconPurple;
      case 'HubDocumentsRoute':
        return iconIndigo;
      case 'HubNotesRoute':
        return iconTeal;
      default:
        return iconBlue;
    }
  }
}

typedef HubSolidIcon = HeltySolidIcon;
