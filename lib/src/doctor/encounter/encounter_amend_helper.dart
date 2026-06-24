import 'package:flutter/material.dart';

import 'doctor_encounter_view_screen.dart';

/// Merges optional [editReason] into a PATCH/POST body when versioned edits apply.
Map<String, dynamic> encounterPatchWithAmend(
  EncounterScope? scope,
  Map<String, dynamic> body,
) {
  if (scope == null || !scope.versionedEdits) return body;
  final reason = scope.editReason?.trim();
  if (reason == null || reason.isEmpty) return body;
  return {...body, 'editReason': reason};
}

String? amendEditReason(EncounterScope? scope) {
  if (scope == null || !scope.versionedEdits) return null;
  final reason = scope.editReason?.trim();
  if (reason == null || reason.isEmpty) return null;
  return reason;
}

void showEncounterSaveSnackBar(
  BuildContext context, {
  required EncounterScope? scope,
  String ongoingMessage = 'Saved',
}) {
  final message =
      scope?.versionedEdits == true ? 'Amendment saved' : ongoingMessage;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// User-facing message for encounter edit API failures.
String encounterEditErrorMessage(Object error) {
  final text = error.toString();
  if (text.contains('Only a physician may edit this inpatient encounter')) {
    return 'Read-only chart — only physicians may edit while admission is active.';
  }
  if (text.contains('Only the treating doctor for this encounter may edit')) {
    return 'Read-only chart — only the treating doctor may edit this encounter.';
  }
  if (text.contains('Cannot edit a cancelled encounter')) {
    return 'This encounter is cancelled and cannot be edited.';
  }
  return text;
}

void showEncounterEditErrorSnackBar(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(encounterEditErrorMessage(error))),
  );
}

/// Optional reason dialog when entering amend mode.
Future<String?> showAmendReasonDialog(BuildContext context) async {
  final ctrl = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Amendment reason'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Optional: describe why you are changing this completed encounter. '
              'Each save is recorded in edit history.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      );
    },
  );
  ctrl.dispose();
  return result;
}

Future<String?> showChangeAmendReasonDialog(
  BuildContext context, {
  String? currentReason,
}) async {
  final ctrl = TextEditingController(text: currentReason ?? '');
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Edit amendment reason'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Reason for amendments',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
  ctrl.dispose();
  return result;
}
