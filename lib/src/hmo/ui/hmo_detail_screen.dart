import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../models/hmo_models.dart';
import '../../services/hmo_service.dart';
import 'package:helty/app_router.gr.dart';

@RoutePage()
class HmoDetailScreen extends StatefulWidget {
  const HmoDetailScreen({super.key, required this.hmoId});

  final String hmoId;

  @override
  State<HmoDetailScreen> createState() => _HmoDetailScreenState();
}

class _HmoDetailScreenState extends State<HmoDetailScreen> {
  final _svc = HmoService();
  bool _loading = true;
  String? _error;
  HmoDetail? _detail;

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
      final d = await _svc.getById(widget.hmoId);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _confirmDeletePrice(HmoServicePriceRow row) async {
    final name = row.service?.name ?? row.serviceId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove HMO price'),
        content: Text(
          'Remove pricing for "$name"? Billing will fall back to the catalog cost.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _svc.deleteServicePrice(widget.hmoId, row.serviceId);
      if (!mounted) return;
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price removed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete HMO'),
        content: const Text(
          'This cannot be undone. Patients must be reassigned first if linked.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _svc.delete(widget.hmoId);
      if (!mounted) return;
      context.router.maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = _detail;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(d?.name ?? 'HMO'),
        actions: [
          if (d != null) ...[
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await context.router.push(HmoFormRoute(hmoId: d.id));
                _load();
              },
            ),
            IconButton(
              tooltip: 'Add / edit pricing',
              icon: const Icon(Icons.price_change_outlined),
              onPressed: () async {
                await context.router.push(
                  HmoServicePricingRoute(initialHmoId: d.id),
                );
                _load();
              },
            ),
            IconButton(
              tooltip: 'Delete',
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: _confirmDelete,
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : d == null
          ? const Center(child: Text('Not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (d.code != null && d.code!.isNotEmpty)
                            Text('Code: ${d.code}', style: theme.textTheme.bodyLarge),
                          if (d.notes != null && d.notes!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(d.notes!, style: theme.textTheme.bodyMedium),
                          ],
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _showPatients(context, d.id),
                            icon: const Icon(Icons.people_outline),
                            label: const Text('View enrollees'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Service pricing',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: d.servicePrices.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No service prices configured.',
                              style: TextStyle(color: theme.hintColor),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Service')),
                                DataColumn(label: Text('HMO price'), numeric: true),
                                DataColumn(label: Text('Catalog cost'), numeric: true),
                                DataColumn(label: Text('HMO pays'), numeric: true),
                                DataColumn(label: Text('Patient pays'), numeric: true),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: d.servicePrices.map((p) {
                                final name = p.service?.name ?? p.serviceId;
                                return DataRow(
                                  cells: [
                                    DataCell(Text(name)),
                                    DataCell(Text(p.fullCost.toStringAsFixed(2))),
                                    DataCell(Text(
                                      p.service?.cost?.toStringAsFixed(2) ?? '—',
                                    )),
                                    DataCell(Text(
                                      p.hasConfiguredSplit
                                          ? p.hmoPays.toStringAsFixed(2)
                                          : '—',
                                    )),
                                    DataCell(Text(
                                      p.hasConfiguredSplit
                                          ? p.patientPays.toStringAsFixed(2)
                                          : '—',
                                    )),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Edit',
                                            icon: const Icon(Icons.edit_outlined, size: 20),
                                            onPressed: () async {
                                              await context.router.push(
                                                HmoServicePricingRoute(
                                                  initialHmoId: d.id,
                                                  initialServiceId: p.serviceId,
                                                ),
                                              );
                                              _load();
                                            },
                                          ),
                                          IconButton(
                                            tooltip: 'Remove',
                                            icon: Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: theme.colorScheme.error,
                                            ),
                                            onPressed: () => _confirmDeletePrice(p),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _showPatients(BuildContext context, String hmoId) async {
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: FutureBuilder<HmoPatientsPagedResult>(
            future: HmoService().listPatients(hmoId, take: 50),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('${snap.error}'),
                );
              }
              final r = snap.data!;
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Enrollees (${r.total})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: r.patients
                            .map(
                              (p) => ListTile(
                                title: Text(p.displayName),
                                subtitle: Text(
                                  '${p.patientId}${p.phoneNumber != null ? ' · ${p.phoneNumber}' : ''}',
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
