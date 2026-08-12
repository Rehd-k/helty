import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/doctor/completed/widgets/completed_encounter_scope.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/encounter_model.dart';

@RoutePage()
class CompletedEncounterFollowUpTab extends StatelessWidget {
  const CompletedEncounterFollowUpTab({super.key});

  static String? _dateLine(EncounterModel e) {
    final ap = e.followUpAppointment;
    if (ap != null) {
      return DateFormatter.dateTime(ap.appointmentDate);
    }
    final raw = e.followUpDate;
    if (raw != null && raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return DateFormatter.dateTime(parsed);
      return raw;
    }
    return null;
  }

  static String? _instructions(EncounterModel e) =>
      e.followUpAppointment?.notes ?? e.followUpInstructions;

  static String? _referralLine(EncounterModel e) =>
      e.followUpAppointment?.referral ?? e.referral;

  @override
  Widget build(BuildContext context) {
    final scope = CompletedEncounterScope.of(context);
    if (scope == null) {
      return const Center(child: Text('Encounter context not available'));
    }
    final e = scope.encounter;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dateLine = _dateLine(e);
    final instructions = _instructions(e);
    final referral = _referralLine(e);

    final hasFollowUp = (dateLine != null && dateLine.isNotEmpty) ||
        (instructions != null && instructions.isNotEmpty) ||
        (referral != null && referral.isNotEmpty);

    if (!hasFollowUp) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No follow-up or referral recorded for this encounter.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ResponsiveBody(
      center: false,
      expand: false,
      builder: (context, bp) => SingleChildScrollView(
        padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (dateLine != null && dateLine.isNotEmpty)
            _Block(
              title: 'Follow-up date & time',
              content: dateLine,
              theme: theme,
              colorScheme: colorScheme,
            ),
          if (instructions != null && instructions.isNotEmpty) ...[
            const SizedBox(height: 20),
            _Block(
              title: 'Follow-up instructions',
              content: instructions,
              theme: theme,
              colorScheme: colorScheme,
            ),
          ],
          if (referral != null && referral.isNotEmpty) ...[
            const SizedBox(height: 20),
            _Block(
              title: 'Referral',
              content: referral,
              theme: theme,
              colorScheme: colorScheme,
            ),
          ],
        ],
      ),
    ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.title,
    required this.content,
    required this.theme,
    required this.colorScheme,
  });

  final String title;
  final String content;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
