import 'package:dio/dio.dart';
import '../models/pharmacy_queue_models.dart';
import 'package:helty/src/services/api_service.dart';

/// One page from GET /invoice-drugs (includes server [total] for pagination).
class PharmacyInvoiceDrugListPage {
  const PharmacyInvoiceDrugListPage({
    required this.orders,
    required this.total,
  });

  final List<QueueOrder> orders;
  final int total;
}

/// Service for invoice-drugs prescription queue.
/// Endpoints: GET/PATCH/DELETE /invoice-drugs/:id, etc.
abstract class IPharmacyQueueService {
  /// List invoice-drug orders with optional date range and pagination.
  /// [fromDate] and [toDate] (ISO 8601), [skip] and [take] for pagination.
  Future<PharmacyInvoiceDrugListPage> listInvoiceDrugs({
    String? fromDate,
    String? toDate,
    int skip = 0,
    int take = 20,
  });

  /// Get a single invoice-drug order by ID.
  Future<QueueOrder> getInvoiceDrug(String id);

  /// Update an invoice-drug order.
  Future<QueueOrder> updateInvoiceDrug(String id, Map<String, dynamic> payload);

  /// Delete an invoice-drug order.
  Future<void> deleteInvoiceDrug(String id);

  /// Update a specific item within an invoice-drug order.
  Future<QueueOrder> updateInvoiceDrugItem(
    String id,
    String itemId,
    Map<String, dynamic> payload,
  );

  /// Delete a specific item from an invoice-drug order.
  Future<QueueOrder> deleteInvoiceDrugItem(String id, String itemId);
}

/// API implementation for invoice-drugs endpoints.
class PharmacyQueueApiService implements IPharmacyQueueService {
  PharmacyQueueApiService() : _dio = ApiService().dio;
  final Dio _dio;

  @override
  Future<PharmacyInvoiceDrugListPage> listInvoiceDrugs({
    String? fromDate,
    String? toDate,
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/invoice-drugs',
        queryParameters: {
          if (fromDate != null) 'fromDate': fromDate,
          if (toDate != null) 'toDate': toDate,
          'skip': skip,
          'take': take,
        },
      );
      final data = response.data;
      final list = _extractList(data);
      final orders = list
          .map((json) => QueueOrder.fromJson(json as Map<String, dynamic>))
          .toList();
      final total = _parseTotalCount(data, orders.length);
      return PharmacyInvoiceDrugListPage(orders: orders, total: total);
    } on DioException catch (e) {
      throw Exception('Failed to list invoice drugs: ${_errorMessage(e)}');
    }
  }

  int _parseTotalCount(dynamic data, int fallback) {
    if (data is Map) {
      final t = data['total'];
      if (t is int) return t;
      if (t != null) return int.tryParse(t.toString()) ?? fallback;
    }
    return fallback;
  }

  @override
  Future<QueueOrder> getInvoiceDrug(String id) async {
    try {
      final response = await _dio.get('/invoice-drugs/$id');
      return QueueOrder.fromJson(_unwrapOrderPayload(response.data));
    } on DioException catch (e) {
      throw Exception('Failed to get invoice drug: ${_errorMessage(e)}');
    }
  }

  @override
  Future<QueueOrder> updateInvoiceDrug(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.patch('/invoice-drugs/$id', data: payload);
      return QueueOrder.fromJson(_unwrapOrderPayload(response.data));
    } on DioException catch (e) {
      throw Exception('Failed to update invoice drug: ${_errorMessage(e)}');
    }
  }

  @override
  Future<void> deleteInvoiceDrug(String id) async {
    try {
      await _dio.delete('/invoice-drugs/$id');
    } on DioException catch (e) {
      throw Exception('Failed to delete invoice drug: ${_errorMessage(e)}');
    }
  }

  @override
  Future<QueueOrder> updateInvoiceDrugItem(
    String id,
    String itemId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.patch(
        '/invoice-drugs/$id/items/$itemId',
        data: payload,
      );
      return QueueOrder.fromJson(_unwrapOrderPayload(response.data));
    } on DioException catch (e) {
      throw Exception(
        'Failed to update invoice drug item: ${_errorMessage(e)}',
      );
    }
  }

  @override
  Future<QueueOrder> deleteInvoiceDrugItem(String id, String itemId) async {
    try {
      final response = await _dio.delete('/invoice-drugs/$id/items/$itemId');
      return QueueOrder.fromJson(_unwrapOrderPayload(response.data));
    } on DioException catch (e) {
      throw Exception(
        'Failed to delete invoice drug item: ${_errorMessage(e)}',
      );
    }
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List<dynamic>) return data;
    if (data is Map<String, dynamic>) {
      final candidates = [
        data['invoices'],
        data['data'],
        data['items'],
        data['orders'],
        data['results'],
      ];
      for (final entry in candidates) {
        if (entry is List) return entry;
      }
    }
    return const [];
  }

  Map<String, dynamic> _unwrapOrderPayload(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) return inner;
      return data;
    }
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      final inner = m['data'];
      if (inner is Map) return Map<String, dynamic>.from(inner);
      return m;
    }
    throw Exception('Unexpected invoice-drugs response shape');
  }

  String _errorMessage(DioException e) {
    final payload = e.response?.data;
    if (payload is Map && payload['message'] != null) {
      return payload['message'].toString();
    }
    return e.message ?? 'Unknown error';
  }
}

/// Mock implementation for testing without API calls.
class MockPharmacyQueueService implements IPharmacyQueueService {
  @override
  Future<PharmacyInvoiceDrugListPage> listInvoiceDrugs({
    String? fromDate,
    String? toDate,
    int skip = 0,
    int take = 20,
  }) async {
    final all = _buildMockOrders();
    final slice = all.skip(skip).take(take).toList();
    return PharmacyInvoiceDrugListPage(orders: slice, total: all.length);
  }

  @override
  Future<QueueOrder> getInvoiceDrug(String id) async {
    final orders = _buildMockOrders();
    return orders.firstWhere(
      (o) => o.id == id,
      orElse: () => throw Exception('Invoice drug not found: $id'),
    );
  }

  @override
  Future<QueueOrder> updateInvoiceDrug(
    String id,
    Map<String, dynamic> payload,
  ) async {
    return getInvoiceDrug(id);
  }

  @override
  Future<void> deleteInvoiceDrug(String id) async {
    // No-op for mock
  }

  @override
  Future<QueueOrder> updateInvoiceDrugItem(
    String id,
    String itemId,
    Map<String, dynamic> payload,
  ) async {
    return getInvoiceDrug(id);
  }

  @override
  Future<QueueOrder> deleteInvoiceDrugItem(String id, String itemId) async {
    return getInvoiceDrug(id);
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
        doctorDisplayName: 'Dr. Chidi Anagonye',
        department: 'Cardiology',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        urgency: UrgencyLevel.urgent,
        invoiceStatus: 'PAID',
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
            drugId: 'mock-drug-1',
          ),
          PrescribedMedication(
            id: 'm2',
            name: 'Atorvastatin 20mg Tablet',
            dosage: '1 Tablet',
            frequency: 'Once Daily\n(Evening)',
            duration: '30 Days',
            quantity: 30,
            stockAvailable: 0,
            drugId: 'mock-drug-2',
          ),
        ],
      ),
      QueueOrder(
        id: 'RX-94828',
        patient: tahani,
        doctorDisplayName: 'Dr. Michael',
        department: 'General Medicine',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        urgency: UrgencyLevel.urgent,
        invoiceStatus: 'PAID',
        medications: [
          PrescribedMedication(
            id: 'm3',
            name: 'Amoxicillin 500mg',
            dosage: '1 Capsule',
            frequency: '3x Daily',
            duration: '7 Days',
            quantity: 21,
            stockAvailable: 100,
            drugId: 'mock-drug-3',
          ),
          PrescribedMedication(
            id: 'm4',
            name: 'Ibuprofen 400mg',
            dosage: '1 Tablet',
            frequency: 'As needed',
            duration: '5 Days',
            quantity: 15,
            stockAvailable: 500,
            drugId: 'mock-drug-4',
          ),
        ],
      ),
      QueueOrder(
        id: 'RX-94829',
        patient: jason,
        doctorDisplayName: 'Dr. Janet',
        department: 'Orthopedics',
        timestamp: DateTime.now().subtract(const Duration(minutes: 32)),
        urgency: UrgencyLevel.standard,
        invoiceStatus: 'PENDING',
        medications: [
          PrescribedMedication(
            id: 'm5',
            name: 'Cyclobenzaprine 5mg',
            dosage: '1 Tablet',
            frequency: 'At bedtime',
            duration: '14 Days',
            quantity: 14,
            stockAvailable: 50,
            drugId: 'mock-drug-5',
          ),
          PrescribedMedication(
            id: 'm6',
            name: 'Naproxen 500mg',
            dosage: '1 Tablet',
            frequency: '2x Daily',
            duration: '14 Days',
            quantity: 28,
            stockAvailable: 200,
            drugId: 'mock-drug-6',
          ),
        ],
      ),
      QueueOrder(
        id: 'RX-94830',
        patient: mindy,
        doctorDisplayName: 'Dr. Trevor',
        department: 'Psychiatry',
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        urgency: UrgencyLevel.standard,
        invoiceStatus: 'PENDING',
        medications: [
          PrescribedMedication(
            id: 'm7',
            name: 'Sertraline 50mg',
            dosage: '1 Tablet',
            frequency: 'Once Daily',
            duration: '30 Days',
            quantity: 30,
            stockAvailable: 80,
            drugId: 'mock-drug-7',
          ),
        ],
      ),
    ];
  }
}
