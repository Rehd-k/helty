import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/providers/service_providers.dart';

@RoutePage()
class ObstetricsEditBabyScreen extends ConsumerStatefulWidget {
  final String babyId;

  const ObstetricsEditBabyScreen({
    super.key,
    required this.babyId,
  });

  @override
  ConsumerState<ObstetricsEditBabyScreen> createState() =>
      _ObstetricsEditBabyScreenState();
}

class _ObstetricsEditBabyScreenState
    extends ConsumerState<ObstetricsEditBabyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _birthWeightCtrl = TextEditingController();
  final _birthLengthCtrl = TextEditingController();
  final _apgar1Ctrl = TextEditingController();
  final _apgar5Ctrl = TextEditingController();
  final _resuscitationCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  ObstetricsService get _obstetrics => ref.read(obstetricsServiceProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final b = await _obstetrics.getBaby(widget.babyId);
      if (!mounted) return;
      _birthWeightCtrl.text = b.birthWeightG?.toString() ?? '';
      _birthLengthCtrl.text = b.birthLengthCm?.toString() ?? '';
      _apgar1Ctrl.text = b.apgar1?.toString() ?? '';
      _apgar5Ctrl.text = b.apgar5?.toString() ?? '';
      _resuscitationCtrl.text = b.resuscitation ?? '';
      setState(() => _loading = false);
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

  @override
  void dispose() {
    _birthWeightCtrl.dispose();
    _birthLengthCtrl.dispose();
    _apgar1Ctrl.dispose();
    _apgar5Ctrl.dispose();
    _resuscitationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _error = null;
    setState(() => _saving = true);
    try {
      await _obstetrics.updateBaby(widget.babyId, {
        if (_birthWeightCtrl.text.trim().isNotEmpty)
          'birthWeightG': int.tryParse(_birthWeightCtrl.text.trim()),
        if (_birthLengthCtrl.text.trim().isNotEmpty)
          'birthLengthCm': double.tryParse(_birthLengthCtrl.text.trim()),
        if (_apgar1Ctrl.text.trim().isNotEmpty)
          'apgar1': int.tryParse(_apgar1Ctrl.text.trim()),
        if (_apgar5Ctrl.text.trim().isNotEmpty)
          'apgar5': int.tryParse(_apgar5Ctrl.text.trim()),
        'resuscitation': _resuscitationCtrl.text.trim(),
      });
      if (!mounted) return;
      context.router.maybePop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Baby updated.')),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading && _birthWeightCtrl.text.isEmpty && _error == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit baby')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit baby'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.router.maybePop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            TextFormField(
              controller: _birthWeightCtrl,
              decoration: const InputDecoration(
                labelText: 'Birth weight (g)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _birthLengthCtrl,
              decoration: const InputDecoration(
                labelText: 'Birth length (cm)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apgar1Ctrl,
              decoration: const InputDecoration(
                labelText: 'Apgar 1 min',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apgar5Ctrl,
              decoration: const InputDecoration(
                labelText: 'Apgar 5 min',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _resuscitationCtrl,
              decoration: const InputDecoration(
                labelText: 'Resuscitation',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update baby'),
            ),
          ],
        ),
      ),
    );
  }
}
