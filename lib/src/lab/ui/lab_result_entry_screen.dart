import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/providers/lab_providers.dart';
import 'package:helty/src/lab/widgets/lab_dynamic_result_form.dart';
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

class _LabResultEntryScreenState extends ConsumerState<LabResultEntryScreen> {
  final GlobalKey<LabDynamicResultFormState> _formKey =
      GlobalKey<LabDynamicResultFormState>();
  List<LabTestField>? _fields;
  Map<String, String> _initialValues = {};
  bool _loading = true;
  String? _error;
  bool _saving = false;
  String? _testName;
  String? _testVersionId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = ref.read(labApiServiceProvider);
    try {
      final order = await api.getOrderById(widget.orderId);
      final matching =
          order.items.where((e) => e.id == widget.orderItemId).toList();
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
      final fields = await api.getTestFields(_testVersionId!);
      final results = await api.getResults(item.id);
      final initialValues = <String, String>{};
      for (final r in results) {
        if (r.fieldId.isNotEmpty) {
          initialValues[r.fieldId] = r.value;
        }
      }
      if (mounted) {
        setState(() {
          _fields = fields;
          _initialValues = initialValues;
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
                Icon(Icons.error_outline_rounded,
                    size: 48, color: theme.colorScheme.error),
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

    if (_fields!.isEmpty) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: LabDynamicResultForm(
                  key: _formKey,
                  fields: _fields!,
                  initialValues: _initialValues,
                  onChanged: (_) {},
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
              onPressed: _saving || staff == null
                  ? null
                  : () => _submit(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save results'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final staff = ref.read(currentStaffProvider);
    if (staff == null) return;

    final formState = _formKey.currentState;
    if (formState == null) return;
    if (!formState.validate()) return;

    final values = formState.values;
    if (values.isEmpty) return;

    setState(() {
      _error = null;
      _saving = true;
    });

    final results = values.entries
        .map((e) => {'fieldId': e.key, 'value': e.value})
        .toList();

    final router = context.router;
    try {
      await ref.read(labApiServiceProvider).createResultsBatch(
            orderItemId: widget.orderItemId,
            enteredBy: staff.id,
            results: results,
          );
      if (!mounted) return;
      router.maybePop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }
}
