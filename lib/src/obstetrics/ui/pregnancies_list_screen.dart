import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_cards.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_list_scaffold.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_theme.dart';
import 'package:helty/src/paitients/patient_providers.dart';
import 'package:helty/src/providers/service_providers.dart';

@RoutePage()
class ObstetricsPregnanciesListScreen extends ConsumerStatefulWidget {
  /// When null, patient comes from [patientProvider].selectedPatient.
  final String? patientId;

  /// Optional OPD encounter to link antenatal visits created from this flow.
  final String? encounterId;

  const ObstetricsPregnanciesListScreen({
    super.key,
    this.patientId,
    this.encounterId,
  });

  @override
  ConsumerState<ObstetricsPregnanciesListScreen> createState() =>
      _ObstetricsPregnanciesListScreenState();
}

class _ObstetricsPregnanciesListScreenState
    extends ConsumerState<ObstetricsPregnanciesListScreen> {
  List<Pregnancy> _pregnancies = [];
  int _total = 0;
  int _skip = 0;
  static const int _take = 20;
  bool _loading = false;
  String? _error;
  int _filterIndex = 0;

  static const _filterLabels = [
    'All',
    'Ongoing',
    'Delivered',
    'Lost',
    'Terminated',
  ];

  ObstetricsService get _service => ref.read(obstetricsServiceProvider);

  String? get _effectivePatientId {
    final selected = ref.watch(patientProvider).selectedPatient;
    return selected?.id ??
        (widget.patientId?.trim().isEmpty == false ? widget.patientId : null);
  }

  PregnancyStatus? get _statusFilter {
    switch (_filterIndex) {
      case 1:
        return PregnancyStatus.ONGOING;
      case 2:
        return PregnancyStatus.DELIVERED;
      case 3:
        return PregnancyStatus.LOST;
      case 4:
        return PregnancyStatus.TERMINATED;
      default:
        return null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final patientId = _effectivePatientId;
    if (patientId != null &&
        patientId.isNotEmpty &&
        _pregnancies.isEmpty &&
        _skip == 0 &&
        !_loading) {
      _load(reset: true);
    }
  }

  Future<void> _load({bool reset = false}) async {
    final patientId = _effectivePatientId;
    if (patientId == null || patientId.isEmpty) {
      if (mounted) {
        setState(() {
          _pregnancies = [];
          _total = 0;
          _loading = false;
        });
      }
      return;
    }
    if (reset) _skip = 0;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _service.listPregnancies(
        patientId: patientId,
        status: _statusFilter,
        skip: _skip,
        take: _take,
      );
      if (!mounted) return;
      setState(() {
        if (reset || _skip == 0) {
          _pregnancies = res.pregnancies;
        } else {
          _pregnancies = [..._pregnancies, ...res.pregnancies];
        }
        _total = res.total;
        _loading = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onFilterSelected(int index) {
    if (_filterIndex == index) return;
    setState(() => _filterIndex = index);
    _load(reset: true);
  }

  void _openPregnancy(Pregnancy p) {
    context.router.push(
      ObstetricsPregnancyViewRoute(
        pregnancyId: p.id,
        encounterId: p.encounterId ?? widget.encounterId,
      ),
    );
  }

  void _addPregnancy() {
    context.router.push(ObstetricsAddPregnancyRoute()).then((_) => _load(reset: true));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final patientId = _effectivePatientId;
    final selectedPatient = ref.watch(patientProvider).selectedPatient;

    if (patientId == null || patientId.isEmpty) {
      return Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: const Text('Pregnancies'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.router.maybePop(),
          ),
        ),
        body: ResponsiveBody(
          builder: (context, bp) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Select a patient to view pregnancies.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    Widget? errorBanner;
    if (_error != null) {
      errorBanner = Material(
        color: colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: Text(_error!)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _error = null),
              ),
            ],
          ),
        ),
      );
    }

    Widget? encounterBanner;
    if (widget.encounterId != null && widget.encounterId!.isNotEmpty) {
      encounterBanner = Material(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.link, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'OPD visit linked — new antenatal visits use encounter ${widget.encounterId}.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final listBody = ResponsiveBody(
      center: false,
      bottomPadding: 0,
      builder: (context, bp) => _loading && _pregnancies.isEmpty
        ? const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          )
        : _pregnancies.isEmpty
            ? _EmptyPregnancies(onAdd: _addPregnancy)
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ObstetricsTheme.listHorizontalPadding,
                    ),
                    child: Text(
                      '$_total record${_total == 1 ? '' : 's'}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ..._pregnancies.map(
                    (p) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ObstetricsTheme.listHorizontalPadding,
                      ),
                      child: PregnancySummaryCard(
                        pregnancy: p,
                        onTap: () => _openPregnancy(p),
                      ),
                    ),
                  ),
                  if (_skip + _pregnancies.length < _total)
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              setState(() => _skip += _take);
                              _load();
                            },
                      child: const Text('Load more'),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
    );

    return ObListScaffold(
      title: 'Pregnancies',
      subtitle: 'Antenatal, labour & postnatal for this patient',
      isLoading: false,
      onRefresh: () => _load(reset: true),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loading ? null : () => _load(reset: true),
        ),
      ],
      errorBanner: errorBanner,
      header: Column(
        children: [
          if (encounterBanner != null) encounterBanner,
          ObPatientBanner(patient: selectedPatient),
        ],
      ),
      filterBar: ObFilterChipRow(
        labels: _filterLabels,
        selectedIndex: _filterIndex,
        onSelected: _onFilterSelected,
      ),
      body: listBody,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPregnancy,
        icon: const Icon(Icons.add),
        label: const Text('Add pregnancy'),
      ),
    );
  }
}

class _EmptyPregnancies extends StatelessWidget {
  const _EmptyPregnancies({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: scheme.primaryContainer,
            child: Icon(
              Icons.pregnant_woman_rounded,
              size: 48,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No pregnancies recorded',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add pregnancy'),
          ),
        ],
      ),
    );
  }
}
