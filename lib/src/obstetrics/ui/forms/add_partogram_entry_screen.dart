import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/providers/service_providers.dart';

@RoutePage()
class ObstetricsAddPartogramEntryScreen extends ConsumerStatefulWidget {
  final String labourDeliveryId;

  const ObstetricsAddPartogramEntryScreen({
    super.key,
    required this.labourDeliveryId,
  });

  @override
  ConsumerState<ObstetricsAddPartogramEntryScreen> createState() =>
      _ObstetricsAddPartogramEntryScreenState();
}

class _ObstetricsAddPartogramEntryScreenState
    extends ConsumerState<ObstetricsAddPartogramEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recordedAtCtrl = TextEditingController();
  final _cervicalDilationCtrl = TextEditingController();
  final _stationCtrl = TextEditingController();
  final _contractionsCtrl = TextEditingController();
  final _fetalHeartRateCtrl = TextEditingController();
  final _mouldingCtrl = TextEditingController();
  final _descentCtrl = TextEditingController();
  final _oxytocinCtrl = TextEditingController();
  final _commentsCtrl = TextEditingController();

  bool _saving = false;
  String? _error;

  ObstetricsService get _obstetrics => ref.read(obstetricsServiceProvider);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _recordedAtCtrl.text = now.toIso8601String();
  }

  @override
  void dispose() {
    _recordedAtCtrl.dispose();
    _cervicalDilationCtrl.dispose();
    _stationCtrl.dispose();
    _contractionsCtrl.dispose();
    _fetalHeartRateCtrl.dispose();
    _mouldingCtrl.dispose();
    _descentCtrl.dispose();
    _oxytocinCtrl.dispose();
    _commentsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    _recordedAtCtrl.text = dt.toIso8601String();
  }

  Future<void> _submit() async {
    _error = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final recordedById = ref.read(authProvider).staff?.id;
    if (recordedById == null || recordedById.isEmpty) {
      setState(() => _error = 'You must be logged in.');
      return;
    }
    final recordedAt = _recordedAtCtrl.text.trim();
    if (recordedAt.isEmpty) {
      setState(() => _error = 'Recorded at is required.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _obstetrics.addPartogramEntry(widget.labourDeliveryId, {
        'recordedAt': recordedAt,
        'recordedById': recordedById,
        if (_cervicalDilationCtrl.text.trim().isNotEmpty)
          'cervicalDilationCm':
              double.tryParse(_cervicalDilationCtrl.text.trim()),
        if (_stationCtrl.text.trim().isNotEmpty)
          'station': double.tryParse(_stationCtrl.text.trim()),
        if (_contractionsCtrl.text.trim().isNotEmpty)
          'contractionsPer10Min':
              int.tryParse(_contractionsCtrl.text.trim()),
        if (_fetalHeartRateCtrl.text.trim().isNotEmpty)
          'fetalHeartRate': int.tryParse(_fetalHeartRateCtrl.text.trim()),
        if (_mouldingCtrl.text.trim().isNotEmpty)
          'moulding': _mouldingCtrl.text.trim(),
        if (_descentCtrl.text.trim().isNotEmpty)
          'descent': _descentCtrl.text.trim(),
        if (_oxytocinCtrl.text.trim().isNotEmpty)
          'oxytocin': _oxytocinCtrl.text.trim(),
        if (_commentsCtrl.text.trim().isNotEmpty)
          'comments': _commentsCtrl.text.trim(),
      });
      if (!mounted) return;
      context.router.maybePop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partogram entry added.')),
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
        title: const Text('Add partogram entry'),
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
              controller: _recordedAtCtrl,
              decoration: InputDecoration(
                labelText: 'Recorded at *',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDateTime,
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cervicalDilationCtrl,
              decoration: const InputDecoration(
                labelText: 'Cervical dilation (cm)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stationCtrl,
              decoration: const InputDecoration(
                labelText: 'Station',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contractionsCtrl,
              decoration: const InputDecoration(
                labelText: 'Contractions per 10 min',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fetalHeartRateCtrl,
              decoration: const InputDecoration(
                labelText: 'Fetal heart rate',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mouldingCtrl,
              decoration: const InputDecoration(
                labelText: 'Moulding',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descentCtrl,
              decoration: const InputDecoration(
                labelText: 'Descent',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _oxytocinCtrl,
              decoration: const InputDecoration(
                labelText: 'Oxytocin',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commentsCtrl,
              decoration: const InputDecoration(
                labelText: 'Comments',
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
                  : const Text('Save entry'),
            ),
          ],
        ),
      ),
    );
  }
}
