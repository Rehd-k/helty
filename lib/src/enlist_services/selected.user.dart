import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/extensions/capitalizer.extention.dart';

import '../core/widgets/patient_avatar.dart';
import 'package:helty/src/shared/department_colors.dart';
import 'package:helty/src/widgets/helty_surface.dart';
import '../paitients/patient_providers.dart';

class SelectedPatientCard extends ConsumerWidget {
  const SelectedPatientCard({super.key, this.onBeforeClear});

  /// When set, return `true` to clear the patient, `false` to cancel.
  final Future<bool> Function()? onBeforeClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientState = ref.watch(patientProvider);
    final selectedPatient = patientState.selectedPatient;
    if (selectedPatient == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = DepartmentColors.frontDesk;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: HeltySurfaceCard(
        padding: const EdgeInsets.all(20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: accent.withValues(alpha: 0.06),
              ),
            ),
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accent.withValues(alpha: 0.25),
                          width: 2,
                        ),
                      ),
                      child: PatientAvatar.fromPatient(
                        selectedPatient,
                        size: 56,
                        backgroundColor: accent.withValues(alpha: 0.12),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cs.tertiary,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.surface, width: 2),
                        ),
                        child: Icon(
                          Icons.check,
                          size: 10,
                          color: cs.onTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedPatient.firstName.capitalize(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _detailBadge(context, Icons.badge_outlined, cs,
                          selectedPatient.patientId == ''
                              ? 'No ID'
                              : selectedPatient.patientId),
                      const SizedBox(height: 4),
                      _detailBadge(
                        context,
                        Icons.local_hospital_outlined,
                        cs,
                        selectedPatient.wardHmoDisplayLine,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    if (onBeforeClear != null) {
                      final shouldClear = await onBeforeClear!();
                      if (!shouldClear) return;
                    }
                    ref.read(patientProvider.notifier).clearPatient();
                  },
                  icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                  tooltip: "Remove Patient",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailBadge(
    BuildContext context,
    IconData icon,
    ColorScheme cs,
    String text,
  ) {
    return Row(
      children: [
        Icon(icon, size: 12, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}

