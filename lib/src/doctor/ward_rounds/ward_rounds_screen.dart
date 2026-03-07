import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/models/admission_model.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/admission_service.dart';
import 'package:helty/src/services/ward_round_note_service.dart';

@RoutePage()
class WardRoundsScreen extends ConsumerStatefulWidget {
  const WardRoundsScreen({super.key});

  @override
  ConsumerState<WardRoundsScreen> createState() => _WardRoundsScreenState();
}

class _WardRoundsScreenState extends ConsumerState<WardRoundsScreen> {
  final _admissionService = AdmissionService();

  List<AdmissionModel> _admissions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdmissions();
  }

  Future<void> _loadAdmissions() async {
    final staff = ref.read(authProvider).staff;
    final doctorId = staff?.id ?? staff?.staffId ?? '';
    if (doctorId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Not logged in as a doctor.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _admissionService.list(
        status: 'admitted',
        attendingDoctorId: doctorId,
      );
      if (!mounted) return;
      setState(() {
        _admissions = list;
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

  void _openInpatientView(AdmissionModel admission) {
    context.router.push(
      InpatientPatientViewRoute(
        patientId: admission.patientId,
        admissionId: admission.id,
        ward: admission.ward,
        bedNumber: admission.bedPreference,
        diagnosis: admission.provisionalDiagnosis,
      ),
    );
  }

  Future<void> _showDocumentRoundDialog(AdmissionModel admission) async {
    final staff = ref.read(authProvider).staff;
    final doctorId = staff?.id ?? staff?.staffId ?? '';
    if (doctorId.isEmpty) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DocumentRoundDialog(
        admissionId: admission.id,
        doctorId: doctorId,
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ward round note saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Loading your inpatients…',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.error),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadAdmissions,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_admissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bed_outlined,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No inpatients under your care',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Admitted patients with you as attending doctor will appear here for ward rounds.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAdmissions,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _admissions.length,
        itemBuilder: (context, index) {
          final a = _admissions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(a.provisionalDiagnosis ?? 'Admission'),
              subtitle: Text(
                '${a.ward ?? 'Ward'} • Bed ${a.bedPreference ?? '—'} • Patient ${a.patientId}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => _showDocumentRoundDialog(a),
                    child: const Text('Document round'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _openInpatientView(a),
                    child: const Text('Open'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DocumentRoundDialog extends StatefulWidget {
  const _DocumentRoundDialog({
    required this.admissionId,
    required this.doctorId,
  });

  final String admissionId;
  final String doctorId;

  @override
  State<_DocumentRoundDialog> createState() => _DocumentRoundDialogState();
}

class _DocumentRoundDialogState extends State<_DocumentRoundDialog> {
  final _wardRoundNoteService = WardRoundNoteService();
  final _subjectiveCtrl = TextEditingController();
  final _objectiveCtrl = TextEditingController();
  final _assessmentCtrl = TextEditingController();
  final _planCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _subjectiveCtrl.dispose();
    _objectiveCtrl.dispose();
    _assessmentCtrl.dispose();
    _planCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = _subjectiveCtrl.text.trim();
    final o = _objectiveCtrl.text.trim();
    final a = _assessmentCtrl.text.trim();
    final p = _planCtrl.text.trim();
    if (s.isEmpty && o.isEmpty && a.isEmpty && p.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one field (Subjective, Objective, Assessment, or Plan).')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _wardRoundNoteService.create(
        admissionId: widget.admissionId,
        doctorId: widget.doctorId,
        roundDate: DateTime.now(),
        subjective: s.isEmpty ? null : s,
        objective: o.isEmpty ? null : o,
        assessment: a.isEmpty ? null : a,
        plan: p.isEmpty ? null : p,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Document ward round'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _subjectiveCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Subjective',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _objectiveCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Objective',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _assessmentCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Assessment',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _planCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Plan',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
