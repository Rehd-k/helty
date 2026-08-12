import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:helty/src/services/api_service.dart';

enum HospitalReportKind {
  wardAdmissions,
  requestsByWard,
  dischargeHistory,
  medicalRecordsAttendance,
  medicalRecordsAdmissions,
}

enum HospitalReportExportFormat { json, csv, xlsx }

extension HospitalReportKindX on HospitalReportKind {
  String get path => switch (this) {
    HospitalReportKind.wardAdmissions => '/reports/ward-admissions',
    HospitalReportKind.requestsByWard => '/reports/requests-by-ward',
    HospitalReportKind.dischargeHistory => '/reports/discharge-history',
    HospitalReportKind.medicalRecordsAttendance =>
      '/reports/medical-records/attendance',
    HospitalReportKind.medicalRecordsAdmissions =>
      '/reports/medical-records/admissions',
  };

  String get title => switch (this) {
    HospitalReportKind.wardAdmissions => 'Ward admissions',
    HospitalReportKind.requestsByWard => 'Requests by ward',
    HospitalReportKind.dischargeHistory => 'Discharge history',
    HospitalReportKind.medicalRecordsAttendance => 'Attendance',
    HospitalReportKind.medicalRecordsAdmissions => 'Admissions summary',
  };

  String get exportBasename => switch (this) {
    HospitalReportKind.wardAdmissions => 'ward-admissions',
    HospitalReportKind.requestsByWard => 'requests-by-ward',
    HospitalReportKind.dischargeHistory => 'discharge-history',
    HospitalReportKind.medicalRecordsAttendance =>
      'medical-records-attendance',
    HospitalReportKind.medicalRecordsAdmissions =>
      'medical-records-admissions',
  };

  bool get requiresRequestType => this == HospitalReportKind.requestsByWard;
}

class HospitalReportsService {
  HospitalReportsService({Dio? dio}) : _dio = dio ?? ApiService().dio;

  final Dio _dio;

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _query({
    required DateTime from,
    required DateTime to,
    HospitalReportExportFormat? format,
    String? requestType,
    String? wardId,
  }) {
    return {
      'from': _ymd(from),
      'to': _ymd(to),
      if (format != null && format != HospitalReportExportFormat.json)
        'format': format.name,
      if (requestType != null && requestType.trim().isNotEmpty)
        'type': requestType.trim().toLowerCase(),
      if (wardId != null && wardId.trim().isNotEmpty) 'wardId': wardId.trim(),
    };
  }

  Future<dynamic> fetchJson({
    required HospitalReportKind kind,
    required DateTime from,
    required DateTime to,
    String? requestType,
    String? wardId,
  }) async {
    final resp = await _dio.get(
      kind.path,
      queryParameters: _query(
        from: from,
        to: to,
        requestType: requestType,
        wardId: wardId,
      ),
    );
    return resp.data;
  }

  Future<Uint8List> exportBytes({
    required HospitalReportKind kind,
    required DateTime from,
    required DateTime to,
    required HospitalReportExportFormat format,
    String? requestType,
    String? wardId,
  }) async {
    if (format == HospitalReportExportFormat.json) {
      throw ArgumentError('Use fetchJson for JSON format');
    }
    final resp = await _dio.get<List<int>>(
      kind.path,
      queryParameters: _query(
        from: from,
        to: to,
        format: format,
        requestType: requestType,
        wardId: wardId,
      ),
      options: Options(responseType: ResponseType.bytes),
    );
    final data = resp.data;
    if (data == null) throw StateError('Empty export response');
    return Uint8List.fromList(data);
  }

  /// Flattens common JSON report shapes into table rows for on-screen display.
  static List<Map<String, String>> flattenForTable(dynamic payload) {
    if (payload == null) return const [];
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry('$k', _cell(v))))
          .toList();
    }
    if (payload is Map) {
      for (final key in [
        'rows',
        'items',
        'data',
        'admissions',
        'encounters',
        'groups',
        'wards',
        'results',
      ]) {
        final nested = payload[key];
        if (nested is List) {
          return flattenForTable(nested);
        }
      }
      return [payload.map((k, v) => MapEntry('$k', _cell(v)))];
    }
    return [
      {'value': payload.toString()},
    ];
  }

  static String _cell(dynamic v) {
    if (v == null) return '';
    if (v is Map || v is List) return v.toString();
    return v.toString();
  }
}
