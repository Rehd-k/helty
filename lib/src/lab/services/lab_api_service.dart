import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../helper/app_timezone.dart';
import '../../investigations/models/investigation_models.dart';
import '../../investigations/models/investigation_query_params.dart';
import '../../services/api_service.dart';
import '../models/lab_models.dart';

/// API client for dynamic lab module. All endpoints under /lab.
class LabApiService {
  LabApiService() : _dio = ApiService().dio;

  final Dio _dio;
  static const _prefix = '/lab';

  // ── Categories ───────────────────────────────────────────────────────────

  Future<LabCategory> createCategory({
    required String name,
    String? description,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/categories',
      data: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    final data = response.data;
    if (data == null) throw StateError('Create category returned no data');
    return LabCategory.fromJson(data);
  }

  Future<LabCategoriesResponse> getCategories({int? skip, int? take}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/categories',
      queryParameters: {
        if (skip != null) 'skip': skip,
        if (take != null) 'take': take,
      },
    );
    final data = response.data;
    if (data == null) throw StateError('Get categories returned no data');
    return LabCategoriesResponse.fromJson(data);
  }

  Future<LabCategory> updateCategory(
    String id, {
    String? name,
    String? description,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/categories/$id',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
      },
    );
    final data = response.data;
    if (data == null) throw StateError('Update category returned no data');
    return LabCategory.fromJson(data);
  }

  Future<void> deleteCategory(String id) async {
    await _dio.delete('$_prefix/categories/$id');
  }

  // ── Tests ───────────────────────────────────────────────────────────────

  Future<LabTest> createTest({
    required String categoryId,
    required String name,
    required String sampleType,
    String? description,
    double? price,
    bool? isActive,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/tests',
      data: {
        'categoryId': categoryId,
        'name': name,
        'sampleType': sampleType,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (price != null) 'price': price,
        if (isActive != null) 'isActive': isActive,
      },
    );
    final data = response.data;
    if (data == null) throw StateError('Create test returned no data');
    return LabTest.fromJson(data);
  }

  Future<LabTestsResponse> getTests({
    String? categoryId,
    bool? isActive,
    int? skip,
    int? take,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/tests',
      queryParameters: {
        if (categoryId != null) 'categoryId': categoryId,
        if (isActive != null) 'isActive': isActive,
        if (skip != null) 'skip': skip,
        if (take != null) 'take': take,
        if (fromDate != null) 'fromDate': AppTimezone.toBackendIso(fromDate),
        if (toDate != null) 'toDate': AppTimezone.toBackendIso(toDate),
      },
    );
    final data = response.data;
    if (data == null) throw StateError('Get tests returned no data');
    return LabTestsResponse.fromJson(data);
  }

  Future<LabTest> getTestById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('$_prefix/tests/$id');
    final data = response.data;
    if (data == null) throw StateError('Get test returned no data');
    return LabTest.fromJson(data);
  }

  Future<LabTest> updateTest(
    String id, {
    String? categoryId,
    String? name,
    String? sampleType,
    String? description,
    double? price,
    bool? isActive,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/tests/$id',
      data: {
        if (categoryId != null) 'categoryId': categoryId,
        if (name != null) 'name': name,
        if (sampleType != null) 'sampleType': sampleType,
        if (description != null) 'description': description,
        if (price != null) 'price': price,
        if (isActive != null) 'isActive': isActive,
      },
    );
    final data = response.data;
    if (data == null) throw StateError('Update test returned no data');
    return LabTest.fromJson(data);
  }

  Future<void> deleteTest(String id) async {
    await _dio.delete('$_prefix/tests/$id');
  }

  // ── Test versions ────────────────────────────────────────────────────────

  Future<LabTestVersion> createTestVersion(
    String testId, {
    bool setActive = true,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/tests/$testId/version',
      data: {'setActive': setActive},
    );
    final data = response.data;
    if (data == null) throw StateError('Create version returned no data');
    return LabTestVersion.fromJson(data);
  }

  Future<List<LabTestVersion>> getTestVersions(String testId) async {
    final response = await _dio.get<List<dynamic>>(
      '$_prefix/tests/$testId/versions',
    );
    final list = response.data;
    if (list == null) return [];
    return list
        .map((e) => LabTestVersion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Test fields ──────────────────────────────────────────────────────────

  Future<LabTestField> createTestField({
    required String testVersionId,
    required String label,
    required String fieldType,
    String? unit,
    String? referenceRange,
    bool? required,
    int? position,
    String? optionsJson,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/test-fields',
      data: {
        'testVersionId': testVersionId,
        'label': label,
        'fieldType': fieldType,
        if (unit != null && unit.isNotEmpty) 'unit': unit,
        if (referenceRange != null && referenceRange.isNotEmpty)
          'referenceRange': referenceRange,
        if (required != null) 'required': required,
        if (position != null) 'position': position,
        if (optionsJson != null && optionsJson.isNotEmpty)
          'optionsJson': optionsJson,
      },
    );
    final data = response.data;
    if (data == null) throw StateError('Create field returned no data');
    return LabTestField.fromJson(data);
  }

  Future<List<LabTestField>> getTestFields(String versionId) async {
    final response = await _dio.get<List<dynamic>>(
      '$_prefix/test-fields/$versionId',
    );
    final list = response.data;
    if (list == null) return [];
    return list
        .map((e) => LabTestField.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// PATCH `/test-fields/field/:id` avoids clashing with
  /// `GET /test-fields/:testVersionId`.
  Future<LabTestField> updateTestField(
    String fieldId, {
    String? label,
    String? fieldType,
    String? unit,
    String? referenceRange,
    bool? required,
    int? position,
    String? optionsJson,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/test-fields/field/$fieldId',
      data: {
        if (label != null) 'label': label,
        if (fieldType != null) 'fieldType': fieldType,
        if (unit != null) 'unit': unit,
        if (referenceRange != null) 'referenceRange': referenceRange,
        if (required != null) 'required': required,
        if (position != null) 'position': position,
        if (optionsJson != null) 'optionsJson': optionsJson,
      },
    );
    final data = response.data;
    if (data == null) throw StateError('Update field returned no data');
    return LabTestField.fromJson(data);
  }

  Future<void> deleteTestField(String fieldId) async {
    await _dio.delete('$_prefix/test-fields/field/$fieldId');
  }

  // ── Orders ───────────────────────────────────────────────────────────────

  Future<LabOrder> createOrder({
    required String patientId,
    String? doctorId,
    required List<LabOrderItemInput> items,
    String? invoiceId,
    String? invoiceItemId,
    String? serviceId,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('At least one test version is required');
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/orders',
      data: {
        'patientId': patientId,
        if (doctorId != null && doctorId.isNotEmpty) 'doctorId': doctorId,
        if (invoiceId != null && invoiceId.isNotEmpty) 'invoiceId': invoiceId,
        if (invoiceItemId != null && invoiceItemId.isNotEmpty)
          'invoiceItemId': invoiceItemId,
        if (serviceId != null && serviceId.isNotEmpty) 'serviceId': serviceId,
        'items': items.map((e) => e.toJson()).toList(),
      },
    );
    final data = response.data;
    if (data == null) throw StateError('Create order returned no data');
    return LabOrder.fromJson(data);
  }

  Future<LabOrdersResponse> getOrders({
    String? patientId,
    LabOrderStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    int? skip,
    int? take,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/orders',
      queryParameters: {
        if (patientId != null) 'patientId': patientId,
        if (status != null) 'status': status.apiValue,
        if (fromDate != null) 'fromDate': AppTimezone.toBackendIso(fromDate),
        if (toDate != null) 'toDate': AppTimezone.toBackendIso(toDate),
        if (skip != null) 'skip': skip,
        if (take != null) 'take': take,
      },
    );
    final data = response.data;
    if (data == null) throw StateError('Get orders returned no data');
    return LabOrdersResponse.fromJson(data);
  }

  Future<LabOrder> getOrderById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/orders/$id',
    );
    final data = response.data;
    if (data == null) throw StateError('Get order returned no data');
    return LabOrder.fromJson(data);
  }

  Future<LabOrder> updateOrderStatus(String id, LabOrderStatus status) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/orders/$id',
      data: {'status': status.apiValue},
    );
    final data = response.data;
    if (data == null) throw StateError('Update order returned no data');
    return LabOrder.fromJson(data);
  }

  // ── Samples ──────────────────────────────────────────────────────────────

  Future<LabSample> createSample({
    required String orderItemId,
    required String sampleType,
    required String collectedBy,
    required DateTime collectionTime,
    String? barcode,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/samples',
      data: {
        'orderItemId': orderItemId,
        'sampleType': sampleType,
        'collectedBy': collectedBy,
        'collectionTime': collectionTime.toIso8601String(),
        if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
      },
    );
    final data = response.data;
    if (data == null) throw StateError('Create sample returned no data');
    return LabSample.fromJson(data);
  }

  // ── Results ──────────────────────────────────────────────────────────────

  Future<void> createResult({
    required String orderItemId,
    required String fieldId,
    required String value,
    required String enteredBy,
  }) async {
    await _dio.post(
      '$_prefix/results',
      data: {
        'orderItemId': orderItemId,
        'fieldId': fieldId,
        'value': value,
        'enteredBy': enteredBy,
      },
    );
  }

  /// Each map: `fieldId`, `value`, and optional `hiddenFromReport` (per-result only).
  Future<void> createResultsBatch({
    required String orderItemId,
    required String enteredBy,
    required List<Map<String, dynamic>> results,
  }) async {
    await _dio.post(
      '$_prefix/results/batch',
      data: {
        'orderItemId': orderItemId,
        'enteredBy': enteredBy,
        'results': results,
      },
    );
  }

  Future<List<LabResult>> getResults(String orderItemId) async {
    final response = await _dio.get<List<dynamic>>(
      '$_prefix/results/$orderItemId',
    );
    final list = response.data;
    if (list == null) return [];
    return list
        .map((e) => LabResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Antibiotics ──────────────────────────────────────────────────────────

  Future<LabAntibiotic> createAntibiotic({
    required String name,
    String? code,
    bool isActive = true,
    int position = 0,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/antibiotics',
      data: {
        'name': name,
        if (code != null && code.isNotEmpty) 'code': code,
        'isActive': isActive,
        'position': position,
      },
    );
    final data = response.data;
    if (data == null) throw StateError('Create antibiotic returned no data');
    return LabAntibiotic.fromJson(data);
  }

  Future<LabAntibioticsResponse> getAntibiotics({
    bool? activeOnly,
    int? skip,
    int? take,
  }) async {
    final response = await _dio.get<dynamic>(
      '$_prefix/antibiotics',
      queryParameters: {
        if (activeOnly == true) 'activeOnly': true,
        if (skip != null) 'skip': skip,
        if (take != null) 'take': take,
      },
    );
    return _antibioticsResponseFromBody(response.data);
  }

  Future<LabAntibiotic> updateAntibiotic(
    String id, {
    String? name,
    String? code,
    bool? isActive,
    int? position,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/antibiotics/$id',
      data: {
        if (name != null) 'name': name,
        if (code != null) 'code': code,
        if (isActive != null) 'isActive': isActive,
        if (position != null) 'position': position,
      },
    );
    final data = response.data;
    if (data == null) throw StateError('Update antibiotic returned no data');
    return LabAntibiotic.fromJson(data);
  }

  Future<void> deleteAntibiotic(String id) async {
    await _dio.delete('$_prefix/antibiotics/$id');
  }

  // ── AST result options ───────────────────────────────────────────────────

  Future<LabAstResultOption> createAstResultOption({
    required String label,
    String? code,
    bool isActive = true,
    int position = 0,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/ast-result-options',
      data: {
        'label': label,
        if (code != null && code.isNotEmpty) 'code': code,
        'isActive': isActive,
        'position': position,
      },
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Create AST result option returned no data');
    }
    return LabAstResultOption.fromJson(data);
  }

  Future<LabAstResultOptionsResponse> getAstResultOptions({
    bool? activeOnly,
    int? skip,
    int? take,
  }) async {
    final response = await _dio.get<dynamic>(
      '$_prefix/ast-result-options',
      queryParameters: {
        if (activeOnly == true) 'activeOnly': true,
        if (skip != null) 'skip': skip,
        if (take != null) 'take': take,
      },
    );
    return _astResultOptionsResponseFromBody(response.data);
  }

  Future<LabAstResultOption> updateAstResultOption(
    String id, {
    String? label,
    String? code,
    bool? isActive,
    int? position,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/ast-result-options/$id',
      data: {
        if (label != null) 'label': label,
        if (code != null) 'code': code,
        if (isActive != null) 'isActive': isActive,
        if (position != null) 'position': position,
      },
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Update AST result option returned no data');
    }
    return LabAstResultOption.fromJson(data);
  }

  Future<void> deleteAstResultOption(String id) async {
    await _dio.delete('$_prefix/ast-result-options/$id');
  }

  // ── AST results ──────────────────────────────────────────────────────────

  Future<List<LabAstResult>> getAstResults(String orderItemId) async {
    final response = await _dio.get<dynamic>(
      '$_prefix/ast-results/$orderItemId',
    );
    return _jsonObjectListFromResponse(
      response.data,
    ).map(LabAstResult.fromJson).toList();
  }

  Future<List<LabAstResult>> createAstResultsBatch({
    required String orderItemId,
    required String enteredBy,
    required List<Map<String, String>> results,
  }) async {
    final response = await _dio.post<dynamic>(
      '$_prefix/ast-results/batch',
      data: {
        'orderItemId': orderItemId,
        'enteredBy': enteredBy,
        'results': results
            .map(
              (e) => {
                'antibioticId': e['antibioticId'],
                'resultOptionId': e['resultOptionId'],
              },
            )
            .toList(),
      },
    );
    return _jsonObjectListFromResponse(
      response.data,
    ).map(LabAstResult.fromJson).toList();
  }

  @visibleForTesting
  static List<Map<String, dynamic>> jsonObjectListFromResponseForTest(
    dynamic data,
  ) => _jsonObjectListFromResponse(data);

  /// Backend may return a bare JSON array, `{ "data": [...] }`, or
  /// `{ "orderItemId": "...", "results": [...] }` for AST results.
  static List<Map<String, dynamic>> _jsonObjectListFromResponse(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in ['data', 'results']) {
        final inner = map[key];
        if (inner is List) {
          return inner.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    }
    throw StateError('Expected list response, got ${data.runtimeType}');
  }

  static LabAntibioticsResponse _antibioticsResponseFromBody(dynamic data) {
    if (data == null) {
      throw StateError('Get antibiotics returned no data');
    }
    if (data is List) {
      final items = data
          .map(
            (e) => LabAntibiotic.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      return LabAntibioticsResponse(data: items, total: items.length);
    }
    if (data is Map) {
      return LabAntibioticsResponse.fromJson(Map<String, dynamic>.from(data));
    }
    throw StateError('Expected antibiotics response, got ${data.runtimeType}');
  }

  static LabAstResultOptionsResponse _astResultOptionsResponseFromBody(
    dynamic data,
  ) {
    if (data == null) {
      throw StateError('Get AST result options returned no data');
    }
    if (data is List) {
      final items = data
          .map(
            (e) => LabAstResultOption.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
      return LabAstResultOptionsResponse(data: items, total: items.length);
    }
    if (data is Map) {
      return LabAstResultOptionsResponse.fromJson(
        Map<String, dynamic>.from(data),
      );
    }
    throw StateError(
      'Expected AST result options response, got ${data.runtimeType}',
    );
  }

  // ── Investigations (receptionist reporting) ─────────────────────────────

  Future<InvestigationSummary> getInvestigationsSummary(
    InvestigationsQueryParams params,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/investigations/summary',
      queryParameters: params.toQueryParameters(includePagination: false),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Get investigations summary returned no data');
    }
    return InvestigationSummary.fromJson(data);
  }

  Future<InvestigationListResponse> getInvestigations(
    InvestigationsQueryParams params,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/investigations',
      queryParameters: params.toQueryParameters(),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Get investigations returned no data');
    }
    return InvestigationListResponse.fromJson(data);
  }
}

// ── Response wrappers ──────────────────────────────────────────────────────

class LabCategoriesResponse {
  const LabCategoriesResponse({
    required this.data,
    required this.total,
    this.skip,
    this.take,
  });

  final List<LabCategory> data;
  final int total;
  final int? skip;
  final int? take;

  factory LabCategoriesResponse.fromJson(Map<String, dynamic> json) =>
      LabCategoriesResponse(
        data: (json['data'] as List<dynamic>)
            .map((e) => LabCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as num).toInt(),
        skip: (json['skip'] as num?)?.toInt(),
        take: (json['take'] as num?)?.toInt(),
      );
}

class LabTestsResponse {
  const LabTestsResponse({
    required this.data,
    required this.total,
    this.skip,
    this.take,
  });

  final List<LabTest> data;
  final int total;
  final int? skip;
  final int? take;

  factory LabTestsResponse.fromJson(Map<String, dynamic> json) =>
      LabTestsResponse(
        data: (json['data'] as List<dynamic>)
            .map((e) => LabTest.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as num).toInt(),
        skip: (json['skip'] as num?)?.toInt(),
        take: (json['take'] as num?)?.toInt(),
      );
}

class LabOrdersResponse {
  const LabOrdersResponse({
    required this.data,
    required this.total,
    this.skip,
    this.take,
  });

  final List<LabOrder> data;
  final int total;
  final int? skip;
  final int? take;

  factory LabOrdersResponse.fromJson(Map<String, dynamic> json) =>
      LabOrdersResponse(
        data: (json['data'] as List<dynamic>)
            .map((e) => LabOrder.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as num).toInt(),
        skip: (json['skip'] as num?)?.toInt(),
        take: (json['take'] as num?)?.toInt(),
      );
}

class LabAntibioticsResponse {
  const LabAntibioticsResponse({
    required this.data,
    required this.total,
    this.skip,
    this.take,
  });

  final List<LabAntibiotic> data;
  final int total;
  final int? skip;
  final int? take;

  factory LabAntibioticsResponse.fromJson(Map<String, dynamic> json) =>
      LabAntibioticsResponse(
        data: (json['data'] as List<dynamic>)
            .map((e) => LabAntibiotic.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as num).toInt(),
        skip: (json['skip'] as num?)?.toInt(),
        take: (json['take'] as num?)?.toInt(),
      );
}

class LabAstResultOptionsResponse {
  const LabAstResultOptionsResponse({
    required this.data,
    required this.total,
    this.skip,
    this.take,
  });

  final List<LabAstResultOption> data;
  final int total;
  final int? skip;
  final int? take;

  factory LabAstResultOptionsResponse.fromJson(Map<String, dynamic> json) =>
      LabAstResultOptionsResponse(
        data: (json['data'] as List<dynamic>)
            .map((e) => LabAstResultOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as num).toInt(),
        skip: (json['skip'] as num?)?.toInt(),
        take: (json['take'] as num?)?.toInt(),
      );
}
