import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/doctor/completed/widgets/completed_encounter_scope.dart';
import 'package:helty/src/models/encounter_model.dart';

@RoutePage()
class CompletedEncounterDiagnosisTab extends StatelessWidget {
  const CompletedEncounterDiagnosisTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = CompletedEncounterScope.of(context);
    if (scope == null) {
      return const Center(child: Text('Encounter context not available'));
    }
    final e = scope.encounter;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    var primaryCode = e.primaryIcdCode;
    var primaryDesc = e.primaryIcdDescription;
    if ((primaryCode == null || primaryCode.isEmpty) &&
        (primaryDesc == null || primaryDesc.isEmpty) &&
        e.linkedDiagnoses.isNotEmpty) {
      primaryCode = e.linkedDiagnoses.first.primaryIcdCode;
      primaryDesc = e.linkedDiagnoses.first.primaryIcdDescription;
    }

    List<MapEntry<String, String>> secondary = [];
    if (e.secondaryDiagnosesJson != null && e.secondaryDiagnosesJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(e.secondaryDiagnosesJson!) as List<dynamic>?;
        if (decoded != null) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final code = item['code']?.toString() ?? '';
              final desc = item['description']?.toString() ?? item['desc']?.toString() ?? '';
              if (code.isNotEmpty || desc.isNotEmpty) {
                secondary.add(MapEntry(code, desc));
              }
            }
          }
        }
      } catch (_) {}
    }

    List<String> procedures = [];
    if (e.proceduresJson != null && e.proceduresJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(e.proceduresJson!) as List<dynamic>?;
        if (decoded != null) {
          for (final item in decoded) {
            if (item is String) {
              procedures.add(item);
            } else if (item is Map<String, dynamic>) {
              procedures.add(item['name']?.toString() ?? item['code']?.toString() ?? '');
            }
          }
        }
      } catch (_) {}
    }

    final List<EncounterDiagnosisSnapshot> linkedExtra =
        e.linkedDiagnoses.length > 1 ? e.linkedDiagnoses.sublist(1) : [];

    return ResponsiveBody(
      center: false,
      expand: false,
      builder: (context, bp) => SingleChildScrollView(
        padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (primaryCode != null || primaryDesc != null) ...[
            _Section(
              title: 'Primary diagnosis',
              theme: theme,
              colorScheme: colorScheme,
              children: [
                if (primaryCode != null && primaryCode.isNotEmpty)
                  Text(
                    primaryCode,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                if (primaryDesc != null && primaryDesc.isNotEmpty) ...[
                  if (primaryCode != null && primaryCode.isNotEmpty)
                    const SizedBox(height: 4),
                  Text(
                    primaryDesc,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
          ],
          if (e.linkedDiagnoses.length > 1) ...[
            _Section(
              title: 'Additional diagnosis records',
              theme: theme,
              colorScheme: colorScheme,
              children: [
                for (final d in linkedExtra)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (d.primaryIcdCode != null &&
                            d.primaryIcdCode!.isNotEmpty)
                          Text(
                            d.primaryIcdCode!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        if (d.primaryIcdDescription != null &&
                            d.primaryIcdDescription!.isNotEmpty)
                          Text(
                            d.primaryIcdDescription!,
                            style: theme.textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          if (secondary.isNotEmpty) ...[
            _Section(
              title: 'Secondary diagnoses',
              theme: theme,
              colorScheme: colorScheme,
              children: [
                for (final entry in secondary)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (entry.key.isNotEmpty)
                          SizedBox(
                            width: 80,
                            child: Text(
                              entry.key,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        if (entry.key.isNotEmpty) const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          if (procedures.isNotEmpty) ...[
            _Section(
              title: 'Procedures',
              theme: theme,
              colorScheme: colorScheme,
              children: [
                for (final p in procedures)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      p,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ],
          if (primaryCode == null &&
              primaryDesc == null &&
              e.linkedDiagnoses.isEmpty &&
              secondary.isEmpty &&
              procedures.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No diagnosis or procedures recorded.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.theme,
    required this.colorScheme,
    required this.children,
  });

  final String title;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
