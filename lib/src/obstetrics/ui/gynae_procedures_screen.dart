import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_cards.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_list_scaffold.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_theme.dart';
import 'package:helty/src/paitients/patient_providers.dart';
import 'package:helty/src/providers/service_providers.dart';

const _commonProcedureTypes = [
  'D&C',
  'Hysterectomy',
  'Laparoscopy',
  'Colposcopy',
  'Other',
];

@RoutePage()
class ObstetricsGynaeProceduresScreen extends ConsumerStatefulWidget {
  final String? patientId;

  const ObstetricsGynaeProceduresScreen({
    super.key,
    this.patientId,
  });

  @override
  ConsumerState<ObstetricsGynaeProceduresScreen> createState() =>
      _ObstetricsGynaeProceduresScreenState();
}

class _ObstetricsGynaeProceduresScreenState
    extends ConsumerState<ObstetricsGynaeProceduresScreen> {
  List<GynaeProcedure> _procedures = [];
  int _total = 0;
  int _skip = 0;
  static const int _take = 20;
  bool _loading = true;
  String? _error;
  int _typeFilterIndex = 0;

  ObstetricsService get _service => ref.read(obstetricsServiceProvider);

  String? get _effectivePatientId {
    final fromWidget = widget.patientId?.trim();
    if (fromWidget != null && fromWidget.isNotEmpty) return fromWidget;
    return ref.watch(patientProvider).selectedPatient?.id;
  }

  String? get _procedureTypeFilter {
    if (_typeFilterIndex == 0) return null;
    return _commonProcedureTypes[_typeFilterIndex - 1];
  }

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) _skip = 0;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _service.listGynaeProcedures(
        patientId: _effectivePatientId,
        procedureType: _procedureTypeFilter,
        skip: _skip,
        take: _take,
      );
      if (!mounted) return;
      setState(() {
        if (reset || _skip == 0) {
          _procedures = res.procedures;
        } else {
          _procedures = [..._procedures, ...res.procedures];
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

  void _onTypeFilter(int index) {
    if (_typeFilterIndex == index) return;
    setState(() => _typeFilterIndex = index);
    _load(reset: true);
  }

  void _addProcedure() {
    context.router
        .push(ObstetricsAddGynaeProcedureRoute(patientId: _effectivePatientId))
        .then((_) => _load(reset: true));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedPatient = ref.watch(patientProvider).selectedPatient;
    final typeLabels = ['All types', ..._commonProcedureTypes];

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

    final listBody = _loading && _procedures.isEmpty
        ? const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          )
        : _procedures.isEmpty
            ? _EmptyGynae(onAdd: _addProcedure)
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ObstetricsTheme.listHorizontalPadding,
                    ),
                    child: Text(
                      '$_total procedure${_total == 1 ? '' : 's'}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ..._procedures.map(
                    (p) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ObstetricsTheme.listHorizontalPadding,
                      ),
                      child: GynaeProcedureCard(
                        procedure: p,
                        onTap: () => context.router
                            .push(
                              ObstetricsEditGynaeProcedureRoute(
                                procedureId: p.id,
                              ),
                            )
                            .then((_) => _load(reset: true)),
                      ),
                    ),
                  ),
                  if (_skip + _procedures.length < _total)
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
              );

    return ObListScaffold(
      title: 'Gynaecology',
      subtitle: _effectivePatientId != null
          ? 'Procedures for selected patient'
          : 'All procedures (select patient to filter)',
      isLoading: false,
      onRefresh: () => _load(reset: true),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loading ? null : () => _load(reset: true),
        ),
      ],
      errorBanner: errorBanner,
      header: _effectivePatientId != null
          ? ObPatientBanner(patient: selectedPatient)
          : null,
      filterBar: ObFilterChipRow(
        labels: typeLabels,
        selectedIndex: _typeFilterIndex,
        onSelected: _onTypeFilter,
      ),
      body: listBody,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProcedure,
        icon: const Icon(Icons.add),
        label: const Text('Add procedure'),
      ),
    );
  }
}

class _EmptyGynae extends StatelessWidget {
  const _EmptyGynae({required this.onAdd});

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
            backgroundColor: scheme.tertiaryContainer,
            child: Icon(
              Icons.medical_services_rounded,
              size: 48,
              color: scheme.tertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No gynaecology procedures',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add procedure'),
          ),
        ],
      ),
    );
  }
}
