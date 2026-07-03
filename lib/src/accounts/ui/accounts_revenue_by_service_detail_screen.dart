import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/accounts/accounts_palette.dart';
import 'package:helty/src/accounts/auth/accounting_permissions.dart';
import 'package:helty/src/accounts/models/accounts_models.dart';
import 'package:helty/src/accounts/providers/accounts_providers.dart';
import 'package:helty/src/accounts/widgets/accounts_access_denied.dart';
import 'package:helty/src/accounts/widgets/accounts_async_scaffold.dart';
import 'package:helty/src/accounts/widgets/accounts_data_table_box.dart';
import 'package:helty/src/accounts/widgets/accounts_money_format.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class AccountsRevenueByServiceDetailScreen extends ConsumerStatefulWidget {
  const AccountsRevenueByServiceDetailScreen({
    super.key,
    required this.serviceCategory,
    required this.period,
    this.asOf,
  });

  final String serviceCategory;
  final String period;
  final DateTime? asOf;

  @override
  ConsumerState<AccountsRevenueByServiceDetailScreen> createState() =>
      _AccountsRevenueByServiceDetailScreenState();
}

class _AccountsRevenueByServiceDetailScreenState
    extends ConsumerState<AccountsRevenueByServiceDetailScreen> {
  static const _take = 50;

  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  int _skip = 0;
  String _debouncedQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final q = _searchCtrl.text.trim();
      if (q == _debouncedQuery) return;
      setState(() {
        _debouncedQuery = q;
        _skip = 0;
      });
    });
  }

  AccountsRevenueByServiceDetailsParams get _params {
    return AccountsRevenueByServiceDetailsParams(
      period: widget.period,
      asOf: widget.asOf,
      serviceCategory: widget.serviceCategory,
      skip: _skip,
      take: _take,
      q: _debouncedQuery.isEmpty ? null : _debouncedQuery,
    );
  }

  void _goToPage(int skip) {
    setState(() => _skip = skip);
  }

  @override
  Widget build(BuildContext context) {
    if (!canViewRevenueByService(ref.watch(authProvider).staff)) {
      return const AccountsAccessDenied(title: 'Revenue by service');
    }

    final async = ref.watch(accountsRevenueByServiceDetailsProvider(_params));
    final fmt = accountsNairaFormat();
    final periodLabel = AccountsPeriodFilter.labelFor(widget.period);

    return AccountsAsyncScaffold<AccountsRevenueByServiceDetailsResponse>(
      title: widget.serviceCategory,
      subtitle: '$periodLabel — payment details',
      colors: AccountsPalette.reports,
      asyncValue: async,
      onRetry: () =>
          ref.invalidate(accountsRevenueByServiceDetailsProvider(_params)),
      header: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: _searchCtrl,
          decoration: const InputDecoration(
            hintText: 'Search patient, ID, phone, or invoice…',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ),
      builder: (context, data) {
        final showingFrom = data.total == 0 ? 0 : data.skip + 1;
        final showingTo = (data.skip + data.rows.length).clamp(0, data.total);
        final hasPrev = data.skip > 0;
        final hasNext = data.skip + data.take < data.total;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${fmt.format(data.totalAmount)} total · ${data.total} transactions'
              '${data.total > 0 ? ' · showing $showingFrom–$showingTo' : ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            if (data.rows.isEmpty)
              const Expanded(
                child: AccountsEmptyState(
                  title: 'No payments found',
                  subtitle: 'Try a different search or period.',
                ),
              )
            else
              Expanded(
                child: AccountsDataTableBox(
                  child: DataTable2(
                  minWidth: 1100,
                  columns: const [
                      DataColumn2(label: Text('Date'), size: ColumnSize.S),
                      DataColumn2(label: Text('Patient'), size: ColumnSize.M),
                      DataColumn2(label: Text('Hospital ID'), size: ColumnSize.S),
                      DataColumn2(label: Text('Service'), size: ColumnSize.M),
                      DataColumn2(label: Text('Qty'), size: ColumnSize.S),
                      DataColumn2(label: Text('Amount'), size: ColumnSize.S),
                      DataColumn2(
                        label: Text('Payment'),
                        size: ColumnSize.S,
                      ),
                      DataColumn2(label: Text('Invoice #'), size: ColumnSize.S),
                      DataColumn2(
                        label: Text('Received by'),
                        size: ColumnSize.S,
                      ),
                    ],
                    rows: [
                      for (final r in data.rows)
                        DataRow2(
                          cells: [
                            DataCell(
                              Text(
                                DateFormatter.dateTimeWithSeconds(r.paidAt),
                              ),
                            ),
                            DataCell(
                              _LinkCell(
                                label: r.patient.displayName,
                                enabled: r.patient.id.isNotEmpty,
                                onTap: () => context.router.push(
                                  PatientChartRoute(
                                    patientUuid: r.patient.id,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(r.patient.patientId ?? '—')),
                            DataCell(Text(r.service.name ?? '—')),
                            DataCell(Text('${r.lineItem.quantity}')),
                            DataCell(Text(fmt.format(r.amount))),
                            DataCell(
                              Text(
                                r.payment.method?.isNotEmpty == true
                                    ? r.payment.method!
                                    : r.payment.source,
                              ),
                            ),
                            DataCell(
                              _LinkCell(
                                label: r.invoice.invoiceID,
                                enabled: r.invoice.id.isNotEmpty,
                                onTap: () => context.router.push(
                                  PatientBillingRoute(
                                    invoiceId: r.invoice.id,
                                    patientName: r.patient.displayName,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(r.payment.receivedBy)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            if (data.total > _take) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: hasPrev
                        ? () => _goToPage((data.skip - _take).clamp(0, data.total))
                        : null,
                    child: const Text('Previous'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: hasNext
                        ? () => _goToPage(data.skip + _take)
                        : null,
                    child: const Text('Next'),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LinkCell extends StatelessWidget {
  const _LinkCell({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!enabled || label.isEmpty) {
      return Text(label.isEmpty ? '—' : label);
    }
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
