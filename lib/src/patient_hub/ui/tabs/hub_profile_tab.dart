import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/nursing_permissions.dart';
import '../../../helper/date.formatter.dart';
import '../../../models/staff_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/patient_allergy_editor.dart';
import '../../../widgets/patient_immunization_editor.dart';
import '../../../widgets/helty_surface.dart';
import '../../providers/patient_hub_providers.dart';
import '../../patient_hub_metrics.dart';
import '../../widgets/patient_hub_scope.dart';

@RoutePage()
class HubProfileScreen extends ConsumerWidget {
  const HubProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientUuid = PatientHubScope.requirePatientUuid(context);
    final profileAsync = ref.watch(patientHubProfileProvider(patientUuid));
    final staff = ref.watch(currentStaffProvider);
    final canEditRecords = _canEditClinicalRecords(staff);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (patient) {
        return ResponsiveBody(
          expand: false,
          builder: (context, bp) => SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: HeltySurfaceCard(
                    padding: const EdgeInsets.all(12),
                    child: PatientAllergyEditor(
                      key: ValueKey('hub-allergies-$patientUuid'),
                      patientId: patientUuid,
                      enabled: canEditRecords,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: HeltySurfaceCard(
                    padding: const EdgeInsets.all(12),
                    child: PatientImmunizationEditor(
                      key: ValueKey('hub-immunizations-$patientUuid'),
                      patientId: patientUuid,
                      enabled: canEditRecords,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _canEditClinicalRecords(Staff? staff) {
    if (staff == null) return false;
    if (isNursingStaff(staff)) return true;
    final at = staff.accountType?.name.toLowerCase() ?? '';
    final r = staff.staffRole.toLowerCase();
    return at == 'medical_records' ||
        r == 'medical_records' ||
        r == 'records_officer' ||
        r == 'medical_records_head' ||
        staff.accountType == AccountType.medical_records;
  }

  Widget _section(BuildContext context, String title, List<Widget> rows) {
    final visible = rows.where((r) => r is! SizedBox).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HeltySurfaceCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const HubSolidIcon(
                  icon: Icons.folder_outlined,
                  color: PatientHubMetrics.iconPurple,
                  size: 26,
                  iconSize: 14,
                  radius: 7,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...visible,
          ],
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
            child: HeltyEllipsisText(
              text: label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: HeltyEllipsisText(text: value)),
        ],
      ),
    );
  }
}
