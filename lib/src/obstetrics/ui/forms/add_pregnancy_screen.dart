import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/providers/service_providers.dart';

@RoutePage()
class ObstetricsAddPregnancyScreen extends ConsumerStatefulWidget {
  final String patientId;

  const ObstetricsAddPregnancyScreen({
    super.key,
    required this.patientId,
  });

  @override
  ConsumerState<ObstetricsAddPregnancyScreen> createState() =>
      _ObstetricsAddPregnancyScreenState();
}

class _ObstetricsAddPregnancyScreenState
    extends ConsumerState<ObstetricsAddPregnancyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gravidaCtrl = TextEditingController(text: '1');
  final _paraCtrl = TextEditingController(text: '0');
  final _lmpCtrl = TextEditingController();
  final _eddCtrl = TextEditingController();
  final _bookingDateCtrl = TextEditingController();
  final _outcomeCtrl = TextEditingController();

  PregnancyStatus? _status = PregnancyStatus.ONGOING;
  bool _saving = false;
  String? _error;

  ObstetricsService get _service => ref.read(obstetricsServiceProvider);

  @override
  void dispose() {
    _gravidaCtrl.dispose();
    _paraCtrl.dispose();
    _lmpCtrl.dispose();
    _eddCtrl.dispose();
    _bookingDateCtrl.dispose();
    _outcomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
    TextEditingController ctrl, {
    DateTime? initial,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      ctrl.text = date.toIso8601String().split('T').first;
    }
  }

  Future<void> _submit() async {
    _error = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final gravida = int.tryParse(_gravidaCtrl.text.trim());
    final para = int.tryParse(_paraCtrl.text.trim());
    if (gravida == null || gravida < 0) {
      setState(() => _error = 'Gravida must be a number ≥ 0.');
      return;
    }
    if (para == null || para < 0) {
      setState(() => _error = 'Para must be a number ≥ 0.');
      return;
    }
    final lmp = _lmpCtrl.text.trim();
    final edd = _eddCtrl.text.trim();
    if (lmp.isEmpty || edd.isEmpty) {
      setState(() => _error = 'LMP and EDD are required.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.createPregnancy({
        'patientId': widget.patientId,
        'gravida': gravida,
        'para': para,
        'lmp': lmp,
        'edd': edd,
        if (_bookingDateCtrl.text.trim().isNotEmpty)
          'bookingDate': _bookingDateCtrl.text.trim(),
        if (_status != null) 'status': _status!.apiValue,
        if (_outcomeCtrl.text.trim().isNotEmpty)
          'outcome': _outcomeCtrl.text.trim(),
      });
      if (!mounted) return;
      context.router.maybePop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pregnancy added.')),
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
        title: const Text('Add pregnancy'),
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
              controller: _gravidaCtrl,
              decoration: const InputDecoration(
                labelText: 'Gravida *',
                hintText: '0',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0) return 'Enter a number ≥ 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _paraCtrl,
              decoration: const InputDecoration(
                labelText: 'Para *',
                hintText: '0',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0) return 'Enter a number ≥ 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lmpCtrl,
              decoration: InputDecoration(
                labelText: 'LMP (date) *',
                hintText: 'YYYY-MM-DD',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(_lmpCtrl),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _eddCtrl,
              decoration: InputDecoration(
                labelText: 'EDD (date) *',
                hintText: 'YYYY-MM-DD',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(_eddCtrl),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bookingDateCtrl,
              decoration: InputDecoration(
                labelText: 'Booking date (optional)',
                hintText: 'YYYY-MM-DD',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(_bookingDateCtrl),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PregnancyStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: PregnancyStatus.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _outcomeCtrl,
              decoration: const InputDecoration(
                labelText: 'Outcome (optional)',
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
                  : const Text('Save pregnancy'),
            ),
          ],
        ),
      ),
    );
  }
}
