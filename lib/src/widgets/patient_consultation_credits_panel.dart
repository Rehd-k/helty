import 'package:flutter/material.dart';

import '../models/consultation_credit_model.dart';
import '../paitients/patient_service.dart';
import 'consultation_credit_chip.dart';

/// Loads and lists active OPD consultation credits for a patient.
class PatientConsultationCreditsPanel extends StatefulWidget {
  const PatientConsultationCreditsPanel({
    super.key,
    required this.patientId,
    this.title = 'Consultation credits',
  });

  final String patientId;
  final String title;

  @override
  State<PatientConsultationCreditsPanel> createState() =>
      _PatientConsultationCreditsPanelState();
}

class _PatientConsultationCreditsPanelState
    extends State<PatientConsultationCreditsPanel> {
  final _patientService = PatientService();
  List<ConsultationCredit>? _credits;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.patientId.trim().isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final list =
          await _patientService.fetchConsultationCredits(widget.patientId);
      if (!mounted) return;
      setState(() {
        _credits = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _credits = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final credits = _credits ?? [];
    if (credits.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...credits.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ConsultationCreditChip.fromCredit(credit: c),
            ),
          ),
        ],
      ),
    );
  }
}
