import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_form_scaffold.dart';

@RoutePage()
class ObstetricsAddBabyScreen extends ConsumerStatefulWidget {
  final String labourDeliveryId;
  final String pregnancyId;

  const ObstetricsAddBabyScreen({
    super.key,
    required this.labourDeliveryId,
    required this.pregnancyId,
  });

  @override
  ConsumerState<ObstetricsAddBabyScreen> createState() =>
      _ObstetricsAddBabyScreenState();
}

class _ObstetricsAddBabyScreenState
    extends ConsumerState<ObstetricsAddBabyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _birthWeightCtrl = TextEditingController();
  final _birthLengthCtrl = TextEditingController();
  final _apgar1Ctrl = TextEditingController();
  final _apgar5Ctrl = TextEditingController();
  final _resuscitationCtrl = TextEditingController();
  final _birthOrderCtrl = TextEditingController(text: '1');

  BabySex? _sex = BabySex.U;
  String? _motherId;
  bool _loadingPregnancy = true;
  bool _saving = false;
  String? _error;

  ObstetricsService get _obstetrics => ref.read(obstetricsServiceProvider);

  @override
  void initState() {
    super.initState();
    _loadPregnancy();
  }

  Future<void> _loadPregnancy() async {
    try {
      final p = await _obstetrics.getPregnancy(widget.pregnancyId);
      if (!mounted) return;
      setState(() {
        _motherId = p.patientId;
        _loadingPregnancy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingPregnancy = false;
        _error = 'Could not load pregnancy (mother id).';
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
    _birthOrderCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _error = null;
    if (_motherId == null || _motherId!.isEmpty) {
      setState(() => _error = 'Mother ID not available.');
      return;
    }
    if (_sex == null) {
      setState(() => _error = 'Sex is required.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await _obstetrics.createBaby(widget.labourDeliveryId, {
        'motherId': _motherId!,
        'sex': _sex!.apiValue,
        if (_birthWeightCtrl.text.trim().isNotEmpty)
          'birthWeightG': int.tryParse(_birthWeightCtrl.text.trim()),
        if (_birthLengthCtrl.text.trim().isNotEmpty)
          'birthLengthCm': double.tryParse(_birthLengthCtrl.text.trim()),
        if (_apgar1Ctrl.text.trim().isNotEmpty)
          'apgar1': int.tryParse(_apgar1Ctrl.text.trim()),
        if (_apgar5Ctrl.text.trim().isNotEmpty)
          'apgar5': int.tryParse(_apgar5Ctrl.text.trim()),
        if (_resuscitationCtrl.text.trim().isNotEmpty)
          'resuscitation': _resuscitationCtrl.text.trim(),
        'birthOrder': int.tryParse(_birthOrderCtrl.text.trim()) ?? 1,
      });
      if (!mounted) return;
      context.router.maybePop(true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Baby added.')));
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
    if (_loadingPregnancy && _motherId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add baby')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && _motherId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Add baby'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.router.maybePop(),
          ),
        ),
        body: Center(child: Text(_error!)),
      );
    }

    return ObstetricsFormScaffold(
      title: 'Add baby',
      subtitle: 'Record baby sex and birth metrics.',
      formKey: _formKey,
      contextBanner: ObFormContextBanner(
        title: 'Baby record',
        lines: ['Delivery: ${widget.labourDeliveryId}'],
        icon: Icons.child_care_rounded,
      ),
      error: _error,
      saving: _saving,
      saveLabel: 'Save baby',
      onSave: () {
        _submit();
      },
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => context.router.maybePop(),
      ),
      children: [
        ObFormSectionCard(
          title: 'Baby details',
          icon: Icons.child_care_rounded,
          children: [
            DropdownButtonFormField<BabySex>(
              initialValue: _sex,
              decoration: const InputDecoration(
                labelText: 'Sex *',
                border: OutlineInputBorder(),
              ),
              items: BabySex.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: (v) => setState(() => _sex = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _birthOrderCtrl,
              decoration: const InputDecoration(
                labelText: 'Birth order',
                hintText: '1',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
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
          ],
        ),
      ],
    );
  }
}
