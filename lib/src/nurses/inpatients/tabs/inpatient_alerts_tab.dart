import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';

@RoutePage()
class InpatientAlertsScreen extends StatelessWidget {
  const InpatientAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = [
      _Alert(
        type: 'Overdue medication',
        message: 'Paracetamol 1g PO overdue by 45 mins',
        time: '15 mins ago',
        severity: 'High',
        resolvable: true,
      ),
      _Alert(
        type: 'Abnormal vitals',
        message: 'SpO₂ 89% on room air',
        time: '5 mins ago',
        severity: 'Critical',
        resolvable: false,
      ),
      _Alert(
        type: 'Allergy conflict',
        message: 'Order for Amoxicillin in patient with penicillin allergy',
        time: '1 hr ago',
        severity: 'High',
        resolvable: true,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Alerts',
        subtitle:
            'Overdue meds, abnormal vitals and allergy conflicts for this patient',
        child: Column(
          children: alerts
              .map(
                (a) => _AlertTile(alert: a),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _Alert {
  final String type;
  final String message;
  final String time;
  final String severity;
  final bool resolvable;

  const _Alert({
    required this.type,
    required this.message,
    required this.time,
    required this.severity,
    required this.resolvable,
  });
}

class _AlertTile extends StatelessWidget {
  final _Alert alert;

  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color color;
    switch (alert.severity.toLowerCase()) {
      case 'critical':
        color = scheme.error;
        break;
      case 'high':
        color = scheme.error;
        break;
      default:
        color = scheme.tertiary;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        alert.type,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(alert.message),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            alert.time,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 4),
          if (alert.resolvable)
            OutlinedButton(
              onPressed: () {},
              child: const Text('Resolve'),
            ),
        ],
      ),
    );
  }
}

