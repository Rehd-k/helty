import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_form_scaffold.dart';

@RoutePage()
class ObstetricsEditGynaeProcedureScreen extends ConsumerStatefulWidget {
  final String procedureId;

  const ObstetricsEditGynaeProcedureScreen({
    super.key,
    required this.procedureId,
  });

  @override
  ConsumerState<ObstetricsEditGynaeProcedureScreen> createState() =>
      _ObstetricsEditGynaeProcedureScreenState();
}

class _ObstetricsEditGynaeProcedureScreenState
    extends ConsumerState<ObstetricsEditGynaeProcedureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _findingsCtrl = TextEditingController();
  final _complicationsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

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
      final p = await _obstetrics.getGynaeProcedure(widget.procedureId);
      if (!mounted) return;
      _findingsCtrl.text = p.findings ?? '';
      _complicationsCtrl.text = p.complications ?? '';
      _notesCtrl.text = p.notes ?? '';
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
    _findingsCtrl.dispose();
    _complicationsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _error = null;
    setState(() => _saving = true);
    try {
      await _obstetrics.updateGynaeProcedure(widget.procedureId, {
        'findings': _findingsCtrl.text.trim(),
        'complications': _complicationsCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
      });
      if (!mounted) return;
      context.router.maybePop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Procedure updated.')),
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
    if (_loading && _findingsCtrl.text.isEmpty && _error == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit procedure')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return ObstetricsFormScaffold(
      title: 'Edit procedure',
      subtitle: 'Update findings, complications, and notes.',
      formKey: _formKey,
      error: _error,
      saving: _saving,
      saveLabel: 'Update procedure',
      onSave: () {
        _submit();
      },
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => context.router.maybePop(),
      ),
      contextBanner: ObFormContextBanner(
        title: 'Gynaecology',
        lines: ['Procedure ID: ${widget.procedureId}'],
        icon: Icons.medical_services_rounded,
      ),
      children: [
        ObFormSectionCard(
          title: 'Procedure notes',
          icon: Icons.medical_services_rounded,
          children: [
            TextFormField(
              controller: _findingsCtrl,
              decoration: const InputDecoration(
                labelText: 'Findings',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _complicationsCtrl,
              decoration: const InputDecoration(
                labelText: 'Complications',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes',
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
