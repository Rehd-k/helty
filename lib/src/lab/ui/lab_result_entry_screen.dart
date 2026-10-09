import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/providers/lab_providers.dart';
import 'package:helty/src/lab/widgets/lab_ast_result_grid.dart';
import 'package:helty/src/lab/widgets/lab_dynamic_result_form.dart';
import 'package:helty/src/lab/widgets/send_lab_results_dialog.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class LabResultEntryScreen extends ConsumerStatefulWidget {
  const LabResultEntryScreen({
    super.key,
    required this.orderId,
    required this.orderItemId,
  });

  final String orderId;
  final String orderItemId;

  @override
  ConsumerState<LabResultEntryScreen> createState() =>
      _LabResultEntryScreenState();
}

class _LabResultEntryScreenState extends ConsumerState<LabResultEntryScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<LabDynamicResultFormState> _formKey =
      GlobalKey<LabDynamicResultFormState>();
  List<LabTestField>? _fields;
  Map<String, String> _initialValues = {};
  Map<String, ReferenceEvaluation?> _fieldEvaluations = {};
  final Set<String> _hiddenFieldIds = {};
  bool _loading = true;
  String? _error;
  bool _saving = false;
  bool _sending = false;
  bool _offerSendToPatient = false;
  LabOrder? _order;
  String? _testName;
  String? _testVersionId;
  bool _hasExistingResults = false;
  bool _astRequested = false;
  List<LabAntibiotic> _antibiotics = [];
  List<LabAstResultOption> _astResultOptions = [];
  Map<String, String> _astSelections = {};
  final TextEditingController _notesController = TextEditingController();
  late final AnimationController _aiPulse;

  @override
  void initState() {
    super.initState();
    _aiPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _aiPulse.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showAiPlanLock() {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
              ),
            ),
            child: const Icon(Icons.lock_rounded, color: Colors.white),
          ),
          title: const Text('Create with AI'),
          content: Text(
            'This feature is not available on your payment plan.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _load() async {
    final api = ref.read(labApiServiceProvider);
    try {
      final order = await ref.read(labOrderByIdProvider(widget.orderId).future);
      _order = order;
      final matching = order.items
          .where((e) => e.id == widget.orderItemId)
          .toList();
      final item = matching.isEmpty ? null : matching.first;
      if (item == null) {
        setState(() {
          _error = 'Order item not found';
          _loading = false;
        });
        return;
      }
      _testVersionId = item.testVersion?.id;
      _testName = item.testVersion?.test?.name;
      _astRequested = item.astRequested;
      _notesController.text = item.scientistNotes?.trim() ?? '';
      if (_testVersionId == null ||
          _testVersionId!.isEmpty ||
          item.id.isEmpty) {
        setState(() {
          _error = _testVersionId == null || _testVersionId!.isEmpty
              ? 'Test version not found'
              : 'Order item has no id';
          _loading = false;
        });
        return;
      }

      final fieldsFuture = api.getTestFields(_testVersionId!);
      final resultsFuture = api.getResults(item.id);
      final antibioticsFuture = _astRequested
          ? ref.read(labAntibioticsFutureProvider.future)
          : null;
      final optionsFuture = _astRequested
          ? ref.read(labAstResultOptionsFutureProvider.future)
          : null;
      final astResultsFuture = _astRequested
          ? api.getAstResults(item.id)
          : null;

      final fields = await fieldsFuture;
      final results = await resultsFuture;

      List<LabAntibiotic> antibiotics = [];
      List<LabAstResultOption> astOptions = [];
      Map<String, String> astSelections = {};

      if (_astRequested) {
        final abxResponse = await antibioticsFuture!;
        final optResponse = await optionsFuture!;
        final astResults = await astResultsFuture!;
        antibiotics = abxResponse.data.where((a) => a.isActive).toList();
        astOptions = optResponse.data.where((o) => o.isActive).toList();
        for (final r in astResults) {
          astSelections[r.antibiotic.id] = r.resultOption.id;
        }
      }

      final initialValues = <String, String>{};
      final evaluations = <String, ReferenceEvaluation?>{};
      final hidden = <String>{};
      for (final r in results) {
        if (r.fieldId.isNotEmpty) {
          initialValues[r.fieldId] = r.value;
          evaluations[r.fieldId] = r.referenceEvaluation;
          if (r.hiddenFromReport) hidden.add(r.fieldId);
        }
      }
      if (mounted) {
        setState(() {
          _fields = fields;
          _initialValues = initialValues;
          _fieldEvaluations = evaluations;
          _hiddenFieldIds
            ..clear()
            ..addAll(hidden);
          _hasExistingResults = results.isNotEmpty;
          _antibiotics = antibiotics;
          _astResultOptions = astOptions;
          _astSelections = astSelections;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final staff = ref.watch(currentStaffProvider);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Enter results')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _fields == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Enter results'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.router.maybePop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _load();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hasFields = _fields!.isNotEmpty;
    if (!hasFields && !_astRequested) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_testName ?? 'Enter results'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.router.maybePop(),
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No result fields defined for this test. Add fields in Lab config.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_testName ?? 'Enter results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.router.maybePop(),
        ),
      ),
      body: ResponsiveBody(
        expand: false,
        builder: (context, bp) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasExistingResults && hasFields) ...[
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Existing results were loaded for this test. '
                            'Updating and saving will overwrite the stored values.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (hasFields)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: LabDynamicResultForm(
                      key: _formKey,
                      fields: _fields!,
                      initialValues: _initialValues,
                      fieldEvaluations: _fieldEvaluations,
                      hiddenFieldIds: _hiddenFieldIds,
                      onFieldHidden: (fieldId) {
                        setState(() => _hiddenFieldIds.add(fieldId));
                      },
                      onChanged: (_) {},
                    ),
                  ),
                ),
              if (hasFields && _hiddenFieldIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Hidden for this result (not printed)',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _hiddenFieldIds.map((id) {
                    String label = id;
                    for (final e in _fields!) {
                      if (e.id == id) {
                        label = e.label;
                        break;
                      }
                    }
                    return ActionChip(
                      avatar: Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text('Show $label'),
                      onPressed: () {
                        setState(() => _hiddenFieldIds.remove(id));
                      },
                    );
                  }).toList(),
                ),
              ],
              if (_astRequested) ...[
                if (hasFields) const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Antibiotic Susceptibility',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select susceptibility only for antibiotics that were tested.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LabAstResultGrid(
                          antibiotics: _antibiotics,
                          resultOptions: _astResultOptions,
                          selections: _astSelections,
                          onChanged: (antibioticId, resultOptionId) {
                            setState(() {
                              if (resultOptionId == null) {
                                _astSelections.remove(antibioticId);
                              } else {
                                _astSelections[antibioticId] = resultOptionId;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Text(
                            'Scientist notes',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          _CreateWithAiButton(
                            pulse: _aiPulse,
                            onPressed: _showAiPlanLock,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Printed at the bottom of this test. Leave blank to omit it from the report.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        minLines: 3,
                        maxLines: 6,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment for this test',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving || _sending
                    ? null
                    : _offerSendToPatient
                    ? () => _sendSavedResults(context)
                    : staff == null
                    ? null
                    : () => _submit(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving || _sending
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _offerSendToPatient
                            ? 'Send to patient'
                            : 'Save results',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _persistNotes() {
    return ref
        .read(labApiServiceProvider)
        .updateOrderItemNotes(
          orderItemId: widget.orderItemId,
          scientistNotes: _notesController.text,
        );
  }

  Future<void> _submit(BuildContext context) async {
    final staff = ref.read(currentStaffProvider);
    if (staff == null) return;

    if (_fields != null && _fields!.isNotEmpty) {
      final formState = _formKey.currentState;
      if (formState == null) return;
      if (!formState.validate()) return;
    }

    setState(() {
      _error = null;
      _saving = true;
    });

    final api = ref.read(labApiServiceProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      if (_fields != null && _fields!.isNotEmpty) {
        final formState = _formKey.currentState!;
        final values = formState.values;
        final results = <Map<String, dynamic>>[];
        for (final f in _fields!) {
          final hidden = _hiddenFieldIds.contains(f.id);
          results.add({
            'fieldId': f.id,
            'value': values[f.id] ?? '',
            'hiddenFromReport': hidden,
          });
        }
        await api.createResultsBatch(
          orderItemId: widget.orderItemId,
          enteredBy: staff.id,
          results: results,
        );
      }

      if (_astRequested) {
        final astRows = _astSelections.entries
            .where((e) => e.value.isNotEmpty)
            .map((e) => {'antibioticId': e.key, 'resultOptionId': e.value})
            .toList();
        if (astRows.isNotEmpty) {
          await api.createAstResultsBatch(
            orderItemId: widget.orderItemId,
            enteredBy: staff.id,
            results: astRows,
          );
        }
      }

      await _persistNotes();

      if (!mounted) return;
      invalidateLabOrderCaches(ref, orderId: widget.orderId);
      ref.invalidate(labOrdersFutureProvider);
      LabOrder? refreshed;
      try {
        refreshed = await ref.read(labOrderByIdProvider(widget.orderId).future);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        if (refreshed != null) _order = refreshed;
        _offerSendToPatient = true;
        _saving = false;
      });
      messenger?.showSnackBar(
        const SnackBar(content: Text('Results saved. Order marked completed.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  Future<void> _sendSavedResults(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final order = _order;
    final patient = order?.patient;
    if (order == null || patient == null || patient.id.isEmpty) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Patient information is missing.')),
      );
      return;
    }
    final matches = order.items
        .where((item) => item.id == widget.orderItemId)
        .toList();
    if (matches.isEmpty) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Order item not found.')),
      );
      return;
    }

    final choice = await showSendLabResultsToPatientDialog(
      context,
      patient: patient,
    );
    if (choice == null || !mounted) return;

    setState(() {
      _error = null;
      _sending = true;
    });
    try {
      await _persistNotes();
      LabOrder orderForSend = order;
      try {
        final refreshed = await ref.read(
          labOrderByIdProvider(widget.orderId).future,
        );
        orderForSend = refreshed;
        if (mounted) setState(() => _order = refreshed);
      } catch (_) {}
      final sendMatches = orderForSend.items
          .where((item) => item.id == widget.orderItemId)
          .toList();
      await sendLabResultsToPatient(
        api: ref.read(labApiServiceProvider),
        patient: patient,
        entries: [
          (
            order: orderForSend,
            item: sendMatches.isEmpty ? matches.first : sendMatches.first,
          ),
        ],
        sendEmail: choice.sendEmail,
        sendSms: choice.sendSms,
      );
      if (!mounted) return;
      final channels = [
        if (choice.sendEmail) 'email',
        if (choice.sendSms) 'phone',
      ].join(' and ');
      messenger?.showSnackBar(
        SnackBar(content: Text('Results sent by $channels.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = labSendErrorText(e));
      messenger?.showSnackBar(SnackBar(content: Text(labSendErrorText(e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _CreateWithAiButton extends StatelessWidget {
  const _CreateWithAiButton({required this.pulse, required this.onPressed});

  final Animation<double> pulse;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(pulse.value);
        return Transform.scale(
          scale: 1 + (0.045 * t),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                colors: [
                  Color.lerp(
                    const Color(0xFF4F46E5),
                    const Color(0xFF7C3AED),
                    t,
                  )!,
                  Color.lerp(
                    const Color(0xFF6366F1),
                    const Color(0xFF2563EB),
                    t,
                  )!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF7C3AED,
                  ).withValues(alpha: 0.28 + (0.38 * t)),
                  blurRadius: 10 + (14 * t),
                  spreadRadius: 0.4 * t,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'Create with AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.lock_rounded, color: Colors.white, size: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
