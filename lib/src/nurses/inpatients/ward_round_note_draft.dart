import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory SOAP draft for a minimizable ward round note dialog.
class WardRoundNoteDraft {
  const WardRoundNoteDraft({
    required this.admissionId,
    this.subjective,
    this.objective,
    this.assessment,
    this.plan,
    this.expandedIndex = 0,
  });

  final String admissionId;
  final String? subjective;
  final String? objective;
  final String? assessment;
  final String? plan;
  final int expandedIndex;

  bool get hasContent =>
      (subjective?.trim().isNotEmpty ?? false) ||
      (objective?.trim().isNotEmpty ?? false) ||
      (assessment?.trim().isNotEmpty ?? false) ||
      (plan?.trim().isNotEmpty ?? false);
}

enum WardRoundNoteDialogOutcome { saved, discarded, minimized }

class WardRoundNoteDialogResult {
  const WardRoundNoteDialogResult({
    required this.outcome,
    this.draft,
  });

  final WardRoundNoteDialogOutcome outcome;
  final WardRoundNoteDraft? draft;
}

/// Holds a minimized ward round note draft for the open inpatient admission.
final wardRoundNoteDraftProvider =
    StateProvider<WardRoundNoteDraft?>((ref) => null);
