import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../helper/date.formatter.dart';
import '../../providers/patient_hub_providers.dart';
import '../../widgets/hub_empty_state.dart';
import '../../widgets/patient_hub_scope.dart';

@RoutePage()
class HubProfileScreen extends ConsumerWidget {
  const HubProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientUuid = PatientHubScope.requirePatientUuid(context);
    final profileAsync = ref.watch(patientHubProfileProvider(patientUuid));

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (patient) {
        return ResponsiveBody(
          expand: false,
          builder: (context, bp) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _section(context, 'Demographics', [
                _row('Title', patient.title),
                _row('Full name', '${patient.surname} ${patient.firstName}'),
                _row('Hospital no.', patient.patientId),
                _row('Card no.', patient.cardNo),
                _row('DOB', DateFormatter.medicalDate(patient.dob)),
                _row('Gender', patient.gender),
                _row('Marital status', patient.maritalStatus),
                _row('Nationality', patient.nationality),
                _row('State of origin', patient.stateOfOrigin),
                _row('LGA', patient.lga),
                _row('Town', patient.town),
                _row('Religion', patient.religion),
                _row('Profession', patient.profession),
                _row('Preferred language', patient.preferredLanguage),
              ]),
              _section(context, 'Contact', [
                _row('Phone', patient.phoneNumber),
                _row('Email', patient.email),
                _row('Permanent address', patient.permanentAddress),
                _row('Residence', patient.addressOfResidence),
              ]),
              _section(context, 'Next of kin', [
                _row('Name', patient.nextOfKinName),
                _row('Phone', patient.nextOfKinPhone),
                _row('Relationship', patient.nextOfKinRelationship),
                _row('Address', patient.nextOfKinAddress),
              ]),
              _section(context, 'Coverage & status', [
                _row('HMO', patient.hmoProvider?.name ?? patient.hmo),
                _row('Status', patient.status),
                _row('Ward', patient.ward),
                _row('Bed', patient.bedNumber),
                if (patient.admissionDate != null)
                  _row(
                    'Admission date',
                    DateFormatter.medicalDate(patient.admissionDate!),
                  ),
                if (patient.createdAt != null)
                  _row(
                    'Registered',
                    DateFormatter.medicalDate(patient.createdAt!),
                  ),
                if (patient.createdBy != null &&
                    patient.createdBy!.trim().isNotEmpty)
                  _row('Created by', patient.createdBy!.trim()),
              ]),
              if (patient.allergies.isEmpty)
                const HubEmptyState(
                  title: 'No allergies on file',
                  icon: Icons.check_circle_outline,
                )
              else
                _section(
                  context,
                  'Allergies',
                  patient.allergies
                      .map((a) => _row(
                            a.isSevere ? 'Severe' : 'Allergy',
                            a.name,
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> rows) {
    final visible = rows.where((r) => r is! SizedBox).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...visible,
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
