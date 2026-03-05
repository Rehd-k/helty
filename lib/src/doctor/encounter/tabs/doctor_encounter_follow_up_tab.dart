import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/services/encounter_service.dart';

@RoutePage()
class DoctorEncounterFollowUpTab extends StatefulWidget {
  const DoctorEncounterFollowUpTab({super.key});

  @override
  State<DoctorEncounterFollowUpTab> createState() =>
      _DoctorEncounterFollowUpTabState();
}

class _DoctorEncounterFollowUpTabState extends State<DoctorEncounterFollowUpTab> {
  final _encounterService = EncounterService();
  DateTime? _followUpDate;
  final _instructionsCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  bool _loading = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _instructionsCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    try {
      final enc = await _encounterService.getById(scope.encounterId);
      if (!mounted) return;
      if (enc != null) {
        if (enc.followUpDate != null) {
          _followUpDate = DateTime.tryParse(enc.followUpDate!);
        }
        _instructionsCtrl.text = enc.followUpInstructions ?? '';
        _referralCtrl.text = enc.referral ?? '';
      }
      setState(() => _loaded = true);
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _save() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    setState(() => _loading = true);
    try {
      await _encounterService.update(scope.encounterId, {
        'followUpDate': _followUpDate?.toIso8601String(),
        'followUpInstructions': _instructionsCtrl.text.trim().isEmpty
            ? null
            : _instructionsCtrl.text.trim(),
        'referral': _referralCtrl.text.trim().isEmpty ? null : _referralCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Follow-up saved')),
      );
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
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

    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Follow-up date',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: Text(
              _followUpDate == null
                  ? 'Select date'
                  : '${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _followUpDate ?? DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null && mounted) setState(() => _followUpDate = date);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _instructionsCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Follow-up instructions',
              border: OutlineInputBorder(),
              hintText: 'e.g. Review LFT, continue medications',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _referralCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Referral (if needed)',
              border: OutlineInputBorder(),
              hintText: 'e.g. Refer to Cardiology',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loading ? null : _save,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save follow-up'),
          ),
        ],
      ),
    );
  }
}
