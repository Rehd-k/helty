import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../models/clinical_specialty_models.dart';
import '../../providers/clinical_specialty_providers.dart';

/// Two-step wizard: pick specialties, then sections. Calls [onSync] with full module list.
class SpecialtyModulesWizard extends ConsumerStatefulWidget {
  const SpecialtyModulesWizard({
    super.key,
    required this.encounterId,
    required this.initialModules,
    required this.onSync,
  });

  final String encounterId;
  final List<EncounterSpecialtyModuleModel> initialModules;
  final Future<void> Function(List<EncounterSpecialtyModuleModel> next) onSync;

  static Future<void> show(
    BuildContext context, {
    required String encounterId,
    required List<EncounterSpecialtyModuleModel> initialModules,
    required Future<void> Function(List<EncounterSpecialtyModuleModel> next)
        onSync,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: SpecialtyModulesWizard(
          encounterId: encounterId,
          initialModules: initialModules,
          onSync: onSync,
        ),
      ),
    );
  }

  @override
  ConsumerState<SpecialtyModulesWizard> createState() =>
      _SpecialtyModulesWizardState();
}

class _SpecialtyModulesWizardState extends ConsumerState<SpecialtyModulesWizard> {
  int _step = 0;
  final Set<String> _selectedSpecialties = {};
  final Map<String, Set<String>> _sectionKeysBySpecialty = {};
  final _searchCtrl = TextEditingController();
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    for (final m in widget.initialModules) {
      _selectedSpecialties.add(m.specialty);
      _sectionKeysBySpecialty[m.specialty] = m.enabledSectionKeys.toSet();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final next = <EncounterSpecialtyModuleModel>[];
    for (final code in _selectedSpecialties) {
      final keys = _sectionKeysBySpecialty[code]?.toList() ?? [];
      keys.sort();
      next.add(
        EncounterSpecialtyModuleModel(
          specialty: code,
          enabledSectionKeys: keys,
        ),
      );
    }

    final prevKeys = <String>{};
    for (final m in widget.initialModules) {
      for (final k in m.enabledSectionKeys) {
        prevKeys.add('${m.specialty}|$k');
      }
    }
    final nextKeys = <String>{};
    for (final m in next) {
      for (final k in m.enabledSectionKeys) {
        nextKeys.add('${m.specialty}|$k');
      }
    }
    final removed = prevKeys.difference(nextKeys);
    if (removed.isNotEmpty && mounted) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove specialty sections?'),
          content: Text(
            'Turning off sections will delete their saved data on the server for this encounter (${removed.length} section(s)). Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() => _syncing = true);
    try {
      await widget.onSync(next);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final catalogAsync = ref.watch(clinicalSpecialtyCatalogProvider);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.88,
      child: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Catalog failed: $e')),
        data: (catalog) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Row(
                  children: [
                    Text(
                      _step == 0 ? 'Specialties' : 'Sections',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _stepChip(theme, scheme, 0, '1. Specialties'),
                    const Gap(8),
                    Icon(Icons.chevron_right, color: scheme.outline),
                    const Gap(8),
                    _stepChip(theme, scheme, 1, '2. Sections'),
                  ],
                ),
              ),
              const Gap(12),
              if (_step == 0) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search specialties',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const Gap(12),
              ],
              Expanded(
                child: _step == 0
                    ? _buildSpecialtyStep(catalog, theme, scheme)
                    : _buildSectionStep(catalog, theme, scheme),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (_step == 1)
                      OutlinedButton(
                        onPressed: () => setState(() => _step = 0),
                        child: const Text('Back'),
                      ),
                    const Spacer(),
                    if (_step == 0)
                      FilledButton(
                        onPressed: _selectedSpecialties.isEmpty
                            ? null
                            : () => setState(() => _step = 1),
                        child: const Text('Next'),
                      )
                    else
                      FilledButton.icon(
                        onPressed: _syncing ? null : _confirm,
                        icon: _syncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check, size: 20),
                        label: Text(_syncing ? 'Saving…' : 'Save modules'),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stepChip(
    ThemeData theme,
    ColorScheme scheme,
    int idx,
    String label,
  ) {
    final on = _step == idx;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: on ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: on ? scheme.onPrimaryContainer : scheme.onSurface,
          fontWeight: on ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSpecialtyStep(
    ClinicalSpecialtyCatalogModel catalog,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    final q = _searchCtrl.text.trim().toLowerCase();
    var list = catalog.specialties;
    if (q.isNotEmpty) {
      list = list
          .where(
            (s) =>
                s.displayName.toLowerCase().contains(q) ||
                s.code.toLowerCase().contains(q),
          )
          .toList();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final s = list[i];
        final selected = _selectedSpecialties.contains(s.code);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: selected
              ? scheme.primary.withValues(alpha: 0.08)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected ? scheme.primary : scheme.outline.withValues(alpha: 0.12),
            ),
          ),
          child: CheckboxListTile(
            value: selected,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selectedSpecialties.add(s.code);
                  _sectionKeysBySpecialty.putIfAbsent(s.code, () {
                    final embedded = s.sections
                        .where((x) => !x.isDeepLink)
                        .map((x) => x.key)
                        .toSet();
                    return embedded.isEmpty
                        ? s.sections.map((x) => x.key).toSet()
                        : embedded;
                  });
                } else {
                  _selectedSpecialties.remove(s.code);
                  _sectionKeysBySpecialty.remove(s.code);
                }
              });
            },
            title: Text(
              s.displayName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              s.description ?? s.code,
              style: theme.textTheme.bodySmall,
            ),
            secondary: Icon(
              Icons.medical_information_outlined,
              color: scheme.primary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionStep(
    ClinicalSpecialtyCatalogModel catalog,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    final codes = _selectedSpecialties.toList()..sort();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: codes.length,
      itemBuilder: (ctx, i) {
        final code = codes[i];
        final matches = catalog.specialties.where((e) => e.code == code);
        final spec = matches.isEmpty
            ? CatalogSpecialtyModel(code: code, displayName: code, sections: [])
            : matches.first;
        final selected = _sectionKeysBySpecialty.putIfAbsent(code, () => {});

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outline.withValues(alpha: 0.12)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  spec.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Gap(12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: spec.sections.map((sec) {
                    final on = selected.contains(sec.key);
                    final isDeep = sec.isDeepLink;
                    return FilterChip(
                      selected: on,
                      label: Text(sec.label),
                      avatar: Icon(
                        isDeep ? Icons.link : Icons.article_outlined,
                        size: 18,
                      ),
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            selected.add(sec.key);
                          } else {
                            selected.remove(sec.key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
