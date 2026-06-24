import '../../helper/app_timezone.dart';
import '../../radiology/models/radiology_models.dart';

enum InvestigationSortBy {
  createdAt,
  testName,
  amount,
  patientName,
  status;

  String get apiValue {
    switch (this) {
      case InvestigationSortBy.createdAt:
        return 'createdAt';
      case InvestigationSortBy.testName:
        return 'testName';
      case InvestigationSortBy.amount:
        return 'amount';
      case InvestigationSortBy.patientName:
        return 'patientName';
      case InvestigationSortBy.status:
        return 'status';
    }
  }

  static InvestigationSortBy fromApiValue(String? value) {
    if (value == null || value.isEmpty) return InvestigationSortBy.createdAt;
    for (final e in InvestigationSortBy.values) {
      if (e.apiValue == value) return e;
    }
    return InvestigationSortBy.createdAt;
  }
}

enum InvestigationSortOrder {
  asc,
  desc;

  String get apiValue => name;

  static InvestigationSortOrder fromApiValue(String? value) {
    if (value == null || value.isEmpty) return InvestigationSortOrder.desc;
    return value.toLowerCase() == 'asc'
        ? InvestigationSortOrder.asc
        : InvestigationSortOrder.desc;
  }
}

/// Query parameters for lab/radiology investigations endpoints.
class InvestigationsQueryParams {
  const InvestigationsQueryParams({
    this.fromDate,
    this.toDate,
    this.testName,
    this.status,
    this.departmentId,
    this.categoryId,
    this.sampleCollected,
    this.priority,
    this.sortBy = InvestigationSortBy.createdAt,
    this.sortOrder = InvestigationSortOrder.desc,
    this.skip = 0,
    this.take = 20,
  });

  final DateTime? fromDate;
  final DateTime? toDate;
  final String? testName;
  final String? status;
  final String? departmentId;
  final String? categoryId;
  final bool? sampleCollected;
  final RadiologyPriority? priority;
  final InvestigationSortBy sortBy;
  final InvestigationSortOrder sortOrder;
  final int skip;
  final int take;

  InvestigationsQueryParams copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    String? testName,
    String? status,
    String? departmentId,
    String? categoryId,
    bool? sampleCollected,
    bool clearSampleCollected = false,
    RadiologyPriority? priority,
    bool clearPriority = false,
    InvestigationSortBy? sortBy,
    InvestigationSortOrder? sortOrder,
    int? skip,
    int? take,
  }) {
    return InvestigationsQueryParams(
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      testName: testName ?? this.testName,
      status: status ?? this.status,
      departmentId: departmentId ?? this.departmentId,
      categoryId: categoryId ?? this.categoryId,
      sampleCollected:
          clearSampleCollected ? null : (sampleCollected ?? this.sampleCollected),
      priority: clearPriority ? null : (priority ?? this.priority),
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      skip: skip ?? this.skip,
      take: take ?? this.take,
    );
  }

  Map<String, dynamic> toQueryParameters({bool includePagination = true}) {
    final trimmedTest = testName?.trim();
    return {
      if (fromDate != null) 'fromDate': AppTimezone.toBackendIso(fromDate!),
      if (toDate != null) 'toDate': AppTimezone.toBackendIso(toDate!),
      if (trimmedTest != null && trimmedTest.isNotEmpty) 'testName': trimmedTest,
      if (status != null && status!.isNotEmpty) 'status': status,
      if (departmentId != null && departmentId!.isNotEmpty)
        'departmentId': departmentId,
      if (categoryId != null && categoryId!.isNotEmpty) 'categoryId': categoryId,
      if (sampleCollected != null) 'sampleCollected': sampleCollected,
      if (priority != null) 'priority': priority!.apiValue,
      if (includePagination) ...{
        'sortBy': sortBy.apiValue,
        'sortOrder': sortOrder.apiValue,
        'skip': skip,
        'take': take,
      },
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvestigationsQueryParams &&
          runtimeType == other.runtimeType &&
          fromDate == other.fromDate &&
          toDate == other.toDate &&
          testName == other.testName &&
          status == other.status &&
          departmentId == other.departmentId &&
          categoryId == other.categoryId &&
          sampleCollected == other.sampleCollected &&
          priority == other.priority &&
          sortBy == other.sortBy &&
          sortOrder == other.sortOrder &&
          skip == other.skip &&
          take == other.take;

  @override
  int get hashCode => Object.hash(
        fromDate,
        toDate,
        testName,
        status,
        departmentId,
        categoryId,
        sampleCollected,
        priority,
        sortBy,
        sortOrder,
        skip,
        take,
      );
}

InvestigationsQueryParams investigationsParamsForDay(DateTime day) {
  return InvestigationsQueryParams(
    fromDate: AppTimezone.dateTime(day.year, day.month, day.day),
    toDate: AppTimezone.dateTime(day.year, day.month, day.day, 23, 59, 59, 999),
  );
}
