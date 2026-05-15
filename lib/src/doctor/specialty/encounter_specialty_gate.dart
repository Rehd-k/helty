import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../models/clinical_specialty_models.dart';
import '../../providers/clinical_specialty_providers.dart';
import '../../services/clinical_specialty_service.dart';

/// First step when opening an encounter: pick specialties & sections, or skip.
class EncounterSpecialtyGate extends ConsumerStatefulWidget {
  const EncounterSpecialtyGate({
    super.key,
    required this.encounterId,
    required this.onFinished,
  });

  final String encounterId;
  final void Function() onFinished;

  /// Non-dismissible dialog (width ≥ [narrowWidthBreakpoint]) or bottom sheet
  /// (narrower). Pops the overlay route then invokes [onUserFinished].
  static Future<void> showBlockingOverlay(
    BuildContext context, {
    required String encounterId,
    required VoidCallback onUserFinished,
    double narrowWidthBreakpoint = 720,
  }) async {
    if (!context.mounted) return;
    final size = MediaQuery.sizeOf(context);
    final useDialog = size.width >= narrowWidthBreakpoint;

    if (useDialog) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final w = math.min(920.0, size.width * 0.9).clamp(480.0, 920.0);
          final h = math.min(900.0, size.height * 0.85).clamp(400.0, 900.0);
          return Dialog(
            clipBehavior: Clip.antiAlias,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: SizedBox(
              width: w,
              height: h,
              child: EncounterSpecialtyGate(
                encounterId: encounterId,
                onFinished: () {
                  Navigator.of(ctx).pop();
                  onUserFinished();
                },
              ),
            ),
          );
        },
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        isDismissible: false,
        enableDrag: false,
        showDragHandle: false,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.92,
            minChildSize: 0.5,
            maxChildSize: 0.98,
            builder: (_, __) => EncounterSpecialtyGate(
              encounterId: encounterId,
              onFinished: () {
                Navigator.of(ctx).pop();
                onUserFinished();
              },
            ),
          ),
        ),
      );
    }
  }

  @override
  ConsumerState<EncounterSpecialtyGate> createState() =>
      _EncounterSpecialtyGateState();
}

class _EncounterSpecialtyGateState
    extends ConsumerState<EncounterSpecialtyGate> {
  final _searchCtrl = TextEditingController();
  final _svc = ClinicalSpecialtyService();
  int _step = 0;
  final Set<String> _selectedCodes = {};
  final Map<String, Set<String>> _sectionKeysBySpecialty = {};
  bool _hydrated = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateFromServer());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _hydrateFromServer() async {
    if (_hydrated) return;
    _hydrated = true;
    try {
      final modules = await _svc.listModules(widget.encounterId);
      if (!mounted) return;
      setState(() {
        for (final m in modules) {
          if (m.enabledSectionKeys.isEmpty) continue;
          _selectedCodes.add(m.specialty);
          _sectionKeysBySpecialty[m.specialty] = m.enabledSectionKeys.toSet();
        }
      });
    } catch (_) {
      // leave empty — doctor can select fresh
    }
  }

  IconData _iconForCode(String code) {
    switch (code) {
      case 'CARDIOLOGY':
        return Icons.favorite_rounded;
      case 'NEUROLOGY':
      case 'NEUROSURGERY':
        return Icons.psychology_rounded;
      case 'DERMATOLOGY':
        return Icons.healing_rounded;
      case 'PEDIATRICS':
        return Icons.child_care_rounded;
      case 'OBSTETRICS_GYNECOLOGY':
        return Icons.pregnant_woman_rounded;
      case 'ORTHOPEDICS':
        return Icons.accessible_rounded;
      case 'PSYCHIATRY':
        return Icons.psychology_alt_rounded;
      case 'OPHTHALMOLOGY':
        return Icons.visibility_rounded;
      case 'OTOLARYNGOLOGY':
        return Icons.hearing_rounded;
      case 'UROLOGY':
        return Icons.water_drop_rounded;
      case 'NEPHROLOGY':
        return Icons.filter_alt_rounded;
      case 'ENDOCRINOLOGY':
        return Icons.bloodtype_rounded;
      case 'GASTROENTEROLOGY':
        return Icons.restaurant_rounded;
      case 'PULMONOLOGY':
        return Icons.air_rounded;
      case 'HEMATOLOGY':
      case 'ONCOLOGY':
        return Icons.biotech_rounded;
      case 'RADIOLOGY':
        return Icons.radio_button_checked_rounded;
      case 'ANESTHESIOLOGY':
        return Icons.medication_liquid_rounded;
      case 'EMERGENCY_MEDICINE':
        return Icons.local_hospital_rounded;
      case 'FAMILY_MEDICINE':
      case 'INTERNAL_MEDICINE':
        return Icons.family_restroom_rounded;
      case 'GENERAL_SURGERY':
      case 'PLASTIC_SURGERY':
        return Icons.content_cut_rounded;
      case 'PATHOLOGY':
        return Icons.biotech_rounded;
      case 'INFECTIOUS_DISEASE':
        return Icons.shield_outlined;
      case 'RHEUMATOLOGY':
        return Icons.back_hand_rounded;
      case 'CRITICAL_CARE_MEDICINE':
        return Icons.monitor_heart_rounded;
      case 'PHYSICAL_MEDICINE_REHABILITATION':
        return Icons.directions_walk_rounded;
      case 'ALLERGY_IMMUNOLOGY':
        return Icons.coronavirus_rounded;
      default:
        return Icons.medical_information_rounded;
    }
  }

  void _toggleSpecialty(String code, ClinicalSpecialtyCatalogModel catalog) {
    setState(() {
      if (_selectedCodes.contains(code)) {
        _selectedCodes.remove(code);
        _sectionKeysBySpecialty.remove(code);
      } else {
        _selectedCodes.add(code);
        CatalogSpecialtyModel? spec;
        for (final x in catalog.specialties) {
          if (x.code == code) {
            spec = x;
            break;
          }
        }
        if (spec != null) {
          _sectionKeysBySpecialty[code] = spec.sections
              .map((s) => s.key)
              .toSet();
        }
      }
    });
  }

  void _toggleSection(String specialty, String sectionKey) {
    setState(() {
      final set = _sectionKeysBySpecialty.putIfAbsent(specialty, () => {});
      if (set.contains(sectionKey)) {
        set.remove(sectionKey);
      } else {
        set.add(sectionKey);
      }
    });
  }

  Future<void> _skip() async {
    widget.onFinished();
  }

  Future<void> _saveAndFinish() async {
    if (_selectedCodes.isEmpty) {
      widget.onFinished();
      return;
    }
    setState(() => _saving = true);
    try {
      final next = <EncounterSpecialtyModuleModel>[];
      for (final code in _selectedCodes) {
        final keys = (_sectionKeysBySpecialty[code] ?? {}).toList()..sort();
        if (keys.isEmpty) continue;
        next.add(
          EncounterSpecialtyModuleModel(
            specialty: code,
            enabledSectionKeys: keys,
          ),
        );
      }
      await _svc.syncModules(widget.encounterId, next);
      ref.invalidate(encounterSpecialtyModulesProvider(widget.encounterId));
      if (!mounted) return;
      widget.onFinished();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save specialties: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int _crossAxisCount(double width) {
    if (width >= 1100) return 4;
    if (width >= 720) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final catalogAsync = ref.watch(clinicalSpecialtyCatalogProvider);

    return catalogAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: scheme.error),
              const Gap(12),
              Text(
                'Could not load specialty catalog: $e',
                textAlign: TextAlign.center,
              ),
              const Gap(16),
              FilledButton(
                onPressed: _skip,
                child: const Text('Continue without specialties'),
              ),
            ],
          ),
        ),
      ),
      data: (catalog) {
        final q = _searchCtrl.text.trim().toLowerCase();
        var specs = catalog.specialties;
        if (q.isNotEmpty) {
          specs = specs
              .where(
                (s) =>
                    s.displayName.toLowerCase().contains(q) ||
                    s.code.toLowerCase().contains(q) ||
                    (s.description ?? '').toLowerCase().contains(q),
              )
              .toList();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxis = _crossAxisCount(constraints.maxWidth);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.primaryContainer.withValues(alpha: 0.55),
                        scheme.tertiaryContainer.withValues(alpha: 0.35),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.grid_view_rounded,
                            color: scheme.primary,
                            size: 28,
                          ),
                          const Gap(12),
                          Expanded(
                            child: Text(
                              _step == 0
                                  ? 'Which specialties apply to this visit?'
                                  : 'Choose clinical sections',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),
                      Text(
                        _step == 0
                            ? 'Tap cards to select. You can skip and use only the standard chart tabs.'
                            : 'Toggle the structured forms you need. Deep-link items open other modules.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                      const Gap(16),
                      Row(
                        children: [
                          _StepDot(active: _step == 0, label: '1'),
                          Expanded(
                            child: Container(
                              height: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              color: scheme.outline.withValues(alpha: 0.25),
                            ),
                          ),
                          _StepDot(active: _step == 1, label: '2'),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_step == 0) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search specialties',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
                Expanded(
                  child: _step == 0
                      ? GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxis,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.05,
                              ),
                          itemCount: specs.length,
                          itemBuilder: (ctx, i) {
                            final s = specs[i];
                            final on = _selectedCodes.contains(s.code);
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _toggleSpecialty(s.code, catalog),
                                borderRadius: BorderRadius.circular(20),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: on
                                          ? scheme.primary
                                          : scheme.outline.withValues(
                                              alpha: 0.2,
                                            ),
                                      width: on ? 2.5 : 1,
                                    ),
                                    color: on
                                        ? scheme.primaryContainer.withValues(
                                            alpha: 0.65,
                                          )
                                        : scheme.surfaceContainerHighest
                                              .withValues(alpha: 0.45),
                                    boxShadow: on
                                        ? [
                                            BoxShadow(
                                              color: scheme.primary.withValues(
                                                alpha: 0.22,
                                              ),
                                              blurRadius: 14,
                                              offset: const Offset(0, 6),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  padding: const EdgeInsets.all(14),
                                  child: Stack(
                                    children: [
                                      if (on)
                                        Align(
                                          alignment: Alignment.topRight,
                                          child: Icon(
                                            Icons.check_circle_rounded,
                                            color: scheme.primary,
                                            size: 22,
                                          ),
                                        ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            _iconForCode(s.code),
                                            size: 32,
                                            color: on
                                                ? scheme.primary
                                                : scheme.onSurfaceVariant,
                                          ),
                                          const Gap(10),
                                          Text(
                                            s.displayName,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: scheme.onSurface,
                                                ),
                                          ),
                                          const Gap(4),
                                          Expanded(
                                            child: Text(
                                              s.description ?? s.code,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: scheme.onSurface
                                                        .withValues(
                                                          alpha: 0.65,
                                                        ),
                                                    height: 1.25,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : _buildSectionStep(theme, scheme, catalog),
                ),
                _buildFooter(theme, scheme),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionStep(
    ThemeData theme,
    ColorScheme scheme,
    ClinicalSpecialtyCatalogModel catalog,
  ) {
    final codes = _selectedCodes.toList()..sort();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: codes.length,
      itemBuilder: (ctx, i) {
        final code = codes[i];
        CatalogSpecialtyModel? spec;
        for (final x in catalog.specialties) {
          if (x.code == code) {
            spec = x;
            break;
          }
        }
        if (spec == null) return const SizedBox.shrink();
        final specModel = spec;
        final selected = _sectionKeysBySpecialty[code] ?? {};

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_iconForCode(code), color: scheme.primary, size: 22),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      specModel.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(12),
              LayoutBuilder(
                builder: (ctx, c) {
                  final w = (c.maxWidth - 8) / 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: specModel.sections.map((sec) {
                      final isOn = selected.contains(sec.key);
                      final isDeep = sec.isDeepLink;
                      return SizedBox(
                        width: w.clamp(140, 320),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _toggleSection(code, sec.key),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isOn
                                      ? scheme.primary
                                      : scheme.outline.withValues(alpha: 0.18),
                                  width: isOn ? 2 : 1,
                                ),
                                color: isOn
                                    ? scheme.primaryContainer.withValues(
                                        alpha: 0.5,
                                      )
                                    : scheme.surfaceContainerHighest.withValues(
                                        alpha: 0.35,
                                      ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isDeep
                                        ? Icons.link_rounded
                                        : Icons.article_rounded,
                                    size: 18,
                                    color: isOn
                                        ? scheme.primary
                                        : scheme.onSurfaceVariant,
                                  ),
                                  const Gap(8),
                                  Expanded(
                                    child: Text(
                                      sec.label,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            fontWeight: isOn
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                  if (isOn)
                                    Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: scheme.primary,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter(ThemeData theme, ColorScheme scheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outline.withValues(alpha: 0.12)),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            TextButton(
              onPressed: _saving ? null : _skip,
              child: const Text('Skip for now'),
            ),
            const Spacer(),
            if (_step == 1)
              OutlinedButton(
                onPressed: _saving ? null : () => setState(() => _step = 0),
                child: const Text('Back'),
              ),
            const Gap(12),
            FilledButton.icon(
              onPressed: _saving
                  ? null
                  : () async {
                      if (_step == 0) {
                        if (_selectedCodes.isEmpty) {
                          await _skip();
                          return;
                        }
                        setState(() => _step = 1);
                      } else {
                        await _saveAndFinish();
                      }
                    },
              icon: _saving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                  : Icon(
                      _step == 0
                          ? Icons.arrow_forward_rounded
                          : Icons.check_rounded,
                      size: 20,
                    ),
              label: Text(
                _step == 0
                    ? (_selectedCodes.isEmpty
                          ? 'Continue without specialties'
                          : 'Next: choose sections')
                    : 'Save & open chart',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.active, required this.label});

  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? scheme.primary : scheme.surfaceContainerHighest,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
