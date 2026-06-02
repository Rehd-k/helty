import 'package:flutter/material.dart';

import '../helper/date.formatter.dart';
import '../models/consultation_credit_model.dart';

/// Compact label for OPD consultation visit credit on queue / billing rows.
class ConsultationCreditChip extends StatelessWidget {
  const ConsultationCreditChip({
    super.key,
    required this.visitsRemaining,
    this.expiresAt,
    this.serviceName,
    this.compact = false,
    this.expired = false,
    this.consumable,
  });

  ConsultationCreditChip.fromLine({
    super.key,
    required ConsultationServiceLine line,
    this.compact = false,
  }) : visitsRemaining = line.visitsRemaining,
       expiresAt = line.expiresAt,
       serviceName = line.name,
       expired = line.isExpired,
       consumable = null;

  ConsultationCreditChip.fromCredit({
    super.key,
    required ConsultationCredit credit,
    this.compact = false,
  }) : visitsRemaining = credit.visitsRemaining,
       expiresAt = credit.expiresAt,
       serviceName = credit.serviceName,
       expired = credit.isExpired,
       consumable = credit.consumable;

  final int visitsRemaining;
  final DateTime? expiresAt;
  final String? serviceName;
  final bool compact;
  final bool expired;
  final bool? consumable;

  String get _label {
    if (expired) {
      return compact ? 'Credit expired' : 'Consultation credit expired';
    }
    if (visitsRemaining <= 0) {
      return compact ? 'No visits left' : 'All consultation visits used';
    }
    final visitWord = visitsRemaining == 1 ? 'visit' : 'visits';
    final visitsPart = '$visitsRemaining $visitWord left';
    final exp = expiresAt;
    if (exp == null) return visitsPart;
    final expLocal = exp.toLocal();
    final expPart = compact
        ? 'exp ${DateFormatter.medicalDate(expLocal)}'
        : 'expires ${DateFormatter.medicalDate(expLocal)}';
    return '$visitsPart · $expPart';
  }

  bool get _warnSoon {
    if (expired || visitsRemaining <= 0) return false;
    final exp = expiresAt;
    if (exp == null) return false;
    return exp.difference(DateTime.now()).inHours < 48;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color bg;
    Color fg;
    if (expired || visitsRemaining <= 0) {
      bg = colorScheme.surfaceContainerHighest;
      fg = colorScheme.onSurfaceVariant;
    } else if (_warnSoon) {
      bg = colorScheme.tertiaryContainer.withValues(alpha: 0.7);
      fg = colorScheme.onTertiaryContainer;
    } else if (consumable == true) {
      bg = colorScheme.primaryContainer.withValues(alpha: 0.6);
      fg = colorScheme.onPrimaryContainer;
    } else {
      bg = colorScheme.secondaryContainer.withValues(alpha: 0.5);
      fg = colorScheme.onSecondaryContainer;
    }

    final name = serviceName?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (name != null && name.isNotEmpty && !compact)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              name,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: compact ? 2 : 4,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w500,
              fontSize: compact ? 10 : 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
