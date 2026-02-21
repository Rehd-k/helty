import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/paitients/patient_service.dart';

import '../paitients/patient_model.dart';
import 'select.user.dart';
import 'selected.user.dart';

@RoutePage()
class EnlistPaitientScreen extends StatefulWidget {
  const EnlistPaitientScreen({super.key});

  @override
  EnlistPaitientState createState() => EnlistPaitientState();
}

class EnlistPaitientState extends State<EnlistPaitientScreen> {
  PatientService patientService = PatientService();
  double spacing = 16.0;
  double runSpacing = 16.0;
  List<Patient> patients = [];
  Patient? patient;

  void fetchPatients([String? query]) async {
    List<Patient> res = await patientService.fetchPatients(
      query: query,
      isAscending: true,
    );

    setState(() {
      patients = res;
    });
  }

  void selectPatient(Patient selectedPatient) async {
    print('object');
    setState(() {
      patient = selectedPatient;
    });
  }

  void clearPatient() {
    setState(() {
      patient = null;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchPatients();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWide = width >= 1100;

        if (!isWide) {
          return Column(
            children: [
              SelectUser(
                patients: patients,
                onSearch: (String value) {},
                onPatientSelected: (Patient value) {
                  selectPatient(value);
                },
              ),
              const SizedBox(height: 20),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                flex: 2, // 2/3
                child: SelectUser(
                  patients: patients,
                  onSearch: (String value) {
                    fetchPatients(value);
                  },
                  onPatientSelected: (Patient value) {
                    selectPatient(value);
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 1, // 1/3
                child: patient == null
                    ? SizedBox()
                    : SelectedPatientCard(
                        patient: patient,
                        onClear: clearPatient,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
