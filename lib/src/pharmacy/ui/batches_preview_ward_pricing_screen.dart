import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_exception.dart';
import '../models/pharmacy_model.dart';
import '../services/pharmacy_service.dart';

/// Ward / batch pricing preview for a drug (route: `pharmacy/batchespreview-ward-pricing/:id`).
@RoutePage()
class BatchesPreviewWardPricingScreen extends StatefulWidget {
  const BatchesPreviewWardPricingScreen({
    super.key,
    @PathParam('id') required this.id,
  });

  /// Drug id from the path.
  final String id;

  @override
  State<BatchesPreviewWardPricingScreen> createState() =>
      _BatchesPreviewWardPricingScreenState();
}

class _BatchesPreviewWardPricingScreenState
    extends State<BatchesPreviewWardPricingScreen> {
  final _api = PharmacyApiService();

  bool _loading = true;
  String? _error;
  Drug? _drug;
  List<DrugBatch> _batches = const [];
  List<DrugPrice> _wardPrices = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getBatchesPreviewWardPricing(widget.id);
      if (!mounted) return;
      setState(() {
        _applyPayload(data);
        _loading = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applyPayload(Map<String, dynamic> data) {
    final drugRaw = data['drug'];
    if (drugRaw is Map) {
      try {
        _drug = Drug.fromJson(Map<String, dynamic>.from(drugRaw));
      } catch (_) {
        _drug = null;
      }
    } else {
      _drug = null;
    }

    _batches = _parseBatchList(
      data['batches'] ??
          data['items'] ??
          data['data'] ??
          data['drugBatches'],
    );

    _wardPrices = _parseWardPriceList(
      data['wardPricing'] ??
          data['wardPrices'] ??
          data['prices'] ??
          data['drugPrices'],
    );
  }

  List<DrugBatch> _parseBatchList(dynamic raw) {
    if (raw is! List) return const [];
    final out = <DrugBatch>[];
    for (final e in raw) {
      if (e is! Map) continue;
      try {
        out.add(DrugBatch.fromJson(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    return out;
  }

  List<DrugPrice> _parseWardPriceList(dynamic raw) {
    if (raw is! List) return const [];
    final out = <DrugPrice>[];
    for (final e in raw) {
      if (e is! Map) continue;
      try {
        out.add(DrugPrice.fromJson(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _drug?.brandName ?? 'Ward pricing preview';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.router.maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Drug ID: ${widget.id}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (_drug != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _drug!.genericName,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Batches',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_batches.isEmpty)
                      Text(
                        'No batch rows returned (or unrecognized shape).',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      _BatchesTable(batches: _batches),
                    const SizedBox(height: 28),
                    Text(
                      'Ward pricing',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_wardPrices.isEmpty)
                      Text(
                        'No ward price rows returned (or unrecognized shape).',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      _WardPricesTable(prices: _wardPrices),
                  ],
                ),
              ),
            ),
    );
  }
}

class _BatchesTable extends StatelessWidget {
  const _BatchesTable({required this.batches});

  final List<DrugBatch> batches;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Batch')),
          DataColumn(label: Text('Expiry')),
          DataColumn(label: Text('Qty')),
          DataColumn(label: Text('Cost')),
        ],
        rows: batches.map((b) {
          return DataRow(
            cells: [
              DataCell(Text(b.batchNumber ?? '—')),
              DataCell(
                Text(
                  b.expiryDate != null ? dateFmt.format(b.expiryDate!) : '—',
                ),
              ),
              DataCell(Text('${b.quantityRemaining ?? b.quantityReceived}')),
              DataCell(
                Text(
                  b.costPrice != null
                      ? b.costPrice!.toFinancial(isMoney: true)
                      : '—',
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _WardPricesTable extends StatelessWidget {
  const _WardPricesTable({required this.prices});

  final List<DrugPrice> prices;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Ward')),
          DataColumn(label: Text('Price')),
        ],
        rows: prices.map((p) {
          return DataRow(
            cells: [
              DataCell(Text(p.wardName ?? p.wardId)),
              DataCell(Text(p.price.toFinancial(isMoney: true))),
            ],
          );
        }).toList(),
      ),
    );
  }
}
