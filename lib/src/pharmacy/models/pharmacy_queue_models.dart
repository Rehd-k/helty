// Models for the pharmacy prescription queue (drugs sent to pharmacy on behalf of patients).

enum UrgencyLevel { urgent, standard, waiting }

class PrescribedMedication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final int quantity;
  final int stockAvailable;
  bool isDispensed;

  PrescribedMedication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.quantity,
    required this.stockAvailable,
    this.isDispensed = false,
  });

  bool get inStock => stockAvailable >= quantity;
}

class Allergy {
  final String name;
  final bool isSevere;
  Allergy(this.name, this.isSevere);
}

class PastMedication {
  final String name;
  final String date;
  final bool isDiscontinued;
  PastMedication(this.name, this.date, {this.isDiscontinued = false});
}

class PharmacyQueuePatient {
  final String id;
  final String name;
  final String gender;
  final int age;
  final String weight;
  final String height;
  final List<Allergy> allergies;
  final String? interactionWarning;
  final List<PastMedication> history;

  PharmacyQueuePatient({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.weight,
    required this.height,
    required this.allergies,
    this.interactionWarning,
    required this.history,
  });
}

class QueueOrder {
  final String id;
  final PharmacyQueuePatient patient;
  final String doctorName;
  final String department;
  final DateTime timestamp;
  final UrgencyLevel urgency;
  final String? doctorNotes;
  final List<PrescribedMedication> medications;

  QueueOrder({
    required this.id,
    required this.patient,
    required this.doctorName,
    required this.department,
    required this.timestamp,
    required this.urgency,
    this.doctorNotes,
    required this.medications,
  });

  String get medSummary => medications.map((m) => m.name).join(', ');
}
