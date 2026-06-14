import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/doctor/encounter/encounter_amend_helper.dart';
import 'package:helty/src/doctor/templates/encounter_template_fields.dart';
import 'package:helty/src/doctor/templates/encounter_template_merge.dart';
import 'package:helty/src/models/clinical_specialty_models.dart';
import 'package:helty/src/models/encounter_template_model.dart';
import 'package:helty/src/services/clinical_specialty_service.dart';
import 'package:helty/src/services/encounter_service.dart';

/// Client-side apply flow for encounter templates (no server apply endpoint).
class EncounterTemplateApplier {
  EncounterTemplateApplier({
    EncounterService? encounterService,
    ClinicalSpecialtyService? clinicalSpecialtyService,
  })  : _encounterService = encounterService ?? EncounterService(),
        _clinicalSpecialtyService =
            clinicalSpecialtyService ?? ClinicalSpecialtyService();

  final EncounterService _encounterService;
  final ClinicalSpecialtyService _clinicalSpecialtyService;

  Future<EncounterTemplateMergeMode?> showMergeModeDialog(
    BuildContext context,
  ) {
    return showDialog<EncounterTemplateMergeMode>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Apply template'),
          content: const Text(
            'This encounter already has clinical data. How should the template be applied?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                ctx,
                EncounterTemplateMergeMode.fillEmptyOnly,
              ),
              child: const Text('Fill empty only'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                ctx,
                EncounterTemplateMergeMode.replaceAll,
              ),
              child: const Text('Replace all'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> apply({
    required BuildContext context,
    required EncounterScope scope,
    required EncounterTemplateModel template,
  }) async {
    final encounter = await _encounterService.getById(
      scope.encounterId,
      expand: ['specialtyModules', 'clinicalSections'],
    );
    if (encounter == null) {
      throw StateError('Encounter not found');
    }

    var mode = EncounterTemplateMergeMode.replaceAll;
    if (encounterHasClinicalData(encounter)) {
      if (!context.mounted) return false;
      final chosen = await showMergeModeDialog(context);
      if (chosen == null || !context.mounted) return false;
      mode = chosen;
    }

    final patch = mergeClinicalPatch(
      current: encounter,
      template: template,
      mode: mode,
    );

    if (patch.isNotEmpty) {
      await _encounterService.update(
        scope.encounterId,
        encounterPatchWithAmend(scope, patch),
      );
    }

    if (templateHasDiagnosis(template)) {
      final diagnosis = mergeDiagnosisFields(
        current: encounter,
        template: template,
        mode: mode,
      );
      final diagnosisPatch = <String, dynamic>{};
      for (final key in kEncounterTemplateDiagnosisKeys) {
        if (diagnosis.containsKey(key) &&
            !encounterTemplateFieldIsEmpty(diagnosis[key])) {
          diagnosisPatch[key] = diagnosis[key];
        }
      }
      if (diagnosisPatch.isNotEmpty) {
        await _encounterService.saveDiagnosis(
          scope.encounterId,
          diagnosisPatch,
          editReason: amendEditReason(scope),
        );
      }
    }

    if (!encounterTemplateFieldIsEmpty(template.specialtyModulesJson)) {
      final modules = _parseSpecialtyModules(template.specialtyModulesJson!);
      if (modules.isNotEmpty) {
        if (mode == EncounterTemplateMergeMode.replaceAll) {
          await _clinicalSpecialtyService.syncModules(
            scope.encounterId,
            modules,
            editReason: amendEditReason(scope),
          );
        } else {
          final existing = encounter.specialtyModules ?? [];
          if (existing.isEmpty) {
            await _clinicalSpecialtyService.syncModules(
              scope.encounterId,
              modules,
              editReason: amendEditReason(scope),
            );
          }
        }
      }
    }

    if (!encounterTemplateFieldIsEmpty(template.clinicalSectionsJson)) {
      final sections = _parseClinicalSections(template.clinicalSectionsJson!);
      for (final section in sections) {
        if (mode == EncounterTemplateMergeMode.fillEmptyOnly) {
          final hasExisting = encounter.clinicalSections?.any(
                (s) =>
                    s.specialty == section.specialty &&
                    s.sectionKey == section.sectionKey &&
                    s.data.isNotEmpty,
              ) ??
              false;
          if (hasExisting) continue;
        }
        await _clinicalSpecialtyService.upsertSection(
          scope.encounterId,
          section.specialty,
          section.sectionKey,
          section.data,
          schemaVersion: section.schemaVersion,
          editReason: amendEditReason(scope),
        );
      }
    }

    return true;
  }

  List<EncounterSpecialtyModuleModel> _parseSpecialtyModules(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) {
            final m = Map<String, dynamic>.from(e);
            final keysRaw = m['enabledSectionKeys'];
            final keys = <String>[];
            if (keysRaw is List) {
              for (final k in keysRaw) {
                keys.add(k.toString());
              }
            }
            return EncounterSpecialtyModuleModel(
              specialty: m['specialty']?.toString() ?? '',
              enabledSectionKeys: keys,
            );
          })
          .where((m) => m.specialty.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  List<({String specialty, String sectionKey, int schemaVersion, Map<String, dynamic> data})>
      _parseClinicalSections(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) {
            final m = Map<String, dynamic>.from(e);
            final dataRaw = m['data'];
            Map<String, dynamic> data = {};
            if (dataRaw is Map<String, dynamic>) {
              data = Map<String, dynamic>.from(dataRaw);
            } else if (dataRaw is Map) {
              data = Map<String, dynamic>.from(dataRaw);
            }
            final sv = m['schemaVersion'];
            return (
              specialty: m['specialty']?.toString() ?? '',
              sectionKey: m['sectionKey']?.toString() ?? '',
              schemaVersion: sv is int ? sv : int.tryParse('$sv') ?? 1,
              data: data,
            );
          })
          .where((s) => s.specialty.isNotEmpty && s.sectionKey.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
