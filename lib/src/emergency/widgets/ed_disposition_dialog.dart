import 'package:flutter/material.dart';

import '../models/ed_enums.dart';
import '../models/emergency_visit_model.dart';
import '../services/emergency_service.dart';

/// Result of disposition dialog.
class EdDispositionResult {
  const EdDispositionResult({
    required this.payload,
    required this.navigateToAdmissionTab,
  });

  final EdDispositionPayload payload;
  final bool navigateToAdmissionTab;
}

/// Disposition modal with Discharge / Transfer / Admit tabs.
Future<EdDispositionResult?> showEdDispositionDialog(
  BuildContext context, {
  required String encounterId,
  required String visitId,
  required bool hasDiagnosis,
}) {
  return showDialog<EdDispositionResult>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => EdDispositionDialog(
      encounterId: encounterId,
      visitId: visitId,
      hasDiagnosis: hasDiagnosis,
    ),
  );
}

class EdDispositionDialog extends StatefulWidget {
  const EdDispositionDialog({
    super.key,
    required this.encounterId,
    required this.visitId,
    required this.hasDiagnosis,
  });

  final String encounterId;
  final String visitId;
  final bool hasDiagnosis;

  @override
  State<EdDispositionDialog> createState() => _EdDispositionDialogState();
}

class _EdDispositionDialogState extends State<EdDispositionDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _emergencyService = EmergencyService();

  final _notesCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _followUpCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();

  EdDisposition _dischargeType = EdDisposition.dischargeHome;
  EdDisposition _admitType = EdDisposition.admitWard;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _notesCtrl.dispose();
    _summaryCtrl.dispose();
    _followUpCtrl.dispose();
    _destinationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(EdDisposition disposition, {bool admit = false}) async {
    if (!widget.hasDiagnosis) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one diagnosis before disposition.'),
        ),
      );
      return;
    }

    if (_notesCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disposition notes are required.')),
      );
      return;
    }

    if (disposition == EdDisposition.transferExternal &&
        _destinationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transfer destination is required.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final payload = EdDispositionPayload(
        disposition: disposition,
        dispositionNotes: _notesCtrl.text.trim(),
        dischargeSummary: _summaryCtrl.text.trim().isEmpty
            ? null
            : _summaryCtrl.text.trim(),
        followUpInstructions: _followUpCtrl.text.trim().isEmpty
            ? null
            : _followUpCtrl.text.trim(),
        transferDestination: _destinationCtrl.text.trim().isEmpty
            ? null
            : _destinationCtrl.text.trim(),
      );

      if (admit) {
        await _emergencyService.submitDisposition(
          visitId: widget.visitId,
          encounterId: widget.encounterId,
          payload: payload,
        );
        if (!mounted) return;
        Navigator.of(context).pop(
          EdDispositionResult(payload: payload, navigateToAdmissionTab: true),
        );
        return;
      }

      await _emergencyService.submitDisposition(
        visitId: widget.visitId,
        encounterId: widget.encounterId,
        payload: payload,
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        EdDispositionResult(payload: payload, navigateToAdmissionTab: false),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Disposition failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ED Disposition'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.hasDiagnosis)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Warning: no diagnosis recorded yet.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            TabBar(
              controller: _tabCtrl,
              tabs: const [
                Tab(text: 'Discharge'),
                Tab(text: 'Transfer'),
                Tab(text: 'Admit'),
                Tab(text: 'Death'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildDischargeTab(),
                  _buildTransferTab(),
                  _buildAdmitTab(),
                  _buildDeathTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildNotesFields() {
    return Column(
      children: [
        TextField(
          controller: _notesCtrl,
          decoration: const InputDecoration(
            labelText: 'Disposition notes *',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _summaryCtrl,
          decoration: const InputDecoration(
            labelText: 'Summary / instructions',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildDischargeTab() {
    return ListView(
      children: [
        DropdownButtonFormField<EdDisposition>(
          initialValue: _dischargeType,
          decoration: const InputDecoration(
            labelText: 'Discharge type',
            border: OutlineInputBorder(),
          ),
          items: const [EdDisposition.dischargeHome, EdDisposition.dischargeAma]
              .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _dischargeType = v);
          },
        ),
        const SizedBox(height: 12),
        _buildNotesFields(),
        const SizedBox(height: 12),
        TextField(
          controller: _followUpCtrl,
          decoration: const InputDecoration(
            labelText: 'Follow-up instructions',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _submitting ? null : () => _submit(_dischargeType),
          child: Text(_submitting ? 'Submitting…' : 'Discharge patient'),
        ),
      ],
    );
  }

  Widget _buildTransferTab() {
    return ListView(
      children: [
        TextField(
          controller: _destinationCtrl,
          decoration: const InputDecoration(
            labelText: 'Transfer destination *',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        _buildNotesFields(),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _submitting
              ? null
              : () => _submit(EdDisposition.transferExternal),
          child: Text(_submitting ? 'Submitting…' : 'Transfer patient'),
        ),
      ],
    );
  }

  Widget _buildDeathTab() {
    return ListView(
      children: [
        Text(
          'Record in-hospital death. Encounter will be completed with '
          'workflow status DECEASED.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: 0.75,
                ),
          ),
        ),
        const SizedBox(height: 12),
        _buildNotesFields(),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _submitting
              ? null
              : () => _submit(EdDisposition.deceased),
          child: Text(_submitting ? 'Submitting…' : 'Record death'),
        ),
      ],
    );
  }

  Widget _buildAdmitTab() {
    return ListView(
      children: [
        DropdownButtonFormField<EdDisposition>(
          initialValue: _admitType,
          decoration: const InputDecoration(
            labelText: 'Admission type',
            border: OutlineInputBorder(),
          ),
          items: const [EdDisposition.admitWard, EdDisposition.admitIcu]
              .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _admitType = v);
          },
        ),
        const SizedBox(height: 12),
        _buildNotesFields(),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _submitting
              ? null
              : () => _submit(_admitType, admit: true),
          child: Text(_submitting ? 'Saving…' : 'Proceed to admission'),
        ),
      ],
    );
  }
}
