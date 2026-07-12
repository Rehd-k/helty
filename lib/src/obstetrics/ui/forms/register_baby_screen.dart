import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_form_scaffold.dart';

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
    return ObstetricsFormScaffold(
      title: 'Register baby as patient',
      subtitle: 'Create a patient profile for this baby.',
      formKey: _formKey,
      error: _error,
      saving: _saving,
      saveLabel: 'Register patient',
      onSave: () {
        _submit();
      },
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => context.router.maybePop(),
      ),
      contextBanner: ObFormContextBanner(
        title: 'Patient registration',
        lines: ['Baby ID: ${widget.babyId}'],
        icon: Icons.person_add_rounded,
      ),
      children: [
        ResponsiveBody(
          center: false,
          bottomPadding: 0,
          builder: (context, bp) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ObFormSectionCard(
          title: 'Patient details',
          icon: Icons.person_add_rounded,
          children: [
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
          ],
        ),
            ],
          ),
        ),
      ],
    );
  }
}
