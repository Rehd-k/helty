import 'package:flutter/material.dart';
import 'package:helty/src/core/extensions/capitalizer.extention.dart';

import '../paitients/patient_model.dart';

/// 🎨 Modern List Tile for Patients
class PatientTile extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;

  const PatientTile({super.key, required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).appBarTheme.backgroundColor,
          border: Border.all(color: Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Text(
                patient.firstName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        patient.displayName == 'Unknown'
                            ? patient.patientId
                            : patient.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  // Patient ID as separate labeled field (display patientId, not internal id)
                  Text(
                    'Patient ID: ${patient.patientId}',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    patient.wardHmoDisplayLine,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (patient.phoneNumber != null &&
                      patient.phoneNumber!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    _infoBadge(Icons.phone_outlined, patient.phoneNumber!),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
