import 'package:flutter/material.dart';
import 'package:helty/src/lab/widgets/lab_order_results_dialog.dart';
import 'package:helty/src/models/lab_order_model.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';
import 'package:helty/src/radiology/services/radiology_service.dart';
import 'package:helty/src/radiology/ui/widgets/radiology_order_results_dialog.dart';

/// Read-only lab result dialog for completed encounter review.
void showCompletedEncounterLabDialog(
  BuildContext context,
  LabOrderModel order,
) {
  showLabOrderResultsDialog(
    context,
    order: order,
    showEncounterId: false,
  );
}

/// Read-only radiology summary including report text and uploaded files.
void showCompletedEncounterRadiologyDialog(
  BuildContext context,
  RadiologyOrder order,
) {
  showRadiologyOrderResultsDialog(
    context,
    service: RadiologyService(),
    order: order,
  );
}
