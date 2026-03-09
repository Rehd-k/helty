import '../models/pharmacy_queue_models.dart';

/// Service for prescription queue (drugs sent to pharmacy on behalf of patients).
/// Inject [MockPharmacyQueueService] for now; replace with your API implementation when ready.
abstract class IPharmacyQueueService {
  /// Fetches current prescription queue orders (e.g. from GET /pharmacy/queue or your route).
  Future<List<QueueOrder>> getQueueOrders();
}

/// Mock implementation. Replace with a class that calls your API, e.g.:
/// `PharmacyQueueApiService implements IPharmacyQueueService` and in
/// `getQueueOrders()` call your route (e.g. GET /pharmacy/prescription-queue).
class MockPharmacyQueueService implements IPharmacyQueueService {
  @override
  Future<List<QueueOrder>> getQueueOrders() async {
    return _buildMockOrders();
  }

  static List<QueueOrder> _buildMockOrders() {
    final eleanor = PharmacyQueuePatient(
      id: 'PT-847291',
      name: 'Eleanor Shellstrop',
      gender: 'F',
      age: 42,
      weight: '65 kg',
      height: '165 cm',
      allergies: [Allergy('Penicillin', true), Allergy('Latex', false)],
      interactionWarning:
          'Lisinopril may interact with current OTC NSAID usage reported by patient. Advise monitoring.',
      history: [
        PastMedication('Metformin 500mg', 'Oct 10, 2023'),
        PastMedication('Omeprazole 20mg', 'Sep 28, 2023'),
        PastMedication('Amlodipine 5mg', 'Aug 15, 2023', isDiscontinued: true),
      ],
    );

    final tahani = PharmacyQueuePatient(
      id: 'PT-102934',
      name: 'Tahani Al-Jamil',
      gender: 'F',
      age: 38,
      weight: '60 kg',
      height: '175 cm',
      allergies: [],
      history: [],
    );

    final jason = PharmacyQueuePatient(
      id: 'PT-993821',
      name: 'Jason Mendoza',
      gender: 'M',
      age: 30,
      weight: '70 kg',
      height: '172 cm',
      allergies: [],
      history: [],
    );

    final mindy = PharmacyQueuePatient(
      id: 'PT-481920',
      name: 'Mindy St. Claire',
      gender: 'F',
      age: 55,
      weight: '62 kg',
      height: '168 cm',
      allergies: [],
      history: [],
    );

    return [
      QueueOrder(
        id: 'RX-94827',
        patient: eleanor,
        doctorName: 'Dr. Chidi Anagonye',
        department: 'Cardiology',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        urgency: UrgencyLevel.urgent,
        doctorNotes:
            'Patient reported mild dizziness with previous medication. Monitor blood pressure closely during initial doses of Lisinopril. Remind patient to take Atorvastatin in the evening.',
        medications: [
          PrescribedMedication(
            id: 'm1',
            name: 'Lisinopril 10mg Tablet',
            dosage: '1 Tablet',
            frequency: 'Once Daily\n(Morning)',
            duration: '30 Days',
            quantity: 30,
            stockAvailable: 450,
          ),
          PrescribedMedication(
            id: 'm2',
            name: 'Atorvastatin 20mg Tablet',
            dosage: '1 Tablet',
            frequency: 'Once Daily\n(Evening)',
            duration: '30 Days',
            quantity: 30,
            stockAvailable: 0,
          ),
        ],
      ),
      QueueOrder(
        id: 'RX-94828',
        patient: tahani,
        doctorName: 'Dr. Michael',
        department: 'General Medicine',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        urgency: UrgencyLevel.urgent,
        medications: [
          PrescribedMedication(
            id: 'm3',
            name: 'Amoxicillin 500mg',
            dosage: '1 Capsule',
            frequency: '3x Daily',
            duration: '7 Days',
            quantity: 21,
            stockAvailable: 100,
          ),
          PrescribedMedication(
            id: 'm4',
            name: 'Ibuprofen 400mg',
            dosage: '1 Tablet',
            frequency: 'As needed',
            duration: '5 Days',
            quantity: 15,
            stockAvailable: 500,
          ),
        ],
      ),
      QueueOrder(
        id: 'RX-94829',
        patient: jason,
        doctorName: 'Dr. Janet',
        department: 'Orthopedics',
        timestamp: DateTime.now().subtract(const Duration(minutes: 32)),
        urgency: UrgencyLevel.standard,
        medications: [
          PrescribedMedication(
            id: 'm5',
            name: 'Cyclobenzaprine 5mg',
            dosage: '1 Tablet',
            frequency: 'At bedtime',
            duration: '14 Days',
            quantity: 14,
            stockAvailable: 50,
          ),
          PrescribedMedication(
            id: 'm6',
            name: 'Naproxen 500mg',
            dosage: '1 Tablet',
            frequency: '2x Daily',
            duration: '14 Days',
            quantity: 28,
            stockAvailable: 200,
          ),
        ],
      ),
      QueueOrder(
        id: 'RX-94830',
        patient: mindy,
        doctorName: 'Dr. Trevor',
        department: 'Psychiatry',
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        urgency: UrgencyLevel.standard,
        medications: [
          PrescribedMedication(
            id: 'm7',
            name: 'Sertraline 50mg',
            dosage: '1 Tablet',
            frequency: 'Once Daily',
            duration: '30 Days',
            quantity: 30,
            stockAvailable: 80,
          ),
        ],
      ),
    ];
  }
}
