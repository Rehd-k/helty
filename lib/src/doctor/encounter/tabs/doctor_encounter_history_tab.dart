import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/services/encounter_service.dart';

@RoutePage()
class DoctorEncounterHistoryTab extends StatefulWidget {
  const DoctorEncounterHistoryTab({super.key});

  @override
  State<DoctorEncounterHistoryTab> createState() =>
      _DoctorEncounterHistoryTabState();
}

class _DoctorEncounterHistoryTabState extends State<DoctorEncounterHistoryTab> {
  final _encounterService = EncounterService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _chiefComplaintCtrl;
  late final TextEditingController _hpiCtrl;
  late final TextEditingController _pmhCtrl;
  late final TextEditingController _surgicalCtrl;
  late final TextEditingController _drugCtrl;
  late final TextEditingController _allergyCtrl;
  late final TextEditingController _familyCtrl;
  late final TextEditingController _socialCtrl;

  bool _loading = false;
  bool _loaded = false;
  bool _draftLoadScheduled = false;

  @override
  void initState() {
    super.initState();
    _chiefComplaintCtrl = TextEditingController();
    _hpiCtrl = TextEditingController();
    _pmhCtrl = TextEditingController();
    _surgicalCtrl = TextEditingController();
    _drugCtrl = TextEditingController();
    _allergyCtrl = TextEditingController();
    _familyCtrl = TextEditingController();
    _socialCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_draftLoadScheduled) {
      _draftLoadScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadDraft();
      });
    }
  }

  @override
  void dispose() {
    _chiefComplaintCtrl.dispose();
    _hpiCtrl.dispose();
    _pmhCtrl.dispose();
    _surgicalCtrl.dispose();
    _drugCtrl.dispose();
    _allergyCtrl.dispose();
    _familyCtrl.dispose();
    _socialCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    setState(() => _loading = true);
    try {
      final enc = await _encounterService.getById(scope.encounterId);
      if (!mounted) return;
      if (enc != null) {
        _chiefComplaintCtrl.text = enc.chiefComplaint ?? '';
        _hpiCtrl.text = enc.hpi ?? '';
        _pmhCtrl.text = enc.pmh ?? '';
        _surgicalCtrl.text = enc.surgicalHistory ?? '';
        _drugCtrl.text = enc.drugHistory ?? '';
        _allergyCtrl.text = enc.allergyHistory ?? '';
        _familyCtrl.text = enc.familyHistory ?? '';
        _socialCtrl.text = enc.socialHistory ?? '';
      }
      setState(() {
        _loading = false;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveDraft() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    setState(() => _loading = true);
    try {
      await _encounterService.update(scope.encounterId, {
        'chiefComplaint': _chiefComplaintCtrl.text.trim().isEmpty
            ? null
            : _chiefComplaintCtrl.text.trim(),
        'hpi': _hpiCtrl.text.trim().isEmpty ? null : _hpiCtrl.text.trim(),
        'pmh': _pmhCtrl.text.trim().isEmpty ? null : _pmhCtrl.text.trim(),
        'surgicalHistory':
            _surgicalCtrl.text.trim().isEmpty ? null : _surgicalCtrl.text.trim(),
        'drugHistory':
            _drugCtrl.text.trim().isEmpty ? null : _drugCtrl.text.trim(),
        'allergyHistory':
            _allergyCtrl.text.trim().isEmpty ? null : _allergyCtrl.text.trim(),
        'familyHistory':
            _familyCtrl.text.trim().isEmpty ? null : _familyCtrl.text.trim(),
        'socialHistory':
            _socialCtrl.text.trim().isEmpty ? null : _socialCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved')),
      );
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = EncounterScope.of(context);
    if (scope == null) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: Text('Encounter context not available')),
      );
    }

    if (_loading && !_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DropdownButton<String>(
                  value: null,
                  hint: Text('Templates', style: theme.textTheme.bodyMedium),
                  items: const [
                    DropdownMenuItem(value: 'default', child: Text('Default')),
                  ],
                  onChanged: (_) {},
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Voice typing not yet integrated')),
                    );
                  },
                  icon: const Icon(Icons.mic_none, size: 18),
                  label: const Text('Voice typing'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _loading ? null : _saveDraft,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save draft'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _section('Chief Complaint', _chiefComplaintCtrl, maxLines: 2),
            _section('History of Present Illness (HPI)', _hpiCtrl, maxLines: 6),
            _section('Past Medical History (PMH)', _pmhCtrl, maxLines: 4),
            _section('Surgical History', _surgicalCtrl, maxLines: 3),
            _section('Drug History', _drugCtrl, maxLines: 3),
            _section('Allergy History', _allergyCtrl, maxLines: 2),
            _section('Family History', _familyCtrl, maxLines: 4),
            _section('Social History', _socialCtrl, maxLines: 3),
          ],
        ),
      ),
    );
  }

  Widget _section(String label, TextEditingController ctrl, {int maxLines = 4}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: 'Enter $label',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
          ),
        ],
      ),
    );
  }
}
