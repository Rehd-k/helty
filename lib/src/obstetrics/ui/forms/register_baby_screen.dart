import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/providers/service_providers.dart';

@RoutePage()
class ObstetricsRegisterBabyScreen extends ConsumerStatefulWidget {
  final String babyId;

  const ObstetricsRegisterBabyScreen({
    super.key,
    required this.babyId,
  });

  @override
  ConsumerState<ObstetricsRegisterBabyScreen> createState() =>
      _ObstetricsRegisterBabyScreenState();
}

class _ObstetricsRegisterBabyScreenState
    extends ConsumerState<ObstetricsRegisterBabyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _otherNameCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();

  bool _saving = false;
  String? _error;

  ObstetricsService get _obstetrics => ref.read(obstetricsServiceProvider);

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _surnameCtrl.dispose();
    _otherNameCtrl.dispose();
    _genderCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _error = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final firstName = _firstNameCtrl.text.trim();
    final surname = _surnameCtrl.text.trim();
    if (firstName.isEmpty || surname.isEmpty) {
      setState(() => _error = 'First name and surname are required.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _obstetrics.registerBabyAsPatient(widget.babyId, {
        'firstName': firstName,
        'surname': surname,
        if (_otherNameCtrl.text.trim().isNotEmpty)
          'otherName': _otherNameCtrl.text.trim(),
        if (_genderCtrl.text.trim().isNotEmpty)
          'gender': _genderCtrl.text.trim(),
      });
      if (!mounted) return;
      context.router.maybePop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Baby registered as patient.')),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register baby as patient'),
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
              controller: _firstNameCtrl,
              decoration: const InputDecoration(
                labelText: 'First name *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _surnameCtrl,
              decoration: const InputDecoration(
                labelText: 'Surname *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _otherNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Other name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _genderCtrl,
              decoration: const InputDecoration(
                labelText: 'Gender (optional)',
                hintText: 'Derived from baby sex if omitted',
                border: OutlineInputBorder(),
              ),
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
                  : const Text('Register patient'),
            ),
          ],
        ),
      ),
    );
  }
}
