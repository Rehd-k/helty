import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'section_form_registry.dart';
import 'specialty_deep_link_nav.dart';
import 'specialty_modules_wizard.dart';
import '../../models/clinical_specialty_models.dart';
import '../../providers/clinical_specialty_providers.dart';
import '../../services/clinical_specialty_service.dart';

/// In-encounter specialty section editor (used in a modal sheet, not a tab).
class EncounterSpecialtyFormsPanel extends ConsumerStatefulWidget {
  const EncounterSpecialtyFormsPanel({
    super.key,
    required this.encounterId,
    required this.patientId,
    this.readOnly = false,
    this.showAppBar = true,
    this.title = 'Specialty forms',
    this.editReason,
  });

  final String encounterId;
  final String patientId;
  final bool readOnly;
  final bool showAppBar;
  final String title;
  final String? editReason;

  static Future<void> showSheet(
    BuildContext context, {
    required String encounterId,
    required String patientId,
    String? editReason,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        builder: (_, scrollCtrl) => EncounterSpecialtyFormsPanel(
          encounterId: encounterId,
          patientId: patientId,
          showAppBar: true,
          editReason: editReason,
        ),
      ),
    );
  }

  @override
  ConsumerState<EncounterSpecialtyFormsPanel> createState() =>
      _EncounterSpecialtyFormsPanelState();
}

class _EncounterSpecialtyFormsPanelState
    extends ConsumerState<EncounterSpecialtyFormsPanel> {
  final _svc = ClinicalSpecialtyService();
  String? _selectedCompositeKey;
  final Map<String, Map<String, dynamic>> _drafts = {};
  final Map<String, int> _schemaVersions = {};
  Timer? _debounce;
  bool _saving = false;
  String? _lastSaveMessage;
  bool _didPickInitialSection = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  String _composite(String specialty, String sectionKey) =>
      '$specialty::$sectionKey';

  CatalogSectionModel? _lookupSection(
    ClinicalSpecialtyCatalogModel? catalog,
    String specialty,
    String sectionKey,
  ) {
    if (catalog == null) return null;
    for (final s in catalog.specialties) {
      if (s.code != specialty) continue;
      for (final sec in s.sections) {
        if (sec.key == sectionKey) return sec;
      }
    }
    return null;
  }

  Future<void> _openWizard(
    BuildContext context,
    String encounterId,
    List<EncounterSpecialtyModuleModel> current,
  ) async {
    await SpecialtyModulesWizard.show(
      context,
      encounterId: encounterId,
      initialModules: current,
      onSync: (next) async {
        await _svc.syncModules(
          encounterId,
          next,
          editReason: widget.editReason,
        );
        ref.invalidate(encounterSpecialtyModulesProvider(encounterId));
      },
    );
  }

  Future<void> _ensureLoaded(
    String encounterId,
    String specialty,
    String sectionKey,
  ) async {
    final ck = _composite(specialty, sectionKey);
    if (_drafts.containsKey(ck)) return;
    try {
      final rows = await _svc.listSections(
        encounterId,
        specialty: specialty,
        keys: [sectionKey],
      );
      if (rows.isEmpty) {
        _drafts[ck] = {};
        _schemaVersions[ck] = 1;
      } else {
        final row = rows.first;
        _drafts[ck] = Map<String, dynamic>.from(row.data);
        _schemaVersions[ck] = row.schemaVersion;
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load section: $e')),
        );
      }
    }
  }

  void _scheduleSave(
    BuildContext context,
    String encounterId,
    String specialty,
    String sectionKey,
  ) {
    if (widget.readOnly) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 750), () async {
      final ck = _composite(specialty, sectionKey);
      final data = _drafts[ck];
      if (data == null) return;
      setState(() {
        _saving = true;
        _lastSaveMessage = null;
      });
      try {
        final row = await _svc.upsertSection(
          encounterId,
          specialty,
          sectionKey,
          data,
          schemaVersion: _schemaVersions[ck] ?? 1,
          editReason: widget.editReason,
        );
        _schemaVersions[ck] = row.schemaVersion;
        if (mounted) {
          setState(() {
            _saving = false;
            _lastSaveMessage = 'Saved';
          });
        }
      } catch (e) {
        if (!mounted || !context.mounted) return;
        setState(() {
          _saving = false;
          _lastSaveMessage = 'Save failed';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final encounterId = widget.encounterId;
    final patientId = widget.patientId;
    final modulesAsync = ref.watch(encounterSpecialtyModulesProvider(encounterId));
    final catalogAsync = ref.watch(clinicalSpecialtyCatalogProvider);

    return modulesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Modules: $e')),
      data: (modules) {
        return catalogAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Catalog: $e')),
          data: (catalog) {
            final flat = <({String specialty, String sectionKey})>[];
            for (final m in modules) {
              for (final k in m.enabledSectionKeys) {
                flat.add((specialty: m.specialty, sectionKey: k));
              }
            }

            if (flat.isEmpty) {
              _didPickInitialSection = false;
            } else if (!_didPickInitialSection && _selectedCompositeKey == null) {
              _didPickInitialSection = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final first = flat.first;
                if (!mounted) return;
                setState(() {
                  _selectedCompositeKey =
                      _composite(first.specialty, first.sectionKey);
                });
                _ensureLoaded(encounterId, first.specialty, first.sectionKey);
              });
            }

            final validKeys = flat
                .map((e) => _composite(e.specialty, e.sectionKey))
                .toSet();
            if (_selectedCompositeKey != null &&
                !validKeys.contains(_selectedCompositeKey) &&
                flat.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final first = flat.first;
                setState(() {
                  _selectedCompositeKey =
                      _composite(first.specialty, first.sectionKey);
                });
                _ensureLoaded(encounterId, first.specialty, first.sectionKey);
              });
            }

            final selected = _selectedCompositeKey;
            String? selSpec;
            String? selKey;
            if (selected != null) {
              final parts = selected.split('::');
              if (parts.length == 2) {
                selSpec = parts[0];
                selKey = parts[1];
              }
            }

            final theme = Theme.of(context);
            final scheme = theme.colorScheme;

            final body = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.showAppBar)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (!widget.readOnly)
                  Padding(
                    padding:
                        EdgeInsets.fromLTRB(16, widget.showAppBar ? 4 : 0, 16, 8),
                    child: Row(
                      children: [
                        const Spacer(),
                        if (_saving)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (_lastSaveMessage != null)
                          Text(
                            _lastSaveMessage!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.tertiary,
                            ),
                          ),
                        const Gap(12),
                        FilledButton.tonalIcon(
                          onPressed: () =>
                              _openWizard(context, encounterId, modules),
                          icon: const Icon(Icons.tune, size: 20),
                          label: const Text('Configure'),
                        ),
                      ],
                    ),
                  ),
                if (flat.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.medical_information_outlined,
                            size: 56,
                            color: scheme.outline,
                          ),
                          const Gap(16),
                          Text(
                            'No specialty sections enabled',
                            style: theme.textTheme.titleMedium,
                          ),
                          const Gap(8),
                          Text(
                            'Use Configure to add modules for this visit.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          if (!widget.readOnly) ...[
                            const Gap(20),
                            FilledButton.icon(
                              onPressed: () =>
                                  _openWizard(context, encounterId, modules),
                              icon: const Icon(Icons.add),
                              label: const Text('Configure specialties'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else ...[
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: flat.length,
                      separatorBuilder: (_, __) => const Gap(8),
                      itemBuilder: (ctx, i) {
                        final item = flat[i];
                        final ck = _composite(item.specialty, item.sectionKey);
                        final meta = _lookupSection(
                          catalog,
                          item.specialty,
                          item.sectionKey,
                        );
                        final label = meta?.label ?? item.sectionKey;
                        final on = ck == selected;
                        return ChoiceChip(
                          label: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: on,
                          onSelected: (_) {
                            setState(() => _selectedCompositeKey = ck);
                            _ensureLoaded(
                              encounterId,
                              item.specialty,
                              item.sectionKey,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: selSpec != null && selKey != null
                        ? _buildEditor(
                            context,
                            catalog,
                            encounterId,
                            patientId,
                            selSpec,
                            selKey,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            );

            if (widget.showAppBar) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.close),
                        ),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: body),
                ],
              );
            }
            return body;
          },
        );
      },
    );
  }

  Widget _buildEditor(
    BuildContext context,
    ClinicalSpecialtyCatalogModel catalog,
    String encounterId,
    String patientId,
    String specialty,
    String sectionKey,
  ) {
    final ck = _composite(specialty, sectionKey);
    final meta = _lookupSection(catalog, specialty, sectionKey);

    if (meta != null && meta.isDeepLink) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.link,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(meta.label),
                  subtitle: const Text(
                    'Data is captured in the linked module. Open it below when supported.',
                  ),
                ),
                const Gap(16),
                FilledButton.icon(
                  onPressed: () => navigateSpecialtyDeepLink(
                    context: context,
                    section: meta,
                    patientId: patientId,
                    encounterId: encounterId,
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open linked workflow'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_drafts.containsKey(ck)) {
      return const Center(child: CircularProgressIndicator());
    }

    var data = Map<String, dynamic>.from(_drafts[ck] ?? {});
    final example = meta?.exampleData;
    if (example != null) {
      for (final e in example.entries) {
        data.putIfAbsent(e.key, () => e.value);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: buildSectionForm(
        sectionKey: sectionKey,
        data: data,
        exampleData: example,
        readOnly: widget.readOnly,
        onChanged: widget.readOnly
            ? (_) {}
            : (next) {
                setState(() {
                  _drafts[ck] = next;
                  _lastSaveMessage = null;
                });
                _scheduleSave(context, encounterId, specialty, sectionKey);
              },
      ),
    );
  }
}
