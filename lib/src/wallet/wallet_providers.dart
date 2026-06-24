import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/invoice_billing_models.dart';
import '../patient_chart/models/patient_chart_models.dart';
import '../patient_chart/services/patient_chart_service.dart';
import '../providers/invoices_providers.dart';

@immutable
class WalletHistoryQuery {
  const WalletHistoryQuery({
    required this.patientUuid,
    this.skip = 0,
    this.limit = 20,
    this.fromDate,
    this.toDate,
    this.typeFilter,
  });

  final String patientUuid;
  final int skip;
  final int limit;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? typeFilter;

  @override
  bool operator ==(Object other) {
    return other is WalletHistoryQuery &&
        other.patientUuid == patientUuid &&
        other.skip == skip &&
        other.limit == limit &&
        other.fromDate == fromDate &&
        other.toDate == toDate &&
        other.typeFilter == typeFilter;
  }

  @override
  int get hashCode => Object.hash(
    patientUuid,
    skip,
    limit,
    fromDate,
    toDate,
    typeFilter,
  );
}

final patientChartServiceProvider = Provider<PatientChartService>((ref) {
  return PatientChartService();
});

final patientWalletHistoryProvider = FutureProvider.autoDispose
    .family<WalletChartPage, WalletHistoryQuery>((ref, query) async {
      final chartService = ref.watch(patientChartServiceProvider);
      final chart = await chartService.getChart(
        query.patientUuid,
        include: [PatientChartSectionKeys.wallet],
        limit: query.limit,
        skip: query.skip,
        fromDate: query.fromDate,
        toDate: query.toDate,
      );
      final walletSection = chart.sections[PatientChartSectionKeys.wallet];
      final sectionMap = walletSection != null && walletSection.isNotEmpty
          ? walletSection.first
          : null;
      var page = WalletChartPage.fromChartSection(
        sectionMap,
        summaryBalance: chart.summary.walletBalance,
        patientChartNumber: chart.patient.patientId,
        patientName: chart.patient.displayName,
      );
      if (query.typeFilter != null && query.typeFilter!.isNotEmpty) {
        final filter = query.typeFilter!.toUpperCase();
        page = WalletChartPage(
          wallet: page.wallet,
          transactions: page.transactions
              .where((t) => t.type.toUpperCase() == filter)
              .toList(),
          walletBalance: page.walletBalance,
          patientChartNumber: page.patientChartNumber ?? chart.patient.patientId,
          patientName: page.patientName ?? chart.patient.displayName,
        );
      }
      return page;
    });

void invalidatePatientWalletHistory(WidgetRef ref, String patientUuid) {
  ref.invalidate(patientWalletProvider(patientUuid));
  ref.invalidate(walletTransactionsProvider(patientUuid));
  ref.invalidate(patientWalletHistoryProvider);
}
