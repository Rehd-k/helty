import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/responsive.dart';

import '../../../app_router.gr.dart';
import '../../enlist_services/select.user.dart';
import '../../enlist_services/selected.user.dart';
import '../../helper/theme.dart';
import '../../paitients/patient_model.dart';
import '../../paitients/patient_providers.dart';
import '../../widgets/helty_surface.dart';
import '../patient_hub_metrics.dart';
import '../widgets/hub_page_header.dart';

@RoutePage()
class PatientHubSearchScreen extends ConsumerWidget {
  const PatientHubSearchScreen({super.key});

  void _openHub(BuildContext context, Patient patient) {
    final uuid = patient.id;
    if (uuid == null || uuid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This patient has no system ID; cannot open hub.'),
        ),
      );
      return;
    }
    context.router.push(PatientHubRoute(patientUuid: uuid));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientState = ref.watch(patientProvider);
    final patients = patientState.patients;
    final selectedPatient = patientState.selectedPatient;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final width = bp.maxWidth > 0
              ? bp.maxWidth
              : MediaQuery.sizeOf(context).width;
          final compact = width < PatientHubMetrics.cardBreakpoint;
          final useWideSearch = bp.isDesktop;

          Widget buildSelectUser() {
            return SelectUser(
              patients: patients,
              serviceName: 'patient_hub',
              onSearch: (value) {
                ref.read(patientProvider.notifier).searchPatients(
                      0,
                      10,
                      value,
                      useWideSearch ? 'nameIdPhonenumber' : 'fullName',
                      null,
                      null,
                      useWideSearch ? 'surname' : 'fullName',
                      true,
                      null,
                    );
              },
              onPatientSelected: (patient) {
                ref.read(patientProvider.notifier).selectPatient(patient);
              },
            );
          }

          Widget buildActionPanel() {
            if (selectedPatient == null) {
              return HeltySurfaceCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const HubSolidIcon(
                          icon: Icons.person_search_outlined,
                          color: PatientHubMetrics.iconTeal,
                          size: 26,
                          iconSize: 14,
                          radius: 7,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Selected patient',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Search and select a patient to open their hub.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }
            return HeltySurfaceCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SelectedPatientCard(),
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openHub(context, selectedPatient),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              cs.primary,
                              Color.lerp(cs.primary, cs.tertiary, 0.45)!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.folder_shared_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Open patient hub',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final header = HubPageHeader(
            title: 'Patient Hub',
            subtitle: 'Search and open a longitudinal chart.',
            compact: compact,
          );

          if (bp.isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: 10),
                Expanded(child: buildSelectUser()),
                if (selectedPatient != null) ...[
                  const SizedBox(height: 10),
                  buildActionPanel(),
                ],
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 10),
              Expanded(
                child: ResponsiveRowColumn(
                  stackWhenWidthBelow: AppBreakpoints.desktopMin,
                  firstFlex: 2,
                  secondFlex: 1,
                  gap: 12,
                  first: buildSelectUser(),
                  second: buildActionPanel(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
