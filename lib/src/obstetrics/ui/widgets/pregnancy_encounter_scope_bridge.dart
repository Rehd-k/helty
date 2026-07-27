import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/ui/pregnancy_view_screen.dart';
import 'package:helty/src/providers/auth_provider.dart';

/// Wraps [child] in [EncounterScope] for antenatal clinical orders.
class PregnancyEncounterScopeBridge extends ConsumerWidget {
  const PregnancyEncounterScopeBridge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregnancyScope = PregnancyViewScope.of(context);
    if (pregnancyScope == null) {
      return const Center(child: Text('Pregnancy context not available'));
    }

    final pregnancy = pregnancyScope.pregnancy;
    if (pregnancy == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final encounterId = pregnancyScope.effectiveEncounterId;
    if (encounterId == null || encounterId.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.link_off_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'ANC encounter not linked to this pregnancy.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Pull to refresh on the pregnancy screen, or re-open after booking.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    final staffId = ref.watch(authProvider).staff?.id;
    final canEdit = pregnancy.status == PregnancyStatus.ONGOING &&
        staffId != null &&
        staffId.isNotEmpty;

    return EncounterScope(
      encounterId: encounterId,
      patientId: pregnancy.patientId,
      doctorId: staffId,
      actingStaffId: staffId,
      canEdit: canEdit,
      isOutpatient: true,
      pregnancyId: pregnancyScope.pregnancyId,
      child: child,
    );
  }
}
